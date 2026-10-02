import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    
    @State private var isOTPSent: Bool = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullName, email, username, password, confirmPassword
    }
    
    private let backgroundColor = Color.black
    private let inputBorderColor = Color.white.opacity(0.3)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            if isOTPSent {
                VerifyOTPView(
                    email: email,
                    onBack: {
                        withAnimation { isOTPSent = false }
                    },
                    onResend: {
                        validateAndRegister()
                    }
                )
                .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                createAccountForm
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isOTPSent)
        .navigationBarHidden(true)
    }
    
    // MARK: - Step 1: Form View
    private var createAccountForm: some View {
        VStack(spacing: 0) {
            
            HStack {
                Button(action: { presentationMode.wrappedValue.dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                Spacer()
                Text("Sign up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Spacer()
                Color.clear.frame(width: 16, height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
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
                        customInputField(title: "Email", text: $email, field: .email, keyboardType: .emailAddress)
                        customInputField(title: "Username", text: $username, field: .username)
                        customPasswordField
                        customConfirmPasswordField
                    }
                    
                    Button(action: validateAndRegister) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(height: 48)
                            
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Continue")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .disabled(authManager.isLoading || isFormIncomplete)
                    .opacity(isFormIncomplete ? 0.5 : 1.0)
                    .padding(.top, 8)
                    
                    VStack(spacing: 4) {
                        Text("By continuing, I accept Mammoth's")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Link("Terms of Use", destination: URL(string: "https://your-domain.com/terms")!)
                                .font(.system(size: 12, weight: .semibold))
                                .underline()
                                .foregroundColor(.gray)
                            
                            Text("and")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Link("Privacy Policy", destination: URL(string: "https://your-domain.com/privacy")!)
                                .font(.system(size: 12, weight: .semibold))
                                .underline()
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.top, 12)
                    
                    Spacer(minLength: 40)
                    
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
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
        }
    }
    
    // MARK: - Helper Views
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
        VStack(alignment: .leading, spacing: 2) {
            if !password.isEmpty {
                Text("Password")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            HStack {
                if isPasswordVisible {
                    TextField("", text: $password, prompt: Text(password.isEmpty ? "Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .password)
                } else {
                    SecureField("", text: $password, prompt: Text(password.isEmpty ? "Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .password)
                }
                
                Button(action: { isPasswordVisible.toggle() }) {
                    Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
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
        VStack(alignment: .leading, spacing: 2) {
            if !confirmPassword.isEmpty {
                Text("Confirm Password")
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            HStack {
                if isConfirmPasswordVisible {
                    TextField("", text: $confirmPassword, prompt: Text(confirmPassword.isEmpty ? "Confirm Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .confirmPassword)
                } else {
                    SecureField("", text: $confirmPassword, prompt: Text(confirmPassword.isEmpty ? "Confirm Password" : "").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .focused($focusedField, equals: .confirmPassword)
                }
                
                Button(action: { isConfirmPasswordVisible.toggle() }) {
                    Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.7))
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
    
    // MARK: - Validation & Actions
    private var isFormIncomplete: Bool {
        fullName.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty
    }
    
    private func isValidEmail(_ emailStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: emailStr)
    }
    
    private func validateAndRegister() {
        // เช็กฝั่ง Client ก่อน ถ้าไม่ผ่านให้เรียก showErrorNotification ของ AuthManager
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
        
        // ยิง API สั่งขอ OTP
        authManager.requestRegisterOTP(fullName: fullName, username: username, email: email, password: password) { success in
            if success {
                withAnimation { isOTPSent = true }
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager())
}
