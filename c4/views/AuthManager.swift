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
    
    // ข้อมูลกรณีถูกแบน
    @Published var isBanned: Bool = false
    @Published var banInfo: BanInfo? = nil

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

    // MARK: - 1. Check Auth Status
    func checkAuthStatus() {
        guard let savedToken = token, !savedToken.isEmpty else {
            self.isAuthenticated = false
            return
        }

        guard let url = URL(string: "\(baseURL)/check_auth.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                guard let data = data, error == nil else {
                    self?.isAuthenticated = false
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                    if decoded.status, let user = decoded.data {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                        self?.isBanned = false
                    } else {
                        if decoded.errorCode == "DEVICE_PERMANENTLY_BANNED" || decoded.errorCode == "DEVICE_TEMPORARILY_BANNED" {
                            self?.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message)
                        } else {
                            self?.logoutLocal()
                        }
                    }
                } catch {
                    self?.logoutLocal()
                }
            }
        }.resume()
    }

    // MARK: - 2. Register Account (Multipart Form Data)
    func register(fullName: String, udid: String, avatarImageData: Data?, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUDID = udid.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedFullName.isEmpty else {
            let msg = "กรุณากรอกชื่อ-นามสกุล"
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard !trimmedUDID.isEmpty else {
            let msg = "ไม่พบรหัส UDID ของเครื่อง"
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let url = URL(string: "\(baseURL)/register_f1x3r.php") else { return }

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

                        let msg = "ลงทะเบียนเรียบร้อยแล้ว"
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                        completion(true)
                    } else {
                        // เช็คกรณีถูกแบน
                        if decoded.errorCode == "DEVICE_PERMANENTLY_BANNED" || decoded.errorCode == "DEVICE_TEMPORARILY_BANNED" {
                            self?.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message)
                        } else {
                            let msg = decoded.message
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
    }

    private func handleBan(banInfo: BanInfo?, errorCode: String?, message: String?) {
        logoutLocal()
        self.isBanned = true
        self.banInfo = banInfo
        
        let msg = message ?? "อุปกรณ์ของคุณถูกระงับการใช้งาน"
        self.errorMessage = msg
        self.showErrorNotification(message: msg)
    }
}
