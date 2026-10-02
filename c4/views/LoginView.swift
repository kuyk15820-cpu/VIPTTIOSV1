import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var userLogin: String = ""
    @State private var userPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // ตรวจจับสถานะการเปิด/ปิด แป้นพิมพ์
    @FocusState private var isInputFocused: Bool
    
    // URL ไอคอนชั่วคราวสำหรับทดสอบ (เป็นไฟล์ PNG สีขาวโปร่งใส)
    private let emailIconURL = URL(string: "https://f1x3r.org/f1x3r_auth/email.png")
    private let passwordIconURL = URL(string: "https://f1x3r.org/f1x3r_auth/password.png")
    
    // โทนสีตาม UI Design
    private let backgroundColor = Color.black
    private let inputBackgroundColor = Color.clear
    private let inputBorderColor = Color.white.opacity(0.3)
    
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
                .padding(.bottom, isInputFocused ? 12 : 28)
                
                // MARK: - Title Text (สลับแนวนอนเมื่อกำลังพิมพ์)
                Text(isInputFocused ? "Hey, Welcome Back" : "Hey,\nWelcome\nBack")
                    .font(.system(size: isInputFocused ? 24 : 34, weight: .bold))
                    .foregroundColor(.white)
                    .lineSpacing(4)
                    .padding(.bottom, isInputFocused ? 16 : 32)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isInputFocused)
                
                // MARK: - Input Fields
                VStack(spacing: 12) {
                    
                    // ช่องกรอก Email / Username (ใช้ AsyncImage ดึงไอคอนจาก URL ชั่วคราว)
                    HStack(spacing: 10) {
                        AsyncImage(url: emailIconURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .opacity(0.6)
                            default:
                                Image(systemName: "envelope.fill") // SF Symbol สำรองกรณีโหลดรูปไม่ได้
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 18, height: 18)
                        
                        TextField("", text: $userLogin, prompt: Text("Email id").foregroundColor(.gray))
                            .foregroundColor(.white)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .focused($isInputFocused)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .background(inputBackgroundColor)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(inputBorderColor, lineWidth: 1)
                    )
                    
                    // ช่องกรอก Password (ใช้ AsyncImage ดึงไอคอนจาก URL ชั่วคราว)
                    HStack(spacing: 10) {
                        AsyncImage(url: passwordIconURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFit()
                                    .opacity(0.6)
                            default:
                                Image(systemName: "lock.fill") // SF Symbol สำรองกรณีโหลดรูปไม่ได้
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.gray)
                            }
                        }
                        .frame(width: 18, height: 18)
                        
                        if isPasswordVisible {
                            TextField("", text: $userPassword, prompt: Text("Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                                .focused($isInputFocused)
                        } else {
                            SecureField("", text: $userPassword, prompt: Text("Password").foregroundColor(.gray))
                                .foregroundColor(.white)
                                .focused($isInputFocused)
                        }
                        
                        Button(action: {
                            isPasswordVisible.toggle()
                        }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
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
                        RoundedRectangle(cornerRadius: 23)
                            .fill(Color.white)
                            .frame(height: 46)
                        
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
