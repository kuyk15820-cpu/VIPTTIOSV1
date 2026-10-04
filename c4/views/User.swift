import Foundation

// MARK: - Register Response Data Model
/// รองรับ Object Data ที่ส่งกลับมาจาก register.php
struct User: Codable, Identifiable {
    let id: Int
    let fullName: String
    let avatarUrl: String?
    let deviceId: Int?
    let udid: String?
    let token: String?

    enum CodingKeys: String, CodingKey {
        case id = "user_id"          // PHP ส่งมาเป็น user_id
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
        case deviceId = "device_id"
        case udid
        case token
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
