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
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back,")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                        
                        Text(authManager.currentUser?.fullName ?? "User")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    
                    // User Badge Icon
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .frame(width: 44, height: 44)
                        .foregroundColor(purpleAccent)
                }
                .padding(.top, 20)
                
                // Profile Data Card
                VStack(alignment: .leading, spacing: 16) {
                    Text("Profile Details")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(purpleAccent)
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    ProfileRow(icon: "person.fill", title: "Username", value: authManager.currentUser?.username ?? "-")
                    ProfileRow(icon: "envelope.fill", title: "Email", value: authManager.currentUser?.email ?? "-")
                    ProfileRow(icon: "shield.fill", title: "Role", value: authManager.currentUser?.role.capitalized ?? "-")
                    
                    Divider()
                        .background(Color.gray.opacity(0.3))
                    
                    ProfileRow(icon: "calendar", title: "Registered", value: formatDate(authManager.currentUser?.createdAt))
                    ProfileRow(icon: "clock.fill", title: "First Login", value: formatDate(authManager.currentUser?.firstLoginAt))
                    ProfileRow(icon: "arrow.right.circle.fill", title: "Last Login", value: formatDate(authManager.currentUser?.lastLoginAt))
                }
                .padding(20)
                .background(cardBackgroundColor)
                .cornerRadius(20)
                
                Spacer()
                
                // Logout Button
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
    
    // Helper แปลง Format วันที่
    private func formatDate(_ dateString: String?) -> String {
        guard let dateString = dateString, !dateString.isEmpty else { return "-" }
        return dateString
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
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
        }
    }
}
