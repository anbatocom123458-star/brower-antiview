import SwiftUI

/// Cửa sổ nổi chuẩn Desktop — hỗ trợ kéo di chuyển, resize từ 4 góc/cạnh,
/// tỉ lệ khung hình, thanh URL điều hướng, và con trỏ ảo.
///
/// v3.4: Redesign toàn diện — title bar tích hợp browser controls,
/// resize handle trên mọi góc/cạnh, virtual cursor overlay,
/// aspect ratio selector, snap-to-edge khi kéo gần viền.
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
    @State private var showBrowserBar: Bool = false
    @State private var showAspectRatioMenu: Bool = false
    @State private var editingURL: String = ""
    @State private var isURLEditing: Bool = false
    @State private var showTabSwitcher: Bool = false

    // MARK: - Resize state
    @State private var resizeEdge: ResizeEdge = .none
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartPosition: CGPoint = .zero

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
            browserToolBar
            webViewContent
            resizeHandles
        }
        .frame(width: tab.floatingSize.width, height: tab.floatingSize.height)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: .black.opacity(0.5), radius: 30, y: 12)
        .shadow(color: .cyan.opacity(isDragging ? 0.15 : 0), radius: 20, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    borderStroke,
                    lineWidth: isActiveWindow ? 1.5 : 0.8
                )
        )
        .overlay(
            // Virtual cursor overlay
            Group {
                if tab.virtualCursorEnabled || floatingManager.globalVirtualCursorEnabled {
                    VirtualCursorOverlay(
                        position: $tab.virtualCursorLocalPosition,
                        windowSize: tab.floatingSize,
                        hapticsEnabled: hapticsEnabled
                    )
                }
            }
        )
        .offset(
            x: tab.floatingPosition.x + dragOffset.width,
            y: tab.floatingPosition.y + dragOffset.height
        )
        .zIndex(Double(tab.windowOrder))
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .animation(.easeInOut(duration: 0.2), value: tab.floatingSize)
        .onAppear {
            constrainPosition()
        }
        .onChange(of: isDragging) { dragging in
            if !dragging {
                snapIfNeeded()
            }
        }
    }

    private var borderStroke: Color {
        if isActiveWindow {
            return tab.isPrivateMode ? Color.purple.opacity(0.7) : Color.cyan.opacity(0.6)
        }
        return Color.white.opacity(0.12)
    }

    // MARK: - Title Bar (macOS-style traffic lights + title + actions)

    private var titleBar: some View {
        HStack(spacing: 0) {
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
                    toggleMaximize()
                }
            }
            .padding(.leading, 12)

            Spacer()

            // Title + lock icon
            HStack(spacing: 4) {
                if tab.controller.isLoading {
                    ProgressView()
                        .scaleEffect(0.4)
                        .tint(.cyan)
                }
                Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                    .font(.system(size: 8))
                    .foregroundColor(tab.controller.isSecure ? .green.opacity(0.8) : .orange.opacity(0.8))
                Text(tab.displayTitle)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(1)
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                // Tab switcher
                Button(action: {
                    haptic(.light)
                    showTabSwitcher.toggle()
                }) {
                    Text("\(tabsManager.tabCount)")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .frame(width: 18, height: 14)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .stroke(Color.white.opacity(0.4), lineWidth: 0.8)
                        )
                }
                .buttonStyle(.plain)

                // Browser bar toggle
                Button(action: {
                    haptic(.light)
                    showBrowserBar.toggle()
                }) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(showBrowserBar ? .cyan : .white.opacity(0.6))
                }
                .buttonStyle(.plain)

                // Aspect ratio menu
                Button(action: {
                    haptic(.light)
                    showAspectRatioMenu.toggle()
                }) {
                    Image(systemName: "aspectratio")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .popover(isPresented: $showAspectRatioMenu) {
                    if #available(iOS 16.4, *) {
                        AspectRatioMenu(tab: tab, floatingManager: floatingManager)
                            .presentationCompactAdaptation(.popover)
                    } else {
                        AspectRatioMenu(tab: tab, floatingManager: floatingManager)
                    }
                }

                // Virtual cursor toggle
                Button(action: {
                    haptic(.light)
                    toggleVirtualCursor()
                }) {
                    Image(systemName: "cursorarrow.click.2")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(
                            (tab.virtualCursorEnabled || floatingManager.globalVirtualCursorEnabled)
                                ? .cyan : .white.opacity(0.6)
                        )
                }
                .buttonStyle(.plain)
            }
            .padding(.trailing, 12)
        }
        .padding(.vertical, 7)
        .frame(height: 30)
        .background(
            LinearGradient(
                colors: isActiveWindow
                    ? [Color.white.opacity(0.1), Color.white.opacity(0.04)]
                    : [Color.white.opacity(0.06), Color.white.opacity(0.02)],
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

    // MARK: - Browser Tool Bar (URL + Navigation)

    private var browserToolBar: some View {
        Group {
            if showBrowserBar {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
                        // Navigation buttons
                        navButton(icon: "arrow.left", isEnabled: tab.controller.canGoBack) {
                            tab.controller.goBack()
                        }
                        navButton(icon: "arrow.right", isEnabled: tab.controller.canGoForward) {
                            tab.controller.goForward()
                        }

                        // URL field
                        HStack(spacing: 4) {
                            Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                                .font(.system(size: 8))
                                .foregroundColor(tab.controller.isSecure ? .green : .orange)

                            if isURLEditing {
                                TextField("URL hoặc tìm kiếm...", text: $editingURL)
                                    .font(.system(size: 10, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .autocapitalization(.none)
                                    .disableAutocorrection(true)
                                    .submitLabel(.go)
                                    .onSubmit {
                                        isURLEditing = false
                                        tab.controller.navigate(to: editingURL)
                                    }
                                    .onTapGesture { }
                            } else {
                                Text(tab.controller.urlString.replacingOccurrences(of: "https://", with: "").replacingOccurrences(of: "http://", with: ""))
                                    .font(.system(size: 9, weight: .medium, design: .rounded))
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                                    .onTapGesture {
                                        editingURL = tab.controller.urlString
                                        isURLEditing = true
                                    }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(6)

                        // Reload / Stop
                        navButton(
                            icon: tab.controller.isLoading ? "xmark" : "arrow.clockwise",
                            isEnabled: true
                        ) {
                            tab.controller.isLoading ? tab.controller.stopLoading() : tab.controller.reload()
                        }

                        // Home
                        navButton(icon: "house.fill", isEnabled: true) {
                            tab.controller.goHome()
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)

                    Divider().background(Color.white.opacity(0.1))
                }
                .background(Color.black.opacity(0.5))
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.85), value: showBrowserBar)
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

    // MARK: - Resize Handles (4 corners + 4 edges)

    private var resizeHandles: some View {
        ZStack {
            // Corner handles
            ResizeCornerHandle(edge: .topLeading, tab: tab, floatingManager: floatingManager)
            ResizeCornerHandle(edge: .topTrailing, tab: tab, floatingManager: floatingManager)
            ResizeCornerHandle(edge: .bottomLeading, tab: tab, floatingManager: floatingManager)
            ResizeCornerHandle(edge: .bottomTrailing, tab: tab, floatingManager: floatingManager)
        }
    }

    // MARK: - Helpers

    private var isActiveWindow: Bool {
        tab.id == tabsManager.activeTabId
    }

    private func toggleMaximize() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            let screen = UIScreen.main.bounds
            if tab.floatingSize.width > 400 {
                // Restore
                let restoreSize = floatingManager.defaultWindowSize
                tab.floatingSize = restoreSize
                tab.floatingPosition = CGPoint(x: 20, y: 60)
            } else {
                // Maximize
                tab.floatingSize = CGSize(width: screen.width - 40, height: screen.height - 120)
                tab.floatingPosition = CGPoint(x: 20, y: 60)
            }
        }
    }

    private func toggleVirtualCursor() {
        haptic(.light)
        if floatingManager.globalVirtualCursorEnabled {
            floatingManager.globalVirtualCursorEnabled = false
        } else {
            floatingManager.globalVirtualCursorEnabled = true
        }
        tab.virtualCursorEnabled = floatingManager.globalVirtualCursorEnabled
    }

    private func constrainPosition() {
        let screen = UIScreen.main.bounds
        let maxX = screen.width - tab.floatingSize.width
        let maxY = screen.height - tab.floatingSize.height - 90
        let minX: CGFloat = 0
        let minY: CGFloat = 10

        let clampedX = max(minX, min(maxX, tab.floatingPosition.x))
        let clampedY = max(minY, min(maxY, tab.floatingPosition.y))

        if tab.floatingPosition.x != clampedX || tab.floatingPosition.y != clampedY {
            withAnimation(.spring(response: 0.3)) {
                tab.floatingPosition = CGPoint(x: clampedX, y: clampedY)
            }
        }
    }

    private func snapIfNeeded() {
        let screen = UIScreen.main.bounds
        let snapThreshold: CGFloat = 20
        let pos = tab.floatingPosition

        if pos.x < snapThreshold {
            floatingManager.snapToEdge(tab, edge: .left)
        } else if pos.x > screen.width - tab.floatingSize.width - snapThreshold {
            floatingManager.snapToEdge(tab, edge: .right)
        }
        if pos.y < snapThreshold {
            floatingManager.snapToEdge(tab, edge: .top)
        } else if pos.y > screen.height - tab.floatingSize.height - 90 - snapThreshold {
            floatingManager.snapToEdge(tab, edge: .bottom)
        }
    }

    private func navButton(icon: String, isEnabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: {
            haptic(.light)
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white.opacity(isEnabled ? 0.8 : 0.25))
                .frame(width: 16, height: 16)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }

    private func controlButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(color)
                .frame(width: 12, height: 12)
                .background(Circle().fill(color.opacity(0.3)))
        }
        .buttonStyle(.plain)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Resize Corner Handle

private struct ResizeCornerHandle: View {
    let edge: ResizeEdge
    @ObservedObject var tab: BrowserTab
    @ObservedObject var floatingManager: FloatingWindowManager

    @State private var startSize: CGSize = .zero
    @State private var startPosition: CGPoint = .zero

    var body: some View {
        GeometryReader { geo in
            let handleSize: CGFloat = 22
            let position = cornerPosition(in: geo.size, handleSize: handleSize)

            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: handleSize, height: handleSize)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.5)
                )
                .position(position)
                .contentShape(Circle())
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { value in
                            startSize = tab.floatingSize
                            startPosition = tab.floatingPosition
                            handleDragChanged(value)
                        }
                        .onEnded { _ in
                            constrainPosition()
                        }
                )
        }
        .frame(width: 22, height: 22)
        .position(cornerPositionInWindow)
    }

    private var cornerPositionInWindow: CGPoint {
        let w = tab.floatingSize.width
        let h = tab.floatingSize.height
        switch edge {
        case .topLeading: return CGPoint(x: 11, y: 11)
        case .topTrailing: return CGPoint(x: w - 11, y: 11)
        case .bottomLeading: return CGPoint(x: 11, y: h - 11)
        case .bottomTrailing: return CGPoint(x: w - 11, y: h - 11)
        case .none: return CGPoint(x: w / 2, y: h / 2)
        }
    }

    private func cornerPosition(in size: CGSize, handleSize: CGFloat) -> CGPoint {
        let h = handleSize / 2
        switch edge {
        case .topLeading: return CGPoint(x: h, y: h)
        case .topTrailing: return CGPoint(x: size.width - h, y: h)
        case .bottomLeading: return CGPoint(x: h, y: size.height - h)
        case .bottomTrailing: return CGPoint(x: size.width - h, y: size.height - h)
        case .none: return CGPoint(x: size.width / 2, y: size.height / 2)
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        let minW: CGFloat = 280
        let maxW: CGFloat = UIScreen.main.bounds.width - 40
        let minH: CGFloat = 320
        let maxH: CGFloat = UIScreen.main.bounds.height - 120

        var deltaW: CGFloat = 0
        var deltaH: CGFloat = 0

        switch edge {
        case .topLeading:
            deltaW = -value.translation.width
            deltaH = -value.translation.height
        case .topTrailing:
            deltaW = value.translation.width
            deltaH = -value.translation.height
        case .bottomLeading:
            deltaW = -value.translation.width
            deltaH = value.translation.height
        case .bottomTrailing:
            deltaW = value.translation.width
            deltaH = value.translation.height
        case .none:
            break
        }

        let newW = max(minW, min(maxW, startSize.width + deltaW))
        var newH = max(minH, min(maxH, startSize.height + deltaH))

        // Maintain aspect ratio if locked
        if let ratio = tab.aspectRatio?.ratio {
            newH = newW / ratio
            newH = max(minH, min(maxH, newH))
        }

        tab.floatingSize = CGSize(width: newW, height: newH)

        // Adjust position for top/left edges
        if edge == .topLeading || edge == .topTrailing {
            let heightDelta = startSize.height - newH
            tab.floatingPosition = CGPoint(
                x: startPosition.x,
                y: max(10, startPosition.y + heightDelta)
            )
        }
        if edge == .topLeading || edge == .bottomLeading {
            let widthDelta = startSize.width - newW
            tab.floatingPosition = CGPoint(
                x: max(0, startPosition.x + widthDelta),
                y: tab.floatingPosition.y
            )
        }
    }

    private func constrainPosition() {
        let screen = UIScreen.main.bounds
        let maxX = screen.width - tab.floatingSize.width
        let maxY = screen.height - tab.floatingSize.height - 90
        let x = max(0, min(maxX, tab.floatingPosition.x))
        let y = max(10, min(maxY, tab.floatingPosition.y))

        if tab.floatingPosition.x != x || tab.floatingPosition.y != y {
            withAnimation(.spring(response: 0.3)) {
                tab.floatingPosition = CGPoint(x: x, y: y)
            }
        }
    }
}

// MARK: - Resize Edge

enum ResizeEdge {
    case none
    case topLeading, topTrailing, bottomLeading, bottomTrailing
}

// MARK: - Aspect Ratio Menu

private struct AspectRatioMenu: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var floatingManager: FloatingWindowManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            Text("Tỉ lệ khung hình")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.horizontal, 12)
                .padding(.top, 8)

            ForEach(AspectRatioPreset.allCases) { preset in
                Button(action: {
                    floatingManager.setAspectRatio(preset, for: tab)
                    dismiss()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: preset.icon)
                            .font(.system(size: 12))
                            .frame(width: 20)
                        Text(preset.displayName)
                            .font(.system(size: 12))
                        Spacer()
                        if tab.aspectRatio == preset {
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                }
            }
        }
        .frame(width: 160)
    }
}
