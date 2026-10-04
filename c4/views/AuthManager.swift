import Foundation
import UIKit
import Combine

// MARK: - AuthManager Helper Models
struct UserDataResponse: Codable {
    let userId: Int
    let fullName: String
    let avatarUrl: String?
    let deviceId: Int?
    let udid: String?
    let token: String

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case deviceId = "device_id"
        case udid
        case token
    }

    func toUser() -> User {
        return User(
            id: userId,
            fullName: fullName,
            avatarUrl: avatarUrl,
            deviceId: deviceId,
            udid: udid,
            token: token
        )
    }
}

// MARK: - AuthManager
@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil
    
    // 🟢 ตัวแปรจัดการ Loading State ขณะเปิดแอป (ป้องกัน UI เด้งไป RegisterView ก่อน API ตอบกลับ)
    @Published var isCheckingAuth: Bool = false
    
    // ข้อมูลกรณีถูกแบน
    @Published var isBanned: Bool = false
    @Published var banInfo: BanInfo? = nil

    // ข้อมูลกรณีบัญชีถูกลบ
    @Published var isAccountDeleted: Bool = false

    private let baseURL = "https://f1x3r.org/f1x3r_auth"
    private let tokenKey = "user_session_token"

    init() {
        checkAuthStatus()
    }

    // MARK: - Token Management
    private var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    func clearMessages() {
        errorMessage = nil
        successMessage = nil
    }

    // MARK: - Notifications (FTNotificationIndicator)
    func showSuccessNotification(message: String) {
        let icon = UIImage(systemName: "checkmark.circle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        FTNotificationIndicator.setNotificationIndicatorStyle(.dark)
        FTNotificationIndicator.showNotification(
            with: icon,
            title: "สำเร็จ",
            message: message
        )
    }

    func showErrorNotification(message: String) {
        let icon = UIImage(systemName: "exclamationmark.triangle")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        FTNotificationIndicator.setNotificationIndicatorStyle(.dark)
        FTNotificationIndicator.showNotification(
            with: icon,
            title: "ผิดพลาด",
            message: message
        )
    }

    // MARK: - 1. Check Auth Status (หรือ Auto Login ผ่าน UDID กรณีลบแอป)
    func checkAuthStatus() {
        // 🟢 ป้องกันการยิง API ซ้ำซ้อนหากกำลังตรวจสอบอยู่แล้ว
        guard !isCheckingAuth else { return }
        
        isCheckingAuth = true
        let currentUDID = UIDevice.current.identifierForVendor?.uuidString ?? ""

        // 🟢 กรณีที่ 1: มี Token ค้างอยู่ใน UserDefaults
        if let savedToken = token, !savedToken.isEmpty {
            guard let url = URL(string: "\(baseURL)/check_auth.php") else {
                isCheckingAuth = false
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

            URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
                Task { @MainActor in
                    guard let data = data, error == nil else {
                        // ถ้าเกิด Network Error กับ Token ให้ลอง fallback เช็คผ่าน UDID
                        self?.isCheckingAuth = false
                        self?.autoLoginWithUDID(udid: currentUDID)
                        return
                    }

                    do {
                        let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                        if decoded.status, let user = decoded.data {
                            self?.currentUser = user
                            self?.isAuthenticated = true
                            self?.isBanned = false
                            self?.isAccountDeleted = false
                            self?.isCheckingAuth = false
                            
                            // 🟢 Token สมบูรณ์: สั่งอัปเดตข้อมูลเกมล่วงหน้าทันที
                            TargetGameManager.shared.fetchTargetGames(showHUD: false)
                        } else {
                            // 🔴 ตรวจสอบรหัสการแบน หรือการลบบัญชี
                            let bannedCodes = [
                                "DEVICE_PERMANENTLY_BANNED",
                                "DEVICE_TEMPORARILY_BANNED",
                                "ACCOUNT_PERMANENTLY_BANNED",
                                "ACCOUNT_TEMPORARILY_BANNED"
                            ]
                            if let errorCode = decoded.errorCode, bannedCodes.contains(errorCode) {
                                // 🟢 ไม่แสดง FT Notification เพราะมี BannedView คุมเต็มหน้าจอแล้ว
                                self?.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message, showNotification: false)
                            } else if decoded.errorCode == "ACCOUNT_DELETED" {
                                self?.handleAccountDeleted(message: decoded.message, showNotification: false)
                            } else {
                                // 🔴 ถ้า Token ใช้ไม่ได้/หมดอายุ สั่งยิงเช็ค UDID ต่อทันที
                                self?.isCheckingAuth = false
                                self?.autoLoginWithUDID(udid: currentUDID)
                            }
                        }
                    } catch {
                        self?.isCheckingAuth = false
                        self?.autoLoginWithUDID(udid: currentUDID)
                    }
                }
            }.resume()
        } 
        // 🟢 กรณีที่ 2: ไม่มี Token -> Auto Login ผ่าน UDID ทันที
        else if !currentUDID.isEmpty {
            self.isCheckingAuth = false
            self.autoLoginWithUDID(udid: currentUDID)
        } else {
            self.isAuthenticated = false
            self.isCheckingAuth = false
        }
    }

    // 🟢 ฟังก์ชัน Auto Login ผ่าน UDID เมื่อเปิดแอปครั้งแรกหลังติดตั้งใหม่
    private func autoLoginWithUDID(udid: String) {
        guard !isCheckingAuth else { return }
        isCheckingAuth = true

        guard let url = URL(string: "\(baseURL)/register.php") else {
            self.isCheckingAuth = false
            return
        }
        
        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"udid\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(udid)\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                defer { self?.isCheckingAuth = false } // 👈 ปิดสถานะกำลังเช็คเสมอเมื่อจบกระบวนการ
                
                guard let data = data, error == nil else {
                    self?.logoutLocal()
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                    
                    let bannedCodes = [
                        "DEVICE_PERMANENTLY_BANNED",
                        "DEVICE_TEMPORARILY_BANNED",
                        "ACCOUNT_PERMANENTLY_BANNED",
                        "ACCOUNT_TEMPORARILY_BANNED"
                    ]

                    // 🔴 1. เช็คว่าติดแบนหรือไม่
                    if let errorCode = decoded.errorCode, bannedCodes.contains(errorCode) {
                        self?.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message, showNotification: false)
                    } 
                    // 🚫 2. เช็คว่าบัญชีถูกลบไปแล้วหรือไม่ -> สลับไปหน้า AccountDeletedView
                    else if decoded.errorCode == "ACCOUNT_DELETED" {
                        self?.handleAccountDeleted(message: decoded.message, showNotification: false)
                    }
                    // 🟢 3. ถ้าเป็นผู้ใช้เดิม (isExistingUser = true) -> Auto Login เข้าใช้งานทันที
                    else if decoded.status, decoded.isExistingUser == true, let responseData = decoded.data {
                        self?.token = responseData.token
                        self?.currentUser = responseData.toUser()
                        self?.isAuthenticated = true
                        self?.isBanned = false
                        self?.isAccountDeleted = false
                        
                        // 🟢 เมื่อ Auto Login สำเร็จและได้ Token ใหม่มาแล้ว สั่งดึงข้อมูลเกมทันที!
                        TargetGameManager.shared.fetchTargetGames(showHUD: false)
                    } 
                    // ⚪️️ 4. กรณี UDID ใหม่ที่ยังไม่เคยลงทะเบียน -> ไปหน้า RegisterView
                    else {
                        self?.logoutLocal()
                    }
                } catch {
                    self?.logoutLocal()
                }
            }
        }.resume()
    }

    // MARK: - 2. Register / Manual Submit (Multipart Form Data)
    func register(fullName: String, udid: String, avatarImageData: Data?, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUDID = udid.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedUDID.isEmpty else {
            let msg = "ไม่พบรหัส UDID ของเครื่อง"
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let url = URL(string: "\(baseURL)/register.php") else { return }

        isLoading = true

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        // สร้าง Multipart Data Body
        var body = Data()
        
        // 1. full_name
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"full_name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(trimmedFullName)\r\n".data(using: .utf8)!)

        // 2. udid
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"udid\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(trimmedUDID)\r\n".data(using: .utf8)!)

        // 3. avatar (ถ้ามีรูปภาพ)
        if let avatarData = avatarImageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(avatarData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                self?.isLoading = false
                guard let data = data, error == nil else {
                    let msg = "การเชื่อมต่อเครือข่ายล้มเหลว"
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                    if decoded.status, let responseData = decoded.data {
                        self?.token = responseData.token
                        self?.currentUser = responseData.toUser()
                        self?.isAuthenticated = true
                        self?.isBanned = false
                        self?.isAccountDeleted = false

                        // 🟢 ลงทะเบียนสำเร็จ: สั่งโหลดรายการเกมทันที
                        TargetGameManager.shared.fetchTargetGames(showHUD: false)

                        let msg = decoded.isExistingUser == true ? "ยินดีต้อนรับกลับ! เข้าสู่ระบบเรียบร้อย" : "ลงทะเบียนเรียบร้อยแล้ว"
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                        completion(true)
                    } else {
                        let bannedCodes = [
                            "DEVICE_PERMANENTLY_BANNED",
                            "DEVICE_TEMPORARILY_BANNED",
                            "ACCOUNT_PERMANENTLY_BANNED",
                            "ACCOUNT_TEMPORARILY_BANNED"
                        ]
                        if let errorCode = decoded.errorCode, bannedCodes.contains(errorCode) {
                            // กรณีสมัครเอง ให้เด้ง Notification เตือนสั้นๆ ด้วย
                            self?.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message, showNotification: true)
                        } else if decoded.errorCode == "ACCOUNT_DELETED" {
                            self?.handleAccountDeleted(message: decoded.message, showNotification: true)
                        } else {
                            let msg = decoded.message ?? "ไม่สามารถลงทะเบียนได้"
                            self?.errorMessage = msg
                            self?.showErrorNotification(message: msg)
                        }
                        completion(false)
                    }
                } catch {
                    let msg = "เกิดข้อผิดพลาดในการประมวลผลข้อมูล"
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                }
            }
        }.resume()
    }

    // MARK: - 3. Logout
    func logout() {
        clearMessages()

        guard let savedToken = token, let url = URL(string: "\(baseURL)/logout.php") else {
            logoutLocal()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            Task { @MainActor in
                self?.logoutLocal()
                let msg = "ออกจากระบบเรียบร้อยแล้ว"
                self?.successMessage = msg
                self?.showSuccessNotification(message: msg)
            }
        }.resume()
    }

    private func logoutLocal() {
        token = nil
        currentUser = nil
        isAuthenticated = false
        isBanned = false
        isAccountDeleted = false
    }

    private func handleBan(banInfo: BanInfo?, errorCode: String?, message: String?, showNotification: Bool = false) {
        logoutLocal()
        self.isBanned = true
        self.banInfo = banInfo
        self.isCheckingAuth = false
        
        let msg = message ?? "บัญชีหรืออุปกรณ์ของคุณถูกระงับการใช้งาน"
        self.errorMessage = msg
        
        if showNotification {
            self.showErrorNotification(message: msg)
        }
    }

    // 🟢 ฟังก์ชันสำหรับจัดการเมื่อบัญชีถูกลบ
    private func handleAccountDeleted(message: String?, showNotification: Bool = false) {
        logoutLocal()
        self.isAccountDeleted = true
        self.isCheckingAuth = false
        
        let msg = message ?? "บัญชีที่ผูกกับอุปกรณ์นี้ถูกลบแล้ว ไม่สามารถใช้งานหรือสมัครใหม่ได้"
        self.errorMessage = msg
        
        if showNotification {
            self.showErrorNotification(message: msg)
        }
    }
}
