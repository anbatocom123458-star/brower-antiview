import SwiftUI

/// Dock ở dưới cùng trong chế độ cửa sổ nổi — thiết kế tối giản,
/// hiệu ứng kính trong suốt (Glassmorphism), groups chức năng gọn gàng.
///
/// v3.4: Minimalist design with ultraThinMaterial glass effect,
/// grouped actions, cleaner tab icons, subtle shadow.
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

    private let dockHeight: CGFloat = 60

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            dockBar
        }
    }

    // MARK: - Dock Bar

    private var dockBar: some View {
        HStack(spacing: 6) {
            // Group 1: Core actions
            dockIconButton(icon: "xmark.circle.fill", color: .red) {
                haptic(.medium)
                onExitFloatingMode()
            }

            dockIconButton(icon: "plus.circle.fill", color: .cyan) {
                haptic(.medium)
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

            // Group separator
            Capsule()
                .fill(Color.white.opacity(0.12))
                .frame(width: 1, height: 28)

            // Group 3: Info & settings
            dockIconButton(icon: "list.bullet", color: .blue) {
                haptic(.light)
                showTabList = true
            }

            // Virtual cursor global toggle
            dockIconButton(
                icon: floatingManager.globalVirtualCursorEnabled ? "cursorarrow.click.2" : "cursorarrow",
                color: floatingManager.globalVirtualCursorEnabled ? .cyan : .white
            ) {
                haptic(.light)
                floatingManager.toggleGlobalVirtualCursor()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(height: dockHeight)
        .background(dockBackground)
        .padding(.horizontal, 24)
        .padding(.bottom, 8)
        .sheet(isPresented: $showTabList) {
            FloatingTabListView(
                tabsManager: tabsManager,
                floatingManager: floatingManager,
                hapticsEnabled: hapticsEnabled
            )
        }
    }

    // MARK: - Glass Background

    private var dockBackground: some View {
        ZStack {
            // Base glass material
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)

            // Subtle dark tint
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.25))

            // Top highlight
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.clear],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            // Border
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

    private func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        guard hapticsEnabled else { return }
        UIImpactFeedbackGenerator(style: style).impactOccurred()
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
                        isActive ? Color.cyan.opacity(0.6) : Color.clear,
                        lineWidth: 1.2
                    )
            )

            Text(tab.displayTitle)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .lineLimit(1)
                .frame(width: 48)
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
