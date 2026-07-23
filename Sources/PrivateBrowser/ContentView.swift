import SwiftUI
import UIKit

/// Màn hình chính: thanh địa chỉ + trình duyệt + thanh công cụ + menu riêng + đa tab.
/// So với bản cũ, logic điều hướng được chuyển hết vào BrowserController để
/// tránh loop reload, và các cài đặt được đọc qua AppStorage tập trung (SettingsKey).
///
/// Kiến trúc đa tab: TabsManager giữ danh sách BrowserTab, mỗi tab có BrowserController
/// riêng (URL/lịch sử/tiến trình tải độc lập) nhưng dùng CHUNG cấu hình bảo mật
/// (blockWebRTC/desktopMode...) và CHUNG một ZoomManager — mỗi tab khác nhau về nội
/// dung đang xem, không khác nhau về mức độ chặn quảng cáo/WebRTC đang bật.
///
/// Riêng CHẾ ĐỘ RIÊNG TƯ (isPrivateMode) là thuộc tính CỦA TỪNG TAB — người dùng mở
/// một tab Riêng tư riêng biệt (giống Safari), tab đó có viền/nhãn tím rõ ràng để
/// không bao giờ nhầm lẫn mình đang ở tab nào. Về mặt kỹ thuật, MỌI tab (thường lẫn
/// riêng tư) đều đã dùng WKWebsiteDataStore.nonPersistent() — nghĩa là không tab nào
/// lưu cookie/cache xuống đĩa cả; điểm khác biệt của tab Riêng tư chỉ là giao diện
/// nhắc người dùng rõ ràng hơn, không phải một cơ chế ẩn danh khác về bản chất.
///
/// Tất cả WKWebView của mọi tab được giữ SỐNG cùng lúc trong một ZStack (không phải
/// tạo/huỷ mỗi lần chuyển tab) — tab không active chỉ bị ẩn bằng opacity 0 và tắt
/// nhận cảm ứng. Điều này giữ đúng trạng thái cuộn/form đang nhập của các tab nền,
/// giống hành vi tab thật của Safari, đổi lại tốn RAM hơn theo số tab đang mở.
///
/// v3.2: Thêm Userscript Manager, Download Manager, Window Mode, tách tab thường/riêng tư.
struct ContentView: View {
    @StateObject private var tabsManager = TabsManager()
    @StateObject private var zoomManager = ZoomManager()
    @StateObject private var userscriptManager = UserscriptManager.shared
    @StateObject private var downloadManager = DownloadManager.shared

