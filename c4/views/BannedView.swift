import SwiftUI

struct BannedView: View {
    @ObservedObject var authManager = AuthManager.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // 1. Icon แจ้งเตือน
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.1))
                    .frame(width: 120, height: 120)

                Image(systemName: "hand.raised.slash.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.red)
            }

            // 2. หัวข้อและข้อความหลัก
            VStack(spacing: 8) {
                Text("ระงับการใช้งาน")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(authManager.errorMessage ?? "บัญชีหรืออุปกรณ์ของคุณถูกระงับการเข้าใช้งานระบบ")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            // 3. การ์ดแสดงรายละเอียดการแบน (Ban Details Card)
            if let banInfo = authManager.banInfo {
                VStack(alignment: .leading, spacing: 14) {
                    // ประเภทการแบน
                    HStack {
                        Label("ประเภทการระงับ", systemName: "shield.exclamationmark")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(banInfo.type == "permanent" ? "ถาวร" : "ชั่วคราว")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(banInfo.type == "permanent" ? .red : .orange)
                    }

                    // วันที่ปลดแบน (กรณีแบนชั่วคราว)
                    if let banUntil = banInfo.banUntil, banInfo.type == "temporary" {
                        Divider()
                        HStack {
                            Label("สิ้นสุดการระงับ", systemName: "clock.arrow.circlepath")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(banUntil)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                    }

                    // เหตุผลการถูกแบน
                    if let reason = banInfo.reason, !reason.isEmpty {
                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Label("เหตุผล", systemName: "info.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Text(reason)
                                .font(.callout)
                                .foregroundColor(.primary)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 24)
            }

            Spacer()

            // 4. ปุ่มตรวจสอบสถานะการปลดแบน
            Button(action: {
                authManager.checkAuthStatus()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("ตรวจสอบสถานะอีกครั้ง")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }
}

// MARK: - Preview
struct BannedView_Previews: PreviewProvider {
    static var previews: some View {
        BannedView()
    }
}
