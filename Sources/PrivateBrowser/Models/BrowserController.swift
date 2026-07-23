import SwiftUI
import WebKit
import Combine

/// "Bộ não" điều khiển WKWebView — thay cho việc so sánh Binding<String> ở mỗi
/// updateUIView (cách cũ dễ gây loop reload khi người dùng đang gõ URL).
/// Mọi điều hướng đều đi qua các hàm tường minh (navigate/goBack/goForward/reload/stop),
/// giúp hành vi dự đoán được và ổn định hơn nhiều.
final class BrowserController: ObservableObject {
    @Published var urlString: String = BrowserSettingsStore.homeURL
    @Published var pageTitle: String = ""
    @Published var isLoading: Bool = false
    @Published var progress: Double = 0
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var loadError: String? = nil
    @Published var isSecure: Bool = true

    /// Tab này có phải tab Riêng tư (Private) không. Cố định từ lúc tab được tạo —
    /// giống Safari thật, một tab không "chuyển chế độ" giữa chừng, vì điều đó dễ
    /// khiến người dùng tưởng nhầm dữ liệu cũ (trước khi bật) cũng được bảo vệ hồi
    /// tố, hoặc quên mất mình vừa tắt bảo vệ giữa một phiên đang nhạy cảm.
    let isPrivateMode: Bool

    fileprivate weak var webView: WKWebView?
    private var pendingRequest: URLRequest?

    /// Được gọi khi người dùng gõ đúng từ khoá bí mật vào thanh địa chỉ (xem
    /// `secretDebugKeyword` bên dưới). Model chỉ báo sự kiện ra ngoài, không tự vẽ
    /// UI — ContentView gán closure này để mở màn hình console debug.
    var onSecretCommand: (() -> Void)?

    /// Từ khoá bí mật gõ vào thanh địa chỉ để mở console thống kê/debug vui (số tab,
    /// bộ nhớ, phiên bản...). Không liên quan gì tới lịch sử duyệt web hay dữ liệu
    /// người dùng — thuần là một "easter egg" thông tin kỹ thuật.
    static let secretDebugKeyword = "termenol.on"

    init(isPrivateMode: Bool = false) {
        self.isPrivateMode = isPrivateMode
    }

    /// Điều hướng tới một chuỗi do người dùng nhập (URL hoặc từ khóa tìm kiếm).
    func navigate(to raw: String) {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.caseInsensitiveCompare(BrowserController.secretDebugKeyword) == .orderedSame {
            onSecretCommand?()
            return
        }

        loadError = nil
        let formatted = BrowserController.formatInput(raw)
        guard let rawURL = URL(string: formatted) else {
            loadError = "Địa chỉ không hợp lệ. Vui lòng kiểm tra lại."
            return
        }
        // Xoá sạch tham số theo dõi (utm_*, fbclid, gclid...) ngay từ lúc điều hướng —
        // tăng khả năng ẩn mình mà không ảnh hưởng nội dung trang đích.
        let url = BrowserController.stripTrackingParameters(from: rawURL)
        let request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 25)
        if let webView {
            webView.load(request)
        } else {
            // WKWebView chưa được tạo xong (lần đầu khởi động) — lưu lại để load ngay khi sẵn sàng.
            pendingRequest = request
        }
    }

    func load(url: URL) {
        navigate(to: url.absoluteString)
    }

    func goHome() {
        navigate(to: BrowserSettingsStore.homeURL)
    }

    func consumePendingRequest() -> URLRequest? {
        defer { pendingRequest = nil }
        return pendingRequest
    }

    func goBack() {
        guard let webView, webView.canGoBack else { return }
        webView.goBack()
    }

    func goForward() {
        guard let webView, webView.canGoForward else { return }
        webView.goForward()
    }

    func reload() {
        loadError = nil
        if let webView, webView.url != nil {
            webView.reload()
        } else {
            navigate(to: urlString)
        }
    }

    func stopLoading() {
        webView?.stopLoading()
        isLoading = false
        progress = 0
    }

    func attach(_ webView: WKWebView) {
        self.webView = webView
    }

    /// Chuẩn hoá chuỗi người dùng nhập: URL đầy đủ, domain rút gọn, hoặc từ khoá tìm kiếm.
    static func formatInput(_ raw: String) -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return BrowserSettingsStore.homeURL
        }
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") || trimmed.hasPrefix("about:") {
            return trimmed
        }

        let looksLikeDomain = trimmed.range(of: "^[a-zA-Z0-9][a-zA-Z0-9-]*(\\.[a-zA-Z0-9-]+)+(:[0-9]+)?(/.*)?$", options: .regularExpression) != nil
        let hasSpaces = trimmed.contains(" ")

        if hasSpaces || !looksLikeDomain {
            return BrowserSettingsStore.searchURL(for: trimmed)
        }

        let scheme = BrowserSettingsStore.useHTTP ? "http://" : "https://"
        return scheme + trimmed
    }

    /// Các tham số theo dõi (tracking) phổ biến gắn trong link để nhận diện người dùng
    /// qua các chiến dịch quảng cáo/email/mạng xã hội. Xoá an toàn — không ảnh hưởng
    /// nội dung hay chức năng của trang đích.
    private static let trackingQueryKeys: Set<String> = [
        "utm_source", "utm_medium", "utm_campaign", "utm_term", "utm_content", "utm_id", "utm_name",
        "fbclid", "gclid", "gclsrc", "dclid", "msclkid", "mc_eid", "mc_cid",
        "igshid", "ref_src", "ref_url", "yclid", "twclid", "vero_id", "_hsenc", "_hsmi",
        "si", "spm", "wt_zmc", "oly_enc_id", "oly_anon_id"
    ]

    /// Xoá các tham số theo dõi khỏi query string của URL, giữ nguyên các tham số còn lại.
    static func stripTrackingParameters(from url: URL) -> URL {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let items = components.queryItems, !items.isEmpty else {
            return url
        }
        let filtered = items.filter { !trackingQueryKeys.contains($0.name.lowercased()) }
        guard filtered.count != items.count else {
            return url
        }
        components.queryItems = filtered.isEmpty ? nil : filtered
        return components.url ?? url
    }
}
