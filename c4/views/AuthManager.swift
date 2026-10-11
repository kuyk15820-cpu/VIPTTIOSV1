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
    
    // 🟢 ตัวแปรจัดการ Loading State ขณะเปิดแอป (ป้องกัน UI เด้งก่อน API ตอบกลับ)
    @Published var isCheckingAuth: Bool = false
    
    // ข้อมูลกรณีถูกแบน
    @Published var isBanned: Bool = false
    @Published var banInfo: BanInfo? = nil

    // ข้อมูลกรณีบัญชีถูกลบ
    @Published var isAccountDeleted: Bool = false

    private let baseURL = "https://f1x3r.org/f1x3r_auth"
    private let tokenKey = "user_session_token"

    init() {
        Task { @MainActor in
            await checkAuthStatus()
        }
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

    // MARK: - 1. Check Auth Status (ตรวจสอบ Token หรือสร้างบัญชีอัตโนมัติผ่าน UDID)
    func checkAuthStatus() async {
        guard !isCheckingAuth else { return }
        
        isCheckingAuth = true
        defer { isCheckingAuth = false }
        
        let currentUDID = UIDevice.current.identifierForVendor?.uuidString ?? ""

        // 🟢 กรณีที่ 1: มี Token ค้างอยู่ใน UserDefaults -> ตรวจสอบความถูกต้องกับเซิร์ฟเวอร์
        if let savedToken = token, !savedToken.isEmpty {
            guard let url = URL(string: "\(baseURL)/check_auth.php") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                
                if decoded.status, let user = decoded.data {
                    self.currentUser = user
                    self.isAuthenticated = true
                    self.isBanned = false
                    self.isAccountDeleted = false
                } else {
                    let bannedCodes = [
                        "DEVICE_PERMANENTLY_BANNED",
                        "DEVICE_TEMPORARILY_BANNED",
                        "ACCOUNT_PERMANENTLY_BANNED",
                        "ACCOUNT_TEMPORARILY_BANNED"
                    ]
                    if let errorCode = decoded.errorCode, bannedCodes.contains(errorCode) {
                        self.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message, showNotification: false)
                    } else if decoded.errorCode == "ACCOUNT_DELETED" {
                        self.handleAccountDeleted(message: decoded.message, showNotification: false)
                    } else {
                        // 🔴 ถ้า Token หมดอายุหรือไม่ถูกต้อง -> ยิงขอเข้าสู่ระบบ/สร้างบัญชีอัตโนมัติด้วย UDID
                        await self.autoRegisterOrLoginWithUDID(udid: currentUDID)
                    }
                }
            } catch {
                await self.autoRegisterOrLoginWithUDID(udid: currentUDID)
            }
        } 
        // 🟢 กรณีที่ 2: ไม่มี Token -> ทำการสมัคร/เข้าสู่ระบบอัตโนมัติผ่าน UDID ทันที
        else if !currentUDID.isEmpty {
            await self.autoRegisterOrLoginWithUDID(udid: currentUDID)
        } else {
            self.isAuthenticated = false
        }
    }

    // 🟢 ฟังก์ชัน Auto Register / Login ผ่าน UDID (ส่งแค่ UDID ไป ถ้ายังไม่มี Server จะสร้างให้เอง)
    private func autoRegisterOrLoginWithUDID(udid: String) async {
        guard let url = URL(string: "\(baseURL)/register.php") else { return }
        
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

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
            
            let bannedCodes = [
                "DEVICE_PERMANENTLY_BANNED",
                "DEVICE_TEMPORARILY_BANNED",
                "ACCOUNT_PERMANENTLY_BANNED",
                "ACCOUNT_TEMPORARILY_BANNED"
            ]

            // 🔴 1. เช็คสถานะแบน
            if let errorCode = decoded.errorCode, bannedCodes.contains(errorCode) {
                self.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message, showNotification: false)
            } 
            // 🚫 2. เช็คสถานะถูกลบบัญชี
            else if decoded.errorCode == "ACCOUNT_DELETED" {
                self.handleAccountDeleted(message: decoded.message, showNotification: false)
            }
            // 🟢 3. สำเร็จ! ไม่ว่าจะเป็นผู้ใช้เดิมหรือถูกสร้างให้อัตโนมัติใหม่ บันทึก Token แล้วเข้าแอปได้ทันที
            else if decoded.status, let responseData = decoded.data {
                self.token = responseData.token
                self.currentUser = responseData.toUser()
                self.isAuthenticated = true
                self.isBanned = false
                self.isAccountDeleted = false
            } 
            else {
                self.logoutLocal()
            }
        } catch {
            self.logoutLocal()
        }
    }

    // MARK: - 2. Update Profile (สำหรับหน้า AccountView ไว้เปลี่ยนชื่อและรูปโปรไฟล์ทีหลัง)
    func updateProfile(fullName: String, avatarImageData: Data?, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedFullName.isEmpty else {
            let msg = "กรุณากรอกชื่อโปรไฟล์"
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let savedToken = token, let url = URL(string: "\(baseURL)/update_profile.php") else { // ปรับ URL ตามไฟล์ฝั่ง Server ของคุณ
            completion(false)
            return
        }

        isLoading = true

        let boundary = "Boundary-\(UUID().uuidString)"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

        var body = Data()
        
        // 1. full_name
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"full_name\"\r\n\r\n".data(using: .utf8)!)
        body.append("\(trimmedFullName)\r\n".data(using: .utf8)!)

        // 2. avatar (ถ้ามีเลือกรูปใหม่)
        if let avatarData = avatarImageData {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"avatar\"; filename=\"avatar.jpg\"\r\n".data(using: .utf8)!)
            body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            body.append(avatarData)
            body.append("\r\n".data(using: .utf8)!)
        }

        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body

        Task {
            do {
                let (data, _) = try await URLSession.shared.data(for: request)
                self.isLoading = false
                
                let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                if decoded.status, let responseData = decoded.data {
                    self.currentUser = responseData.toUser()
                    let msg = "อัปเดตข้อมูลส่วนตัวเรียบร้อยแล้ว"
                    self.successMessage = msg
                    self.showSuccessNotification(message: msg)
                    completion(true)
                } else {
                    let msg = decoded.message ?? "เกิดข้อผิดพลาดในการอัปเดตข้อมูล"
                    self.errorMessage = msg
                    self.showErrorNotification(message: msg)
                    completion(false)
                }
            } catch {
                self.isLoading = false
                let msg = "การเชื่อมต่อเครือข่ายล้มเหลว"
                self.errorMessage = msg
                self.showErrorNotification(message: msg)
                completion(false)
            }
        }
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

        Task {
            do {
                _ = try await URLSession.shared.data(for: request)
            } catch {
                // Ignore API error on logout
            }
            self.logoutLocal()
            let msg = "ออกจากระบบเรียบร้อยแล้ว"
            self.successMessage = msg
            self.showSuccessNotification(message: msg)
        }
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
        
        let msg = message ?? "บัญชีหรืออุปกรณ์ของคุณถูกระงับการใช้งาน"
        self.errorMessage = msg
        
        if showNotification {
            self.showErrorNotification(message: msg)
        }
    }

    private func handleAccountDeleted(message: String?, showNotification: Bool = false) {
        logoutLocal()
        self.isAccountDeleted = true
        
        let msg = message ?? "บัญชีที่ผูกกับอุปกรณ์นี้ถูกลบแล้ว ไม่สามารถใช้งานหรือสมัครใหม่ได้"
        self.errorMessage = msg
        
        if showNotification {
            self.showErrorNotification(message: msg)
        }
    }
}
