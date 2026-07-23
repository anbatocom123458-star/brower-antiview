import SwiftUI

/// Cửa sổ nổi chuẩn Desktop — hỗ trợ kéo di chuyển, resize từ mọi góc/cạnh,
/// tỉ lệ khung hình, thanh URL điều hướng, con trỏ ảo (Trackpad Mode),
/// chế độ bong bóng (Bubble/PiP), và Reader Mode.
///
/// v4.0: Full floating OS experience:
/// - WebView fills 100% of window (no gaps)
/// - Invisible resize handles (drag from any edge/corner)
/// - Smooth edge clamping (no jitter at screen edges, ignoresSafeArea)
/// - Virtual cursor toggle moved to Dock (global only)
/// - Mini Bubble / PiP mode when minimizing
/// - Reader Mode with AI summary
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
    @State private var showReaderMode = false
    @State private var showReaderSummary = false

    // MARK: - Resize state
    @State private var activeResizeEdge: ResizeEdge = .none
    @State private var resizeStartSize: CGSize = .zero
    @State private var resizeStartPosition: CGPoint = .zero

    // MARK: - Bubble drag state
    @State private var bubbleDragOffset: CGSize = .zero

    var body: some View {
        if tab.isBubbleMode {
            bubbleView
        } else if tab.isMinimizedToDock {
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
            if tab.isReaderMode {
                readerContent
            } else {
                webViewContent
            }
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
            // Virtual cursor overlay (Trackpad Mode)
            Group {
                if floatingManager.globalVirtualCursorEnabled {
                    VirtualCursorOverlay(
                        cursorPosition: $tab.virtualCursorLocalPosition,
                        windowSize: tab.floatingSize,
                        hapticsEnabled: hapticsEnabled,
                        onTap: {
                            if hapticsEnabled {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        },
                        onDragStart: { },
                        onDragChanged: { delta in },
                        onDragEnd: { }
                    )
                }
            }
        )
        .overlay(
            // Invisible resize handles on all edges/corners
            resizeOverlay
        )
        .offset(
            x: tab.floatingPosition.x + dragOffset.width,
            y: tab.floatingPosition.y + dragOffset.height
        )
        .zIndex(Double(tab.windowOrder))
        .animation(.interactiveSpring(response: 0.3, dampingFraction: 0.8), value: isDragging)
        .animation(.easeInOut(duration: 0.2), value: tab.floatingSize)
        .ignoresSafeArea(edges: .all)
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

    // MARK: - Title Bar

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
                    floatingManager.minimizeToBubble(tab, allTabs: tabsManager.tabs)
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

                // Reader mode toggle
                Button(action: {
                    haptic(.light)
                    toggleReaderMode()
                }) {
                    Image(systemName: tab.isReaderMode ? "book.fill" : "book")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(tab.isReaderMode ? .orange : .white.opacity(0.6))
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

    // MARK: - Browser Tool Bar

    private var browserToolBar: some View {
        Group {
            if showBrowserBar {
                VStack(spacing: 0) {
                    HStack(spacing: 6) {
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

                        navButton(
                            icon: tab.controller.isLoading ? "xmark" : "arrow.clockwise",
                            isEnabled: true
                        ) {
                            tab.controller.isLoading ? tab.controller.stopLoading() : tab.controller.reload()
                        }

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
        .clipped()
        .background(Color.black)
    }

    // MARK: - Reader Content View

    private var readerContent: some View {
        VStack(spacing: 0) {
            if tab.isSummarizing {
                // Loading summary
                VStack(spacing: 12) {
                    ProgressView()
                        .tint(.orange)
                    Text("Đang tóm tắt bài viết...")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1A1A2E"))
            } else if let summary = tab.articleSummary, showReaderSummary {
                // Show AI summary
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.orange)
                            Text("Tóm tắt bởi AI")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.orange)
                            Spacer()
                            Button(action: {
                                showReaderSummary = false
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .buttonStyle(.plain)
                        }

                        Divider().background(Color.white.opacity(0.15))

                        Text(summary)
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1A1A2E"))
            } else if let content = tab.readerContent {
                // Show extracted article
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        // Article header
                        VStack(alignment: .leading, spacing: 6) {
                            Text(content.title)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)

                            HStack(spacing: 8) {
                                if !content.author.isEmpty {
                                    Text(content.author)
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                if !content.siteName.isEmpty {
                                    Text("· \(content.siteName)")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                            }

                            // Summarize button
                            Button(action: {
                                summarizeArticle(content)
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 10))
                                    Text("Tóm tắt bằng AI")
                                        .font(.system(size: 10, weight: .semibold))
                                }
                                .foregroundColor(.orange)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.orange.opacity(0.15))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.bottom, 8)

                        // Images
                        ForEach(content.images.prefix(2)) { image in
                            // Image loading would go here in production
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 120)
                                .overlay(
                                    Text("Hình ảnh")
                                        .font(.system(size: 10))
                                        .foregroundColor(.white.opacity(0.3))
                                )
                        }

                        // Content blocks
                        ForEach(content.content) { block in
                            switch block.type {
                            case .heading:
                                Text(block.text)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(.top, 8)
                            case .quote:
                                Text(block.text)
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.cyan.opacity(0.8))
                                    .italic()
                                    .padding(.leading, 12)
                                    .overlay(
                                        Rectangle()
                                            .fill(Color.cyan.opacity(0.4))
                                            .frame(width: 2)
                                            .padding(.leading, 0)
                                    )
                            case .paragraph:
                                Text(block.text)
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineSpacing(3)
                            }
                        }
                    }
                    .padding(16)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1A1A2E"))
            } else {
                // Reader mode active but no content extracted yet
                VStack(spacing: 12) {
                    Image(systemName: "book")
                        .font(.system(size: 32))
                        .foregroundColor(.orange.opacity(0.6))
                    Text("Reader Mode")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("Đang trích xuất nội dung...")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                    ProgressView()
                        .tint(.orange)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(hex: "1A1A2E"))
                .onAppear {
                    extractArticleContent()
                }
            }
        }
    }

    // MARK: - Bubble View (Mini PiP)

    private var bubbleView: some View {
        let bubbleSize: CGFloat = 56

        return ZStack {
            // Bubble body
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
                .shadow(color: .cyan.opacity(0.3), radius: 12, x: 0, y: 4)
                .shadow(color: .black.opacity(0.5), radius: 8, x: 0, y: 2)

            // Favicon / site icon
            if tab.controller.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
                    .tint(.cyan)
            } else {
                Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.8))
            }

            // Subtle ring
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.4),
                            Color.cyan.opacity(0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: bubbleSize, height: bubbleSize)
        }
        .frame(width: bubbleSize, height: bubbleSize)
        .position(tab.bubblePosition)
        .offset(bubbleDragOffset)
        .shadow(color: .cyan.opacity(0.2), radius: 15, x: 0, y: 5)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    bubbleDragOffset = value.translation
                }
                .onEnded { value in
                    let newPos = CGPoint(
                        x: tab.bubblePosition.x + value.translation.width,
                        y: tab.bubblePosition.y + value.translation.height
                    )
                    let screen = UIScreen.main.bounds
                    let halfSize = bubbleSize / 2

                    // Snap to nearest edge
                    let clampedX = max(halfSize, min(screen.width - halfSize, newPos.x))
                    let clampedY = max(halfSize, min(screen.height - halfSize, newPos.y))

                    // Determine if closer to left or right edge
                    let finalX: CGFloat
                    if clampedX < screen.width / 2 {
                        finalX = halfSize + 4
                    } else {
                        finalX = screen.width - halfSize - 4
                    }

                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        tab.bubblePosition = CGPoint(x: finalX, y: clampedY)
                        bubbleDragOffset = .zero
                    }
                }
        )
        .onTapGesture {
            haptic(.medium)
            floatingManager.restoreFromBubble(tab)
        }
        .onLongPressGesture(minimumDuration: 0.3) {
            haptic(.heavy)
            // Long press = close
            withAnimation(.spring(response: 0.3)) {
                tabsManager.close(tab)
            }
        }
    }

    // MARK: - Resize Overlay

    private var resizeOverlay: some View {
        GeometryReader { geo in
            ZStack {
                ResizeZone(edge: .topLeading, tab: tab, floatingManager: floatingManager, onDragStart: { saveResizeState() }, onDragEnd: { constrainPosition() })
                    .frame(width: 24, height: 24)
                    .position(x: 12, y: 12)

                ResizeZone(edge: .topTrailing, tab: tab, floatingManager: floatingManager, onDragStart: { saveResizeState() }, onDragEnd: { constrainPosition() })
                    .frame(width: 24, height: 24)
                    .position(x: geo.size.width - 12, y: 12)

                ResizeZone(edge: .bottomLeading, tab: tab, floatingManager: floatingManager, onDragStart: { saveResizeState() }, onDragEnd: { constrainPosition() })
                    .frame(width: 24, height: 24)
                    .position(x: 12, y: geo.size.height - 12)

                ResizeZone(edge: .bottomTrailing, tab: tab, floatingManager: floatingManager, onDragStart: { saveResizeState() }, onDragEnd: { constrainPosition() })
                    .frame(width: 24, height: 24)
                    .position(x: geo.size.width - 12, y: geo.size.height - 12)

                BottomResizeZone(tab: tab, floatingManager: floatingManager, onDragStart: { saveResizeState() }, onDragEnd: { constrainPosition() })
                    .frame(width: geo.size.width - 48, height: 8)
                    .position(x: geo.size.width / 2, y: geo.size.height - 4)
            }
        }
    }

    // MARK: - Helpers

    private var isActiveWindow: Bool {
        tab.id == tabsManager.activeTabId
    }

    private func saveResizeState() {
        isResizing = true
        resizeStartSize = tab.floatingSize
        resizeStartPosition = tab.floatingPosition
    }

    private func toggleMaximize() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            let screen = UIScreen.main.bounds
            if tab.floatingSize.width > 400 {
                let restoreSize = floatingManager.defaultWindowSize
                tab.floatingSize = restoreSize
                tab.floatingPosition = CGPoint(x: 20, y: 60)
            } else {
                tab.floatingSize = CGSize(width: screen.width - 40, height: screen.height - 120)
                tab.floatingPosition = CGPoint(x: 20, y: 60)
            }
        }
    }

    private func toggleReaderMode() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tab.isReaderMode.toggle()
            showReaderSummary = false
            tab.articleSummary = nil
            tab.readerContent = nil
        }
    }

    private func extractArticleContent() {
        guard let webView = findWKWebView() else { return }
        ReaderModeManager.shared.extractArticle(from: webView) { content in
            tab.readerContent = content
        }
    }

    private func summarizeArticle(_ content: ReaderContent) {
        tab.isSummarizing = true
        showReaderSummary = true
        ReaderModeManager.shared.summarizeArticle(content) { summary in
            tab.articleSummary = summary
            tab.isSummarizing = false
        }
    }

    private func findWKWebView() -> WKWebView? {
        // Walk the view hierarchy to find WKWebView
        let keyWindow = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }

        func findWebView(in view: UIView) -> WKWebView? {
            if let webView = view as? WKWebView {
                return webView
            }
            for subview in view.subviews {
                if let found = findWebView(in: subview) {
                    return found
                }
            }
            return nil
        }

        return keyWindow.flatMap { findWebView(in: $0) }
    }

    private func constrainPosition() {
        isResizing = false
        let screen = UIScreen.main.bounds
        let maxX = screen.width - tab.floatingSize.width
        let maxY = screen.height - tab.floatingSize.height
        let minX: CGFloat = 0
        let minY: CGFloat = 0

        let clampedX = max(minX, min(maxX, tab.floatingPosition.x))
        let clampedY = max(minY, min(maxY, tab.floatingPosition.y))

        if tab.floatingPosition.x != clampedX || tab.floatingPosition.y != clampedY {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
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
        } else if pos.y > screen.height - tab.floatingSize.height - snapThreshold {
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

// MARK: - Resize Zone

private struct ResizeZone: View {
    let edge: ResizeEdge
    @ObservedObject var tab: BrowserTab
    @ObservedObject var floatingManager: FloatingWindowManager
    var onDragStart: () -> Void
    var onDragEnd: () -> Void

    @State private var isDragging = false
    @State private var startSize: CGSize = .zero
    @State private var startPosition: CGPoint = .zero

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startSize = tab.floatingSize
                            startPosition = tab.floatingPosition
                            onDragStart()
                        }
                        handleDragChanged(value)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onDragEnd()
                    }
            )
            .background(
                Group {
                    if isDragging {
                        edgeGlow
                    }
                }
            )
    }

    private var edgeGlow: some View {
        GeometryReader { geo in
            switch edge {
            case .topLeading:
                VStack { Rectangle().fill(LinearGradient(colors: [.cyan.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 2); Spacer() }.frame(height: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .topTrailing:
                VStack { Rectangle().fill(LinearGradient(colors: [.cyan.opacity(0.3), .clear], startPoint: .topTrailing, endPoint: .bottomLeading)).frame(height: 2); Spacer() }.frame(height: 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            case .bottomLeading:
                VStack { Spacer(); Rectangle().fill(LinearGradient(colors: [.clear, .cyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)).frame(height: 2) }.frame(height: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            case .bottomTrailing:
                VStack { Spacer(); Rectangle().fill(LinearGradient(colors: [.clear, .cyan.opacity(0.3)], startPoint: .topTrailing, endPoint: .bottomLeading)).frame(height: 2) }.frame(height: 8)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            case .none:
                EmptyView()
            }
        }
    }

    private func handleDragChanged(_ value: DragGesture.Value) {
        let minW: CGFloat = 280
        let maxW: CGFloat = UIScreen.main.bounds.width - 40
        let minH: CGFloat = 320
        let maxH: CGFloat = UIScreen.main.bounds.height - 80

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

        if let ratio = tab.aspectRatio?.ratio {
            newH = newW / ratio
            newH = max(minH, min(maxH, newH))
        }

        tab.floatingSize = CGSize(width: newW, height: newH)

        if edge == .topLeading || edge == .topTrailing {
            let heightDelta = startSize.height - newH
            tab.floatingPosition = CGPoint(
                x: startPosition.x,
                y: max(0, startPosition.y + heightDelta)
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
}

// MARK: - Bottom Resize Zone (vertical-only resize from bottom edge)

private struct BottomResizeZone: View {
    @ObservedObject var tab: BrowserTab
    @ObservedObject var floatingManager: FloatingWindowManager
    var onDragStart: () -> Void
    var onDragEnd: () -> Void

    @State private var isDragging = false
    @State private var startSize: CGSize = .zero

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { value in
                        if !isDragging {
                            isDragging = true
                            startSize = tab.floatingSize
                            onDragStart()
                        }
                        // Only vertical resize — ignore horizontal translation
                        let minH: CGFloat = 320
                        let maxH: CGFloat = UIScreen.main.bounds.height - 80
                        let newH = max(minH, min(maxH, startSize.height + value.translation.height))
                        tab.floatingSize = CGSize(width: tab.floatingSize.width, height: newH)
                    }
                    .onEnded { _ in
                        isDragging = false
                        onDragEnd()
                    }
            )
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

// MARK: - WKWebView import for findWKWebView

import WebKit
