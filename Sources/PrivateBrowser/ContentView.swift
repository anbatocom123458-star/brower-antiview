import SwiftUI
import UIKit

/// Màn hình chính: thanh địa chỉ + trình duyệt + thanh công cụ + menu riêng + đa tab.
///
/// v3.4: Thêm Biometric Lock cho tab riêng tư, Session Restore tự động,
/// và BlurOverlay khi chưa xác thực.
struct ContentView: View {
    @StateObject private var tabsManager = TabsManager()
    @StateObject private var zoomManager = ZoomManager()
    @StateObject private var userscriptManager = UserscriptManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var floatingManager = FloatingWindowManager()
    @StateObject private var biometricAuth = BiometricAuthManager.shared

    @AppStorage(SettingsKey.blockWebRTC) private var blockWebRTC = true
    @AppStorage(SettingsKey.blockIframe) private var blockIframe = true
    @AppStorage(SettingsKey.blockAds) private var blockAds = true
    @AppStorage(SettingsKey.desktopMode) private var desktopMode = false
    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true
    @AppStorage(SettingsKey.autoClearOnBackground) private var autoClearOnBackground = false
    @AppStorage(SettingsKey.windowMode) private var windowMode = false
    @AppStorage(SettingsKey.userscriptsEnabled) private var userscriptsEnabled = true
    @AppStorage(SettingsKey.restoreSession) private var restoreSession = true
    @AppStorage(SettingsKey.developerToolsEnabled) private var developerToolsEnabled = true
    @AppStorage(SettingsKey.biometricLockPrivateTabs) private var biometricLockPrivateTabs = false

    @Environment(\.scenePhase) private var scenePhase

    @State private var editingText = BrowserSettingsStore.homeURL
    @FocusState private var isURLFieldFocused: Bool
    @State private var showZoomPanel = false
    @State private var showMenu = false
    @State private var showAbout = false
    @State private var showTabGrid = false
    @State private var showWindowMode = false
    @State private var showFloatingMode = false
    @State private var showDebugConsole = false
    @State private var showUserscriptEditor = false
    @State private var showDownloadPanel = false
    @State private var showDeveloperTools = false
    @State private var isBackgrounded = false
    @State private var isScreenCaptured = false
    @State private var hasRestoredSession = false
    @State private var showPrivateBlurOverlay = false

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

