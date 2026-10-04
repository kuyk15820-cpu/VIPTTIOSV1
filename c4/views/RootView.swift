import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            // 🔴 1. แสดงหน้าถูกแบนหากอุปกรณ์หรือบัญชีถูกระงับ
            if authManager.isBanned {
                BannedView()
            }
            // 🚫 2. แสดงหน้าแจ้งเตือนบัญชีถูกลบ
            else if authManager.isAccountDeleted {
                AccountDeletedView()
            }
            // 🟢 3. แสดงหน้าหลักเมื่อยืนยันตัวตนสำเร็จ
            else if authManager.isAuthenticated {
                TargetGameView()
            }
            // 🟡 4. แสดงหน้าลงทะเบียน/เข้าสู่ระบบ (กรณีเป็นอุปกรณ์ใหม่ยังไม่มีข้อมูล)
            else {
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
