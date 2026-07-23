import SwiftUI
import Combine

/// Quản lý các cửa sổ nổi — vị trí, kích thước, thứ tự lớp, trạng thái dock,
/// tỉ lệ khung hình, bong bóng (bubble mode), sắp xếp lưới, và con trỏ ảo.
///
/// v4.0: Full floating OS experience:
/// - Proper screen boundary clamping (no jitter)
/// - Mini Bubble / PiP mode for minimized windows
/// - Multi-window grid tiling (2 or 4 windows)
/// - Virtual cursor global toggle from Dock
final class FloatingWindowManager: ObservableObject {
    @Published var isFloatingMode: Bool = false
    @Published var nextWindowOrder: Int = 0

    /// Con trỏ ảo toàn cục — khi bật, một con trỏ duy nhất di chuyển tự do trên toàn màn hình
    @Published var globalVirtualCursorEnabled: Bool = false

    /// Vị trí con trỏ ảo toàn cục (tọa độ screen, tính từ góc trái trên)
    @Published var globalCursorPosition: CGPoint = CGPoint(x: 200, y: 400)

    /// Tỉ lệ khung hình mặc định cho cửa sổ mới
    @Published var defaultAspectRatio: AspectRatioPreset = .free

    /// Trạng thái sắp xếp lưới hiện tại
    @Published var currentTileMode: TileMode = .none

    enum TileMode {
        case none
        case twoHorizontal
        case twoVertical
        case fourGrid
    }

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

    // MARK: - Screen Boundary Helpers

    var screenBounds: CGRect {
        if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene,
           let window = scene.windows.first {
            return window.bounds
        }
        return UIScreen.main.bounds
    }

    var minPositionY: CGFloat { 0 }

    func maxPositionY(for size: CGSize) -> CGFloat {
        screenBounds.height - size.height
    }

    func maxPositionX(for size: CGSize) -> CGFloat {
        screenBounds.width - size.width
    }

    func clampedPosition(_ position: CGPoint, size: CGSize) -> CGPoint {
        let x = max(0, min(maxPositionX(for: size), position.x))
        let y = max(minPositionY, min(maxPositionY(for: size), position.y))
        return CGPoint(x: x, y: y)
    }

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
        currentTileMode = .none
        for tab in tabsManager.tabs {
            tab.isFloating = false
            tab.isMinimizedToDock = false
            tab.isBubbleMode = false
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

    // MARK: - Bubble Mode (Mini PiP)

    func minimizeToBubble(_ tab: BrowserTab, allTabs: [BrowserTab]) {
        // Save current position/size for restore
        tab.preBubblePosition = tab.floatingPosition
        tab.preBubbleSize = tab.floatingSize

        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            tab.isBubbleMode = true
            // Position bubble at a smart location (right edge, avoid overlap)
            let screen = screenBounds
            let bubbleSize: CGFloat = 56
            let existingBubbles = allTabs.filter { $0.isBubbleMode }.count
            let yOffset = CGFloat(existingBubbles) * (bubbleSize + 12)
            tab.bubblePosition = CGPoint(
                x: screen.width - bubbleSize - 12,
                y: 120 + yOffset
            )
        }
    }