    @AppStorage(SettingsKey.blockWebRTC) private var blockWebRTC = true
    @AppStorage(SettingsKey.blockIframe) private var blockIframe = true
    @AppStorage(SettingsKey.blockAds) private var blockAds = true
    @AppStorage(SettingsKey.desktopMode) private var desktopMode = false
    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKey.autoClearOnBackground) private var autoClearOnBackground = false
    @AppStorage(SettingsKey.windowMode) private var windowMode = false
    @AppStorage(SettingsKey.userscriptsEnabled) private var userscriptsEnabled = true

    @Environment(\.scenePhase) private var scenePhase

    @State private var editingText = BrowserSettingsStore.homeURL
    @FocusState private var isURLFieldFocused: Bool
    @State private var showZoomPanel = false
    @State private var showMenu = false
    @State private var showAbout = false
    @State private var showTabGrid = false
    @State private var showWindowMode = false
    @State private var showDebugConsole = false
    @State private var showUserscriptEditor = false
    @State private var showDownloadPanel = false
    @State private var isBackgrounded = false
    @State private var isScreenCaptured = false

    private var activeController: BrowserController { tabsManager.activeTab.controller }
    private var isActivePrivate: Bool { activeController.isPrivateMode }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: isActivePrivate
                    ? [Color(hex: "1A0B2E"), Color(hex: "0D0619")]
                    : [AppTheme.backgroundTop, AppTheme.backgroundBottom],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.25), value: isActivePrivate)

            VStack(spacing: 0) {
                if isActivePrivate {
                    PrivateModeBanner()
                }

                URLBarView(
                    controller: activeController,
                    editingText: $editingText,
                    isFocused: $isURLFieldFocused,
                    onSubmit: submitURL
                )

                ZStack {
                    ForEach(tabsManager.tabs) { tab in
                        let isActive = tab.id == tabsManager.activeTabId
                        BrowserView(
                            controller: tab.controller,
                            zoomManager: zoomManager,
                            userscriptManager: userscriptManager,
                            blockWebRTC: blockWebRTC,
                            blockIframe: blockIframe,
                            blockAds: blockAds,
                            desktopMode: desktopMode
                        )
                        .opacity(isActive ? 1 : 0)
                        .allowsHitTesting(isActive)
                        .accessibilityHidden(!isActive)
                    }
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isActivePrivate ? Color.purple.opacity(0.6) : Color.clear, lineWidth: 2)
                    )

                    if let error = activeController.loadError {
                        Color.black.opacity(0.25)
                        ErrorOverlayView(
                            message: error,
                            onRetry: { activeController.reload() },
                            onDismiss: { activeController.loadError = nil }
                        )
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)

                BottomToolbarView(
                    controller: activeController,
                    zoomManager: zoomManager,
                    hapticsEnabled: hapticsEnabled,
                    showZoomPanel: showZoomPanel,
                    tabCount: tabsManager.tabCount,
                    onBack: { activeController.goBack() },
                    onForward: { activeController.goForward() },
                    onReloadOrStop: {
                        activeController.isLoading ? activeController.stopLoading() : activeController.reload()
                    },
                    onToggleZoom: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showZoomPanel.toggle() } },
                    onOpenTabs: {
                        isURLFieldFocused = false
                        if windowMode {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showWindowMode = true }
                        } else {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showTabGrid = true }
                        }
                    },
                    onOpenMenu: { showMenu = true },
                    onOpenDownloads: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showDownloadPanel = true }
                    }
                )
            }

            if showZoomPanel {
                ZoomPanelView(zoomManager: zoomManager, isPresented: $showZoomPanel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showDownloadPanel {
                DownloadPanelView(downloadManager: downloadManager, isPresented: $showDownloadPanel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if isScreenCaptured {
                PrivacyShieldView(reason: .screenRecording)
            } else if isBackgrounded {
                PrivacyShieldView(reason: .background)
            }
        }
        .onAppear {
            // Gán một lần duy nhất: mọi tab (kể cả tab tạo sau này) tự forward về đây
            // qua cơ chế wiring trong TabsManager.makeTabAndWire.
            tabsManager.onSecretCommand = {
                isURLFieldFocused = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showDebugConsole = true }
            }
            // Check initial screen capture status
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                isScreenCaptured = scene.screen.isCaptured
            }
        }
        .onChange(of: scenePhase) { newPhase in
            withAnimation(.easeInOut(duration: 0.15)) {
                isBackgrounded = (newPhase != .active)
            }
            if newPhase == .background && autoClearOnBackground {
                PrivacyManager.clearAllData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                // Use scene-based approach to check screen capture status
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    isScreenCaptured = scene.screen.isCaptured
                }
            }
        }
        .onChange(of: tabsManager.activeTabId) { _ in
            // Chuyển tab -> đồng bộ lại thanh địa chỉ theo URL của tab vừa active,
            // và đóng zoom panel/bỏ focus ô nhập để tránh trạng thái UI lẫn giữa 2 tab.
            if !isURLFieldFocused {
                editingText = activeController.urlString
            }
        }
        .sheet(isPresented: $showMenu) {
            MenuView(
                onShowAbout: { showAbout = true },
                onClearData: {
                    PrivacyManager.clearAllData()
                    activeController.reload()
                },
                onNewSession: {
                    PrivacyManager.clearAllData()
                    zoomManager.reset()
                    tabsManager.closeAll()
                },
                onOpenPrivateTab: {
                    tabsManager.openNewPrivateTab()
                },
                onOpenUserscriptEditor: {
                    showUserscriptEditor = true
                },
                onToggleWindowMode: {
                    windowMode.toggle()
                },
                windowMode: windowMode
            )
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
        .sheet(isPresented: $showDebugConsole) {
            DebugConsoleView(tabsManager: tabsManager)
        }
        .sheet(isPresented: $showUserscriptEditor) {
            UserscriptEditorView(userscriptManager: userscriptManager)
        }
        .fullScreenCover(isPresented: $showTabGrid) {
            TabGridView(
                tabsManager: tabsManager,
                isPresented: $showTabGrid,
                hapticsEnabled: hapticsEnabled,
                onOpenNewTab: { tabsManager.openNewTab() }
            )
        }
        .fullScreenCover(isPresented: $showWindowMode) {
            WindowModeView(
                tabsManager: tabsManager,
                zoomManager: zoomManager,
                isPresented: $showWindowMode,
                blockWebRTC: blockWebRTC,
                blockIframe: blockIframe,
                blockAds: blockAds,
                desktopMode: desktopMode,
                hapticsEnabled: hapticsEnabled
            )
        }
    }

    private func submitURL() {
        isURLFieldFocused = false
        activeController.navigate(to: editingText)
    }
}

/// Dải nhãn nhỏ trên cùng nhắc rõ đang ở tab Riêng tư — không thể bỏ sót, không phụ
/// thuộc người dùng phải nhớ hay tự kiểm tra viền màu.
private struct PrivateModeBanner: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "eyeglasses")
                .font(.system(size: 11, weight: .bold))
            Text("Chế độ Riêng tư — không lưu lịch sử, cookie, cache")
                .font(.system(size: 11, weight: .semibold))
        }
        .foregroundColor(.white.opacity(0.9))
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity)
        .background(Color.purple.opacity(0.35))
    }
}

#Preview {
    ContentView()
}
