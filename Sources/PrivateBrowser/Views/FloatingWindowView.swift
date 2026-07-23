import SwiftUI

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
    @State private var lastDragPosition: CGPoint = .zero
    @State private var isResizing: Bool = false
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartLocation: CGPoint = .zero

    var body: some View {
        if tab.isMinimizedToDock {
            minimizedTab
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
        .position(x: tab.floatingPosition.x + dragOffset.width,
                  y: tab.floatingPosition.y + dragOffset.height)
        .shadow(color: .black.opacity(0.4), radius: 20, y: 10)
        .zIndex(Double(tab.windowOrder))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isResizing {
                        dragOffset = value.translation
                    }
                }
                .onEnded { value in
                    if !isResizing {
                        tab.floatingPosition = CGPoint(
                            x: tab.floatingPosition.x + value.translation.width,
                            y: tab.floatingPosition.y + value.translation.height
                        )
                        dragOffset = .zero
                    }
                }
        )
    }

    // MARK: - Title Bar

    private var titleBar: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(isActiveWindow ? Color.green : Color.white.opacity(0.3))
                .frame(width: 8, height: 8)

            Text(tab.displayTitle)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            windowControls
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.08), Color.white.opacity(0.03)],
                startPoint: .top, endPoint: .bottom
            )
        )
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    isResizing = false
                }
        )
    }

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
                .background(Circle().fill(color.opacity(0.2)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Web View Content

    private var webViewContent: some View {
        BrowserView(
            controller: tab.controller,
            zoomManager: zoomManager,
            userscriptManager: UserscriptManager(),
            blockWebRTC: blockWebRTC,
            blockIframe: blockIframe,
            blockAds: blockAds,
            desktopMode: desktopMode
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Resize Handle

    private var resizeHandle: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                path.move(to: CGPoint(x: width - 16, y: height))
                path.addLine(to: CGPoint(x: width, y: height - 16))
            }
            .stroke(Color.white.opacity(0.3), lineWidth: 2)
            .contentShape(Rectangle().size(width: 20, height: 20))
            .position(x: geometry.size.width - 10, y: geometry.size.height - 10)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        isResizing = true
                        let newWidth = tab.floatingSize.width + value.translation.width
                        let newHeight = tab.floatingSize.height + value.translation.height
                        floatingManager.resizeWindow(tab, to: CGSize(width: newWidth, height: newHeight))
                    }
                    .onEnded { _ in
                        isResizing = false
                    }
            )
        }
        .frame(height: 20)
        .background(Color.black.opacity(0.3))
    }

    // MARK: - Minimized Tab (in Dock)

    private var minimizedTab: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isActiveWindow
                                ? [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)]
                                : [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                if tab.controller.isLoading {
                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(0.6)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.5))
                        Text(tab.displayHost)
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.4))
                            .lineLimit(1)
                    }
                }
            }
            .frame(width: 60, height: 44)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isActiveWindow ? Color.cyan.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )

            Text(tab.displayTitle)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 60)
        }
        .onTapGesture {
            haptic(.light)
            tabsManager.select(tab)
            floatingManager.restoreFromDock(tab)
            floatingManager.bringToFront(tab, in: tabsManager)
        }
    }

    // MARK: - Helpers

    private var isActiveWindow: Bool {
        tab.id == tabsManager.activeTabId
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
