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
    @State private var localErrorMessage: String? = nil
    
    // โทนสีเดียวกันกับ LoginView
    private let backgroundColor = Color(red: 0.05, green: 0.04, blue: 0.08)
    private let inputBackgroundColor = Color(red: 0.12, green: 0.11, blue: 0.16)
    private let purpleAccent = Color(red: 0.62, green: 0.38, blue: 1.0)
    
    var body: some View {
        ZStack {
            // พื้นหลัง Dark Theme
            backgroundColor
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // ปุ่ม Back Top-Left
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 16)
                    
                    // หัวข้อ Create account
                    HStack(spacing: 6) {
                        Text("Create")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(purpleAccent)
                    }
                    .padding(.top, 4)
                    
                    // ช่องกรอก Full Name
                    HStack {
                        TextField("", text: $fullName, prompt: Text("Full Name").foregroundColor(.gray))
                            .foregroundColor(.white)
                        
                        if !fullName.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(inputBackgroundColor)
                    .cornerRadius(25)
                    
                    // ช่องกรอก Username
                    HStack {
                        TextField("", text: $username, prompt: Text("Username").foregroundColor(.gray))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if !username.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(inputBackgroundColor)
                    .cornerRadius(25)
                    
                    // ช่องกรอก Email
                    HStack {
                        TextField("", text: $email, prompt: Text("Email address").foregroundColor(.gray))
                            .foregroundColor(.white)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                        
                        if isValidEmail(email) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(inputBackgroundColor)
                    .cornerRadius(25)
                    
                    // ช่องกรอก Password
                    HStack {
                        if isPasswordVisible {
                            TextField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                        } else {
                            SecureField("", text: $password, prompt: Text("Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(inputBackgroundColor)
                    .cornerRadius(25)
                    
                    // ช่องกรอก Confirm Password
                    HStack {
                        if isConfirmPasswordVisible {
                            TextField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                        } else {
                            SecureField("", text: $confirmPassword, prompt: Text("Confirm Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            isConfirmPasswordVisible.toggle()
                        }) {
                            Image(systemName: isConfirmPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray.opacity(0.6))
                        }
                    }
                    .padding()
                    .background(inputBackgroundColor)
                    .cornerRadius(25)
                    
                    // แสดง Error Message ฝั่ง Local หรือ Server
                    if let errorMessage = localErrorMessage ?? authManager.errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .padding(.horizontal, 4)
                    }
                    
                    // ข้อความ ยินยอมเงื่อนไข
                    VStack(spacing: 2) {
                        Text("By signing up, you agree to Loóna's")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                        
                        HStack(spacing: 4) {
                            Link("Terms of Use", destination: URL(string: "https://your-domain.com/terms")!)
                                .font(.system(size: 12))
                                .underline()
                                .foregroundColor(.gray)
                            
                            Text("&")
                                .font(.system(size: 12))
                                .foregroundColor(.gray)
                            
                            Link("Privacy Policy", destination: URL(string: "https://your-domain.com/privacy")!)
                                .font(.system(size: 12))
                                .underline()
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
                    
                    // ปุ่ม Sign up
                    Button(action: {
                        validateAndRegister()
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(purpleAccent)
                                .frame(height: 52)
                            
                            if authManager.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text("Sign up")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(authManager.isLoading || isFormIncomplete)
                    .opacity(isFormIncomplete ? 0.6 : 1.0)
                    .padding(.top, 8)
                    
                    // ลิงก์สลับไปหน้า Login
                    HStack {
                        Spacer()
                        Text("Already have an account?")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Button(action: {
                            presentationMode.wrappedValue.dismiss()
                        }) {
                            Text("Log in")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(purpleAccent)
                        }
                        Spacer()
                    }
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
            }
        }
        .navigationBarHidden(true)
    }
    
    // MARK: - Form Validation Helpers
    private var isFormIncomplete: Bool {
        fullName.isEmpty || username.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty
    }
    
    private func isValidEmail(_ emailStr: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: emailStr)
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
        
        guard password == confirmPassword else {
            localErrorMessage = "Passwords do not match."
            return
        }
        
        authManager.register(
            fullName: fullName,
            username: username,
            email: email,
            password: password
        )
    }
}

// MARK: - Preview
struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
            .environmentObject(AuthManager())
    }
}
