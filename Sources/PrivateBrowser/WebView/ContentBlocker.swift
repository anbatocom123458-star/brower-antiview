import Foundation
@preconcurrency import WebKit

/// Chặn quảng cáo & trình theo dõi ở tầng network bằng WKContentRuleList (định dạng
/// Content Blocker chuẩn của Safari/WebKit) — hiệu quả và nhẹ hơn nhiều so với chỉ
/// dùng JavaScript, vì các request bị chặn trước khi tải về, không tốn băng thông.
enum ContentBlocker {
    private static let identifier = "com.privatebrowser.adblock.v1"
    private static let queue = DispatchQueue(label: "com.privatebrowser.contentblocker")
    private static var cachedRuleList: WKContentRuleList?
    private static var cachedRuleJSON: String?
    private static var isCompiling = false
    private static var pendingHandlers: [(WKContentRuleList?) -> Void] = []

    /// Danh sách rút gọn các domain quảng cáo/theo dõi phổ biến nhất.
    private static let blockedDomains: [String] = [
        "doubleclick.net", "googlesyndication.com", "googleadservices.com",
        "google-analytics.com", "googletagmanager.com", "googletagservices.com",
        "adservice.google.com", "facebook.net", "connect.facebook.net",
        "ads-twitter.com", "analytics.twitter.com", "amazon-adsystem.com",
        "adsrvr.org", "adnxs.com", "criteo.com", "criteo.net", "taboola.com",
        "outbrain.com", "scorecardresearch.com", "quantserve.com",
        "hotjar.com", "mixpanel.com", "segment.io", "segment.com",
        "moatads.com", "adform.net", "pubmatic.com", "rubiconproject.com",
        "openx.net", "bidswitch.net", "casalemedia.com", "smartadserver.com",
        "yieldmo.com", "media.net", "mgid.com", "revcontent.com",
        "chartbeat.com", "newrelic.com", "sentry.io", "appsflyer.com",
        "branch.io", "adjust.com", "kochava.com", "clicktale.net",
        "mc.yandex.ru", "yandex.ru", "bat.bing.com", "clarity.ms",
        "hs-analytics.net", "hubspot.com", "intercom.io", "fullstory.com"
    ]

    private static func buildRuleJSON() -> String {
        let rules = blockedDomains.map { domain -> [String: Any] in
            [
                "trigger": ["url-filter": ".*", "if-domain": ["*\(domain)"]],
                "action": ["type": "block"]
            ]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: rules),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return json
    }

    /// Biên dịch (một lần, có cache trong RAM cho phiên hiện tại) và trả về rule list
    /// sẵn sàng để gắn vào `WKUserContentController` của một WKWebView.
    static func ruleList(completion: @escaping (WKContentRuleList?) -> Void) {
        queue.sync {
            if let cached = cachedRuleList {
                completion(cached)
                return
            }
            pendingHandlers.append(completion)
            guard !isCompiling else { return }
            isCompiling = true

            if cachedRuleJSON == nil {
                cachedRuleJSON = buildRuleJSON()
            }

            let json = cachedRuleJSON
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: identifier,
                encodedContentRuleList: json
            ) { ruleList, error in
                queue.sync {
                    isCompiling = false
                    if let error {
                        print("⚠️ Không thể biên dịch bộ chặn quảng cáo: \(error.localizedDescription)")
                    }
                    cachedRuleList = ruleList
                    let handlers = pendingHandlers
                    pendingHandlers = []
                    handlers.forEach { $0(ruleList) }
                }
            }
        }
    }
}
