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

    fileprivate weak var webView: WKWebView?
    private var pendingRequest: URLRequest?

    /// Điều hướng tới một chuỗi do người dùng nhập (URL hoặc từ khóa tìm kiếm).
    func navigate(to raw: String) {
        loadError = nil
        let formatted = BrowserController.formatInput(raw)
        guard let url = URL(string: formatted) else {
            loadError = "Địa chỉ không hợp lệ. Vui lòng kiểm tra lại."
            return
        }
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
}
