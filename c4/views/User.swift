import Foundation

// MARK: - User Model
struct User: Codable, Identifiable {
    let id: Int
    let fullName: String
    let username: String
    let email: String
    let role: String
    let createdAt: String?
    let firstLoginAt: String?
    let lastLoginAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case username
        case email
        case role
        case createdAt = "created_at"
        case firstLoginAt = "first_login_at"
        case lastLoginAt = "last_login_at"
    }
}

// MARK: - API Response Standard
struct APIResponse<T: Codable>: Codable {
    let status: Bool
    let message: String
    let data: T?
    let errors: [String: String]?
    let errorCode: String?
    let banInfo: BanInfo?

    enum CodingKeys: String, CodingKey {
        case status
        case message
        case data
        case errors
        case errorCode = "error_code"
        case banInfo = "ban_info"
    }
}

// MARK: - Ban Info Model
struct BanInfo: Codable {
    let type: String
    let banUntil: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case type
        case banUntil = "ban_until"
        case reason
    }
}
