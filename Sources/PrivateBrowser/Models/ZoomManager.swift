import SwiftUI
@preconcurrency import WebKit
import Combine

/// Quản lý mức zoom trang web (25% - 200%).
/// Chỉ inject JavaScript khi giá trị thực sự thay đổi để tránh gọi evaluateJavaScript
/// liên tục ở mỗi lần SwiftUI re-render — giúp trang web mượt hơn, đỡ tốn pin (tối ưu ổn định).
final class ZoomManager: ObservableObject {
    let minZoom: CGFloat = 0.25
    let maxZoom: CGFloat = 2.0
    let step: CGFloat = 0.05

    @Published var currentZoom: CGFloat = 1.0 {
        didSet {
            let clamped = min(max(currentZoom, minZoom), maxZoom)
            if clamped != currentZoom {
                currentZoom = clamped
            }
        }
    }

    private var lastAppliedZoom: CGFloat?

    func reset() {
        currentZoom = 1.0
    }

    /// Áp dụng zoom lên webView hiện tại. `force` dùng khi vừa load xong trang mới.
    func apply(to webView: WKWebView, force: Bool = false) {
        guard force || lastAppliedZoom != currentZoom else { return }
        lastAppliedZoom = currentZoom
        let zoomValue = String(format: "%.2f", currentZoom)
        let js = """
        try {
            document.documentElement.style.setProperty('zoom', '\(zoomValue)');
        } catch (e) {}
        """
        webView.evaluateJavaScript(js, completionHandler: nil)
    }
}
