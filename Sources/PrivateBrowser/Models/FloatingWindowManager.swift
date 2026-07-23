import SwiftUI
import Combine

/// Quản lý các cửa sổ nổi — vị trí, kích thước, thứ tự lớp, trạng thái dock,
/// tỉ lệ khung hình, và con trỏ ảo.
///
/// v3.4: Thêm aspect ratio management, virtual cursor global toggle,
/// snap-to-edge, và multi-corner resize support.
final class FloatingWindowManager: ObservableObject {
    @Published var isFloatingMode: Bool = false
    @Published var nextWindowOrder: Int = 0

    /// Con trỏ ảo toàn cục — khi bật, mọi cửa sổ đều hiển thị con trỏ
    @Published var globalVirtualCursorEnabled: Bool = false

    /// Tỉ lệ khung hình mặc định cho cửa sổ mới
    @Published var defaultAspectRatio: AspectRatioPreset = .free

    /// Kích thước cửa sổ mặc định
    var defaultWindowSize: CGSize {
        if let ratio = defaultAspectRatio.ratio {
            let width: CGFloat = 380
            return CGSize(width: width, height: width / ratio)
        }
        return CGSize(width: 380, height: 520)
    }

    private var cancellables = Set<AnyCancellable>()

    init() {}

    // MARK: - Floating Mode Lifecycle

    func enterFloatingMode(from tabsManager: TabsManager) {
        isFloatingMode = true
        nextWindowOrder = tabsManager.tabs.count

        for (index, tab) in tabsManager.tabs.enumerated() {
            tab.isFloating = true
            tab.windowOrder = index
            tab.floatingSize = defaultWindowSize
            tab.aspectRatio = defaultAspectRatio
            tab.floatingPosition = calculatePosition(for: index, total: tabsManager.tabs.count)
        }
    }

    func exitFloatingMode(to tabsManager: TabsManager) {
        isFloatingMode = false
        globalVirtualCursorEnabled = false
        for tab in tabsManager.tabs {
            tab.isFloating = false
            tab.isMinimizedToDock = false
            tab.virtualCursorEnabled = false
        }
    }

    // MARK: - Tab Management

    func addFloatingTab(_ tab: BrowserTab, in tabsManager: TabsManager) {
        tab.isFloating = true
        tab.floatingSize = defaultWindowSize
        tab.aspectRatio = defaultAspectRatio
        tab.windowOrder = nextWindowOrder
        tab.virtualCursorEnabled = globalVirtualCursorEnabled
        tab.floatingPosition = calculatePosition(for: tabsManager.tabs.count, total: tabsManager.tabs.count + 1)
        nextWindowOrder += 1
    }

    func minimizeToDock(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tab.isMinimizedToDock = true
        }
    }

    func restoreFromDock(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tab.isMinimizedToDock = false
        }
        bringToFront(tab, in: nil)
    }

    func bringToFront(_ tab: BrowserTab, in tabsManager: TabsManager?) {
        let maxOrder: Int
        if let tabsManager = tabsManager {
            maxOrder = tabsManager.tabs.map(\.windowOrder).max() ?? 0
        } else {
            maxOrder = nextWindowOrder
        }
        tab.windowOrder = maxOrder + 1
        nextWindowOrder = maxOrder + 2
    }

    // MARK: - Virtual Cursor

    func toggleGlobalVirtualCursor() {
        globalVirtualCursorEnabled.toggle()
        // Đồng bộ trạng thái cho tất cả cửa sổ hiện có
        // (tab mới sẽ tự động nhận qua addFloatingTab)
    }

    // MARK: - Aspect Ratio

    func setAspectRatio(_ preset: AspectRatioPreset, for tab: BrowserTab) {
        tab.aspectRatio = preset
        if let ratio = preset.ratio {
            let width = tab.floatingSize.width
            let newHeight = width / ratio
            tab.floatingSize = CGSize(width: width, height: newHeight)
        }
    }

    // MARK: - Resize

    func resizeWindow(_ tab: BrowserTab, to size: CGSize) {
        let minW: CGFloat = 280
        let maxW: CGFloat = UIScreen.main.bounds.width - 40
        let minH: CGFloat = 320
        let maxH: CGFloat = UIScreen.main.bounds.height - 150

        let newWidth = max(minW, min(maxW, size.width))
        var newHeight = max(minH, min(maxH, size.height))

        // Áp dụng aspect ratio nếu đang lock
        if let ratio = tab.aspectRatio?.ratio {
            newHeight = newWidth / ratio
            newHeight = max(minH, min(maxH, newHeight))
        }

        tab.floatingSize = CGSize(width: newWidth, height: newHeight)
    }

    /// Snap cửa sổ vào cạnh màn hình (gọn gàng)
    func snapToEdge(_ tab: BrowserTab, edge: SnapEdge) {
        let screen = UIScreen.main.bounds
        let margin: CGFloat = 12

        let targetPosition: CGPoint
        switch edge {
        case .left:
            targetPosition = CGPoint(x: margin, y: tab.floatingPosition.y)
        case .right:
            targetPosition = CGPoint(x: screen.width - tab.floatingSize.width - margin, y: tab.floatingPosition.y)
        case .top:
            targetPosition = CGPoint(x: tab.floatingPosition.x, y: margin)
        case .bottom:
            targetPosition = CGPoint(x: tab.floatingPosition.x, y: screen.height - tab.floatingSize.height - 90)
        }

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tab.floatingPosition = targetPosition
        }
    }

    // MARK: - Position Calculation

    private func calculatePosition(for index: Int, total: Int) -> CGPoint {
        let screen = UIScreen.main.bounds
        let padding: CGFloat = 20
        let windowW = defaultWindowSize.width
        let windowH = defaultWindowSize.height
        let topPadding: CGFloat = 20

        let availableWidth = screen.width - padding * 2
        let cols = max(1, Int(availableWidth / (windowW + padding)))
        let row = index / cols
        let col = index % cols

        let totalWindowsInRow = min(cols, total - row * cols)
        let rowWidth = CGFloat(totalWindowsInRow) * windowW + CGFloat(totalWindowsInRow - 1) * padding
        let offsetX = (screen.width - rowWidth) / 2

        let x = offsetX + CGFloat(col) * (windowW + padding)
        let y = topPadding + CGFloat(row) * (windowH + padding)

        return CGPoint(x: x, y: y)
    }
}

// MARK: - Snap Edge

enum SnapEdge {
    case left, right, top, bottom
}
