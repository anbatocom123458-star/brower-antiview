import SwiftUI

/// Cửa sổ nổi — hiển thị nội dung trang web trong một cửa sổ nhỏ,
/// có thể kéo di chuyển, thu nhỏ, đóng, và chỉnh kích thước.
struct FloatingWindowView: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var floatingManager: FloatingWindowManager
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var zoomManager: ZoomManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var hapticsEnabled: Bool

    @State private var dragOffset: CGSize = .zero
    @State private var isResizing: Bool = false
    @State private var isDragging: Bool = false

    var body: some View {
        if tab.isMinimizedToDock {
            EmptyView()
        } else {
            floatingWindow
        }
    }

    // MARK: - Floating Window

    private var floatingWindow: some View {
        VStack(spacing: 0) {
            titleBar
            webViewContent
            resizeHandle
        }
        .frame(width: tab.floatingSize.width, height: tab.floatingSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 25, y: 10)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    isActiveWindow ? Color.cyan.opacity(0.6) : Color.white.opacity(0.15),
                    lineWidth: isActiveWindow ? 2 : 1
                )
        )
        .offset(x: tab.floatingPosition.x + dragOffset.width,
                y: tab.floatingPosition.y + dragOffset.height)
        .zIndex(Double(tab.windowOrder))
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .onAppear {
            // Đảm bảo vị trí ban đầu nằm trong màn hình
            constrainPosition()
        }
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            // Traffic light buttons
            HStack(spacing: 6) {
                controlButton(icon: "xmark", color: .red) {
                    haptic(.medium)
                    withAnimation(.spring(response: 0.3)) {
                        tabsManager.close(tab)
                    }
                }

                controlButton(icon: "minus", color: .yellow) {
                    haptic(.light)
                    floatingManager.minimizeToDock(tab)
                }

                controlButton(icon: "arrow.up.left.and.arrow.down.right", color: .green) {
                    haptic(.light)
                    // Toggle maximize
                    withAnimation(.spring(response: 0.3)) {
                        if tab.floatingSize.width > 400 {
                            tab.floatingSize = CGSize(width: 320, height: 480)
                            tab.floatingPosition = CGPoint(x: 20, y: 60)
                        } else {
                            let screen = UIScreen.main.bounds
                            tab.floatingSize = CGSize(width: screen.width - 40, height: screen.height - 150)
                            tab.floatingPosition = CGPoint(x: 20, y: 60)
                        }
                    }
                }
            }

            // Title
            Text(tab.displayTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)
                .frame(maxWidth: .infinity)

            // Window info
            HStack(spacing: 4) {
                if tab.controller.isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                        .tint(.cyan)
                }
                Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                    .font(.system(size: 9))
                    .foregroundColor(tab.controller.isSecure ? .green.opacity(0.7) : .orange.opacity(0.7))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: isActiveWindow
                    ? [Color.white.opacity(0.12), Color.white.opacity(0.06)]
                    : [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isResizing {
                        isDragging = true
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if !isResizing {
                        isDragging = false
                        tab.floatingPosition = CGPoint(
                            x: tab.floatingPosition.x + value.translation.width,
                            y: tab.floatingPosition.y + value.translation.height
                        )
                        dragOffset = .zero
                        constrainPosition()
                    }
                }
        )
        .onTapGesture {
            haptic(.light)
            tabsManager.select(tab)
            floatingManager.bringToFront(tab, in: tabsManager)
        }
    }

    // MARK: - Window Controls

    private var windowControls: some View {
        HStack(spacing: 6) {
            controlButton(icon: "minus", color: .yellow) {
                haptic(.light)
                floatingManager.minimizeToDock(tab)
            }

            controlButton(icon: "xmark", color: .red) {
                haptic(.medium)
                withAnimation(.spring(response: 0.3)) {
                    tabsManager.close(tab)
                }
            }
        }
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .bold))
                .foregroundColor(color)
                .frame(width: 14, height: 14)
                .background(Circle().fill(color.opacity(0.25)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Web View Content

    private var webViewContent: some View {
        BrowserView(
            controller: tab.controller,
            zoomManager: zoomManager,
            userscriptManager: UserscriptManager.shared,
            blockWebRTC: blockWebRTC,
            blockIframe: blockIframe,
            blockAds: blockAds,
            desktopMode: desktopMode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black)
    }

    // MARK: - Resize Handle

    private var resizeHandle: some View {
        GeometryReader { geometry in
            ZStack {
                // Resize grip dots
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    // Diagonal lines
                    path.move(to: CGPoint(x: width - 18, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - 18))
                    path.move(to: CGPoint(x: width - 12, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - 12))
                    path.move(to: CGPoint(x: width - 6, y: height))
                    path.addLine(to: CGPoint(x: width, y: height - 6))
                }
                .stroke(Color.white.opacity(0.35), lineWidth: 1.5)
            }
            .contentShape(Rectangle().size(width: 30, height: 30))
            .position(x: geometry.size.width - 15, y: geometry.size.height - 15)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isResizing = true
                        let newWidth = max(250, min(UIScreen.main.bounds.width - 40,
                                                    tab.floatingSize.width + value.translation.width))
                        let newHeight = max(350, min(UIScreen.main.bounds.height - 150,
                                                     tab.floatingSize.height + value.translation.height))
                        tab.floatingSize = CGSize(width: newWidth, height: newHeight)
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
        }
        .frame(height: 25)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.4), Color.black.opacity(0.2)],
                startPoint: .top, endPoint: .bottom
            )
        )
    }

    // MARK: - Helpers

    private var isActiveWindow: Bool {
        tab.id == tabsManager.activeTabId
    }

    /// Đảm bảo cửa sổ không bị kéo ra ngoài màn hình
    private func constrainPosition() {
        let screen = UIScreen.main.bounds
        let maxX = screen.width - tab.floatingSize.width
        let maxY = screen.height - tab.floatingSize.height - 100 // Dock height
        let minX: CGFloat = 0
        let minY: CGFloat = 20

        let clampedX = max(minX, min(maxX, tab.floatingPosition.x))
        let clampedY = max(minY, min(maxY, tab.floatingPosition.y))

        if tab.floatingPosition.x != clampedX || tab.floatingPosition.y != clampedY {
            withAnimation(.spring(response: 0.3)) {
                tab.floatingPosition = CGPoint(x: clampedX, y: clampedY)
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
