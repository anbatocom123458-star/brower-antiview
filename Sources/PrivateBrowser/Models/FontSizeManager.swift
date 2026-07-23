import Foundation
import WebKit

/// Quản lý cỡ chữ trang web — zoom font size độc lập với page zoom.
/// v4.1: Font size adjust từ toolbar với nút +/- nhanh.
final class FontSizeManager: ObservableObject {
    @Published var currentScale: Double = 1.0

    static let shared = FontSizeManager()

    private let minScale: Double = 0.6
    private let maxScale: Double = 2.0
    private let step: Double = 0.1

    func increase() {
        currentScale = min(maxScale, currentScale + step)
    }

    func decrease() {
        currentScale = max(minScale, currentScale - step)
    }

    func reset() {
        currentScale = 1.0
    }

    func apply(to webView: WKWebView) {
        let js = "document.body.style.fontSize = '\(Int(currentScale * 100))%';"
        webView.evaluateJavaScript(js)
    }
}
