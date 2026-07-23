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
///
/// v3.4: Thêm state cho floating window nâng cao (virtual cursor, aspect ratio,
/// scroll position cho session persistence).
final class BrowserTab: ObservableObject, Identifiable {
    let id = UUID()
    @Published var controller: BrowserController
    let createdAt = Date()

    // MARK: - Floating Window State

    @Published var isFloating: Bool = false
    @Published var floatingPosition: CGPoint = .zero
    @Published var floatingSize: CGSize = CGSize(width: 320, height: 480)
    @Published var isMinimizedToDock: Bool = false
    @Published var windowOrder: Int = 0

    /// Tỉ lệ khung hình: nil = freeform, các giá trị khác = cố định tỉ lệ
    @Published var aspectRatio: AspectRatioPreset? = nil

    /// Con trỏ ảo có đang bật cho cửa sổ này không
    @Published var virtualCursorEnabled: Bool = false

    /// Vị trí con trỏ ảo trong cửa sổ (tọa độ local, tính từ góc trái trên)
    @Published var virtualCursorLocalPosition: CGPoint = CGPoint(x: 160, y: 240)

    /// Scroll offset được lưu khi persist session (tỷ lệ 0..1)
    @Published var savedScrollProgress: Double = 0

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
        cancellable = controller.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }
        controller.onSecretCommand = { [weak self] in
            self?.onSecretCommand?()
        }
    }

    var displayTitle: String {
        if !controller.pageTitle.trimmingCharacters(in: .whitespaces).isEmpty {
            return controller.pageTitle
        }
        if let url = URL(string: controller.urlString), let host = url.host, !host.isEmpty {
            return host
        }
        return "Tab trống"
    }

    var displayHost: String {
        guard let url = URL(string: controller.urlString), let host = url.host, !host.isEmpty else {
            return controller.urlString
        }
        return host
    }
}

// MARK: - Aspect Ratio

enum AspectRatioPreset: String, CaseIterable, Identifiable, Codable {
    case free
    case sixteenNine = "16:9"
    case fourThree = "4:3"
    case square = "1:1"
    case threeFour = "3:4"
    case nineSixteen = "9:16"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .free: return "Tùy ý"
        case .sixteenNine: return "16:9"
        case .fourThree: return "4:3"
        case .square: return "1:1"
        case .threeFour: return "3:4"
        case .nineSixteen: return "9:16"
        }
    }

    var icon: String {
        switch self {
        case .free: return "arrow.up.left.and.arrow.down.right"
        case .sixteenNine: return "rectangle.landscape.rotate"
        case .fourThree: return "rectangle.portrait"
        case .square: return "square"
        case .threeFour: return "rectangle.portrait.rotate"
        case .nineSixteen: return "rectangle.portrait.rotate"
        }
    }

    var ratio: CGFloat? {
        switch self {
        case .free: return nil
        case .sixteenNine: return 16.0 / 9.0
        case .fourThree: return 4.0 / 3.0
        case .square: return 1.0
        case .threeFour: return 3.0 / 4.0
        case .nineSixteen: return 9.0 / 16.0
        }
    }
}
