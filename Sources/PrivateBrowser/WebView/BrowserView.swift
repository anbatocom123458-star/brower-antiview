import SwiftUI
import WebKit
import UIKit

/// Bọc WKWebView cho SwiftUI. So với bản cũ, bản này:
/// - Không còn so sánh URL ở mỗi updateUIView (nguồn gây loop reload khi gõ URL).
/// - Xử lý đầy đủ JS alert/confirm/prompt để trang không bị "treo" khi gọi window.alert.
/// - Chặn scheme lạ (tel:, mailto:...) bằng cách chuyển cho hệ thống xử lý, không crash.
/// - Dọn dẹp KVO observer đúng cách trong deinit — tránh rò nhớ.
/// - Hỗ trợ tải xuống file (WKDownload) và Userscript Manager.
struct BrowserView: UIViewRepresentable {
    @ObservedObject var controller: BrowserController
    @ObservedObject var zoomManager: ZoomManager
    @ObservedObject var userscriptManager: UserscriptManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockAds: Bool
    var desktopMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, zoomManager: zoomManager, userscriptManager: userscriptManager)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        // Cho phép download
        if #available(iOS 17.0, *) {
            config.allowsExpensiveNetworkAccess = true
        }

        let ucc = config.userContentController
        if blockWebRTC {
            ucc.addUserScript(WKUserScript(
                source: AntiIPLeak.blockScript(blockWebRTC: blockWebRTC),
                injectionTime: .atDocumentStart,
                forMainFrameOnly: false
            ))
        }
        if blockIframe {
            ucc.addUserScript(WKUserScript(
                source: AntiIPLeak.iframeBlockScript,
                injectionTime: .atDocumentEnd,
                forMainFrameOnly: false
            ))
        }
        // Bắt lỗi JS runtime chưa xử lý (kiểu "Application error" của các trang
        // React/Next.js) để hiện màn hình lỗi có nút Thử lại — luôn bật, không phụ
        // thuộc cờ bảo mật nào vì mục đích là ổn định trải nghiệm, không phải riêng tư.
        ucc.add(context.coordinator, name: AntiIPLeak.jsErrorHandlerName)
        ucc.addUserScript(WKUserScript(
            source: AntiIPLeak.jsErrorReportScript,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        ))

        // Inject userscripts
        let userscripts = userscriptManager.userScripts(for: URL(string: controller.urlString) ?? URL(string: "about:blank")!)
        for script in userscripts {
            ucc.addUserScript(script)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.allowsBackForwardNavigationGestures = true
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        if desktopMode {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        }

        context.coordinator.attach(webView)
        controller.attach(webView)
        context.coordinator.syncAdBlock(enabled: blockAds, webView: webView)

        if let pending = controller.consumePendingRequest() {
            webView.load(pending)
        } else {
            controller.navigate(to: controller.urlString)
        }

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.customUserAgent == nil && desktopMode {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        } else if webView.customUserAgent != nil && !desktopMode {
            webView.customUserAgent = nil
        }
        context.coordinator.syncAdBlock(enabled: blockAds, webView: webView)
        zoomManager.apply(to: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
        // WKUserContentController giữ strong reference tới message handler — phải gỡ
        // tường minh, nếu không Coordinator (và toàn bộ BrowserController nó tham chiếu) sẽ rò nhớ.
        webView.configuration.userContentController.removeScriptMessageHandler(forName: AntiIPLeak.jsErrorHandlerName)
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        private weak var controller: BrowserController?
        private weak var zoomManager: ZoomManager?
        private weak var userscriptManager: UserscriptManager?

        private var progressObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        private var backObservation: NSKeyValueObservation?
        private var forwardObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?
        private var adBlockApplied = false
        /// Chống báo lỗi JS dồn dập: nhiều trang ném hàng chục lỗi liên tiếp khi hydrate
        /// hỏng (mỗi component con lỗi một lần) — chỉ hiện overlay lỗi cho lỗi đầu tiên
        /// trong mỗi lượt tải trang, tránh loadError bị ghi đè liên tục gây giật UI.
        private var didReportJSErrorForCurrentLoad = false

        init(controller: BrowserController, zoomManager: ZoomManager, userscriptManager: UserscriptManager) {
            self.controller = controller
            self.zoomManager = zoomManager
            self.userscriptManager = userscriptManager
        }

        /// Bật/tắt bộ chặn quảng cáo & theo dõi (WKContentRuleList) theo cài đặt hiện tại,
        /// tránh biên dịch/gắn lại nhiều lần không cần thiết khi SwiftUI re-render.
        func syncAdBlock(enabled: Bool, webView: WKWebView) {
            if enabled && !adBlockApplied {
                adBlockApplied = true
                ContentBlocker.ruleList { [weak webView] ruleList in
                    guard let ruleList, let webView else { return }
                    DispatchQueue.main.async {
                        webView.configuration.userContentController.add(ruleList)
                    }
                }
            } else if !enabled && adBlockApplied {
                adBlockApplied = false
                webView.configuration.userContentController.removeAllContentRuleLists()
            }
        }

        deinit {
            progressObservation?.invalidate()
            loadingObservation?.invalidate()
            backObservation?.invalidate()
            forwardObservation?.invalidate()
            titleObservation?.invalidate()
        }

        func attach(_ webView: WKWebView) {
            progressObservation = webView.observe(\.estimatedProgress, options: .new) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.controller?.progress = wv.estimatedProgress }
            }
            loadingObservation = webView.observe(\.isLoading, options: .new) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.controller?.isLoading = wv.isLoading }
            }
            backObservation = webView.observe(\.canGoBack, options: .new) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.controller?.canGoBack = wv.canGoBack }
            }
            forwardObservation = webView.observe(\.canGoForward, options: .new) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.controller?.canGoForward = wv.canGoForward }
            }
            titleObservation = webView.observe(\.title, options: .new) { [weak self] wv, _ in
                DispatchQueue.main.async { self?.controller?.pageTitle = wv.title ?? "" }
            }
        }

        // MARK: - Navigation lifecycle

        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            let scheme = url.scheme?.lowercased() ?? ""
            let webSchemes: Set<String> = ["http", "https", "about", "blob", "data", "file"]
            if webSchemes.contains(scheme) {
                // Dọn tham số theo dõi ngay cả khi người dùng bấm link trong trang, không chỉ khi gõ URL.
                let cleaned = BrowserController.stripTrackingParameters(from: url)
                if cleaned != url {
                    decisionHandler(.cancel)
                    webView.load(URLRequest(url: cleaned, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
                    return
                }
                decisionHandler(.allow)
                return
            }
            // Scheme đặc biệt (tel:, mailto:, sms:, facetime:...) -> chuyển cho hệ thống xử lý.
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        }

        /// Kiểm tra response có phải file download không (Content-Disposition: attachment).
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            let response = navigationResponse.response as? HTTPURLResponse
            let contentDisposition = response?.value(forHTTPHeaderField: "Content-Disposition") ?? ""

            // Phát hiện download qua Content-Disposition header
            if contentDisposition.lowercased().contains("attachment") {
                let filename = response?.value(forHTTPHeaderField: "Content-Disposition")
                    .flatMap { headerValue in
                        // Extract filename from Content-Disposition header
                        let parts = headerValue.components(separatedBy: "filename=")
                        return parts.last?.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                    }
                    ?? navigationResponse.response.url?.lastPathComponent
                    ?? "download"
                let url = navigationResponse.response.url

                // Tải file bằng URLSession thay vì WKDownload (tương thích iOS 18)
                if let downloadURL = url {
                    let task = URLSession.shared.downloadTask(with: downloadURL) { tempURL, _, _ in
                        guard let tempURL else { return }
                        let destDir = DownloadManager.downloadsDirectory
                        let destURL = destDir.appendingPathComponent(filename)
                        try? FileManager.default.removeItem(at: destURL)
                        try? FileManager.default.moveItem(at: tempURL, to: destURL)

                        DispatchQueue.main.async {
                            let item = DownloadItem(
                                id: UUID(),
                                filename: filename,
                                url: downloadURL,
                                isPrivateMode: self.controller?.isPrivateMode ?? false,
                                startedAt: Date(),
                                completedAt: Date(),
                                fileURL: destURL
                            )
                            DownloadManager.shared.addCompletedItem(item)
                        }
                    }
                    task.resume()
                }
                decisionHandler(.cancel)
                return
            }

            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            didReportJSErrorForCurrentLoad = false
            DispatchQueue.main.async {
                self.controller?.isLoading = true
                self.controller?.loadError = nil
            }
        }

        func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
            DispatchQueue.main.async {
                guard let urlAbsolute = webView.url?.absoluteString else { return }
                self.controller?.urlString = urlAbsolute
                self.controller?.isSecure = webView.url?.scheme?.lowercased() == "https"
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.controller?.isLoading = false
                self.controller?.progress = 0
                if let urlAbsolute = webView.url?.absoluteString {
                    self.controller?.urlString = urlAbsolute
                }
                if let zoomManager = self.zoomManager {
                    zoomManager.apply(to: webView, force: true)
                }
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            handleFailure(error)
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            handleFailure(error)
        }

        private func handleFailure(_ error: Error) {
            let nsError = error as NSError
            DispatchQueue.main.async {
                self.controller?.isLoading = false
                self.controller?.progress = 0
                // Bỏ qua lỗi "cancelled" — thường do người dùng điều hướng tiếp rất nhanh, không phải lỗi thật.
                if nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorCancelled {
                    return
                }
                self.controller?.loadError = Self.friendlyMessage(for: nsError)
            }
        }

        private static func friendlyMessage(for error: NSError) -> String {
            switch error.code {
            case NSURLErrorNotConnectedToInternet:
                return "Không có kết nối Internet."
            case NSURLErrorTimedOut:
                return "Kết nối quá thời gian chờ. Vui lòng thử lại."
            case NSURLErrorCannotFindHost, NSURLErrorCannotConnectToHost:
                return "Không thể kết nối đến trang web này."
            case NSURLErrorSecureConnectionFailed, NSURLErrorServerCertificateUntrusted:
                return "Kết nối bảo mật không thành công."
            default:
                return "Không thể tải trang. \(error.localizedDescription)"
            }
        }

        // MARK: - Lỗi JavaScript runtime (kiểu "Application error" của DuckDuckGo/Next.js)

        /// Nhận báo lỗi từ jsErrorReportScript. Đây là loại lỗi xảy ra SAU khi điều hướng
        /// đã "thành công" theo góc nhìn mạng (trang tải xong, JS chạy rồi mới lỗi khi
        /// hydrate) — nên không đi qua didFail/didFailProvisionalNavigation ở trên.
        /// Không thể tự khắc phục kiểu lỗi này từ phía trình duyệt (lỗi nằm trong code
        /// của chính trang), nên việc hợp lý nhất là báo rõ cho người dùng và cho phép
        /// tải lại — giống hệt cách Safari/Chrome xử lý khi một trang tự crash.
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == AntiIPLeak.jsErrorHandlerName else { return }
            guard !didReportJSErrorForCurrentLoad else { return }
            didReportJSErrorForCurrentLoad = true
            let detail = (message.body as? String) ?? "Không rõ nguyên nhân"
            DispatchQueue.main.async {
                self.controller?.isLoading = false
                self.controller?.progress = 0
                self.controller?.loadError = "Trang gặp lỗi khi chạy (client-side exception). Một số script hoặc bộ lọc bảo mật có thể đang xung đột với trang này.\n\nChi tiết: \(detail)"
            }
        }

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Trang mở "cửa sổ mới" (target=_blank) -> mở luôn trong webView hiện tại
            // để giữ đúng chế độ riêng tư (không tạo webView con không kiểm soát được).
            // Đẩy sang main queue async thay vì gọi load() ngay trong callback này: tại
            // thời điểm này WebKit đang giữa quy trình nội bộ tạo một webview con, gọi
            // load() đồng bộ đè lên chính webView hiện tại có thể xung đột trạng thái
            // điều hướng trên một số trang (đặc biệt popup đăng nhập OAuth).
            if let url = navigationAction.request.url {
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: url))
                }
            }
            return nil
        }

        func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
            completionHandler(.performDefaultHandling, nil)
        }

        // MARK: - JS Dialogs — bắt buộc phải xử lý, nếu không nhiều trang sẽ bị "treo" vô hạn.

        func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
            DispatchQueue.main.async {
                guard let root = UIApplication.shared.topMostViewController() else {
                    completionHandler()
                    return
                }
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
                root.present(alert, animated: true)
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
            DispatchQueue.main.async {
                guard let root = UIApplication.shared.topMostViewController() else {
                    completionHandler(true)
                    return
                }
                let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "Hủy", style: .cancel) { _ in completionHandler(false) })
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler(true) })
                root.present(alert, animated: true)
            }
        }

        func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
            DispatchQueue.main.async {
                guard let root = UIApplication.shared.topMostViewController() else {
                    completionHandler(defaultText)
                    return
                }
                let alert = UIAlertController(title: nil, message: prompt, preferredStyle: .alert)
                alert.addTextField { textField in textField.text = defaultText }
                alert.addAction(UIAlertAction(title: "Hủy", style: .cancel) { _ in completionHandler(nil) })
                alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                    completionHandler(alert.textFields?.first?.text)
                })
                root.present(alert, animated: true)
            }
        }
    }
}
