import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var userLogin: String = ""
    @State private var userPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // โทนสีตาม UI Design
    private let backgroundColor = Color(red: 0.05, green: 0.04, blue: 0.08)
    private let inputBackgroundColor = Color(red: 0.12, green: 0.11, blue: 0.16)
    private let purpleAccent = Color(red: 0.62, green: 0.38, blue: 1.0)
    
    var body: some View {
        ZStack {
            // พื้นหลัง Dark Theme
            backgroundColor
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 24) {
                // ปุ่ม Back Top-Left
                Button(action: {
                    // Action สำหรับย้อนกลับ
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.top, 16)
                
                // หัวข้อ Welcome back
                HStack(spacing: 6) {
                    Text("Welcome")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("back")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(purpleAccent)
                }
                .padding(.top, 8)
                
                // ช่องกรอก Email / Username
                HStack {
                    TextField("", text: $userLogin, prompt: Text("Username or Email").foregroundColor(.gray))
                        .foregroundColor(.white)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    if !userLogin.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding()
                .background(inputBackgroundColor)
                .cornerRadius(25)
                
                // ช่องกรอก Password
                HStack {
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
                            .foregroundColor(.gray.opacity(0.6))
                    }
                }
                .padding()
                .background(inputBackgroundColor)
                .cornerRadius(25)
                
                // แสดง Error Message ถ้ามีปัญหาในการล็อกอิน
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.horizontal, 4)
                }
                
                // ข้อความ ยินยอมเงื่อนไข (Terms of Use & Privacy Policy)
                VStack(spacing: 2) {
                    Text("By continuing, you agree to Loóna's")
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
                .padding(.top, 8)
                
                // ปุ่ม Log in
                Button(action: {
                    authManager.login(userLogin: userLogin, userPassword: userPassword)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(purpleAccent)
                            .frame(height: 52)
                        
                        if authManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Log in")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(authManager.isLoading || userLogin.isEmpty || userPassword.isEmpty)
                .opacity((userLogin.isEmpty || userPassword.isEmpty) ? 0.6 : 1.0)
                
                // ปุ่ม Forgot your password?
                Button(action: {
                    // Action สำหรับไปหน้า Forgot Password
                }) {
                    Text("Forgot your password?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
                .padding(.top, 4)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
}

// MARK: - Preview (รองรับทั้ง iOS 17+ และเวอร์ชันก่อนหน้า)
#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
