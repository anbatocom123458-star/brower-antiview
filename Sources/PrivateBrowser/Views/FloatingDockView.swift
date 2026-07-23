import SwiftUI

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

    private let dockHeight: CGFloat = 80
    private let tabWidth: CGFloat = 60
    private let tabSpacing: CGFloat = 8

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            dockBar
        }
    }

    // MARK: - Dock Bar

    private var dockBar: some View {
        HStack(spacing: 12) {
            exitButton
            addTabButton
            tabListButton

            Divider()
                .frame(height: 40)
                .foregroundColor(.white.opacity(0.2))

            minimizedTabs
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(height: dockHeight)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // MARK: - Exit Button

    private var exitButton: some View {
        Button(action: {
            haptic(.medium)
            onExitFloatingMode()
        }) {
            VStack(spacing: 4) {
                Image(systemName: "xmark.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("Thoát")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 50)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Add Tab Button

    private var addTabButton: some View {
        Button(action: {
            haptic(.medium)
            let newTab = tabsManager.openNewTab()
            floatingManager.addFloatingTab(newTab, in: tabsManager)
        }) {
            VStack(spacing: 4) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.cyan)
                Text("Tab mới")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 50)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab List Button

    private var tabListButton: some View {
        Button(action: {
            haptic(.light)
            showTabList = true
        }) {
            VStack(spacing: 4) {
                Image(systemName: "list.bullet")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
                Text("\(tabsManager.tabCount)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
            .frame(width: 50)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showTabList) {
            FloatingTabListView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                hapticsEnabled: hapticsEnabled
            )
        }
    }

    // MARK: - Minimized Tabs

    private var minimizedTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: tabSpacing) {
                ForEach(tabsManager.tabs.filter(\.isMinimizedToDock)) { tab in
                    FloatingTabThumbnail(
                        tab: tab,
                        isActive: tab.id == tabsManager.activeTabId,
                        hapticsEnabled: hapticsEnabled
                    ) {
                        haptic(.light)
                        tabsManager.select(tab)
                        floatingManager.restoreFromDock(tab)
                        floatingManager.bringToFront(tab, in: tabsManager)
                    }
                    .onLongPressGesture {
                        haptic(.heavy)
                        floatingManager.restoreFromDock(tab)
                    }
                }
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

// MARK: - Tab Thumbnail

private struct FloatingTabThumbnail: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let hapticsEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isActive
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
                        isActive ? Color.cyan.opacity(0.5) : Color.clear,
                        lineWidth: 1
                    )
            )

            Text(tab.displayTitle)
                .font(.system(size: 8))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 60)
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
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                                Text(tab.displayHost)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
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
            .navigationTitle("Tab đang mở")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}
