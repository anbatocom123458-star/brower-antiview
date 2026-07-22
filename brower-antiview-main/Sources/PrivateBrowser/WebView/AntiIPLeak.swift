import Foundation

/// Các script JS chặn rò IP / fingerprint / iframe. Có thể bật/tắt riêng từng nhóm
/// trong Menu (blockWebRTC, blockFingerprint, blockIframe) để người dùng tự tuỳ biến
/// mức độ chặn — tránh vài trang bị lỗi vì bị chặn quá tay.
struct AntiIPLeak {
    /// Script chặn WebRTC / Geolocation / Battery API và, nếu `spoofFingerprint`
    /// được bật, giả mạo thêm userAgent/canvas/WebGL để chống dấu vân tay trình duyệt.
    static func blockScript(blockWebRTC: Bool, spoofFingerprint: Bool) -> String {
        var parts: [String] = []

        if blockWebRTC {
            parts.append("""
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
            """)
        }

        if spoofFingerprint {
            parts.append("""
            try {
                Object.defineProperty(navigator, 'platform', { get: function() { return 'iPhone'; } });
                Object.defineProperty(screen, 'colorDepth', { get: function() { return 24; } });

                var originalGetContext = HTMLCanvasElement.prototype.getContext;
                HTMLCanvasElement.prototype.getContext = function(type) {
                    var ctx = originalGetContext.apply(this, arguments);
                    if (ctx && type === '2d' && ctx.fillText) {
                        var originalFillText = ctx.fillText;
                        ctx.fillText = function() {
                            ctx.save();
                            ctx.translate(Math.random() * 0.2, Math.random() * 0.2);
                            originalFillText.apply(ctx, arguments);
                            ctx.restore();
                        };
                    }
                    return ctx;
                };

                if (window.WebGLRenderingContext) {
                    var getParameter = WebGLRenderingContext.prototype.getParameter;
                    WebGLRenderingContext.prototype.getParameter = function(parameter) {
                        if (parameter === 37445) return 'Apple Inc.';
                        if (parameter === 37446) return 'Apple GPU';
                        return getParameter.call(this, parameter);
                    };
                }
            } catch (e) {}
            """)
        }

        parts.append("try { console.debug = function(){}; } catch (e) {}")

        return "(function() { 'use strict'; " + parts.joined(separator: "\n") + " })();"
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
}
