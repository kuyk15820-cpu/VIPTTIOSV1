import Foundation
import UIKit
import Combine

// MARK: - AuthManager Helper Models (ใช้เฉพาะในกระบวนการ Auth)
struct UserDataResponse: Codable {
    let id: Int
    let fullName: String
    let username: String
    let email: String
    let role: String
    let createdAt: String?
    let firstLoginAt: String?
    let lastLoginAt: String?
    let sessionToken: String

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case username
        case email
        case role
        case createdAt = "created_at"
        case firstLoginAt = "first_login_at"
        case lastLoginAt = "last_login_at"
        case sessionToken = "session_token"
    }

    func toUser() -> User {
        return User(
            id: id,
            fullName: fullName,
            username: username,
            email: email,
            role: role,
            createdAt: createdAt,
            firstLoginAt: firstLoginAt,
            lastLoginAt: lastLoginAt
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
                        if decoded.errorCode == "ACCOUNT_PERMANENTLY_BANNED" || decoded.errorCode == "ACCOUNT_TEMPORARILY_BANNED" {
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

    // MARK: - 2. Login
    func login(userLogin: String, userPassword: String) {
        clearMessages()

        let trimmedLogin = userLogin.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = userPassword.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedLogin.isEmpty, !trimmedPassword.isEmpty else {
            let msg = AuthMessages.Warning.emptyCredentials
            errorMessage = msg
            showErrorNotification(message: msg)
            return
        }

        guard let url = URL(string: "\(baseURL)/login.php") else { return }
        
        isLoading = true

        let body: [String: String] = [
            "user_login": trimmedLogin,
            "user_password": trimmedPassword
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                self?.isLoading = false
                guard let data = data, error == nil else {
                    let msg = AuthMessages.Error.networkFailed
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                    if decoded.status, let responseData = decoded.data {
                        self?.token = responseData.sessionToken
                        self?.currentUser = responseData.toUser()
                        self?.isAuthenticated = true
                        self?.isBanned = false
                        
                        let msg = AuthMessages.Success.login
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                    } else {
                        if decoded.errorCode == "ACCOUNT_PERMANENTLY_BANNED" || decoded.errorCode == "ACCOUNT_TEMPORARILY_BANNED" {
                            self?.handleBan(banInfo: decoded.banInfo, errorCode: decoded.errorCode, message: decoded.message)
                        } else {
                            let msg = AuthMessages.Error.from(errorCode: decoded.errorCode, serverMessage: decoded.message)
                            self?.errorMessage = msg
                            self?.showErrorNotification(message: msg)
                        }
                    }
                } catch {
                    let msg = AuthMessages.Error.unknown
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                }
            }
        }.resume()
    }

    // MARK: - 3. Register Request
    func requestRegisterOTP(fullName: String, username: String, email: String, password: String, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedUsername = username.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmedFullName.isEmpty {
            let msg = AuthMessages.Warning.emptyFullName
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }
        if trimmedUsername.isEmpty {
            let msg = AuthMessages.Warning.emptyUsername
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }
        if trimmedEmail.isEmpty {
            let msg = AuthMessages.Warning.emptyEmail
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }
        if password.count < 8 {
            let msg = AuthMessages.Warning.passwordTooShort
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let url = URL(string: "\(baseURL)/register_request.php") else { return }

        isLoading = true

        let body: [String: String] = [
            "full_name": trimmedFullName,
            "username": trimmedUsername,
            "email": trimmedEmail,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                self?.isLoading = false
                guard let data = data, error == nil else {
                    let msg = AuthMessages.Error.networkFailed
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                    if decoded.status {
                        let msg = AuthMessages.Success.otpSent
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                        completion(true)
                    } else {
                        let msg = AuthMessages.Error.from(errorCode: decoded.errorCode, serverMessage: decoded.message)
                        self?.errorMessage = msg
                        self?.showErrorNotification(message: msg)
                        completion(false)
                    }
                } catch {
                    let msg = AuthMessages.Error.unknown
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                }
            }
        }.resume()
    }

    // MARK: - 4. Register Verify
    func verifyRegisterOTP(email: String, otp: String, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOTP = otp.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            let msg = AuthMessages.Warning.emptyEmail
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard trimmedOTP.count == 4 else {
            let msg = AuthMessages.Warning.invalidOTPFormat
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let url = URL(string: "\(baseURL)/register_verify.php") else { return }

        isLoading = true

        let body: [String: String] = [
            "email": trimmedEmail,
            "otp": trimmedOTP
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                self?.isLoading = false
                guard let data = data, error == nil else {
                    let msg = AuthMessages.Error.networkFailed
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                    if decoded.status, let responseData = decoded.data {
                        self?.token = responseData.sessionToken
                        self?.currentUser = responseData.toUser()
                        self?.isAuthenticated = true
                        
                        let msg = AuthMessages.Success.registrationCompleted
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                        completion(true)
                    } else {
                        let msg = AuthMessages.Error.from(errorCode: decoded.errorCode, serverMessage: decoded.message)
                        self?.errorMessage = msg
                        self?.showErrorNotification(message: msg)
                        completion(false)
                    }
                } catch {
                    let msg = AuthMessages.Error.unknown
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                }
            }
        }.resume()
    }

    // MARK: - 5. Password Reset Request
    func requestPasswordReset(email: String, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            let msg = AuthMessages.Warning.emptyEmail
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let url = URL(string: "\(baseURL)/request_reset.php") else { return }

        isLoading = true

        let body: [String: String] = ["email": trimmedEmail]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                self?.isLoading = false
                guard let data = data, error == nil else {
                    let msg = AuthMessages.Error.networkFailed
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                    if decoded.status {
                        let msg = AuthMessages.Success.resetRequestSent
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                        completion(true)
                    } else {
                        let msg = AuthMessages.Error.from(errorCode: decoded.errorCode, serverMessage: decoded.message)
                        self?.errorMessage = msg
                        self?.showErrorNotification(message: msg)
                        completion(false)
                    }
                } catch {
                    let msg = AuthMessages.Error.unknown
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                }
            }
        }.resume()
    }

    // MARK: - 6. Reset Password
    func resetPassword(email: String, otp: String, newPassword: String, completion: @escaping (Bool) -> Void) {
        clearMessages()

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedOTP = otp.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            let msg = AuthMessages.Warning.emptyEmail
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard trimmedOTP.count == 4 else {
            let msg = AuthMessages.Warning.invalidOTPFormat
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard newPassword.count >= 8 else {
            let msg = AuthMessages.Warning.passwordTooShort
            errorMessage = msg
            showErrorNotification(message: msg)
            completion(false)
            return
        }

        guard let url = URL(string: "\(baseURL)/reset_password.php") else { return }

        isLoading = true

        let body: [String: String] = [
            "email": trimmedEmail,
            "otp": trimmedOTP,
            "new_password": newPassword
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            Task { @MainActor in
                self?.isLoading = false
                guard let data = data, error == nil else {
                    let msg = AuthMessages.Error.networkFailed
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                    if decoded.status {
                        let msg = AuthMessages.Success.passwordUpdated
                        self?.successMessage = msg
                        self?.showSuccessNotification(message: msg)
                        completion(true)
                    } else {
                        let msg = AuthMessages.Error.from(errorCode: decoded.errorCode, serverMessage: decoded.message)
                        self?.errorMessage = msg
                        self?.showErrorNotification(message: msg)
                        completion(false)
                    }
                } catch {
                    let msg = AuthMessages.Error.unknown
                    self?.errorMessage = msg
                    self?.showErrorNotification(message: msg)
                    completion(false)
                }
            }
        }.resume()
    }

    // MARK: - 7. Logout
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
                let msg = AuthMessages.Success.logout
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
        
        let msg = AuthMessages.Error.from(errorCode: errorCode, serverMessage: message)
        self.errorMessage = msg
        self.showErrorNotification(message: msg)
    }
}
