import SwiftUI

struct VerifyOTPView: View {
    @EnvironmentObject var authManager: AuthManager
    
    let email: String
    var onBack: () -> Void
    var onResend: () -> Void
    
    @State private var otpText: String = ""
    @FocusState private var isFocused: Bool
    @State private var localErrorMessage: String? = nil
    
    private let otpLength = 4
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
                
                // 🟢 OTP Display Cards + Hidden Input Field
                ZStack {
                    // 1. Hidden TextField สำหรับรับ Input จริง
                    TextField("", text: $otpText)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isFocused)
                        .accentColor(.clear)
                        .foregroundColor(.clear)
                        .opacity(0.01)
                        .onChange(of: otpText) { newValue in
                            handleOTPChange(newValue)
                        }
                    
                    // 2. Visual Card Display (ดีไซน์คงเดิม 100%)
                    HStack(spacing: 12) {
                        ForEach(0..<otpLength, id: \.self) { index in
                            let digit = getDigit(at: index)
                            let isCurrentFocus = isFocused && (index == otpText.count || (index == otpLength - 1 && otpText.count == otpLength))
                            
                            Text(digit)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.clear)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isCurrentFocus ? Color.white : inputBorderColor, lineWidth: 1.5)
                                )
                        }
                    }
                    .allowsHitTesting(false)
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    isFocused = true
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
                    otpText = ""
                    localErrorMessage = nil
                    isFocused = true
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isFocused = true
            }
        }
    }
    
    // MARK: - Helper Functions
    
    private func getDigit(at index: Int) -> String {
        if index < otpText.count {
            let start = otpText.index(otpText.startIndex, offsetBy: index)
            return String(otpText[start])
        }
        return ""
    }
    
    private func handleOTPChange(_ newValue: String) {
        let filtered = newValue.filter { $0.isNumber }
        
        if filtered.count > otpLength {
            otpText = String(filtered.prefix(otpLength))
        } else {
            otpText = filtered
        }
        
        if otpText.count == otpLength {
            isFocused = false
            verifyOTP()
        }
    }
    
    private func verifyOTP() {
        guard otpText.count == otpLength else { return }
        
        localErrorMessage = nil
        authManager.verifyRegisterOTP(email: email, otp: otpText) { success in
            if !success {
                otpText = ""
                isFocused = true
            }
        }
    }
}

#Preview {
    VerifyOTPView(email: "test@example.com", onBack: {}, onResend: {})
        .environmentObject(AuthManager())
}
