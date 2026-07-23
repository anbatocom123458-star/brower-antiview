import SwiftUI
import Combine

/// Một tab trình duyệt độc lập: có `BrowserController` riêng (nên có URL/lịch sử
/// back-forward/tiến trình tải riêng), nhưng dùng chung cấu hình bảo mật/zoom của
/// toàn app (blockWebRTC, desktopMode...) — các cờ đó được đọc từ AppStorage ở
/// ContentView và truyền xuống BrowserView như trước, không nhân bản theo từng tab.
///
/// Riêng `isPrivateMode` là thuộc tính CỦA TỪNG TAB, không phải cờ toàn cục — đúng
/// hành vi Safari thật: tab thường và tab Riêng tư tồn tại song song, người dùng tự
/// chọn loại tab khi mở mới, không có một công tắc duy nhất ảnh hưởng mọi tab.
///
/// `ObservableObject` để lưới xem trước (TabGridView) có thể tự cập nhật tiêu đề/URL
/// hiển thị trên từng thẻ khi trang trong tab đó đổi, mà không cần TabsManager tự tay
/// forward từng thay đổi.
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var controller: BrowserController
    let createdAt = Date()

    // Floating window state
    @Published var isFloating: Bool = false
    @Published var floatingPosition: CGPoint = .zero
    @Published var floatingSize: CGSize = CGSize(width: 320, height: 480)
    @Published var isMinimizedToDock: Bool = false
    @Published var windowOrder: Int = 0

    var isPrivateMode: Bool { controller.isPrivateMode }

    /// Báo ra ngoài khi tab này phát hiện từ khoá bí mật (termenol.on) — TabsManager
    /// gán closure này khi tạo tab để forward tiếp lên ContentView, tránh ContentView
    /// phải tự tay lặp qua từng tab để gán callback.
    var onSecretCommand: (() -> Void)?

    private var cancellable: AnyCancellable?

    init(startURL: String? = nil, isPrivateMode: Bool = false) {
        let controller = BrowserController(isPrivateMode: isPrivateMode)
        if let startURL, !startURL.isEmpty {
            controller.urlString = startURL
        }
        self.controller = controller
        // Forward objectWillChange của controller lồng bên trong ra ngoài, để View nào
        // chỉ quan sát BrowserTab (không quan sát trực tiếp controller) vẫn re-render
        // đúng lúc khi title/urlString/isLoading... của tab đổi.
        cancellable = controller.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        controller.onSecretCommand = { [weak self] in
            self?.onSecretCommand?()
        }
    }

    /// Tiêu đề hiển thị trên thẻ tab: ưu tiên tiêu đề trang, rơi về host của URL,
    /// rơi tiếp về "Tab trống" nếu chưa điều hướng đi đâu cả.
    var displayTitle: String {
        if !controller.pageTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            return controller.pageTitle
        }
        if let url = URL(string: controller.urlString), let host = url.host, !host.isEmpty {
            return host
        }
        return "Tab trống"
    }

    /// Host rút gọn hiển thị phụ dưới tiêu đề trên thẻ tab (giống Safari).
    var displayHost: String {
        guard let url = URL(string: controller.urlString), let host = url.host, !host.isEmpty else {
            return controller.urlString
        }
        return host
    }
}
