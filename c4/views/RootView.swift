import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            if authManager.isBanned {
                // 🔴 แสดงหน้าถูกแบนหากอุปกรณ์หรือบัญชีถูกระงับ
                BannedView()
            } else if authManager.isAccountDeleted {
                // 🚫 แสดงหน้าแจ้งเตือนบัญชีถูกลบ
                AccountDeletedView()
            } else if authManager.isAuthenticated {
                // 🟢 แสดงหน้าหลักเมื่อยืนยันตัวตนสำเร็จ
                MainContentView()
            } else {
                // 🟡 แสดงหน้าลงทะเบียน/เข้าสู่ระบบ
                RegisterView()
            }
        }
        .environmentObject(authManager)
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
    }
}
