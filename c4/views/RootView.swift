import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    
    var body: some View {
        Group {
            // ⏳ 1. แสดงหน้า Loading ขณะกำลังตรวจสอบสถานะกับ Server (ป้องกันการเด้งไป RegisterView ก่อน)
            if authManager.isCheckingAuth {
                ProgressView("กำลังตรวจสอบข้อมูล...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(UIColor.systemBackground))
            }
            // 🔴 2. แสดงหน้าถูกแบนหากอุปกรณ์หรือบัญชีถูกระงับ
            else if authManager.isBanned {
                BannedView()
            }
            // 🚫 3. แสดงหน้าแจ้งเตือนบัญชีถูกลบ
            else if authManager.isAccountDeleted {
                AccountDeletedView()
            }
            // 🟢 4. แสดงหน้าหลักเมื่อยืนยันตัวตนสำเร็จ
            else if authManager.isAuthenticated {
                MainContentView()
            }
            // 🟡 5. แสดงหน้าลงทะเบียน/เข้าสู่ระบบ (กรณีเป็นอุปกรณ์ใหม่ยังไม่มีข้อมูล)
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
