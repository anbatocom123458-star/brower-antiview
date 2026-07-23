import SwiftUI

/// Chế độ cửa sổ — hiển thị nhiều tab dưới dạng các "cửa sổ" nhỏ gọn,
/// giống như trên desktop/laptop, có dock ở dưới cùng.
struct WindowModeView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var zoomManager: ZoomManager
    @Binding var isPresented: Bool
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var hapticsEnabled: Bool

    @State private var selectedWindowId: UUID?
    @State private var showSettings = false

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                windowGrid
                dock
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Cửa sổ")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(tabsManager.tabCount) tab đang mở")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer()

            Button(action: {
                haptic(.light)
                tabsManager.openNewTab()
                withAnimation { isPresented = false }
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 32, height: 32)
                    .adaptiveGlass(in: Circle())
            }

            Button(action: {
                haptic(.light)
                withAnimation { isPresented = false }
            }) {
                Text("Xong")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Window Grid

    private var windowGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(tabsManager.tabs) { tab in
                    WindowCard(
                        tab: tab,
                        isActive: tab.id == tabsManager.activeTabId,
                        isMinimized: selectedWindowId == tab.id,
                        canClose: tabsManager.tabCount > 1,
                        onSelect: {
                            haptic(.light)
                            tabsManager.select(tab)
                            withAnimation { isPresented = false }
                        },
                        onMinimize: {
                            haptic(.light)
                            withAnimation(.spring(response: 0.3)) {
                                if selectedWindowId == tab.id {
                                    selectedWindowId = nil
                                } else {
                                    selectedWindowId = tab.id
                                }
                            }
                        },
                        onClose: {
                            haptic(.medium)
                            withAnimation(.spring(response: 0.3)) {
                                tabsManager.close(tab)
                            }
                        },
                        blockWebRTC: blockWebRTC,
                        blockIframe: blockIframe,
                        blockAds: blockAds,
                        desktopMode: desktopMode,
                        zoomManager: zoomManager
                    )
                }
            }
            .padding(16)
        }
    }

    // MARK: - Dock

    private var dock: some View {
        HStack(spacing: 16) {
            dockButton(icon: "plus.circle", label: "Tab mới") {
                haptic(.medium)
                tabsManager.openNewTab()
                withAnimation { isPresented = false }
            }

            dockButton(icon: "eyeglasses", label: "Riêng tư") {
                haptic(.medium)
                tabsManager.openNewPrivateTab()
                withAnimation { isPresented = false }
            }

            dockButton(icon: "square.stack", label: "Đóng hết") {
                haptic(.heavy)
                tabsManager.closeAll()
            }

            dockButton(icon: "gearshape", label: "Cài đặt") {
                haptic(.light)
                showSettings = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .adaptiveGlass(in: RoundedRectangle(cornerRadius: 24), strokeOpacity: 0.1)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sheet(isPresented: $showSettings) {
            MenuView(
                onShowAbout: {},
                onClearData: {
                    PrivacyManager.clearAllData()
                    tabsManager.closeAll()
                },
                onNewSession: {
                    PrivacyManager.clearAllData()
                    zoomManager.reset()
                    tabsManager.closeAll()
                },
                onOpenPrivateTab: {
                    tabsManager.openNewPrivateTab()
                }
            )
        }
    }

    private func dockButton(icon: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Window Card

private struct WindowCard: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let isMinimized: Bool
    let canClose: Bool
    let onSelect: () -> Void
    let onMinimize: () -> Void
    let onClose: () -> Void
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var zoomManager: ZoomManager

    var body: some View {
        VStack(spacing: 0) {
            // Title bar
            HStack(spacing: 6) {
                Circle()
                    .fill(isActive ? Color.green.opacity(0.7) : Color.white.opacity(0.2))
                    .frame(width: 6, height: 6)

                Text(tab.displayTitle)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                // Window controls
                HStack(spacing: 4) {
                    Button(action: onMinimize) {
                        Image(systemName: isMinimized ? "plus" : "minus")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }

                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 16, height: 16)
                            .background(Circle().fill(Color.white.opacity(0.1)))
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.03))

            // Content preview
            if isMinimized {
                minimizedPreview
            } else {
                windowContent
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isActive ? Color.cyan.opacity(0.6) : Color.white.opacity(0.08),
                    lineWidth: isActive ? 1.5 : 1
                )
        )
        .onTapGesture { onSelect() }
    }

    private var minimizedPreview: some View {
        VStack(spacing: 4) {
            Image(systemName: "window.minimize")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.3))
            Text("Đã thu nhỏ")
                .font(.system(size: 9))
                .foregroundColor(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(Color.white.opacity(0.02))
    }

    private var windowContent: some View {
        ZStack {
            LinearGradient(
                colors: isActive
                    ? [Color.cyan.opacity(0.1), Color.blue.opacity(0.05)]
                    : [Color.white.opacity(0.02), Color.white.opacity(0.01)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )

            if tab.controller.isLoading {
                ProgressView().tint(.cyan).scaleEffect(0.7)
            } else {
                VStack(spacing: 4) {
                    Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                        .font(.system(size: 16, weight: .light))
                        .foregroundColor(.white.opacity(0.25))
                    Text(tab.displayHost)
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.2))
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}
