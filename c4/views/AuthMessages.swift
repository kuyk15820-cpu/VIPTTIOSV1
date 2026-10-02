import Foundation

struct AuthMessages {
    
    // MARK: - Success Messages
    struct Success {
        static let login = "เข้าสู่ระบบสำเร็จ"
        static let logout = "ออกจากระบบสำเร็จ"
        static let otpSent = "ส่งรหัส OTP ไปยังอีเมลของคุณเรียบร้อยแล้ว"
        static let registrationCompleted = "สมัครสมาชิกสำเร็จ"
        static let resetRequestSent = "หากมีอีเมลนี้ในระบบ ระบบได้ส่งรหัส OTP ไปยังอีเมลของคุณแล้ว"
        static let passwordUpdated = "เปลี่ยนรหัสผ่านสำเร็จ คุณสามารถเข้าสู่ระบบด้วยรหัสผ่านใหม่ได้ทันที"
    }
    
    // MARK: - Client Validation Warnings (เช็กในแอปก่อนยิง API)
    struct Warning {
        static let emptyCredentials = "กรุณากรอกอีเมล/ชื่อผู้ใช้ และรหัสผ่านให้ครบถ้วน"
        static let emptyEmail = "กรุณากรอกอีเมล"
        static let emptyOTP = "กรุณากรอกรหัส OTP ให้ครบถ้วน"
        static let invalidEmailFormat = "รูปแบบอีเมลไม่ถูกต้อง"
        static let invalidUsernameFormat = "ชื่อผู้ใช้ใช้อักขระได้เฉพาะตัวอักษร, ตัวเลข, '@', '_' หรือ '-' เท่านั้น"
        static let invalidOTPFormat = "รหัส OTP ต้องเป็นตัวเลข 4 หลัก"
        static let passwordTooShort = "รหัสผ่านต้องมีความยาวอย่างน้อย 8 ตัวอักษร"
        static let passwordMismatch = "รหัสผ่านทั้งสองช่องไม่ตรงกัน"
        static let emptyFullName = "กรุณากรอกชื่อ-นามสกุล"
        static let emptyUsername = "กรุณากรอกชื่อผู้ใช้"
        static let emptyPassword = "กรุณากรอกรหัสผ่าน"
    }
    
    // MARK: - Server Errors & Mapping
    struct Error {
        static let invalidCredentials = "อีเมล/ชื่อผู้ใช้ หรือรหัสผ่านไม่ถูกต้อง"
        static let usernameTaken = "ชื่อผู้ใช้นี้ถูกลงทะเบียนไปแล้ว"
        static let emailTaken = "อีเมลนี้ถูกลงทะเบียนไปแล้ว"
        static let otpExpired = "รหัส OTP หมดอายุแล้ว กรุณากดขอรหัสใหม่อีกครั้ง"
        static let tooManyOTPFailed = "กรอกรหัสผิดเกินจำนวนที่กำหนด กรุณากดขอรหัสใหม่อีกครั้ง"
        static let invalidOTP = "รหัส OTP ไม่ถูกต้อง กรุณาตรวจสอบอีกครั้ง"
        static let invalidSession = "เซสชันหมดอายุ หรือไม่พบข้อมูลการทำรายการ"
        static let bannedPermanent = "บัญชีของคุณถูกระงับการใช้งานถาวร"
        static let bannedTemporary = "บัญชีของคุณถูกระงับการใช้งานชั่วคราว"
        static let unauthorized = "เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง"
        static let dbConnectionFailed = "ไม่สามารถเชื่อมต่อฐานข้อมูลได้ กรุณาลองใหม่อีกครั้ง"
        static let networkFailed = "ไม่สามารถเชื่อมต่ออินเทอร์เน็ตได้ กรุณาตรวจสอบการเชื่อมต่อ"
        static let unknown = "เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง"
        
        /// ฟังก์ชัน Map ข้อความจาก Backend JSON Response (ทั้งจาก `error_code` และ `message`)
        static func from(errorCode: String?, serverMessage: String?) -> String {
            if let errorCode = errorCode, !errorCode.isEmpty {
                switch errorCode.uppercased() {
                case "ACCOUNT_PERMANENTLY_BANNED":
                    return bannedPermanent
                case "ACCOUNT_TEMPORARILY_BANNED":
                    return bannedTemporary
                default:
                    break
                }
            }
            
            guard let serverMessage = serverMessage, !serverMessage.isEmpty else {
                return unknown
            }
            
            let msg = serverMessage.lowercased()
            
            // Map ตามข้อความตัวอย่างที่ส่งมาจาก Backend
            if msg.contains("invalid email/username or password") || msg.contains("please enter both email/username and password") {
                return invalidCredentials
            } else if msg.contains("username is already registered") {
                return usernameTaken
            } else if msg.contains("email is already registered") {
                return emailTaken
            } else if msg.contains("otp has expired") {
                return otpExpired
            } else if msg.contains("too many failed attempts") {
                return tooManyOTPFailed
            } else if msg.contains("invalid otp code") {
                return invalidOTP
            } else if msg.contains("unauthorized access") {
                return unauthorized
            } else if msg.contains("database connection failed") {
                return dbConnectionFailed
            } else if msg.contains("invalid registration session") || msg.contains("no active otp request") {
                return invalidSession
            }
            
            // กรณีเป็น Exception สด หรือข้อความอื่นๆ ที่ไม่ได้ตั้งเงื่อนไขไว้
            return serverMessage
        }
    }
}
