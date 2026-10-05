import SwiftUI

// MARK: - Material Loading Spinner Component
struct MaterialSpinner: View {
    @State private var start: CGFloat = 0.0
    @State private var end: CGFloat = 0.05
    @State private var rotation: Double = 0.0
    @State private var animationTask: Task<Void, Never>? = nil
    
    @Binding var isLoading: Bool

    var body: some View {
        SpinnerShape(start: start, end: end)
            .stroke(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.95, green: 0.23, blue: 0.35),
                        Color(red: 0.64, green: 0.14, blue: 0.94),
                        Color(red: 0.26, green: 0.52, blue: 0.96)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
            )
            .frame(width: 45, height: 45)
            .rotationEffect(.degrees(rotation))
            .opacity(isLoading ? 1 : 0)
            .onChange(of: isLoading) { newValue in
                if newValue {
                    startAnimation()
                } else {
                    stopAnimation()
                }
            }
            .onAppear {
                if isLoading {
                    startAnimation()
                }
            }
            .onDisappear {
                stopAnimation()
            }
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        
        animationTask?.cancel()
        animationTask = Task {
            while !Task.isCancelled && isLoading {
                await animate { start += 0.75 }
                await animate { end += 0.75 }
            }
        }
    }

    private func stopAnimation() {
        animationTask?.cancel()
        animationTask = nil
        rotation = 0
    }

    private func animate(_ action: @escaping () -> Void) async {
        withAnimation(.easeOut(duration: 0.65)) {
            action()
        }
        try? await Task.sleep(nanoseconds: 650_000_000)
    }
}

// MARK: - Helper Shape
struct SpinnerShape: Shape {
    var start: CGFloat
    var end: CGFloat
    
    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(start, end) }
        set {
            start = newValue.first
            end = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.midY),
            radius: rect.width / 2,
            startAngle: .degrees(Double(start) * 360),
            endAngle: .degrees(Double(end) * 360),
            clockwise: false
        )
        return path
    }
}

// MARK: - Preview
#Preview {
    MaterialSpinner(isLoading: .constant(true))
}
