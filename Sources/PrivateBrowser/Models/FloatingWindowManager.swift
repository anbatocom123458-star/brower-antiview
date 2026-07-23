import SwiftUI
import Combine

final class FloatingWindowManager: ObservableObject {
    @Published var isFloatingMode: Bool = false
    @Published var dockHeight: CGFloat = 80
    @Published var dockPosition: DockPosition = .bottom
    @Published var nextWindowOrder: Int = 0

    enum DockPosition {
        case bottom, left, right
    }

    private var cancellables = Set<AnyCancellable>()

    init() {}

    func enterFloatingMode(from tabsManager: TabsManager) {
        isFloatingMode = true
        for (index, tab) in tabsManager.tabs.enumerated() {
            tab.isFloating = true
            tab.windowOrder = index
            tab.floatingPosition = initialPosition(for: index, total: tabsManager.tabs.count)
        }
    }

    func exitFloatingMode(to tabsManager: TabsManager) {
        isFloatingMode = false
        for tab in tabsManager.tabs {
            tab.isFloating = false
            tab.isMinimizedToDock = false
        }
    }

    func addFloatingTab(_ tab: BrowserTab, in tabsManager: TabsManager) {
        tab.isFloating = true
        tab.windowOrder = nextWindowOrder
        tab.floatingPosition = initialPosition(for: tabsManager.tabs.count, total: tabsManager.tabs.count + 1)
        nextWindowOrder += 1
    }

    func minimizeToDock(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tab.isMinimizedToDock = true
        }
    }

    func restoreFromDock(_ tab: BrowserTab) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            tab.isMinimizedToDock = false
        }
    }

    func bringToFront(_ tab: BrowserTab, in tabsManager: TabsManager) {
        let maxOrder = tabsManager.tabs.map(\.windowOrder).max() ?? 0
        tab.windowOrder = maxOrder + 1
    }

    private func initialPosition(for index: Int, total: Int) -> CGPoint {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let windowWidth: CGFloat = 320
        let windowHeight: CGFloat = 480
        let dockHeight: CGFloat = 100
        let padding: CGFloat = 20

        let cols = max(1, Int((screenWidth - padding) / (windowWidth + padding)))
        let row = index / cols
        let col = index % cols

        let x = padding + CGFloat(col) * (windowWidth + padding)
        let y = screenHeight - dockHeight - windowHeight - padding - CGFloat(row) * (windowHeight + padding)

        return CGPoint(x: x, y: y)
    }

    func resizeWindow(_ tab: BrowserTab, to size: CGSize) {
        let minWidth: CGFloat = 200
        let maxWidth: CGFloat = UIScreen.main.bounds.width - 40
        let minHeight: CGFloat = 300
        let maxHeight: CGFloat = UIScreen.main.bounds.height - 200

        tab.floatingSize = CGSize(
            width: max(minWidth, min(maxWidth, size.width)),
            height: max(minHeight, min(maxHeight, size.height))
        )
    }
}
