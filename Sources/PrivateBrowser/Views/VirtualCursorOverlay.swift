import SwiftUI

/// Con trỏ ảo mô phỏng Trackpad Mode — toàn bộ vùng màn hình/tabloi
/// trở thành bàn rê chuột (Trackpad). Vuốt ngón tay = con trỏ di chuyển
/// TƯƠNG ĐỐI (relative delta), giống hệt Trackpad trên MacBook.
///
/// Cử chỉ:
/// - Vuốt = di chuyển con trỏ (relative delta)
/// - Chạm nhẹ (tap) = Click chuột
/// - Nhấn giữ + kéo = Drag
///
/// v3.5: Trackpad relative movement mode.
struct VirtualCursorOverlay: View {
    @Binding var cursorPosition: CGPoint
    let windowSize: CGSize
    var hapticsEnabled: Bool
    var onTap: (() -> Void)?
    var onDragStart: (() -> Void)?
    var onDragChanged: ((CGSize) -> Void)?
    var onDragEnd: (() -> Void)?

    @State private var isPressed: Bool = false
    @State private var tapLocation: CGPoint? = nil
    @State private var showTapIndicator: Bool = false
    @State private var isDragging: Bool = false

    // Track the previous touch location for incremental delta calculation
    @State private var lastTouchLocation: CGPoint = .zero

    // Trackpad sensitivity — how fast cursor moves relative to finger
    private let sensitivity: CGFloat = 1.5

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Cursor arrow
                Image(systemName: "cursorarrow")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.7), radius: 3, x: 1, y: 1)
                    .shadow(color: .cyan.opacity(isPressed ? 0.3 : 0), radius: 4, x: 0, y: 0)
                    .position(cursorPosition)
                    .scaleEffect(isPressed ? 0.85 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)

                // Tap/click ripple indicator
                if showTapIndicator {
                    Circle()
                        .stroke(Color.cyan.opacity(0.6), lineWidth: 1.5)
                        .frame(width: 28, height: 28)
                        .position(tapLocation ?? cursorPosition)
                        .scaleEffect(showTapIndicator ? 1.2 : 0.5)
                        .opacity(showTapIndicator ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 0.4), value: showTapIndicator)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showTapIndicator = false
                            }
                        }
                }

                // Drag trail (subtle circle showing cursor during drag)
                if isDragging {
                    Circle()
                        .fill(Color.cyan.opacity(0.15))
                        .frame(width: 6, height: 6)
                        .position(cursorPosition)
                }
            }
            .frame(width: windowSize.width, height: windowSize.height)
            .contentShape(Rectangle())
            .gesture(trackpadGesture)
        }
        .allowsHitTesting(true)
    }

    // MARK: - Trackpad Gesture (Relative Movement)

    private var trackpadGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                let currentLocation = value.location

                if !isDragging {
                    // First touch — record start, don't move yet
                    isDragging = true
                    isPressed = true
                    lastTouchLocation = currentLocation
                    onDragStart?()

                    if hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                    }
                    return
                }

                // INCREMENTAL DELTA: difference between current and previous touch
                let deltaX = (currentLocation.x - lastTouchLocation.x) * sensitivity
                let deltaY = (currentLocation.y - lastTouchLocation.y) * sensitivity

                // Move cursor by the delta (relative movement)
                let newX = max(0, min(windowSize.width, cursorPosition.x + deltaX))
                let newY = max(0, min(windowSize.height, cursorPosition.y + deltaY))

                cursorPosition = CGPoint(x: newX, y: newY)

                // Update last touch for next frame
                lastTouchLocation = currentLocation

                let delta = CGSize(width: deltaX, height: deltaY)
                onDragChanged?(delta)
            }
            .onEnded { value in
                let totalTranslation = value.translation
                let wasTap = abs(totalTranslation.width) < 3 && abs(totalTranslation.height) < 3

                if wasTap {
                    // This was a TAP — trigger click at current cursor position
                    tapLocation = cursorPosition
                    showTapIndicator = true
                    onTap?()

                    if hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                } else {
                    // This was a drag — trigger haptic on release
                    if hapticsEnabled {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    }
                }

                isDragging = false
                isPressed = false
                lastTouchLocation = .zero
                onDragEnd?()
            }
    }
}

// MARK: - Preview

#if DEBUG
struct VirtualCursorOverlay_Previews: PreviewProvider {
    static var previews: some View {
        VirtualCursorOverlay(
            cursorPosition: .constant(CGPoint(x: 150, y: 200)),
            windowSize: CGSize(width: 380, height: 520),
            hapticsEnabled: false,
            onTap: {},
            onDragStart: {},
            onDragChanged: { _ in },
            onDragEnd: {}
        )
        .background(Color.black)
        .previewLayout(.fixed(width: 380, height: 520))
    }
}
#endif
