import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fullName: String = ""
    @State private var username: String = ""
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    
    @State private var isPasswordVisible: Bool = false
    @State private var isConfirmPasswordVisible: Bool = false
    
    @State private var isOTPSent: Bool = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullName, username, email, password, confirmPassword
    }
    
    private let backgroundColor = Color.black
    private let inputBorderColor = Color.white.opacity(0.3)
    
    // URL สำหรับไอคอน eye และ eye-slash
    private let eyeIconURL = URL(string: "https://f1x3r.org/assets/icons/eye.png")
    private let eyeSlashIconURL = URL(string: "https://f1x3r.org/assets/icons/eye-slash.png")
    
    // MARK: - Navigation Bar Customization
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black // ตั้งสีพื้นหลัง Navigation Bar เป็นสีดำทึบ
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white] // สี Title
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        // เอาเส้นแบ่ง / เงาใต้ Navigation Bar ออก ให้กลมกลืนเป็นสีดำล้วน
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()
        
        // 1. ตั้งสีลูกศรย้อนกลับของระบบให้เป็นสีขาว
        UINavigationBar.appearance().tintColor = .white
        
        // 2. ซ่อน Text ของปุ่ม Back โดยตั้งสีตัวอักษรเป็นโปร่งใส (.clear)
        let backButtonAppearance = UIBarButtonItemAppearance()
        backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
        appearance.backButtonAppearance = backButtonAppearance
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            createAccountForm
        }
        .navigationTitle("Sign up")
        .navigationBarTitleDisplayMode(.inline)
        // 🟢 แสดง Navigation Bar สำหรับหน้านี้เพื่อรองรับ Navigation Destination
        .toolbar(.visible, for: .navigationBar)
        // 🟢 Push ไปยัง VerifyOTPView เมื่อส่ง OTP สำเร็จเพื่ออนิเมชั่นและ Navigation Stack ที่ถูกต้อง
        .navigationDestination(isPresented: $isOTPSent) {
            VerifyOTPView(
                email: email,
                onResend: {
                    validateAndRegister()
                }
            )
        }
    }
    
    // MARK: - Step 1: Form View
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
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                } placeholder: {
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
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                        .foregroundColor(.gray)
                } placeholder: {
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
                isOTPSent = true
            }
        }
    }
}

#Preview {
    NavigationStack {
        RegisterView()
            .environmentObject(AuthManager())
    }
}
