import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var userLogin: String = ""
    @State private var userPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // โทนสีตาม UI Design จากรูป
    private let backgroundColor = Color.black
    private let inputBackgroundColor = Color(white: 0.12)
    private let inputBorderColor = Color(white: 0.22)
    
    var body: some View {
        ZStack {
            // พื้นหลัง Dark Theme
            backgroundColor
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 0) {
                
                // MARK: - Navigation Bar / Back Button
                Button(action: {
                    // Action สำหรับย้อนกลับ
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 16, weight: .regular))
                    }
                    .foregroundColor(.white)
                }
                .padding(.top, 16)
                .padding(.bottom, 28)
                
                // MARK: - Title Text
                Text("Hey,\nWelcome\nBack")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .padding(.bottom, 32)
                
                // MARK: - Input Fields
                VStack(spacing: 16) {
                    
                    // ช่องกรอก Email / Username (มี Icon ดึงจาก Bundle)
                    HStack(spacing: 12) {
                        Image("email_icon") // ดึง Icon email จาก Bundle / Asset Catalog
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                        
                        TextField("", text: $userLogin, prompt: Text("Email id").foregroundColor(.gray))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(inputBackgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputBorderColor, lineWidth: 1)
                    )
                    
                    // ช่องกรอก Password (มี Icon ดึงจาก Bundle)
                    HStack(spacing: 12) {
                        Image("password_icon") // ดึง Icon password จาก Bundle / Asset Catalog
                            .resizable()
                            .renderingMode(.template)
                            .scaledToFit()
                            .frame(width: 20, height: 20)
                            .foregroundColor(.gray)
                        
                        if isPasswordVisible {
                            TextField("", text: $userPassword, prompt: Text("Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                        } else {
                            SecureField("", text: $userPassword, prompt: Text("Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 16)
                    .frame(height: 52)
                    .background(inputBackgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputBorderColor, lineWidth: 1)
                    )
                }
                
                // MARK: - Forgot Password Button
                HStack {
                    Spacer()
                    Button(action: {
                        // Action ไปหน้า Forget Password
                    }) {
                        Text("Forgot password?")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 12)
                .padding(.bottom, 28)
                
                // แสดง Error Message
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.bottom, 12)
                }
                
                // MARK: - Sign In Main Button
                Button(action: {
                    authManager.login(userLogin: userLogin, userPassword: userPassword)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(Color.white)
                            .frame(height: 52)
                        
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .black))
                        } else {
                            Text("Sign In")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.black)
                        }
                    }
                }
                .disabled(authManager.isLoading || userLogin.isEmpty || userPassword.isEmpty)
                .opacity((userLogin.isEmpty || userPassword.isEmpty) ? 0.6 : 1.0)
                
                Spacer()
                
                // MARK: - Sign Up Footer
                HStack {
                    Spacer()
                    Text("Don't have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                    
                    Button(action: {
                        // Action สลับไปหน้า Register / Sign Up
                    }) {
                        Text("Sign up")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(.bottom, 20)
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
