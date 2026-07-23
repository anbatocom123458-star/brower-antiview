import Foundation
@preconcurrency import WebKit

/// Xoá sạch toàn bộ dữ liệu duyệt web: cookie, cache, localStorage, IndexedDB...
/// cả trong website data store mặc định và store không lưu trữ (nonPersistent)
/// mà BrowserView đang dùng.
enum PrivacyManager {
    static func clearAllData(completion: @escaping () -> Void = {}) {
        let types = WKWebsiteDataStore.allWebsiteDataTypes()
        let since = Date(timeIntervalSince1970: 0)
        let group = DispatchGroup()

        group.enter()
        WKWebsiteDataStore.default().removeData(ofTypes: types, modifiedSince: since) {
            group.leave()
        }

        group.enter()
        WKWebsiteDataStore.nonPersistent().removeData(ofTypes: types, modifiedSince: since) {
            group.leave()
        }

        group.enter()
        DispatchQueue.main.async {
            URLCache.shared.removeAllCachedResponses()
            if let cookies = HTTPCookieStorage.shared.cookies {
                cookies.forEach { HTTPCookieStorage.shared.deleteCookie($0) }
            }
            group.leave()
        }

        group.notify(queue: .main) {
            completion()
        }
    }
}
