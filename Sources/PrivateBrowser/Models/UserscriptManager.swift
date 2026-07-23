import Foundation
import WebKit

/// Quản lý Userscript — cho phép người dùng dán code JS tự chạy trên trang,
/// tương tự Tampermonkey nhưng dành cho iOS (giới hạn WKWebView).
final class UserscriptManager: ObservableObject {
    @Published var scripts: [Userscript] = []
    @Published var showEditor = false
    @Published var editingScript: Userscript?

    static let shared = UserscriptManager()
    private let storageKey = "userscripts.storage"

    init() {
        loadScripts()
    }

    /// Thêm script mới
    func addScript(_ script: Userscript) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index] = script
        } else {
            scripts.append(script)
        }
        saveScripts()
    }

    /// Xóa script
    func removeScript(_ script: Userscript) {
        scripts.removeAll { $0.id == script.id }
        saveScripts()
    }

    /// Bật/tắt script
    func toggleScript(_ script: Userscript) {
        if let index = scripts.firstIndex(where: { $0.id == script.id }) {
            scripts[index].isEnabled.toggle()
            saveScripts()
        }
    }

    /// Lấy danh sách script đang bật, khớp với URL hiện tại
    func activeScripts(for url: URL) -> [Userscript] {
        scripts.filter { $0.isEnabled && $0.matchesURL(url) }
    }

    /// Tạo WKUserScript từ danh sách script aktiv cho URL
    func userScripts(for url: URL) -> [WKUserScript] {
        activeScripts(for: url).compactMap { script -> WKUserScript? in
            guard let source = script.source else { return nil }
            let isDocumentEnd = script.runAt == .documentEnd
            return WKUserScript(
                source: source,
                injectionTime: isDocumentEnd ? .atDocumentEnd : .atDocumentStart,
                forMainFrameOnly: script.runInFrames == .top
            )
        }
    }

    func saveScripts() {
        if let data = try? JSONEncoder().encode(scripts) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func loadScripts() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Userscript].self, from: data) else {
            return
        }
        scripts = decoded
    }
}

struct Userscript: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var source: String?
    var isEnabled: Bool
    var runAt: InjectionTime
    var runInFrames: FrameTarget
    var matchPatterns: [String]
    var createdAt: Date
    var updatedAt: Date

    enum InjectionTime: String, Codable {
        case documentStart = "document_start"
        case documentEnd = "document_end"
    }

    enum FrameTarget: String, Codable {
        case top = "top"
        case all = "all"
    }

    init(
        id: UUID = UUID(),
        name: String,
        description: String = "",
        source: String? = nil,
        isEnabled: Bool = true,
        runAt: InjectionTime = .documentEnd,
        runInFrames: FrameTarget = .top,
        matchPatterns: [String] = ["*://*/*"],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.source = source
        self.isEnabled = isEnabled
        self.runAt = runAt
        self.runInFrames = runInFrames
        self.matchPatterns = matchPatterns
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    /// Kiểm tra URL có khớp với pattern không
    func matchesURL(_ url: URL) -> Bool {
        guard let urlString = url.absoluteString.lowercased() as String? else { return false }
        for pattern in matchPatterns {
            let regexPattern = pattern
                .replacingOccurrences(of: ".", with: "\\.")
                .replacingOccurrences(of: "*", with: ".*")
                .replacingOccurrences(of: "?", with: "\\?")
            if urlString.range(of: regexPattern, options: .regularExpression) != nil {
                return true
            }
        }
        return matchPatterns.isEmpty
    }
}
