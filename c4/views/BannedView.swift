import SwiftUI

struct BannedView: View {
    @EnvironmentObject var authManager: AuthManager
    
    private let backgroundColor = Color(red: 0.05, green: 0.04, blue: 0.08)
    private let cardBackgroundColor = Color(red: 0.12, green: 0.11, blue: 0.16)
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Ban Warning Icon
                Image(systemName: "exclamationmark.octagon.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundColor(.red)
                
                Text("Account Suspended")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                // Ban Details Card
                VStack(spacing: 16) {
                    HStack {
                        Text("Ban Type:")
                            .foregroundColor(.gray)
                        Spacer()
                        Text(authManager.banInfo?.type.capitalized ?? "Permanent")
                            .bold()
                            .foregroundColor(.red)
                    }
                    
                    if let banUntil = authManager.banInfo?.banUntil {
                        HStack {
                            Text("Banned Until:")
                                .foregroundColor(.gray)
                            Spacer()
                            Text(banUntil)
                                .foregroundColor(.white)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reason:")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        
                        Text(authManager.banInfo?.reason ?? "Violation of Terms of Service.")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .background(cardBackgroundColor)
                .cornerRadius(20)
                
                Spacer()
                
                // Back to Login Button
                Button(action: {
                    authManager.isBanned = false
                }) {
                    Text("Back to Login")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(Color.gray.opacity(0.3))
                        .cornerRadius(25)
                }
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
    }
}
