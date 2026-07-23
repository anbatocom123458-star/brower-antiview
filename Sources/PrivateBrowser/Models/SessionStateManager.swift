import Foundation
import Combine

/// Lưu và khôi phục toàn bộ trạng thái phiên làm việc —包括 tab, settings, và UI state.
/// Dữ liệu được lưu vào UserDefaults khi app chuyển sang nền và khôi phục khi mở lại.
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
        }
    }

    init() {
        restoreSession()
    }

    /// Lưu trạng thái hiện tại vào UserDefaults
    func saveSession(tabsManager: TabsManager) {
        var tabs: [SessionData.TabSnapshot] = []
        for tab in tabsManager.tabs {
            let snapshot = SessionData.TabSnapshot(
                id: tab.id,
                url: tab.controller.urlString,
                title: tab.controller.pageTitle.isEmpty ? tab.displayHost : tab.controller.pageTitle,
                isPrivate: tab.isPrivateMode
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
