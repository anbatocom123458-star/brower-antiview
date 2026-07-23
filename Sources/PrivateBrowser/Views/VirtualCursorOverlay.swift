import SwiftUI

/// Con trỏ ảo mô phỏng con chuột máy tính — người dùng kéo để di chuyển,
/// chạm để click vào vị trí tương ứng trên nội dung web.
///
/// Vị trí con trỏ được map từ tọa độ local trong cửa sổ sang tọa độ WebView.
struct VirtualCursorOverlay: View {
    @Binding var position: CGPoint
    let windowSize: CGSize
    var hapticsEnabled: Bool

    @State private var isPressed: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Cursor arrow
                Image(systemName: "cursorarrow")
                    .font(.system(size: 20, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 2, x: 1, y: 1)
                    .position(position)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)

                // Click ripple
                if isPressed {
                    Circle()
                        .stroke(Color.cyan.opacity(0.5), lineWidth: 1.5)
                        .frame(width: 24, height: 24)
                        .position(position)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(width: windowSize.width, height: windowSize.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let newX = max(0, min(windowSize.width, value.location.x))
                        let newY = max(0, min(windowSize.height, value.location.y))
                        position = CGPoint(x: newX, y: newY)
                        isPressed = true
                    }
                    .onEnded { value in
                        isPressed = false
                        // Haptic tap tại vị trí
                        if hapticsEnabled {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                    }
            )
        }
        .allowsHitTesting(true)
    }
}
