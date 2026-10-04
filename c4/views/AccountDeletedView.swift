import SwiftUI

struct AccountDeletedView: View {
    @EnvironmentObject var authManager: AuthManager
    
    // อีเมลหรือลิงก์สำหรับติดต่อ Support
    private let supportEmail = "support@f1x3r.org"

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Icon แจ้งเตือนการลบบัญชี
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 110, height: 110)

                    Image(systemName: "trash.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 70, height: 70)
                        .foregroundColor(.red)
                }

                // Title & Description
                VStack(spacing: 10) {
                    Text("บัญชีของคุณถูกลบแล้ว")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    Text("อุปกรณ์นี้ผูกอยู่กับบัญชีที่ถูกลบชั่วคราว จึงไม่สามารถเข้าใช้งานหรือลงทะเบียนสร้างบัญชีใหม่ได้")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }

                // Card คำแนะนำเพิ่มเติม
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.orange)
                        Text("หากต้องการกู้คืนบัญชี")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }

                    Text("หากคุณลบบัญชีโดยไม่ได้ตั้งใจ หรือต้องการกู้คืนข้อมูลบัญชีเดิม โปรดติดต่อทีมงานฝ่ายสนับสนุนผ่านช่องทางด้านล่าง")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineSpacing(3)
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
                .padding(.horizontal, 24)

                Spacer()

                // Action Buttons
                VStack(spacing: 12) {
                    // ปุ่มติดต่อ Support (เปิดเมล)
                    Button(action: openSupportEmail) {
                        HStack(spacing: 8) {
                            Image(systemName: "envelope.fill")
                            Text("ติดต่อฝ่ายสนับสนุน")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // ปุ่มกลับไปตรวจสอบสถานะใหม่
                    Button(action: {
                        Task {
                            await authManager.checkAuthStatus()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                            Text("ตรวจสอบสถานะอีกครั้ง")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(UIColor.tertiarySystemGroupedBackground))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }

    // ฟังก์ชันเปิด Mail App สำหรับส่งอีเมลติดต่อ Support
    private func openSupportEmail() {
        let mailTo = "mailto:\(supportEmail)?subject=คำขอกู้คืนบัญชีผู้ใช้&body=สวัสดีครับ/ค่ะ ต้องการติดต่อกู้คืนบัญชีผู้ใช้งานบนอุปกรณ์นี้"
        if let url = URL(string: mailTo.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "") {
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
    }
}

#Preview {
    AccountDeletedView()
        .environmentObject(AuthManager.shared)
}
