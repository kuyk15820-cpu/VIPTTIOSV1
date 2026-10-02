import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var fullName: String = ""
    @State private var email: String = ""
    @State private var username: String = ""
    @State private var password: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // สถานะการสลับหน้าไปแสดง "Verify your email"
    @State private var isEmailSent: Bool = false
    @State private var localErrorMessage: String? = nil
    
    // ตรวจจับ Focus ของ Input
    @FocusState private var focusedField: Field?
    
    enum Field {
        case fullName, email, username, password
    }
    
    // โทนสีตาม UI ในรูป
    private let backgroundColor = Color.black
    private let inputBorderColor = Color.white.opacity(0.3)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            if isEmailSent {
                // MARK: - Step 2: Verify Your Email View
                verifyEmailView
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                // MARK: - Step 1: Create Account Form
                createAccountForm
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isEmailSent)
        .navigationBarHidden(true)
    }
    
    // MARK: - Form View (หน้าสมัครสมาชิก)
    private var createAccountForm: some View {
        VStack(spacing: 0) {
            
            // Top Navigation Bar
            HStack {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Text("Sign up")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // เพื่อให้ Title อยู่ตรงกลางพอดี
                Color.clear.frame(width: 16, height: 16)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 24)
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Logo Icon
                    Image(systemName: "lasso.and.sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.white)
                        .padding(.top, 12)
                    
                    // Title Header
                    Text("Create your account")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.bottom, 8)
                    
                    // MARK: - Input Fields (Custom Floating Label)
                    VStack(spacing: 14) {
                        
                        // Full Name Field (เพิ่มเข้ามา)
                        customInputField(
                            title: "Full Name",
                            text: $fullName,
                            field: .fullName
                        )
                        
                        // Email Field
                        customInputField(
                            title: "Email",
                            text: $email,
                            field: .email,
                            keyboardType: .emailAddress
                        )
                        
                        // Username Field
                        customInputField(
                            title: "Username",
                            text: $username,
                            field: .username
                        )
                        
                        // Password Field
                        customPasswordField
                    }
                    
                    if let errorMessage = localErrorMessage ?? authManager.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    
                    // MARK: - Sign Up Button
                    Button(action: validateAndRegister) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .frame(height: 48)
                            
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .black))
                            } else {
                                Text("Sign up")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                        }
                    }
                    .disabled(authManager.isLoading || isFormIncomplete)
                    .opacity(isFormIncomplete ? 0.5 : 1.0)
                    .padding(.top, 8)
                    
                    // MARK: - Terms and Privacy Policy
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
                    
                    // MARK: - Footer Link to Login
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
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
    
    // MARK: - Step 2: Verify Email Screen
    private var verifyEmailView: some View {
        VStack(spacing: 0) {
            // Top Navigation Bar
            HStack {
                Button(action: {
                    isEmailSent = false
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
                // Email Icon
                Image(systemName: "envelope.badge")
                    .font(.system(size: 48))
                    .foregroundColor(.white)
                
                Text("Verify your email")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(.white)
                
                VStack(spacing: 4) {
                    Text("Tap on the link we sent to:")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Text(email)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.bottom, 12)
                
                // ปุ่ม Open email app
                Button(action: openEmailApp) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(height: 48)
                        
                        Text("Open email app")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .padding(.horizontal, 24)
                
                // ปุ่ม Resend email
                Button(action: resendEmail) {
                    Text("Resend email")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                }
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Helper Views & Components
    
    // ช่อง Custom Input แบบมี Floating Title เล็กๆ ด้านบน
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
    
    // ช่อง Password Input
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
    
    // MARK: - Validation & Actions
    private var isFormIncomplete: Bool {
        fullName.isEmpty || email.isEmpty || username.isEmpty || password.isEmpty
    }
    
    private func isValidEmail(_ emailStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        return NSPredicate(format:"SELF MATCHES %@", emailRegEx).evaluate(with: emailStr)
    }
    
    private func validateAndRegister() {
        localErrorMessage = nil
        
        guard isValidEmail(email) else {
            localErrorMessage = "Please enter a valid email address."
            return
        }
        
        guard password.count >= 6 else {
            localErrorMessage = "Password must be at least 6 characters long."
            return
        }
        
        // ส่งค่า fullName ร่วมกับข้อมูลอื่นไปยัง AuthManager
        authManager.register(fullName: fullName, username: username, email: email, password: password)
        
        // สลับไปแสดงสเต็ปยืนยันอีเมล
        withAnimation {
            isEmailSent = true
        }
    }
    
    private func openEmailApp() {
        if let mailURL = URL(string: "message://"), UIApplication.shared.canOpenURL(mailURL) {
            UIApplication.shared.open(mailURL)
        } else if let generalMailURL = URL(string: "https://mail.google.com") {
            UIApplication.shared.open(generalMailURL)
        }
    }
    
    private func resendEmail() {
        // ยิง API ส่งอีเมลอีกครั้ง
    }
}

// MARK: - Preview
#Preview {
    RegisterView()
        .environmentObject(AuthManager())
}
