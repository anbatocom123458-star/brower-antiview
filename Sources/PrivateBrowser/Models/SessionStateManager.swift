import Foundation
import Combine

/// Lưu và khôi phục toàn bộ trạng thái phiên làm việc —包括 tab, settings, UI state,
/// vị trí cuộn, thứ tự tab, và trạng thái cửa sổ nổi.
///
/// v3.4: Bổ sung lưu scroll position, window position/size, tab order,
/// và restore session on app launch.
final class SessionStateManager: ObservableObject {
    @Published var lastSessionURL: String?
    @Published var lastActiveTabId: UUID?

    static let shared = SessionStateManager()

    private let storageKey = "session.state"

    private enum Keys {
        static let lastSessionURL = "session.lastURL"
        static let lastActiveTabId = "session.activeTabId"
        static let openTabs = "session.openTabs"
        static let tabURLs = "session.tabURLs"
        static let tabTitles = "session.tabTitles"
        static let tabIsPrivate = "session.tabIsPrivate"
        static let timestamp = "session.timestamp"
    }

    struct SessionData: Codable {
        var lastURL: String?
        var activeTabId: UUID?
        var tabs: [TabSnapshot]
        var timestamp: Date

        struct TabSnapshot: Codable {
            var id: UUID
            var url: String
            var title: String
            var isPrivate: Bool
            var scrollProgress: Double
            var windowOrder: Int
            var isFloating: Bool
            var floatingPositionX: CGFloat
            var floatingPositionY: CGFloat
            var floatingWidth: CGFloat
            var floatingHeight: CGFloat
            var aspectRatioRaw: String?
        }
    }

    init() {
        restoreSession()
    }

    /// Lưu trạng thái hiện tại vào UserDefaults
    func saveSession(tabsManager: TabsManager) {
        var tabs: [SessionData.TabSnapshot] = []
        for (index, tab) in tabsManager.tabs.enumerated() {
            let snapshot = SessionData.TabSnapshot(
                id: tab.id,
                url: tab.controller.urlString,
                title: tab.controller.pageTitle.isEmpty ? tab.displayHost : tab.controller.pageTitle,
                isPrivate: tab.isPrivateMode,
                scrollProgress: tab.savedScrollProgress,
                windowOrder: index,
                isFloating: tab.isFloating,
                floatingPositionX: tab.floatingPosition.x,
                floatingPositionY: tab.floatingPosition.y,
                floatingWidth: tab.floatingSize.width,
                floatingHeight: tab.floatingSize.height,
                aspectRatioRaw: tab.aspectRatio?.rawValue
            )
            tabs.append(snapshot)
        }

        let session = SessionData(
            lastURL: tabsManager.activeTab.controller.urlString,
            activeTabId: tabsManager.activeTabId,
            tabs: tabs,
            timestamp: Date()
        )

        if let data = try? JSONEncoder().encode(session) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Khôi phục trạng thái từ UserDefaults
    func restoreSession() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let session = try? JSONDecoder().decode(SessionData.self, from: data) else {
            return
        }

        lastSessionURL = session.lastURL
        lastActiveTabId = session.activeTabId
    }

    /// Khôi phục tabs vào TabsManager — gọi từ ContentView.onAppear khi restoreSession = true
    func restoreTabs(into tabsManager: TabsManager) {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let session = try? JSONDecoder().decode(SessionData.self, from: data) else {
            return
        }

        guard !session.tabs.isEmpty else { return }

        // Xóa tab mặc định
        tabsManager.closeAll()

        // Tạo lại từng tab từ snapshot
        for snapshot in session.tabs {
            let tab: BrowserTab
            if snapshot.isPrivate {
                tab = tabsManager.openNewPrivateTab(url: snapshot.url, makeActive: false)
            } else {
                tab = tabsManager.openNewTab(url: snapshot.url, makeActive: false)
            }

            // Khôi phục trạng thái floating window
            tab.isFloating = snapshot.isFloating
            tab.floatingPosition = CGPoint(
                x: snapshot.floatingPositionX,
                y: snapshot.floatingPositionY
            )
            tab.floatingSize = CGSize(
                width: snapshot.floatingWidth,
                height: snapshot.floatingHeight
            )
            tab.windowOrder = snapshot.windowOrder
            tab.savedScrollProgress = snapshot.scrollProgress

            // Khôi phục aspect ratio
            if let ratioRaw = snapshot.aspectRatioRaw {
                tab.aspectRatio = AspectRatioPreset(rawValue: ratioRaw)
            }
        }

        // Select lại tab active trước đó
        if let activeId = session.activeTabId,
           let targetTab = tabsManager.tabs.first(where: { $0.id == activeId }) {
            tabsManager.select(targetTab)
        } else if let firstTab = tabsManager.tabs.first {
            tabsManager.select(firstTab)
        }
    }

    /// Lấy snapshot tab đã lưu
    func savedTabs() -> [SessionData.TabSnapshot] {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let session = try? JSONDecoder().decode(SessionData.self, from: data) else {
            return []
        }
        return session.tabs
    }

    /// Xóa dữ liệu phiên đã lưu
    func clearSavedSession() {
        UserDefaults.standard.removeObject(forKey: storageKey)
        lastSessionURL = nil
        lastActiveTabId = nil
    }

    /// Kiểm tra có dữ liệu phiên trước đó không
    var hasSavedSession: Bool {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let session = try? JSONDecoder().decode(SessionData.self, from: data) else {
            return false
        }
        return !session.tabs.isEmpty
    }
}
