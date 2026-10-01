import Foundation
import Combine

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var currentUser: User? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // ข้อมูลกรณีถูกแบน
    @Published var isBanned: Bool = false
    @Published var banInfo: BanInfo? = nil

    private let baseURL = "https://your-domain.com/api" // ⚠️ เปลี่ยนเป็น URL Server ของคุณ
    private let tokenKey = "user_session_token"

    init() {
        checkAuthStatus()
    }

    // MARK: - Get Token
    private var token: String? {
        get { UserDefaults.standard.string(forKey: tokenKey) }
        set { UserDefaults.standard.set(newValue, forKey: tokenKey) }
    }

    // MARK: - Check Auth Status
    func checkAuthStatus() {
        guard let savedToken = token, !savedToken.isEmpty else {
            self.isAuthenticated = false
            return
        }

        guard let url = URL(string: "\(baseURL)/check_auth.php") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else {
                    self?.isAuthenticated = false
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    // กรณีถูกแบน (HTTP 403)
                    if httpResponse.statusCode == 403 {
                        if let banResponse = try? JSONDecoder().decode(APIResponse<User>.self, from: data) {
                            self?.handleBan(banInfo: banResponse.banInfo)
                            return
                        }
                    }
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<User>.self, from: data)
                    if decoded.status, let user = decoded.data {
                        self?.currentUser = user
                        self?.isAuthenticated = true
                    } else {
                        self?.logoutLocal()
                    }
                } catch {
                    self?.logoutLocal()
                }
            }
        }.resume()
    }

    // MARK: - Login
    func login(userLogin: String, userPassword: String) {
        guard let url = URL(string: "\(baseURL)/login.php") else { return }
        
        isLoading = true
        errorMessage = nil

        let body: [String: String] = [
            "user_login": userLogin,
            "user_password": userPassword
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data = data, error == nil else {
                    self?.errorMessage = "Network error. Please try again."
                    return
                }

                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 403 {
                    if let banResponse = try? JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data) {
                        self?.handleBan(banInfo: banResponse.banInfo)
                        return
                    }
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                    if decoded.status, let responseData = decoded.data {
                        self?.token = responseData.sessionToken
                        self?.currentUser = responseData.toUser()
                        self?.isAuthenticated = true
                    } else {
                        self?.errorMessage = decoded.message
                    }
                } catch {
                    self?.errorMessage = "Invalid server response."
                }
            }
        }.resume()
    }

    // MARK: - Register
    func register(fullName: String, username: String, email: String, password: String) {
        guard let url = URL(string: "\(baseURL)/register.php") else { return }

        isLoading = true
        errorMessage = nil

        let body: [String: String] = [
            "full_name": fullName,
            "username": username,
            "email": email,
            "password": password
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                guard let data = data, error == nil else {
                    self?.errorMessage = "Network error. Please try again."
                    return
                }

                do {
                    let decoded = try JSONDecoder().decode(APIResponse<UserDataResponse>.self, from: data)
                    if decoded.status, let responseData = decoded.data {
                        self?.token = responseData.sessionToken
                        self?.currentUser = responseData.toUser()
                        self?.isAuthenticated = true
                    } else {
                        self?.errorMessage = decoded.message
                    }
                } catch {
                    self?.errorMessage = "Registration failed."
                }
            }
        }.resume()
    }

    // MARK: - Logout
    func logout() {
        guard let savedToken = token, let url = URL(string: "\(baseURL)/logout.php") else {
            logoutLocal()
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(savedToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] _, _, _ in
            DispatchQueue.main.async {
                self?.logoutLocal()
            }
        }.resume()
    }

    private func logoutLocal() {
        token = nil
        currentUser = nil
        isAuthenticated = false
    }

    private func handleBan(banInfo: BanInfo?) {
        logoutLocal()
        self.isBanned = true
        self.banInfo = banInfo
    }
}

// MARK: - Helper Data Struct for Auth API Response
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
