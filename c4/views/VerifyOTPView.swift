import SwiftUI

struct VerifyOTPView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    let email: String
    var onResend: () -> Void
    
    @State private var otpText: String = ""
    @FocusState private var isFocused: Bool
    
    private let otpLength = 4
    private let inputBorderColor = Color.white.opacity(0.3)
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
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
            
            Button(action: {
                otpText = ""
                isFocused = true
                onResend()
            }) {
                Text(authManager.isLoading ? "Processing" : "Resend OTP Code")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(authManager.isLoading ? .white.opacity(0.6) : .gray)
            }
            .disabled(authManager.isLoading)
            .padding(.top, 12)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.ignoresSafeArea())
        .navigationTitle("Verification")
        .navigationBarTitleDisplayMode(.inline)
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
        
        authManager.verifyRegisterOTP(email: email, otp: otpText) { success in
            if !success {
                otpText = ""
                isFocused = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        VerifyOTPView(email: "test@example.com", onResend: {})
            .environmentObject(AuthManager())
    }
}
