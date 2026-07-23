import SwiftUI
import Combine

/// Quản lý toàn bộ danh sách tab đang mở và tab nào đang active.
/// Thay thế vai trò "1 BrowserController duy nhất" trước đây trong ContentView —
/// ContentView giờ luôn hiển thị `activeTab.controller`, còn TabsManager lo việc
/// tạo/đóng/chuyển tab và đảm bảo luôn có ít nhất 1 tab tồn tại (không bao giờ để
/// app rơi vào trạng thái 0 tab, tránh phải xử lý màn hình rỗng đặc biệt).
final class TabsManager: ObservableObject {
    @Published private(set) var tabs: [BrowserTab]
    @Published private(set) var activeTabId: UUID

    /// Báo ra ngoài khi BẤT KỲ tab nào (thường hoặc riêng tư) phát hiện từ khoá bí
    /// mật termenol.on — ContentView gán closure này một lần duy nhất ở đây, thay vì
    /// phải lặp qua từng tab. Mọi tab được tạo trong class này đều tự động forward
    /// về đúng closure hiện tại (xem `makeTab`), kể cả tab tạo sau khi đã gán.
    var onSecretCommand: (() -> Void)?

    init() {
        let firstTab = TabsManager.makeTab(url: BrowserSettingsStore.homeURL, isPrivateMode: false)
        self.tabs = [firstTab]
        self.activeTabId = firstTab.id
        firstTab.onSecretCommand = { [weak self] in self?.onSecretCommand?() }
    }

    var activeTab: BrowserTab {
        // Về lý thuyết activeTabId luôn khớp một tab trong `tabs` (mọi hàm thay đổi
        // đều tự cập nhật cả hai cùng lúc), nhưng phòng hờ trường hợp lệch trạng thái
        // (ví dụ do lỗi logic tương lai) thì rơi về tab đầu tiên thay vì crash.
        tabs.first(where: { $0.id == activeTabId }) ?? tabs[0]
    }

    var tabCount: Int { tabs.count }

    /// Tạo tab mới và gán sẵn onSecretCommand forward về closure hiện tại của
    /// TabsManager. Static + nhận closure tường minh để dùng được cả trong init
    /// (lúc đó self chưa init xong, không thể gọi instance method).
    private static func makeTab(url: String?, isPrivateMode: Bool) -> BrowserTab {
        BrowserTab(startURL: url ?? BrowserSettingsStore.homeURL, isPrivateMode: isPrivateMode)
    }

    /// Tạo tab mới và tự gán forward callback về đúng onSecretCommand hiện tại của
    /// instance này — dùng cho mọi lần tạo tab SAU khi TabsManager đã init xong.
    private func makeTabAndWire(url: String?, isPrivateMode: Bool) -> BrowserTab {
        let tab = TabsManager.makeTab(url: url, isPrivateMode: isPrivateMode)
        tab.onSecretCommand = { [weak self] in self?.onSecretCommand?() }
        return tab
    }

    /// Mở một tab thường mới, đưa nó thành active ngay, và trả về tab vừa tạo.
    @discardableResult
    func openNewTab(url: String? = nil, makeActive: Bool = true) -> BrowserTab {
        let tab = makeTabAndWire(url: url, isPrivateMode: false)
        tabs.append(tab)
        if makeActive {
            activeTabId = tab.id
        }
        return tab
    }

    /// Mở một tab Riêng tư mới — không lưu lịch sử/cookie/cache (giống mọi tab khác
    /// về mặt kỹ thuật, vì toàn app đã dùng nonPersistent data store), nhưng được
    /// đánh dấu isPrivateMode để giao diện hiển thị rõ ràng khác biệt (màu/icon),
    /// tránh người dùng nhầm lẫn không biết mình đang ở tab nào.
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

    /// Đóng một tab. Nếu đang đóng tab active, tự chuyển sang tab liền kề (ưu tiên
    /// tab bên phải, rơi về tab bên trái nếu đang đóng tab cuối cùng trong danh sách).
    /// Nếu đây là tab cuối cùng còn lại, mở luôn một tab thường mới thay vì để danh
    /// sách rỗng — tránh toàn bộ phần còn lại của app phải xử lý trạng thái "0 tab".
    /// Tab thay thế luôn là tab THƯỜNG dù tab vừa đóng là private hay không — đóng
    /// tab riêng tư cuối cùng nên quay về trạng thái mặc định an toàn, không tự động
    /// mở một tab riêng tư mới mà người dùng không chủ động chọn.
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

    /// Đóng toàn bộ tab, quay về đúng một tab thường mới — dùng cho "Bắt đầu phiên
    /// mới". Luôn tạo tab thường (không private) để trạng thái sau khi reset là
    /// trạng thái mặc định dễ đoán, không phụ thuộc tab cuối cùng trước đó là gì.
    func closeAll() {
        let replacement = makeTabAndWire(url: BrowserSettingsStore.homeURL, isPrivateMode: false)
        tabs = [replacement]
        activeTabId = replacement.id
    }
}
