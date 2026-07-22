import Foundation

/// Công cụ tìm kiếm mặc định — có thể chọn trong Menu riêng.
enum SearchEngine: String, CaseIterable, Identifiable {
    case duckduckgo
    case google
    case bing
    case ecosia

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .duckduckgo: return "DuckDuckGo"
        case .google: return "Google"
        case .bing: return "Bing"
        case .ecosia: return "Ecosia"
        }
    }

    var icon: String {
        switch self {
        case .duckduckgo: return "shield.checkerboard"
        case .google: return "magnifyingglass.circle"
        case .bing: return "b.circle"
        case .ecosia: return "leaf.circle"
        }
    }

    var homeURL: String {
        switch self {
        case .duckduckgo: return "https://duckduckgo.com"
        case .google: return "https://www.google.com"
        case .bing: return "https://www.bing.com"
        case .ecosia: return "https://www.ecosia.org"
        }
    }

    func searchURL(for query: String) -> String {
        let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        switch self {
        case .duckduckgo: return "https://duckduckgo.com/?q=\(encoded)"
        case .google: return "https://www.google.com/search?q=\(encoded)"
        case .bing: return "https://www.bing.com/search?q=\(encoded)"
        case .ecosia: return "https://www.ecosia.org/search?q=\(encoded)"
        }
    }
}

/// Đọc cài đặt trực tiếp từ UserDefaults — dùng ở các nơi không phải SwiftUI View
/// (ví dụ BrowserController, AntiIPLeak) nên không thể dùng @AppStorage.
/// Key phải khớp với SettingsKey để đồng bộ với các màn hình cấu hình.
struct BrowserSettingsStore {
    static var searchEngine: SearchEngine {
        let raw = UserDefaults.standard.string(forKey: SettingsKey.searchEngine) ?? SearchEngine.duckduckgo.rawValue
        return SearchEngine(rawValue: raw) ?? .duckduckgo
    }

    static var homeURL: String { searchEngine.homeURL }

    static func searchURL(for query: String) -> String {
        searchEngine.searchURL(for: query)
    }

    static var useHTTP: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.defaultHTTP)
    }

    static var blockWebRTC: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.blockWebRTC) == nil
            ? true
            : UserDefaults.standard.bool(forKey: SettingsKey.blockWebRTC)
    }

    static var blockIframe: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.blockIframe) == nil
            ? true
            : UserDefaults.standard.bool(forKey: SettingsKey.blockIframe)
    }

    static var blockFingerprint: Bool {
        UserDefaults.standard.object(forKey: SettingsKey.blockFingerprint) == nil
            ? true
            : UserDefaults.standard.bool(forKey: SettingsKey.blockFingerprint)
    }

    static var desktopMode: Bool {
        UserDefaults.standard.bool(forKey: SettingsKey.desktopMode)
    }
}
