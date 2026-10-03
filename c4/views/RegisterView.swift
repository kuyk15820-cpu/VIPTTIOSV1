import SwiftUI

// MARK: - Auth Step
private enum RegisterStep {
    case register
    case verifyOTP
}

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Flow Step State
    @State private var currentStep: RegisterStep = .register
    
    // MARK: - Form States
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    
    // MARK: - OTP States
    @State private var otpText: String = ""
    @FocusState private var isOTPFocused: Bool
    private let otpLength = 4
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullName, username, email, password, confirmPassword
    }
    
    private let backgroundColor = Color.black
    private let inputBorderColor = Color.white.opacity(0.3)
    
    private let eyeIconURL = URL(string: "https://f1x3r.org/assets/icons/eye.png")
    private let eyeSlashIconURL = URL(string: "https://f1x3r.org/assets/icons/eye-slash.png")
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // 🟢 Render View ตาม Step ปัจจุบัน
            switch currentStep {
            case .register:
                createAccountForm
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
            case .verifyOTP:
                verifyOTPPage
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .navigationTitle(currentStep == .register ? "Sign up" : "")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: currentStep)
    }
    
    // MARK: - Step 1: Register Form
    private var createAccountForm: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                Image(systemName: "lasso.and.sparkles")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
                    .padding(.top, 12)
                
                Text("Create your account")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.bottom, 8)
                
                VStack(spacing: 14) {
                    customInputField(title: "Full Name", text: $fullName, field: .fullName)
                    customInputField(title: "Username", text: $username, field: .username)
                    customInputField(title: "Email", text: $email, field: .email, keyboardType: .emailAddress)
                    customPasswordField
                    customConfirmPasswordField
                }
                
                Button(action: validateAndRegister) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 48)
                        
                        Text(authManager.isLoading ? "Processing..." : "Continue")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .disabled(authManager.isLoading || isFormIncomplete)
                .opacity(isFormIncomplete ? 0.5 : 1.0)
                .padding(.top, 8)
                
                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Text("Log in")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // MARK: - Step 2: Verify OTP View
    private var verifyOTPPage: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button(action: {
                    withAnimation {
                        currentStep = .register
                    }
                }) {
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
                
                // OTP Input Cards
                ZStack {
                    TextField("", text: $otpText)
                        .keyboardType(.numberPad)
                        .textContentType(.oneTimeCode)
                        .focused($isOTPFocused)
                        .accentColor(.clear)
                        .foregroundColor(.clear)
                        .opacity(0.01)
                        .onChange(of: otpText) { newValue in
                            handleOTPChange(newValue)
                        }
                    
                    HStack(spacing: 12) {
                        ForEach(0..<otpLength, id: \.self) { index in
                            let digit = getDigit(at: index)
                            let isCurrentFocus = isOTPFocused && (index == otpText.count || (index == otpLength - 1 && otpText.count == otpLength))
                            
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
                    isOTPFocused = true
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    otpText = ""
                    isOTPFocused = true
                    resendOTP()
                }) {
                    Text(authManager.isLoading ? "Processing..." : "Resend OTP Code")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(authManager.isLoading ? .white.opacity(0.6) : .gray)
                }
                .disabled(authManager.isLoading)
                .padding(.top, 12)
            }
            
            Spacer()
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isOTPFocused = true
            }
        }
    }
    
    // MARK: - Input Field Helpers
    private func customInputField(title: String, text: Binding<String>, field: Field, keyboardType: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !text.wrappedValue.isEmpty {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            TextField("", text: text, prompt: Text(text.wrappedValue.isEmpty ? title : "").foregroundColor(.gray))
                .foregroundColor(.white)
                .keyboardType(keyboardType)
                .autocapitalization(field == .fullName ? .words : .none)
                .disableAutocorrection(field == .fullName ? false : true)
                .focused($focusedField, equals: field)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, text.wrappedValue.isEmpty ? 14 : 8)
        .frame(height: 52)
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(focusedField == field ? Color.white : inputBorderColor, lineWidth: 1)
        )
    }
    
    private var customPasswordField: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if !password.isEmpty {
                    Text("Password")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                if isPasswordVisible {
                    TextField("", text: $password, prompt: Text(password.isEmpty ? "Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .password)
                } else {
                    SecureField("", text: $password, prompt: Text(password.isEmpty ? "Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .password)
                }
            }
            
            Button(action: { isPasswordVisible.toggle() }) {
                AsyncImage(url: isPasswordVisible ? eyeSlashIconURL : eyeIconURL) { image in
                    image.resizable().scaledToFit().frame(width: 20, height: 20).foregroundColor(.gray)
                } placeholder: {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14)).foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, password.isEmpty ? 14 : 8)
        .frame(height: 52)
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(focusedField == .password ? Color.white : inputBorderColor, lineWidth: 1)
        )
    }
    
    private var customConfirmPasswordField: some View {
        HStack(alignment: .center, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                if !confirmPassword.isEmpty {
                    Text("Confirm Password")
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                if isConfirmPasswordVisible {
                    TextField("", text: $confirmPassword, prompt: Text(confirmPassword.isEmpty ? "Confirm Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .confirmPassword)
                } else {
                    SecureField("", text: $confirmPassword, prompt: Text(confirmPassword.isEmpty ? "Confirm Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .confirmPassword)
                }
            }
            
            Button(action: { isConfirmPasswordVisible.toggle() }) {
                AsyncImage(url: isConfirmPasswordVisible ? eyeSlashIconURL : eyeIconURL) { image in
                    image.resizable().scaledToFit().frame(width: 20, height: 20).foregroundColor(.gray)
                } placeholder: {
                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14)).foregroundColor(.gray.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, confirmPassword.isEmpty ? 14 : 8)
        .frame(height: 52)
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(focusedField == .confirmPassword ? Color.white : inputBorderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Logic & Actions
    private var isFormIncomplete: Bool {
        fullName.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty
    }
    
    private func isValidEmail(_ emailStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: emailStr)
    }
    
    private func validateAndRegister() {
        guard isValidEmail(email) else {
            authManager.showErrorNotification(message: AuthMessages.Warning.invalidEmailFormat)
            return
        }
        
        guard password.count >= 8 else {
            authManager.showErrorNotification(message: AuthMessages.Warning.passwordTooShort)
            return
        }
        
        guard password == confirmPassword else {
            authManager.showErrorNotification(message: "รหัสผ่านทั้งสองช่องไม่ตรงกัน")
            return
        }
        
        authManager.requestRegisterOTP(fullName: fullName, username: username, email: email, password: password) { success in
            if success {
                withAnimation {
                    currentStep = .verifyOTP
                }
            }
        }
    }
    
    private func resendOTP() {
        authManager.requestRegisterOTP(fullName: fullName, username: username, email: email, password: password) { _ in }
    }
    
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
            isOTPFocused = false
            verifyOTP()
        }
    }
    
    private func verifyOTP() {
        guard otpText.count == otpLength else { return }
        
        authManager.verifyRegisterOTP(email: email, otp: otpText) { success in
            if !success {
                otpText = ""
                isOTPFocused = true
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager())
}
