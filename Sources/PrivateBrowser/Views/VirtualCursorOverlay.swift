import SwiftUI

/// Con trỏ ảo toàn cục — di chuyển tự do trên TOÀN MÀN HÌNH,
/// không bị giới hạn trong bất kỳ cửa sổ nào. Trackpad-style:
/// vuốt = di chuyển, chạm = click, giữ + kéo = drag.
///
/// v3.3: Single global cursor overlay — works across all floating windows.
struct VirtualCursorOverlay: View {
    @ObservedObject var floatingManager: FloatingWindowManager
    var tabsManager: TabsManager
    var hapticsEnabled: Bool
    var onCursorTap: ((CGPoint) -> Void)?

    @State private var isPressed: Bool = false
    @State private var showTapIndicator: Bool = false
    @State private var tapLocation: CGPoint = .zero
    @State private var isDragging: Bool = false
    @State private var lastTouchLocation: CGPoint = .zero

    private let sensitivity: CGFloat = 1.8
    private let cursorSize: CGFloat = 24

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Cursor arrow — positioned globally on screen
                Image(systemName: "cursorarrow")
                    .font(.system(size: 22, weight: .light))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.8), radius: 4, x: 1, y: 2)
                    .shadow(color: .cyan.opacity(isPressed ? 0.4 : 0.1), radius: 6, x: 0, y: 0)
                    .position(floatingManager.globalCursorPosition)
                    .scaleEffect(isPressed ? 0.8 : 1.0)
                    .animation(.easeInOut(duration: 0.1), value: isPressed)

                // Cursor dot (subtle center point)
                Circle()
                    .fill(Color.cyan.opacity(0.8))
                    .frame(width: 3, height: 3)
                    .position(floatingManager.globalCursorPosition)

                // Tap ripple indicator
                if showTapIndicator {
                    Circle()
                        .stroke(Color.cyan.opacity(0.7), lineWidth: 2)
                        .frame(width: 30, height: 30)
                        .position(tapLocation)
                        .scaleEffect(showTapIndicator ? 1.5 : 0.3)
                        .opacity(showTapIndicator ? 0.0 : 1.0)
                        .animation(.easeOut(duration: 0.5), value: showTapIndicator)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                showTapIndicator = false
                            }
                        }
                }

                // Drag trail particles
                if isDragging {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(Color.cyan.opacity(0.15 - Double(i) * 0.04))
                            .frame(width: CGFloat(6 - i * 2), height: CGFloat(6 - i * 2))
                            .position(
                                x: floatingManager.globalCursorPosition.x - CGFloat(i) * 4,
                                y: floatingManager.globalCursorPosition.y - CGFloat(i) * 4
                            )
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(trackpadGesture)
        }
        .allowsHitTesting(true)
    }

    // MARK: - Trackpad Gesture

    private var trackpadGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                let currentLocation = value.location

                if !isDragging {
                    isDragging = true
                    isPressed = true
                    lastTouchLocation = currentLocation
                    HapticManager.impact(.soft)
                    return
                }

                let deltaX = (currentLocation.x - lastTouchLocation.x) * sensitivity
                let deltaY = (currentLocation.y - lastTouchLocation.y) * sensitivity

                let screen = UIScreen.main.bounds
                let newX = max(0, min(screen.width, floatingManager.globalCursorPosition.x + deltaX))
                let newY = max(0, min(screen.height, floatingManager.globalCursorPosition.y + deltaY))

                floatingManager.globalCursorPosition = CGPoint(x: newX, y: newY)
                lastTouchLocation = currentLocation
            }
            .onEnded { value in
                let totalTranslation = value.translation
                let wasTap = abs(totalTranslation.width) < 5 && abs(totalTranslation.height) < 5

                if wasTap {
                    tapLocation = floatingManager.globalCursorPosition
                    showTapIndicator = true
                    HapticManager.impact(.light)
                    onCursorTap?(floatingManager.globalCursorPosition)
                } else {
                    HapticManager.impact(.medium)
                }

                isDragging = false
                isPressed = false
                lastTouchLocation = .zero
            }
    }
}
