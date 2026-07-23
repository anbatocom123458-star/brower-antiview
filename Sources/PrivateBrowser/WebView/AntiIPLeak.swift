import Foundation

/// Các script JS chặn rò IP qua WebRTC và dọn dẹp console.
///
/// LƯU Ý QUAN TRỌNG VỀ THIẾT KẾ (đọc trước khi thêm lại bất kỳ kỹ thuật "chống dấu
/// vân tay" nào): bản trước của file này từng giả mạo navigator.platform, làm rỗng
/// navigator.plugins/mimeTypes, làm nhiễu canvas/audio bằng số ngẫu nhiên, và cố định
/// hardwareConcurrency/deviceMemory về cùng một giá trị cho MỌI người dùng. Hậu quả là
/// Cloudflare Turnstile, reCAPTCHA v3 và các hệ thống chống bot tương tự liên tục bắt
/// xác minh "tôi không phải robot" — vì chính các script đó tạo ra những tín hiệu bot
/// kinh điển:
///   - plugins rỗng trong khi userAgent tự nhận là Safari/Chrome thật (trình duyệt
///     thật luôn có sẵn plugin PDF mặc định)
///   - navigator.platform mâu thuẫn với userAgent gốc chưa bị đổi
///   - canvas cho kết quả khác nhau giữa 2 lần gọi liên tiếp trên cùng một trang (do
///     Math.random() trong fillText) — một phép thử đối chiếu canvas 2 lần sẽ lộ ngay
///   - hàng loạt người dùng khác nhau cùng báo cáo đúng một cấu hình phần cứng —
///     dễ nhận diện theo cụm hơn là để lộ phần cứng thật của từng máy
/// Giả mạo không nhất quán luôn tệ hơn không giả mạo gì: nó không ẩn danh tính, nó
/// dán nhãn "đây là trình duyệt tự động" lên mọi hệ thống chấm điểm rủi ro. Vì vậy,
/// mặc định của app giờ **không** đụng vào bất kỳ API nhận diện nào — trình duyệt
/// trông và hoạt động giống hệt một WKWebView bình thường, đúng như mọi trình duyệt
/// khác trên máy. Việc ẩn danh thật sự chỉ có thể đến từ việc không lưu dữ liệu
/// (nonPersistent data store — xem BrowserView.makeUIView) và không định tuyến qua
/// máy chủ trung gian, không phải từ việc giả vờ là người khác.
struct AntiIPLeak {
    /// Chặn WebRTC/Geolocation/Battery/Notification — đây là những API có thể làm rò
    /// rỉ thông tin (IP nội bộ qua WebRTC ICE candidate, vị trí GPS thật...) mà việc
    /// chặn chúng KHÔNG tạo ra mâu thuẫn nhận diện nào: một trình duyệt từ chối quyền
    /// vị trí/hoàn toàn không hỗ trợ WebRTC là chuyện hoàn toàn bình thường và phổ
    /// biến, không phải tín hiệu bot.
    static func blockScript(blockWebRTC: Bool) -> String {
        guard blockWebRTC else {
            return "(function() { 'use strict'; try { console.debug = function(){}; } catch (e) {} })();"
        }
        return """
        (function() {
            'use strict';
            try {
                var noop = function() {};
                if (window.RTCPeerConnection) { window.RTCPeerConnection = noop; }
                if (window.webkitRTCPeerConnection) { window.webkitRTCPeerConnection = noop; }
                if (window.RTCSessionDescription) { window.RTCSessionDescription = noop; }
                if (window.RTCIceCandidate) { window.RTCIceCandidate = noop; }
                if (navigator.geolocation) {
                    navigator.geolocation.getCurrentPosition = function(success, error) {
                        if (error) error({ code: 1, message: 'Geolocation denied' });
                    };
                    navigator.geolocation.watchPosition = function(success, error) {
                        if (error) error({ code: 1, message: 'Geolocation denied' });
                        return 0;
                    };
                }
                if (navigator.getBattery) {
                    navigator.getBattery = function() {
                        return Promise.reject(new Error('Battery API disabled'));
                    };
                }
                if (window.Notification) {
                    window.Notification.requestPermission = function() {
                        return Promise.resolve('denied');
                    };
                }
            } catch (e) {}
            try { console.debug = function(){}; } catch (e) {}
        })();
        """
    }

    /// Xoá sạch mọi iframe hiện có và theo dõi iframe mới được chèn động, tự xoá liên tục.
    static let iframeBlockScript = """
    (function() {
        try {
            function removeIframes(root) {
                if (!root || !root.getElementsByTagName) { return; }
                var iframes = root.getElementsByTagName('iframe');
                for (var i = iframes.length - 1; i >= 0; i--) {
                    try { iframes[i].parentNode.removeChild(iframes[i]); } catch (e) {}
                }
            }
            removeIframes(document);
            var observer = new MutationObserver(function(mutations) {
                mutations.forEach(function(mutation) {
                    mutation.addedNodes.forEach(function(node) {
                        if (node.tagName === 'IFRAME') {
                            try { node.parentNode.removeChild(node); } catch (e) {}
                        } else {
                            removeIframes(node);
                        }
                    });
                });
            });
            if (document.body) {
                observer.observe(document.body, { childList: true, subtree: true });
            } else {
                document.addEventListener('DOMContentLoaded', function() {
                    removeIframes(document);
                    observer.observe(document.body, { childList: true, subtree: true });
                });
            }
        } catch (e) {}
    })();
    """

    /// Tên message handler dùng để nhận báo lỗi JS runtime từ WebView (khớp với
    /// `add(_:name:)` gọi trong BrowserView.Coordinator).
    static let jsErrorHandlerName = "privateBrowserJSError"

    /// Bắt các lỗi JavaScript không được xử lý (uncaught exception) và các Promise bị
    /// reject nhưng không có .catch — đây chính là loại lỗi kiểu "Application error:
    /// a client-side exception has occurred" mà nhiều trang React/Next.js (như
    /// DuckDuckGo) tự vẽ ra để thay thế trang trắng khi hydrate lỗi. WKNavigationDelegate
    /// không nhìn thấy loại lỗi này (trang đã "tải xong" theo góc nhìn mạng), nên nếu
    /// không có script này, app sẽ chỉ hiện màn hình đen im lặng, không có nút Thử lại.
    /// Inject riêng, độc lập với blockScript, để không phụ thuộc cờ chống fingerprint.
    static let jsErrorReportScript = """
    (function() {
        try {
            function report(message) {
                try {
                    if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.\(jsErrorHandlerName)) {
                        window.webkit.messageHandlers.\(jsErrorHandlerName).postMessage(String(message).slice(0, 500));
                    }
                } catch (e) {}
            }
            window.addEventListener('error', function(event) {
                var msg = (event && event.message) ? event.message : 'Lỗi JavaScript không xác định';
                report(msg);
            });
            window.addEventListener('unhandledrejection', function(event) {
                var reason = event && event.reason;
                var msg = (reason && reason.message) ? reason.message : String(reason || 'Promise bị từ chối không rõ lý do');
                report(msg);
            });
        } catch (e) {}
    })();
    """
}
