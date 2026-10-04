import SwiftUI

struct MainContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    private let backgroundColor = Color(red: 0.05, green: 0.04, blue: 0.08)
    private let cardBackgroundColor = Color(red: 0.12, green: 0.11, blue: 0.16)
    private let purpleAccent = Color(red: 0.62, green: 0.38, blue: 1.0)
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // MARK: - Header
                HStack(spacing: 16) {
                    // Display User Avatar
                    if let avatarUrlString = authManager.currentUser?.avatarUrl,
                       let avatarURL = URL(string: avatarUrlString) {
                        AsyncImage(url: avatarURL) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 52, height: 52)
                                    .clipShape(Circle())
                            default:
                                defaultAvatar
                            }
                        }
                    } else {
                        defaultAvatar
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back,")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                        
                        Text(authManager.currentUser?.fullName ?? "User")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                }
                .padding(.top, 20)
                
                // MARK: - Profile Data Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Device & Account Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(purpleAccent)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    ProfileRow(
                        icon: "person.id.rectangle.fill",
                        title: "User ID",
                        value: authManager.currentUser?.id != nil ? "\(authManager.currentUser!.id)" : "-"
                    )
                    
                    ProfileRow(
                        icon: "iphone.gen3",
                        title: "Device ID",
                        value: authManager.currentUser?.deviceId != nil ? "\(authManager.currentUser!.deviceId!)" : "-"
                    )
                    
                    ProfileRow(
                        icon: "key.fill",
                        title: "UDID",
                        value: authManager.currentUser?.udid ?? "-"
                    )
                }
                .padding(20)
                .background(cardBackgroundColor)
                .cornerRadius(20)
                
                Spacer()
                
                // MARK: - Logout Button
                Button(action: {
                    authManager.logout()
                }) {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                        Text("Log out")
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(Color.red.opacity(0.8))
                    .cornerRadius(25)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
    }
    
    // Placeholder กรณีไม่มีรูป Avatar หรือโหลดรูปไม่สำเร็จ
    private var defaultAvatar: some View {
        Image(systemName: "person.circle.fill")
            .resizable()
            .frame(width: 52, height: 52)
            .foregroundColor(purpleAccent)
    }
}

// MARK: - Subview Row Component
struct ProfileRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
                .frame(width: 24)
            
            Text(title)
                .font(.system(size: 14))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}
