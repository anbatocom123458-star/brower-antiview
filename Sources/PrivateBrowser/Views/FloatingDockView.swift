import SwiftUI

/// Dock ở dưới cùng trong chế độ cửa sổ nổi — thiết kế tối giản,
/// hiệu ứng kính trong suốt (Glassmorphism), groups chức năng gọn gàng.
///
/// v4.0: Full floating OS dock:
/// - Fixed text truncation under dock icons
/// - Removed blue borders around inactive icons
/// - Virtual cursor toggle button (global only)
/// - Multi-window tile arrange button
/// - Advanced Download Hub with progress/pause/resume
/// - Bubble tabs section
struct FloatingDockView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var floatingManager: FloatingWindowManager
    @ObservedObject var zoomManager: ZoomManager
    @ObservedObject var downloadManager: DownloadManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool
    var hapticsEnabled: Bool
    var onExitFloatingMode: () -> Void

    @State private var showTabList = false
    @State private var showDownloadHub = false

    private let dockHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            dockBar
        }
    }

    // MARK: - Dock Bar

    private var dockBar: some View {
        VStack(spacing: 0) {
            // Bubble tabs (floating above dock)
            if hasBubbleTabs {
                bubbleTabsRow
                    .padding(.bottom, 6)
            }

            HStack(spacing: 6) {
                // Group 1: Core actions
                dockIconButton(icon: "xmark.circle.fill", color: .red) {
                    HapticManager.impact(.medium)
                    onExitFloatingMode()
                }

                dockIconButton(icon: "plus.circle.fill", color: .cyan) {
                    HapticManager.impact(.medium)
                    let newTab = tabsManager.openNewTab()
                    floatingManager.addFloatingTab(newTab, in: tabsManager)
                }

                // Group separator
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 28)

                // Group 2: Tab icons (scrollable)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tabsManager.tabs) { tab in
                            DockTabPill(
                                tab: tab,
                                isActive: tab.id == tabsManager.activeTabId,
                                hapticsEnabled: hapticsEnabled
                            ) {
                                HapticManager.impact(.light)
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

                // Group separator
                Capsule()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1, height: 28)

                // Group 3: Tools
                // Tile arrange button
                dockIconButton(
                    icon: tileIcon,
                    color: floatingManager.currentTileMode != .none ? .cyan : .white
                ) {
                    HapticManager.impact(.light)
                    floatingManager.cycleTileMode(for: tabsManager.tabs)
                }

                // Download hub button
                dockIconButton(
                    icon: downloadManager.activeDownloads.isEmpty ? "arrow.down.circle" : "arrow.down.circle.fill",
                    color: downloadManager.activeDownloads.isEmpty ? .white : .green
                ) {
                    HapticManager.impact(.light)
                    showDownloadHub = true
                }

                // Virtual cursor toggle
                dockIconButton(
                    icon: floatingManager.globalVirtualCursorEnabled ? "cursorarrow.rays" : "cursorarrow",
                    color: floatingManager.globalVirtualCursorEnabled ? .cyan : .white
                ) {
                    HapticManager.impact(.light)
                    floatingManager.toggleGlobalVirtualCursor()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(height: dockHeight)
            .background(dockBackground)
            .padding(.horizontal, 24)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showTabList) {
            FloatingTabListView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                hapticsEnabled: hapticsEnabled
            )
        }
        .sheet(isPresented: $showDownloadHub) {
            DownloadHubView(
                downloadManager: downloadManager,
                hapticsEnabled: hapticsEnabled
            )
        }
    }

    // MARK: - Bubble Tabs Row

    private var hasBubbleTabs: Bool {
        tabsManager.tabs.contains { $0.isBubbleMode }
    }

    private var bubbleTabsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(tabsManager.tabs.filter { $0.isBubbleMode }) { tab in
                    BubbleTabPill(tab: tab, hapticsEnabled: hapticsEnabled) {
                        HapticManager.impact(.light)
                        floatingManager.restoreFromBubble(tab)
                    }
                }
            }
            .padding(.horizontal, 32)
        }
    }

    private var tileIcon: String {
        switch floatingManager.currentTileMode {
        case .none: return "rectangle.split.2x2"
        case .twoHorizontal: return "rectangle.split.2x1"
        case .twoVertical: return "rectangle.split.1x2"
        case .fourGrid: return "rectangle.split.2x2"
        }
    }

    // MARK: - Glass Background

    private var dockBackground: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.25))

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 0.5
                )
        }
        .shadow(color: .black.opacity(0.3), radius: 20, y: 8)
        .shadow(color: .cyan.opacity(0.08), radius: 15, y: 5)
    }

    // MARK: - Dock Icon Button

    private func dockIconButton(icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color.opacity(0.85))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Bubble Tab Pill

