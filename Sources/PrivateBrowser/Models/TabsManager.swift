import SwiftUI
import Combine

/// Quản lý toàn bộ danh sách tab đang mở và tab nào đang active.
/// Thay thế vai trò "1 BrowserController duy nhất" trước đây trong ContentView —
/// ContentView giờ luôn hiển thị `activeTab.controller`, còn TabsManager lo việc
/// tạo/đóng/chuyển tab và đảm bảo luôn có ít nhất 1 tab tồn tại (không bao giờ để
/// app rơi vào trạng thái 0 tab, tránh phải xử lý màn hình rỗng đặc biệt).
///
/// v3.4: Hỗ trợ restore session — TabsManager có thể khôi phục tabs từ session
/// đã lưu khi app khởi động, bao gồm URL, trạng thái private, vị trí cửa sổ.
final class TabsManager: ObservableObject {
    @Published private(set) var tabs: [BrowserTab]
    @Published private(set) var activeTabId: UUID

    var onSecretCommand: (() -> Void)?

    init() {
        let firstTab = TabsManager.makeTab(url: BrowserSettingsStore.homeURL, isPrivateMode: false)
        self.tabs = [firstTab]
        self.activeTabId = firstTab.id
        firstTab.onSecretCommand = { [weak self] in self?.onSecretCommand?() }
    }

    var activeTab: BrowserTab {
        tabs.first(where: { $0.id == activeTabId }) ?? tabs[0]
    }

    var tabCount: Int { tabs.count }

    var regularTabs: [BrowserTab] {
        tabs.filter { !$0.isPrivateMode }
    }

    var privateTabs: [BrowserTab] {
        tabs.filter { $0.isPrivateMode }
    }

    var regularTabCount: Int { regularTabs.count }

    var privateTabCount: Int { privateTabs.count }

    private static func makeTab(url: String?, isPrivateMode: Bool) -> BrowserTab {
        BrowserTab(startURL: url ?? BrowserSettingsStore.homeURL, isPrivateMode: isPrivateMode)
    }

    private func makeTabAndWire(url: String?, isPrivateMode: Bool) -> BrowserTab {
        let tab = TabsManager.makeTab(url: url, isPrivateMode: isPrivateMode)
        tab.onSecretCommand = { [weak self] in self?.onSecretCommand?() }
        return tab
    }

    @discardableResult
    func openNewTab(url: String? = nil, makeActive: Bool = true) -> BrowserTab {
        let tab = makeTabAndWire(url: url, isPrivateMode: false)
        tabs.append(tab)
        if makeActive {
            activeTabId = tab.id
        }
        return tab
    }

    @discardableResult
    func openNewPrivateTab(url: String? = nil, makeActive: Bool = true) -> BrowserTab {
        let tab = makeTabAndWire(url: url, isPrivateMode: true)
        tabs.append(tab)
        if makeActive {
            activeTabId = tab.id
        }
        return tab
    }

    func select(_ tab: BrowserTab) {
        guard tabs.contains(where: { $0.id == tab.id }) else { return }
        activeTabId = tab.id
    }

    func close(_ tab: BrowserTab) {
        guard let index = tabs.firstIndex(where: { $0.id == tab.id }) else { return }
        let wasActive = tab.id == activeTabId

        tabs.remove(at: index)

        if tabs.isEmpty {
            let replacement = makeTabAndWire(url: BrowserSettingsStore.homeURL, isPrivateMode: false)
            tabs = [replacement]
            activeTabId = replacement.id
            return
        }

        if wasActive {
            let nextIndex = min(index, tabs.count - 1)
            activeTabId = tabs[nextIndex].id
        }
    }

    func closeAllExceptActive() {
        let current = activeTab
        tabs = [current]
        activeTabId = current.id
    }

    func closeAll() {
        let replacement = makeTabAndWire(url: BrowserSettingsStore.homeURL, isPrivateMode: false)
        tabs = [replacement]
        activeTabId = replacement.id
    }

    func closeAllPrivateTabs() {
        let privateIds = Set(tabs.filter(\.isPrivateMode).map(\.id))
        tabs.removeAll { $0.isPrivateMode }
        if privateIds.contains(activeTabId), let first = tabs.first {
            activeTabId = first.id
        }
        if tabs.isEmpty {
            closeAll()
        }
    }
}
