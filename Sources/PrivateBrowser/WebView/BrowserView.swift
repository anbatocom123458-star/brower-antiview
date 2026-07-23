import SwiftUI
@preconcurrency import WebKit
import UIKit

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
        private var didReportJSErrorForCurrentLoad = false

        init(controller: BrowserController, zoomManager: ZoomManager, userscriptManager: UserscriptManager) {
            self.controller = controller
            self.zoomManager = zoomManager
            self.userscriptManager = userscriptManager
        }

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
                let cleaned = BrowserController.stripTrackingParameters(from: url)
                if cleaned != url {
                    decisionHandler(.cancel)
                    webView.load(URLRequest(url: cleaned, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData))
                    return
                }
                decisionHandler(.allow)
                return
            }

            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        }

        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
            let response = navigationResponse.response as? HTTPURLResponse
            let contentDisposition = response?.value(forHTTPHeaderField: "Content-Disposition") ?? ""

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
