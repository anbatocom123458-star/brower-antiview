import SwiftUI

/// Chế độ cửa sổ nổi — hiển thị tab dưới dạng các cửa sổ nhỏ,
/// giống như trên desktop/laptop, có dock ở dưới cùng và hình nền máy tính.
///
/// v4.0: Full floating OS with bubble mode, reader mode, multi-window tiling.
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

    @StateObject private var downloadManager = DownloadManager.shared

    var body: some View {
        ZStack {
            // Desktop background
            desktopBackground

            // Floating windows
            ForEach(tabsManager.tabs) { tab in
                if tab.isFloating && !tab.isMinimizedToDock && !tab.isBubbleMode {
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

            // Bubble mode tabs (floating over everything)
            ForEach(tabsManager.tabs) { tab in
                if tab.isBubbleMode {
                    // Bubble is rendered inside FloatingWindowView
                    // but we need to show it here since FloatingWindowView is hidden
                    BubbleOverlay(
                        tab: tab,
                        floatingManager: floatingManager,
                        tabsManager: tabsManager,
                        hapticsEnabled: hapticsEnabled
                    )
                }
            }

            // Dock
            FloatingDockView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                zoomManager: zoomManager,
                downloadManager: downloadManager,
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
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.08, green: 0.06, blue: 0.20),
                    Color(red: 0.10, green: 0.08, blue: 0.25)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            GeometryReader { geo in
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

            // Subtle grid
            GeometryReader { geo in
                Path { path in
                    let spacing: CGFloat = 60
                    var x: CGFloat = 0
                    while x < geo.size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: geo.size.height))
                        x += spacing
                    }
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

// MARK: - Bubble Overlay

/// Standalone bubble view that renders on top of everything when a tab is in bubble mode.
private struct BubbleOverlay: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var floatingManager: FloatingWindowManager
    @ObservedObject var tabsManager: TabsManager
    var hapticsEnabled: Bool

    @State private var dragOffset: CGSize = .zero

    private let bubbleSize: CGFloat = 56

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.8),
                            Color(hex: "1A1A2E").opacity(0.9)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: bubbleSize, height: bubbleSize)

            if tab.controller.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(.cyan)
            } else {
                Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
            }

            Circle()
                .stroke(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.4), Color.cyan.opacity(0.1)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: bubbleSize, height: bubbleSize)
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .position(tab.bubblePosition)
        .offset(dragOffset)
        .shadow(color: .cyan.opacity(0.2), radius: 15, x: 0, y: 5)
        .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { value in
                    let newPos = CGPoint(
                        x: tab.bubblePosition.x + value.translation.width,
                        y: tab.bubblePosition.y + value.translation.height
                    )
                    let screen = UIScreen.main.bounds
                    let halfSize = bubbleSize / 2
                    let clampedX = max(halfSize, min(screen.width - halfSize, newPos.x))
                    let clampedY = max(halfSize, min(screen.height - halfSize, newPos.y))

                    let finalX: CGFloat = clampedX < screen.width / 2 ? halfSize + 4 : screen.width - halfSize - 4

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        tab.bubblePosition = CGPoint(x: finalX, y: clampedY)
                        dragOffset = .zero
                    }
                }
        )
        .onTapGesture {
            if hapticsEnabled {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            floatingManager.restoreFromBubble(tab)
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            if hapticsEnabled {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
            withAnimation(.spring(response: 0.3)) {
                tabsManager.close(tab)
            }
        }
        .zIndex(9999)
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
