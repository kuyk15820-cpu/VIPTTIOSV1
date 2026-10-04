import SwiftUI
import PhotosUI

struct RegisterView: View {
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.presentationMode) var presentationMode
    
    // MARK: - Form States
    @State private var fullName: String = ""
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var avatarImage: UIImage? = nil
    @State private var avatarData: Data? = nil
    
    @FocusState private var isFullNameFocused: Bool
    
    private let backgroundColor = Color.black
    private let inputBorderColor = Color.white.opacity(0.3)
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    
                    // Header Icon
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    Text("Create Account")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.white)
                    
                    // MARK: - Avatar Image Picker
                    VStack(spacing: 8) {
                        PhotosPicker(selection: $selectedItem, matching: .images) {
                            ZStack {
                                if let avatarImage = avatarImage {
                                    Image(uiImage: avatarImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } else {
                                    Circle()
                                        .fill(Color.white.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.white)
                                        Text("Add Photo")
                                            .font(.system(size: 11))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .overlay(
                                Circle()
                                    .stroke(inputBorderColor, lineWidth: 1.5)
                            )
                        }
                        .onChange(of: selectedItem) { newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        self.avatarImage = image
                                        // บีบอัดรูปเป็น JPEG ก่อนส่งไปเซิร์ฟเวอร์
                                        self.avatarData = image.jpegData(compressionQuality: 0.8)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // MARK: - Input Field
                    customInputField(title: "Full Name", text: $fullName)
                    
                    // MARK: - Submit Button
                    Button(action: handleRegister) {
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
                    .disabled(authManager.isLoading || fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    .padding(.top, 12)
                    
                    // Login Link
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Input Field Component
    private func customInputField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            if !text.wrappedValue.isEmpty {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.gray)
            }
            
            TextField("", text: text, prompt: Text(text.wrappedValue.isEmpty ? title : "").foregroundColor(.gray))
                .foregroundColor(.white)
                .autocapitalization(.words)
                .disableAutocorrection(false)
                .focused($isFullNameFocused)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, text.wrappedValue.isEmpty ? 14 : 8)
        .frame(height: 52)
        .background(Color.clear)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isFullNameFocused ? Color.white : inputBorderColor, lineWidth: 1)
        )
    }
    
    // MARK: - Actions
    private func handleRegister() {
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }
        
        // ดึง UDID ของเครื่อง
        let udid = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        
        authManager.register(fullName: trimmedName, udid: udid, avatarImageData: avatarData) { success in
            if success {
                presentationMode.wrappedValue.dismiss()
            }
        }
    }
}

#Preview {
    RegisterView()
        .environmentObject(AuthManager())
}
