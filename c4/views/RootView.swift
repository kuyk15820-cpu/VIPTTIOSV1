import SwiftUI

struct RootView: View {
    @StateObject var authManager = AuthManager()
    
    var body: some View {
        Group {
            if authManager.isBanned {
                BannedView()
            } else if authManager.isAuthenticated {
                MainContentView()
            } else {
                LoginView()
            }
        }
        .environmentObject(authManager)
    }
}
