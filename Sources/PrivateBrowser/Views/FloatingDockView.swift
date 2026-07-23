import SwiftUI

/// Dock ở dưới cùng trong chế độ cửa sổ — hiển thị nút thoát, thêm tab,
/// danh sách tab, và các tab đang thu nhỏ.
struct FloatingDockView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var floatingManager: FloatingWindowManager
    @ObservedObject var zoomManager: ZoomManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var hapticsEnabled: Bool
    var onExitFloatingMode: () -> Void

    @State private var showTabList = false

    private let dockHeight: CGFloat = 70

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            dockBar
        }
    }

    // MARK: - Dock Bar

    private var dockBar: some View {
        HStack(spacing: 8) {
            // Nút thoát
            dockButton(icon: "xmark.circle", label: "Thoát", color: .red) {
                haptic(.medium)
                onExitFloatingMode()
            }

            // Nút thêm tab mới
            dockButton(icon: "plus.circle", label: "Tab mới", color: .cyan) {
                haptic(.medium)
                let newTab = tabsManager.openNewTab()
                floatingManager.addFloatingTab(newTab, in: tabsManager)
            }

            // Nút tab riêng tư
            dockButton(icon: "eyeglasses", label: "Riêng tư", color: .purple) {
                haptic(.medium)
                let newTab = tabsManager.openNewPrivateTab()
                floatingManager.addFloatingTab(newTab, in: tabsManager)
            }

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 36)

            // Danh sách tab đang mở
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(tabsManager.tabs) { tab in
                        DockTabIcon(
                            tab: tab,
                            isActive: tab.id == tabsManager.activeTabId,
                            hapticsEnabled: hapticsEnabled
                        ) {
                            haptic(.light)
                            tabsManager.select(tab)
                            if tab.isMinimizedToDock {
                                floatingManager.restoreFromDock(tab)
                            }
                            floatingManager.bringToFront(tab, in: tabsManager)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }

            // Divider
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.15))
                .frame(width: 1, height: 36)

            // Nút danh sách
            dockButton(icon: "list.bullet", label: "\(tabsManager.tabCount)", color: .blue) {
                haptic(.light)
                showTabList = true
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .frame(height: dockHeight)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.black.opacity(0.3))
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .top, endPoint: .bottom
                        ),
                        lineWidth: 1
                    )
            }
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .sheet(isPresented: $showTabList) {
            FloatingTabListView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                hapticsEnabled: hapticsEnabled
            )
        }
    }

    // MARK: - Dock Button

    private func dockButton(icon: String, label: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color.opacity(0.9))
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(width: 50)
        }
        .buttonStyle(.plain)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Dock Tab Icon

private struct DockTabIcon: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let hapticsEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: isActive
                                ? [Color.cyan.opacity(0.4), Color.blue.opacity(0.3)]
                                : [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )

                if tab.controller.isLoading {
                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(0.5)
                } else {
                    VStack(spacing: 2) {
                        Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                            .font(.system(size: 16))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            .frame(width: 48, height: 48)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(
                        isActive ? Color.cyan.opacity(0.7) : Color.clear,
                        lineWidth: 2
                    )
            )

            Text(tab.displayTitle)
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineLimit(1)
                .frame(width: 56)
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Tab List View

private struct FloatingTabListView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var floatingManager: FloatingWindowManager
    let hapticsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                List {
                    ForEach(tabsManager.tabs) { tab in
                        Button(action: {
                            haptic(.light)
                            tabsManager.select(tab)
                            if tab.isMinimizedToDock {
                                floatingManager.restoreFromDock(tab)
                            }
                            floatingManager.bringToFront(tab, in: tabsManager)
                            dismiss()
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                                    .foregroundColor(.cyan)
                                    .frame(width: 24)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(tab.displayTitle)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Text(tab.displayHost)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.5))
                                        .lineLimit(1)
                                }

                                Spacer()

                                if tab.id == tabsManager.activeTabId {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.cyan)
                                }

                                if tab.isMinimizedToDock {
                                    Image(systemName: "minus.circle")
                                        .foregroundColor(.yellow)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let tab = tabsManager.tabs[index]
                            haptic(.medium)
                            tabsManager.close(tab)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Tab đang mở")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(.cyan)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
