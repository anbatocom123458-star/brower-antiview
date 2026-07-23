import Foundation

/// Quản lý Quick Actions — trang gần đây, thường xuyên truy cập, shortcut tùy chỉnh.
final class QuickActionManager: ObservableObject {
    @Published var recentSites: [QuickAction] = []
    @Published var frequentSites: [QuickAction] = []
    @Published var customShortcuts: [QuickAction] = []

    static let shared = QuickActionManager()

    private enum Keys {
        static let recentSites = "quickaction.recent"
        static let frequentSites = "quickaction.frequent"
        static let customShortcuts = "quickaction.custom"
    }

    private let maxRecent = 10
    private let maxFrequent = 8

    init() {
        load()
    }

    func recordVisit(url: String, title: String) {
        let normalizedURL = url.lowercased()

        // Update frequent sites
        if let index = frequentSites.firstIndex(where: { $0.url.lowercased() == normalizedURL }) {
            frequentSites[index].visitCount += 1
            frequentSites[index].lastVisited = Date()
        } else {
            let action = QuickAction(title: title, url: url, visitCount: 1, lastVisited: Date())
            frequentSites.append(action)
        }
        frequentSites.sort { $0.visitCount > $1.visitCount }
        if frequentSites.count > maxFrequent {
            frequentSites = Array(frequentSites.prefix(maxFrequent))
        }

        // Update recent sites
        recentSites.removeAll { $0.url.lowercased() == normalizedURL }
        let action = QuickAction(title: title, url: url)
        recentSites.insert(action, at: 0)
        if recentSites.count > maxRecent {
            recentSites = Array(recentSites.prefix(maxRecent))
        }

        save()
    }

    func addCustomShortcut(_ shortcut: QuickAction) {
        if let index = customShortcuts.firstIndex(where: { $0.id == shortcut.id }) {
            customShortcuts[index] = shortcut
        } else {
            customShortcuts.append(shortcut)
        }
        save()
    }

    func removeCustomShortcut(_ shortcut: QuickAction) {
        customShortcuts.removeAll { $0.id == shortcut.id }
        save()
    }

    func removeRecent(_ action: QuickAction) {
        recentSites.removeAll { $0.id == action.id }
        save()
    }

    private func save() {
        saveTo(key: Keys.recentSites, items: recentSites)
        saveTo(key: Keys.frequentSites, items: frequentSites)
        saveTo(key: Keys.customShortcuts, items: customShortcuts)
    }

    private func load() {
        recentSites = loadFrom(key: Keys.recentSites)
        frequentSites = loadFrom(key: Keys.frequentSites)
        customShortcuts = loadFrom(key: Keys.customShortcuts)
    }

    private func saveTo(key: String, items: [QuickAction]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    private func loadFrom(key: String) -> [QuickAction] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([QuickAction].self, from: data) else {
            return []
        }
        return decoded
    }
}

struct QuickAction: Codable, Identifiable {
    let id: UUID
    var title: String
    var url: String
    var icon: String
    var visitCount: Int
    var lastVisited: Date?
    var isCustom: Bool

    init(id: UUID = UUID(), title: String, url: String, icon: String = "globe", visitCount: Int = 0, lastVisited: Date? = nil, isCustom: Bool = false) {
        self.id = id
        self.title = title
        self.url = url
        self.icon = icon
        self.visitCount = visitCount
        self.lastVisited = lastVisited
        self.isCustom = isCustom
    }
}
