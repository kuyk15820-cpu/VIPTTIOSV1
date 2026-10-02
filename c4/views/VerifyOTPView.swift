import SwiftUI

struct VerifyOTPView: View {
    @EnvironmentObject var authManager: AuthManager
    
    let email: String
    var onBack: () -> Void
    var onResend: () -> Void
    
    @State private var otpDigits: [String] = Array(repeating: "", count: 4)
    @FocusState private var focusedIndex: Int?
    @State private var localErrorMessage: String? = nil
    
    private let inputBorderColor = Color.white.opacity(0.3)
    
    var body: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Spacer()
            
            VStack(spacing: 20) {
                // Email Icon
                Image(systemName: "envelope.badge")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                
                Text("Enter Verification Code")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text("We've sent a 4-digit OTP code to:")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.bottom, 8)
                
                // 🟢 ช่องกรอก OTP แบบ 4 ช่องแยก
                HStack(spacing: 12) {
                    ForEach(0..<4, id: \.self) { index in
                        TextField("", text: Binding(
                            get: { otpDigits[index] },
                            set: { newValue in
                                handleOTPInput(at: index, value: newValue)
                            }
                        ))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .keyboardType(.numberPad)
                        .focused($focusedIndex, equals: index)
                        .frame(width: 56, height: 56)
                        .background(Color.clear)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(focusedIndex == index ? Color.white : inputBorderColor, lineWidth: 1.5)
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                if authManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding(.vertical, 8)
                }
                
                if let errorMessage = localErrorMessage ?? authManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                }
                
                // ปุ่ม Resend Code
                Button(action: {
                    otpDigits = Array(repeating: "", count: 4)
                    localErrorMessage = nil
                    setFocus(to: 0)
                    onResend()
                }) {
                    Text("Resend OTP Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .disabled(authManager.isLoading)
                .padding(.top, 12)
            }
            
            Spacer()
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear {
            setFocus(to: 0)
        }
    }
    
    // MARK: - Helper Functions
    
    private func handleOTPInput(at index: Int, value: String) {
        let filtered = value.filter { $0.isNumber }
        
        if filtered.count > 1 {
            // รองรับกรณี Paste หรือพิมพ์ไว
            let chars = Array(filtered)
            for i in 0..<min(chars.count, 4) {
                otpDigits[i] = String(chars[i])
            }
            if chars.count >= 4 {
                setFocus(to: nil)
                verifyOTP()
            } else {
                setFocus(to: chars.count)
            }
            return
        }
        
        if filtered.isEmpty {
            otpDigits[index] = ""
            if index > 0 {
                setFocus(to: index - 1)
            }
        } else {
            otpDigits[index] = String(filtered.last!)
            if index < 3 {
                setFocus(to: index + 1)
            } else {
                setFocus(to: nil)
                verifyOTP()
            }
        }
    }
    
    // 🟢 สลับ Focus อย่างปลอดภัยใน RunLoop ถัดไป
    private func setFocus(to targetIndex: Int?) {
        DispatchQueue.main.async {
            self.focusedIndex = targetIndex
        }
    }
    
    private func verifyOTP() {
        let fullOTP = otpDigits.joined()
        guard fullOTP.count == 4 else { return }
        
        localErrorMessage = nil
        authManager.verifyRegisterOTP(email: email, otp: fullOTP) { success in
            if !success {
                // ยืนยันไม่ผ่าน -> เคลียร์ช่องและเด้งไปช่องแรก
                otpDigits = Array(repeating: "", count: 4)
                setFocus(to: 0)
            }
        }
    }
}

#Preview {
    VerifyOTPView(email: "test@example.com", onBack: {}, onResend: {})
        .environmentObject(AuthManager())
}
