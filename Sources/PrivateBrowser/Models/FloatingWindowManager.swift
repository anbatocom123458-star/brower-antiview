import SwiftUI
import Combine

/// Quản lý các cửa sổ nổi — vị trí, kích thước, thứ tự lớp, và trạng thái dock.
final class FloatingWindowManager: ObservableObject {
    @Published var isFloatingMode: Bool = false
    @Published var dockHeight: CGFloat = 90
    @Published var nextWindowOrder: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {}

    /// Vào chế độ cửa sổ — đánh dấu tất cả tab đang mở là floating
    func enterFloatingMode(from tabsManager: TabsManager) {
        isFloatingMode = true
        nextWindowOrder = tabsManager.tabs.count

        for (index, tab) in tabsManager.tabs.enumerated() {
            tab.isFloating = true
            tab.windowOrder = index
            tab.floatingSize = CGSize(width: 320, height: 480)
            tab.floatingPosition = calculatePosition(for: index, total: tabsManager.tabs.count)
        }
    }

    /// Thoát chế độ cửa sổ
    func exitFloatingMode(to tabsManager: TabsManager) {
        isFloatingMode = false
        for tab in tabsManager.tabs {
            tab.isFloating = false
            tab.isMinimizedToDock = false
        }
    }

    /// Thêm tab mới vào chế độ cửa sổ
    func addFloatingTab(_ tab: BrowserTab, in tabsManager: TabsManager) {
        tab.isFloating = true
        tab.floatingSize = CGSize(width: 320, height: 480)
        tab.windowOrder = nextWindowOrder
        tab.floatingPosition = calculatePosition(for: tabsManager.tabs.count, total: tabsManager.tabs.count + 1)
        nextWindowOrder += 1
    }

    /// Thu nhỏ cửa sổ vào dock
    func minimizeToDock(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tab.isMinimizedToDock = true
        }
    }

    /// Khôi phục cửa sổ từ dock
    func restoreFromDock(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            tab.isMinimizedToDock = false
        }
        bringToFront(tab, in: nil)
    }

    /// Đưa cửa sổ lên trên cùng
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

    /// Tính vị trí ban đầu cho cửa sổ — xếp lưới từ trên xuống, trái sang phải
    private func calculatePosition(for index: Int, total: Int) -> CGPoint {
        let screen = UIScreen.main.bounds
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 480
        let dockHeight: CGFloat = 100
        let padding: CGFloat = 24
        let topPadding: CGFloat = 20

        // Số cột tối đa vừa màn hình
        let availableWidth = screen.width - padding * 2
        let cols = max(1, Int(availableWidth / (windowWidth + padding)))
        let row = index / cols
        let col = index % cols

        // Center horizontally if fewer windows than max cols
        let totalWindowsInRow = min(cols, total - row * cols)
        let rowWidth = CGFloat(totalWindowsInRow) * windowWidth + CGFloat(totalWindowsInRow - 1) * padding
        let offsetX = (screen.width - rowWidth) / 2

        let x = offsetX + CGFloat(col) * (windowWidth + padding)
        let y = topPadding + CGFloat(row) * (windowHeight + padding)

        return CGPoint(x: x, y: y)
    }

    /// Thay đổi kích thước cửa sổ
    func resizeWindow(_ tab: BrowserTab, to size: CGSize) {
        let minWidth: CGFloat = 250
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 40
        let minHeight: CGFloat = 350
        let maxHeight: CGFloat = UIScreen.main.bounds.height - 150

        tab.floatingSize = CGSize(
            width: max(minWidth, min(maxWidth, size.width)),
            height: max(minHeight, min(maxHeight, size.height))
        )
    }
}
