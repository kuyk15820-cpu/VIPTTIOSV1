import SwiftUI

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    
    @State private var userLogin: String = ""
    @State private var userPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    // สถานะสำหรับเปิด/ปิด หน้าต่างลืมรหัสผ่าน
    @State private var showForgotPasswordView: Bool = false
    
    // ตรวจจับสถานะการเปิด/ปิด แป้นพิมพ์
    @FocusState private var isInputFocused: Bool
    
    // URL ไอคอนชั่วคราวสำหรับทดสอบ
    private let emailIconURL = URL(string: "https://f1x3r.org/f1x3r_auth/email.png")
    private let passwordIconURL = URL(string: "https://f1x3r.org/f1x3r_auth/password.png")
    
    // โทนสีตาม UI Design
    private let backgroundColor = Color.black
    private let inputBackgroundColor = Color.clear
    private let inputBorderColor = Color.white.opacity(0.3)
    
    var body: some View {
        NavigationStack {
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
                    
                    // MARK: - Title Text
                    Text(isInputFocused ? "Hey, Welcome Back" : "Hey,\nWelcome\nBack")
                        .font(.system(size: isInputFocused ? 24 : 34, weight: .bold))
                        .foregroundColor(.white)
                        .lineSpacing(4)
                        .padding(.bottom, isInputFocused ? 16 : 32)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isInputFocused)
                    
                    // MARK: - Input Fields
                    VStack(spacing: 12) {
                        
                        // ช่องกรอก Email / Username
                        HStack(spacing: 10) {
                            AsyncImage(url: emailIconURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .opacity(0.6)
                                default:
                                    Image(systemName: "envelope.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .foregroundColor(.gray)
                                }
                            }
                            .frame(width: 18, height: 18)
                            
                            TextField("", text: $userLogin, prompt: Text("Email or Username").foregroundColor(.gray))
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
                        
                        // ช่องกรอก Password
                        HStack(spacing: 10) {
                            AsyncImage(url: passwordIconURL) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .opacity(0.6)
                                default:
                                    Image(systemName: "lock.fill")
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
                    
                    // MARK: - Forgot Password Button (ต่อเข้ากับ Sheet ลืมรหัสผ่าน)
                    HStack {
                        Spacer()
                        Button(action: {
                            showForgotPasswordView = true
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
                        
                        NavigationLink(destination: RegisterView().environmentObject(authManager)) {
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
            // 🟢 เปลี่ยนมาใช้ .toolbar(.hidden, for: .navigationBar) แทน .navigationBarHidden(true)
            .toolbar(.hidden, for: .navigationBar)
            // เปิดหน้า ForgotPasswordView
            .sheet(isPresented: $showForgotPasswordView) {
                ForgotPasswordView()
                    .environmentObject(authManager)
            }
        }
        .tint(.white) // กำหนดให้สีปุ่ม Back และ Title ของระบบเป็นสีขาว
    }
}

// MARK: - Subview: Forgot Password View (ขอ OTP 4 หลัก + ตั้งรหัสใหม่)
struct ForgotPasswordView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    @State private var email: String = ""
    @State private var otpCode: String = ""
    @State private var newPassword: String = ""
    @State private var isPasswordVisible: Bool = false
    
    @State private var isOTPSent: Bool = false
    @State private var localErrorMessage: String? = nil
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Top Bar
                HStack {
                    Spacer()
                    Button(action: { presentationMode.wrappedValue.dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.gray)
                    }
                }
                .padding(.top, 16)
                
                Spacer()
                
                if !isOTPSent {
                    // Step 1: ขอ OTP
                    VStack(spacing: 16) {
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("Reset Password")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Enter your email address to receive a 4-digit OTP code.")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                        
                        TextField("Email Address", text: $email)
                            .padding(.horizontal, 14)
                            .frame(height: 46)
                            .foregroundColor(.white)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
                            .autocapitalization(.none)
                        
                        if let error = localErrorMessage ?? authManager.errorMessage {
                            Text(error).font(.system(size: 13)).foregroundColor(.red)
                        }
                        
                        Button(action: requestOTP) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.white).frame(height: 48)
                                if authManager.isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Send OTP").font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                                }
                            }
                        }
                        .disabled(authManager.isLoading || email.isEmpty)
                        .opacity(email.isEmpty ? 0.5 : 1.0)
                    }
                } else {
                    // Step 2: กรอก OTP + ตั้งรหัสผ่านใหม่
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.white)
                        
                        Text("Enter New Password")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                        
                        TextField("4-Digit OTP Code", text: Binding(
                            get: { otpCode },
                            set: { if $0.count <= 4 { otpCode = $0 } }
                        ))
                        .keyboardType(.numberPad)
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .foregroundColor(.white)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        
                        HStack {
                            if isPasswordVisible {
                                TextField("New Password (min 8 chars)", text: $newPassword)
                                    .foregroundColor(.white)
                            } else {
                                SecureField("New Password (min 8 chars)", text: $newPassword)
                                    .foregroundColor(.white)
                            }
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding(.horizontal, 14)
                        .frame(height: 46)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.3), lineWidth: 1))
                        
                        if let error = localErrorMessage ?? authManager.errorMessage {
                            Text(error).font(.system(size: 13)).foregroundColor(.red)
                        }
                        
                        Button(action: resetPassword) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12).fill(Color.white).frame(height: 48)
                                if authManager.isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Text("Reset Password").font(.system(size: 16, weight: .semibold)).foregroundColor(.black)
                                }
                            }
                        }
                        .disabled(authManager.isLoading || otpCode.count != 4 || newPassword.count < 8)
                        .opacity((otpCode.count != 4 || newPassword.count < 8) ? 0.5 : 1.0)
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func requestOTP() {
        localErrorMessage = nil
        authManager.requestPasswordReset(email: email) { success in
            if success {
                withAnimation { isOTPSent = true }
            }
        }
    }
    
    private func resetPassword() {
        localErrorMessage = nil
        authManager.resetPassword(email: email, otp: otpCode, newPassword: newPassword) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

// MARK: - Preview
#Preview {
    LoginView()
        .environmentObject(AuthManager())
}
