import SwiftUI

/// Chế độ cửa sổ nổi — hiển thị tab dưới dạng các cửa sổ nhỏ,
/// giống như trên desktop/laptop, có dock ở dưới cùng và hình nền máy tính.
struct FloatingModeView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var floatingManager: FloatingWindowManager
    @ObservedObject var zoomManager: ZoomManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var hapticsEnabled: Bool
    @Binding var isPresented: Bool

    var body: some View {
        ZStack {
            // Hình nền desktop-style
            desktopBackground

            // Các cửa sổ nổi
            ForEach(tabsManager.tabs) { tab in
                if tab.isFloating && !tab.isMinimizedToDock {
                    FloatingWindowView(
                        tab: tab,
                        floatingManager: floatingManager,
                        tabsManager: tabsManager,
                        zoomManager: zoomManager,
                        blockWebRTC: blockWebRTC,
                        blockIframe: blockIframe,
                        blockAds: blockAds,
                        desktopMode: desktopMode,
                        hapticsEnabled: hapticsEnabled
                    )
                }
            }

            // Dock ở dưới
            FloatingDockView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                zoomManager: zoomManager,
                blockWebRTC: blockWebRTC,
                blockIframe: blockIframe,
                blockAds: blockAds,
                desktopMode: desktopMode,
                hapticsEnabled: hapticsEnabled,
                onExitFloatingMode: {
                    haptic(.heavy)
                    floatingManager.exitFloatingMode(to: tabsManager)
                    withAnimation(.spring(response: 0.3)) {
                        isPresented = false
                    }
                }
            )
        }
        .ignoresSafeArea()
        .onAppear {
            floatingManager.enterFloatingMode(from: tabsManager)
        }
    }

    // MARK: - Desktop Background

    private var desktopBackground: some View {
        ZStack {
            // Gradient nền chính
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.06, blue: 0.20),
                    Color(red: 0.10, green: 0.08, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Các vòng sáng trang trí
            GeometryReader { geo in
                // Vòng sáng lớn trên trái
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.08),
                        Color.blue.opacity(0.04),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.2, y: 0.3),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.6
                )

                // Vòng sáng phải
                RadialGradient(
                    colors: [
                        Color.purple.opacity(0.06),
                        Color.pink.opacity(0.03),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.8, y: 0.6),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.5
                )

                // Vòng sáng dưới
                RadialGradient(
                    colors: [
                        Color.cyan.opacity(0.05),
                        Color.clear
                    ],
                    center: UnitPoint(x: 0.5, y: 0.9),
                    startRadius: 0,
                    endRadius: geo.size.width * 0.4
                )
            }

            // Grid line subtle
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 60
                    // Vertical lines
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += spacing
                    }
                    // Horizontal lines
                    var y: CGFloat = 0
                    while y < geo.size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: geo.size.width, y: y))
                        y += spacing
                    }
                }
                .stroke(Color.white.opacity(0.02), lineWidth: 0.5)
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Preview

struct FloatingModeView_Previews: PreviewProvider {
    static var previews: some View {
        FloatingModeView(
            tabsManager: TabsManager(),
            floatingManager: FloatingWindowManager(),
            zoomManager: ZoomManager(),
            blockWebRTC: false,
            blockIframe: false,
            blockAds: false,
            desktopMode: false,
            hapticsEnabled: true,
            isPresented: .constant(true)
        )
    }
}