    func restoreFromBubble(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            tab.isBubbleMode = false
            // Restore to saved position
            tab.floatingPosition = tab.preBubblePosition
            tab.floatingSize = tab.preBubbleSize
        }
        bringToFront(tab, in: nil)
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
    }

    // MARK: - Aspect Ratio

    func setAspectRatio(_ preset: AspectRatioPreset, for tab: BrowserTab) {
        tab.aspectRatio = preset
        if let ratio = preset.ratio {
            let width = tab.floatingSize.width
            let newHeight = width / ratio
            tab.floatingSize = CGSize(width: width, height: newHeight)
            tab.floatingPosition = clampedPosition(tab.floatingPosition, size: tab.floatingSize)
        }
    }

    // MARK: - Resize

    func resizeWindow(_ tab: BrowserTab, to size: CGSize) {
        let minW: CGFloat = 280
        let maxW: CGFloat = screenBounds.width - 40
        let minH: CGFloat = 320
        let maxH: CGFloat = screenBounds.height - 80

        let newWidth = max(minW, min(maxW, size.width))
        var newHeight = max(minH, min(maxH, size.height))

        if let ratio = tab.aspectRatio?.ratio {
            newHeight = newWidth / ratio
            newHeight = max(minH, min(maxH, newHeight))
        }

        tab.floatingSize = CGSize(width: newWidth, height: newHeight)
        tab.floatingPosition = clampedPosition(tab.floatingPosition, size: tab.floatingSize)
    }

    func snapToEdge(_ tab: BrowserTab, edge: SnapEdge) {
        let screen = screenBounds
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
            targetPosition = CGPoint(x: tab.floatingPosition.x, y: screen.height - tab.floatingSize.height - margin)
        }

        let clamped = clampedPosition(targetPosition, size: tab.floatingSize)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            tab.floatingPosition = clamped
        }
    }

    // MARK: - Multi-Window Grid / Tiling

    /// Tự động sắp xếp các cửa sổ đang active thành lưới (2 hoặc 4 cửa sổ).
    func tileWindows(_ tabs: [BrowserTab], mode: TileMode) {
        let screen = screenBounds
        let visibleTabs = tabs.filter { $0.isFloating && !$0.isMinimizedToDock && !$0.isBubbleMode }
        guard visibleTabs.count >= 2 else { return }

        currentTileMode = mode

        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            switch mode {
            case .twoHorizontal:
                // 2 windows side by side
                let gap: CGFloat = 8
                let margin: CGFloat = 12
                let topMargin: CGFloat = 12
                let bottomMargin: CGFloat = 80
                let w = (screen.width - gap - margin * 2) / 2
                let h = screen.height - topMargin - bottomMargin

                for (index, tab) in visibleTabs.prefix(2).enumerated() {
                    tab.floatingSize = CGSize(width: w, height: h)
                    let x = margin + CGFloat(index) * (w + gap)
                    tab.floatingPosition = clampedPosition(
                        CGPoint(x: x, y: topMargin),
                        size: tab.floatingSize
                    )
                }

            case .twoVertical:
                // 2 windows stacked
                let gap: CGFloat = 8
                let margin: CGFloat = 12
                let topMargin: CGFloat = 12
                let bottomMargin: CGFloat = 80
                let w = screen.width - margin * 2
                let h = (screen.height - topMargin - bottomMargin - gap) / 2

                for (index, tab) in visibleTabs.prefix(2).enumerated() {
                    tab.floatingSize = CGSize(width: w, height: h)
                    let y = topMargin + CGFloat(index) * (h + gap)
                    tab.floatingPosition = clampedPosition(
                        CGPoint(x: margin, y: y),
                        size: tab.floatingSize
                    )
                }

            case .fourGrid:
                // 4 windows in grid
                let gap: CGFloat = 8
                let margin: CGFloat = 12
                let topMargin: CGFloat = 12
                let bottomMargin: CGFloat = 80
                let w = (screen.width - gap - margin * 2) / 2
                let h = (screen.height - topMargin - bottomMargin - gap) / 2

                for (index, tab) in visibleTabs.prefix(4).enumerated() {
                    let col = index % 2
                    let row = index / 2
                    tab.floatingSize = CGSize(width: w, height: h)
                    let x = margin + CGFloat(col) * (w + gap)
                    let y = topMargin + CGFloat(row) * (h + gap)
                    tab.floatingPosition = clampedPosition(
                        CGPoint(x: x, y: y),
                        size: tab.floatingSize
                    )
                }

            case .none:
                break
            }
        }
    }

    /// Toggle tile mode: none -> next available -> none
    func cycleTileMode(for tabs: [BrowserTab]) {
        let visibleCount = tabs.filter { $0.isFloating && !$0.isMinimizedToDock && !$0.isBubbleMode }.count
        guard visibleCount >= 2 else {
            currentTileMode = .none
            return
        }

        let nextMode: TileMode
        switch currentTileMode {
        case .none:
            nextMode = visibleCount >= 4 ? .fourGrid : .twoHorizontal
        case .twoHorizontal:
            nextMode = .twoVertical
        case .twoVertical:
            nextMode = visibleCount >= 4 ? .fourGrid : .none
        case .fourGrid:
            nextMode = .none
        }

        currentTileMode = nextMode
        if nextMode != .none {
            tileWindows(tabs, mode: nextMode)
        }
    }

    // MARK: - Position Calculation

    private func calculatePosition(for index: Int, total: Int) -> CGPoint {
        let screen = screenBounds
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

        return clampedPosition(CGPoint(x: x, y: y), size: defaultWindowSize)
    }
}

// MARK: - Snap Edge

enum SnapEdge {
    case left, right, top, bottom
}
