import SwiftUI

// MARK: - Back Button Styles Enum
enum BackButtonStyle: String, CaseIterable {
    case `default` = "Default"
    case rounded = "Rounded"
    case minimal = "Minimal"
    case icon = "Icon Only"
}

// MARK: - Custom Back Button Views
struct DefaultBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .semibold))
                Text("Back")
                    .font(.system(size: 17))
            }
            .foregroundColor(.blue)
        }
    }
}

struct RoundedBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: "arrow.left")
                    .font(.system(size: 14, weight: .bold))
                Text("Back")
                    .font(.system(size: 15, weight: .medium))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(20)
        }
    }
}

struct MinimalBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 20, weight: .medium))
            }
            .foregroundColor(.primary)
        }
    }
}

struct IconOnlyBackButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "arrow.left.circle.fill")
                .font(.system(size: 28))
                .foregroundColor(.blue)
        }
    }
}

// MARK: - Custom Back Button Modifier
struct CustomBackButtonModifier: ViewModifier {
    let style: BackButtonStyle
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    backButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var backButton: some View {
        switch style {
        case .default:
            DefaultBackButton(action: action)
        case .rounded:
            RoundedBackButton(action: action)
        case .minimal:
            MinimalBackButton(action: action)
        case .icon:
            IconOnlyBackButton(action: action)
        }
    }
}

// MARK: - View Extension for Easy Usage & Swipe Back
extension View {
    func customBackButton(style: BackButtonStyle, action: @escaping () -> Void) -> some View {
        modifier(CustomBackButtonModifier(style: style, action: action))
    }
    
    func enableSwipeBack() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first,
              let navigationController = window.rootViewController?.navigationController ?? findNavigationController(in: window.rootViewController) else {
            return
        }
        
        navigationController.interactivePopGestureRecognizer?.isEnabled = true
        navigationController.interactivePopGestureRecognizer?.delegate = nil
    }
    
    private func findNavigationController(in viewController: UIViewController?) -> UINavigationController? {
        guard let viewController = viewController else {
            return nil
        }
        
        if let navigationController = viewController as? UINavigationController {
            return navigationController
        }
        
        for child in viewController.children {
            if let found = findNavigationController(in: child) {
                return found
            }
        }
        
        return nil
    }
}
