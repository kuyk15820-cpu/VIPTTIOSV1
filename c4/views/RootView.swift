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
            // 🟢 3. แสดงหน้าหลักเมื่อยืนยันตัวตนสำเร็จ (รวมถึงกรณีที่ระบบสร้างบัญชีอัตโนมัติด้วย UDID เรียบร้อยแล้ว)
            else {
                TargetGameView()
            }
        }
        .environmentObject(authManager)
    }
}

// MARK: - Preview
struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(AuthManager())
    }
}