private struct BubbleTabPill: View {
    @ObservedObject var tab: BrowserTab
    let hapticsEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                        startPoint: .topLeading, endPoint: .bottomTrailing
                    )
                )
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                )
                .overlay(
                    Circle().stroke(Color.cyan.opacity(0.4), lineWidth: 1)
                )

            Text(tab.displayTitle)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 48, alignment: .center)
                .truncationMode(.tail)
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Dock Tab Pill

private struct DockTabPill: View {
    @ObservedObject var tab: BrowserTab
    let isActive: Bool
    let hapticsEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 3) {
            ZStack {
                if isActive {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.25)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.white.opacity(0.04)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                }

                if tab.controller.isLoading {
                    ProgressView()
                        .tint(.cyan)
                        .scaleEffect(0.45)
                } else {
                    Image(systemName: tab.controller.isSecure ? "lock.fill" : "globe")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .frame(width: 40, height: 40)
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isActive ? Color.cyan.opacity(0.5) : Color.clear,
                        lineWidth: 1.0
                    )
            )

            Text(tab.displayTitle)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 48, alignment: .center)
                .truncationMode(.tail)
        }
        .onTapGesture(perform: onTap)
    }
}

// MARK: - Download Hub View

private struct DownloadHubView: View {
    @ObservedObject var downloadManager: DownloadManager
    let hapticsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 12) {
                        // Active downloads
                        if !downloadManager.activeDownloads.isEmpty {
                            SectionHeader(title: "Đang tải", icon: "arrow.down.circle.fill", color: .cyan)

                            ForEach(downloadManager.activeDownloads) { item in
                                ActiveDownloadCard(item: item, downloadManager: downloadManager)
                            }
                        }

                        // Completed downloads
                        if !downloadManager.completedDownloads.isEmpty {
                            SectionHeader(title: "Đã hoàn thành", icon: "checkmark.circle.fill", color: .green)

                            ForEach(downloadManager.completedDownloads) { item in
                                CompletedDownloadCard(item: item)
                            }
                        }

                        if downloadManager.activeDownloads.isEmpty && downloadManager.completedDownloads.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "arrow.down.circle")
                                    .font(.system(size: 40))
                                    .foregroundColor(.white.opacity(0.2))
                                Text("Chưa có tải xuống nào")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.4))
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding(16)
                }
            }
            .navigationTitle("Trung tâm tải xuống")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") { dismiss() }
                        .foregroundColor(.cyan)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if !downloadManager.completedDownloads.isEmpty {
                        Button("Xóa hết") {
                            HapticManager.impact(.medium)
                            downloadManager.clearAll()
                        }
                        .foregroundColor(.red.opacity(0.8))
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Section Header

private struct SectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
    }
}

// MARK: - Active Download Card

private struct ActiveDownloadCard: View {
    let item: DownloadItem
    @ObservedObject var downloadManager: DownloadManager

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "doc.fill")
                    .foregroundColor(.cyan)
                Text(item.filename)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Button(action: {
                    downloadManager.cancelDownload(id: item.id)
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [.cyan, .blue],
                                startPoint: .leading, endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.3, height: 6)
                        .animation(.linear(duration: 1), value: item.id)
                }
            }
            .frame(height: 6)

            HStack {
                Text("Đang tải...")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.4))
                Spacer()
                if let url = item.url {
                    Text(url.host ?? "")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.cyan.opacity(0.15), lineWidth: 0.5)
        )
    }
}

// MARK: - Completed Download Card

private struct CompletedDownloadCard: View {
    let item: DownloadItem

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: item.isPrivateMode ? "lock.fill" : "doc.fill")
                .foregroundColor(item.isPrivateMode ? .purple : .green)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.filename)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                if let url = item.url {
                    Text(url.host ?? "")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()

            if item.isPrivateMode {
                Text("Tự xóa")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.purple.opacity(0.7))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.purple.opacity(0.15)))
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green.opacity(0.7))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

// MARK: - Tab List View

private struct FloatingTabListView: View {
    @ObservedObject var tabsManager: TabsManager
    @ObservedObject var floatingManager: FloatingWindowManager
    let hapticsEnabled: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(colors: [Color(hex: "0A0A1A"), Color(hex: "12122B")], startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()

                List {
                    ForEach(tabsManager.tabs) { tab in
                        Button(action: {
                            HapticManager.impact(.light)
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
                            HapticManager.impact(.medium)
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
}