                    // Private tab blur overlay
                    if showPrivateBlurOverlay {
                        PrivateBlurOverlay(
                            biometricAuth: biometricAuth,
                            onUnlock: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showPrivateBlurOverlay = false
                                }
                            },
                            onCancel: {
                                // Đóng tab riêng tư khi hủy xác thực
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    showPrivateBlurOverlay = false
                                }
                                tabsManager.closeAllPrivateTabs()
                            }
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
                    },
                    onOpenDeveloperTools: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showDeveloperTools = true }
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
            tabsManager.onSecretCommand = {
                isURLFieldFocused = false
                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showDebugConsole = true }
            }

            // Check initial screen capture status
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                isScreenCaptured = scene.screen.isCaptured
            }

            // Restore session if enabled
            if restoreSession && !hasRestoredSession {
                hasRestoredSession = true
                SessionStateManager.shared.restoreTabs(into: tabsManager)
                editingText = activeController.urlString
            }
        }
        .onChange(of: scenePhase) { newPhase in
            withAnimation(.easeInOut(duration: 0.15)) {
                isBackgrounded = (newPhase != .active)
            }
            if newPhase == .background {
                SessionStateManager.shared.saveSession(tabsManager: tabsManager)
                if autoClearOnBackground {
                    PrivacyManager.clearAllData()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: UIScreen.capturedDidChangeNotification)) { _ in
            withAnimation(.easeInOut(duration: 0.15)) {
                if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                    isScreenCaptured = scene.screen.isCaptured
                }
            }
        }
        .onChange(of: tabsManager.activeTabId) { _ in
            if !isURLFieldFocused {
                editingText = activeController.urlString
            }
            // Kiểm tra biometric lock cho tab riêng tư
            checkBiometricLockForActiveTab()
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
                    SessionStateManager.shared.clearSavedSession()
                },
                onOpenPrivateTab: {
                    openPrivateTabWithAuth()
                },
                onOpenUserscriptEditor: {
                    showUserscriptEditor = true
                },
                onToggleWindowMode: {
                    windowMode.toggle()
                },
                onOpenDeveloperTools: {
                    showDeveloperTools = true
                },
                onToggleFloatingMode: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showFloatingMode = true
                    }
                },
                currentWindowMode: windowMode,
                currentFloatingMode: showFloatingMode
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
        .sheet(isPresented: $showDeveloperTools) {
            DeveloperToolsView(controller: activeController)
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
        .fullScreenCover(isPresented: $showFloatingMode) {
            FloatingModeView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                zoomManager: zoomManager,
                blockWebRTC: blockWebRTC,
                blockIframe: blockIframe,
                blockAds: blockAds,
                desktopMode: desktopMode,
                hapticsEnabled: hapticsEnabled,
                isPresented: $showFloatingMode
            )
        }
    }

    private func submitURL() {
        isURLFieldFocused = false
        activeController.navigate(to: editingText)
    }

    // MARK: - Biometric Lock

    private func openPrivateTabWithAuth() {
        guard biometricLockPrivateTabs else {
            // Không bật khóa sinh trắc — mở trực tiếp
            tabsManager.openNewPrivateTab()
            return
        }

        biometricAuth.authenticate { success in
            DispatchQueue.main.async {
                if success {
                    biometricAuth.lock() // Reset cho lần tiếp theo
                    tabsManager.openNewPrivateTab()
                }
            }
        }
    }

    private func checkBiometricLockForActiveTab() {
        guard biometricLockPrivateTabs else {
            showPrivateBlurOverlay = false
            return
        }

        guard tabsManager.activeTab.isPrivateMode else {
            showPrivateBlurOverlay = false
            return
        }

        // Hiển thị overlay blur cho tab riêng tư
        showPrivateBlurOverlay = true

        // Tự động yêu cầu xác thực
        biometricAuth.authenticate { success in
            DispatchQueue.main.async {
                if success {
                    biometricAuth.lock()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                        showPrivateBlurOverlay = false
                    }
                }
                // Nếu thất bại, overlay vẫn hiển thị
            }
        }
    }
}

// MARK: - Private Mode Banner

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

// MARK: - Private Blur Overlay

/// Màn hình mờ che nội dung tab riêng tư khi chưa xác thực sinh trắc học.
private struct PrivateBlurOverlay: View {
    @ObservedObject var biometricAuth: BiometricAuthManager
    var onUnlock: () -> Void
    var onCancel: () -> Void

    var body: some View {
        ZStack {
            // Blur background
            VisualEffectBlur(style: .systemThinMaterialDark)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.purple.opacity(0.8))

                Text("Tab Riêng tư đang khóa")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)

                if let error = biometricAuth.authError {
                    Text(error)
                        .font(.system(size: 12))
                        .foregroundColor(.red.opacity(0.8))
                        .multilineTextAlignment(.center)
                }

                Text("Yêu cầu xác thực để xem nội dung")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.6))

                if biometricAuth.isAuthenticating {
                    ProgressView()
                        .tint(.purple)
                } else {
                    Button(action: {
                        biometricAuth.authenticate { success in
                            if success {
                                biometricAuth.lock()
                                onUnlock()
                            }
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "faceid")
                            Text("Xác thực")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color.purple.opacity(0.7))
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button(action: onCancel) {
                    Text("Đóng tab")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Visual Effect Blur (UIViewRepresentable)

private struct VisualEffectBlur: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        let blurEffect = UIBlurEffect(style: style)
        return UIVisualEffectView(effect: blurEffect)
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
        uiView.effect = UIBlurEffect(style: style)
    }
}

#Preview {
    ContentView()
}
