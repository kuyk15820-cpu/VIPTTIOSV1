import SwiftUI

struct RootView: View {
    @StateObject var authManager = AuthManager()
    
    var body: some View {
        Group {
            // เอาเงื่อนไข if authManager.isBanned ออกชั่วคราว
            if authManager.isAuthenticated {
                MainContentView()
            } else {
                RegisterView()
            }
        }
        .environmentObject(authManager)
    }
}
