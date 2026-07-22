import SwiftUI
import WebKit
import UIKit

/// Bọc WKWebView cho SwiftUI. So với bản cũ, bản này:
/// - Không còn so sánh URL ở mỗi updateUIView (nguồn gây loop reload khi gõ URL).
/// - Xử lý đầy đủ JS alert/confirm/prompt để trang không bị "treo" khi gọi window.alert.
/// - Chặn scheme lạ (tel:, mailto:...) bằng cách chuyển cho hệ thống xử lý, không crash.
/// - Dọn dẹp KVO observer đúng cách trong deinit — tránh rò nhớ.
struct BrowserView: UIViewRepresentable {
    @ObservedObject var controller: BrowserController
    @ObservedObject var zoomManager: ZoomManager
    var blockWebRTC: Bool
    var blockIframe: Bool
    var blockFingerprint: Bool
    var desktopMode: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(controller: controller, zoomManager: zoomManager)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = .nonPersistent()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        let ucc = config.userContentController
        if blockWebRTC || blockFingerprint {
            ucc.addUserScript(WKUserScript(
                source: AntiIPLeak.blockScript(blockWebRTC: blockWebRTC, spoofFingerprint: blockFingerprint),
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
        zoomManager.apply(to: webView)
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.navigationDelegate = nil
        webView.uiDelegate = nil
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        private weak var controller: BrowserController?
        private weak var zoomManager: ZoomManager?

        private var progressObservation: NSKeyValueObservation?
        private var loadingObservation: NSKeyValueObservation?
        private var backObservation: NSKeyValueObservation?
        private var forwardObservation: NSKeyValueObservation?
        private var titleObservation: NSKeyValueObservation?

        init(controller: BrowserController, zoomManager: ZoomManager) {
            self.controller = controller
            self.zoomManager = zoomManager
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
                decisionHandler(.allow)
                return
            }
            // Scheme đặc biệt (tel:, mailto:, sms:, facetime:...) -> chuyển cho hệ thống xử lý.
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
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

        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            // Trang mở "cửa sổ mới" (target=_blank) -> mở luôn trong webView hiện tại
            // để giữ đúng chế độ riêng tư (không tạo webView con không kiểm soát được).
            if let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
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
