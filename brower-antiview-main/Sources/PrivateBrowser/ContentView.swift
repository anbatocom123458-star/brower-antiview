import SwiftUI

/// Màn hình chính: thanh địa chỉ + trình duyệt + thanh công cụ + menu riêng.
/// So với bản cũ, logic điều hướng được chuyển hết vào BrowserController để
/// tránh loop reload, và các cài đặt được đọc qua AppStorage tập trung (SettingsKey).
struct ContentView: View {
    @StateObject private var controller = BrowserController()
    @StateObject private var zoomManager = ZoomManager()

    @AppStorage(SettingsKey.blockWebRTC) private var blockWebRTC = true
    @AppStorage(SettingsKey.blockIframe) private var blockIframe = true
    @AppStorage(SettingsKey.blockFingerprint) private var blockFingerprint = true
    @AppStorage(SettingsKey.desktopMode) private var desktopMode = false
    @AppStorage(SettingsKey.hapticsEnabled) private var hapticsEnabled = true

    @Environment(\.scenePhase) private var scenePhase

    @State private var editingText = BrowserSettingsStore.homeURL
    @FocusState private var isURLFieldFocused: Bool
    @State private var showZoomPanel = false
    @State private var showMenu = false
    @State private var showAbout = false
    @State private var isBackgrounded = false

    var body: some View {
        ZStack {
            LinearGradient(colors: [AppTheme.backgroundTop, AppTheme.backgroundBottom], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                URLBarView(
                    controller: controller,
                    editingText: $editingText,
                    isFocused: $isURLFieldFocused,
                    onSubmit: submitURL
                )

                ZStack {
                    BrowserView(
                        controller: controller,
                        zoomManager: zoomManager,
                        blockWebRTC: blockWebRTC,
                        blockIframe: blockIframe,
                        blockFingerprint: blockFingerprint,
                        desktopMode: desktopMode
                    )
                    .cornerRadius(16)

                    if let error = controller.loadError {
                        Color.black.opacity(0.25)
                        ErrorOverlayView(
                            message: error,
                            onRetry: { controller.reload() },
                            onDismiss: { controller.loadError = nil }
                        )
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
                .shadow(color: .black.opacity(0.3), radius: 15, x: 0, y: 8)

                BottomToolbarView(
                    controller: controller,
                    zoomManager: zoomManager,
                    hapticsEnabled: hapticsEnabled,
                    showZoomPanel: showZoomPanel,
                    onBack: { controller.goBack() },
                    onForward: { controller.goForward() },
                    onReloadOrStop: {
                        controller.isLoading ? controller.stopLoading() : controller.reload()
                    },
                    onToggleZoom: { withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) { showZoomPanel.toggle() } },
                    onOpenMenu: { showMenu = true }
                )
            }

            if showZoomPanel {
                ZoomPanelView(zoomManager: zoomManager, isPresented: $showZoomPanel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if isBackgrounded {
                PrivacyShieldView()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            withAnimation(.easeInOut(duration: 0.15)) {
                isBackgrounded = (newPhase != .active)
            }
        }
        .sheet(isPresented: $showMenu) {
            MenuView(
                onShowAbout: { showAbout = true },
                onClearData: {
                    PrivacyManager.clearAllData()
                    controller.reload()
                }
            )
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    private func submitURL() {
        isURLFieldFocused = false
        controller.navigate(to: editingText)
    }
}

#Preview {
    ContentView()
}
