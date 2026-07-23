import Foundation

/// Quản lý bookmark/tổng hợp — lưu URL yêu thích, đồng bộ UserDefaults.
/// v4.1: Hỗ trợ bookmark, recently closed tabs, và site permissions.
final class BookmarkManager: ObservableObject {
    @Published var bookmarks: [BookmarkItem] = []
    @Published var recentlyClosed: [ClosedTab] = []

    static let shared = BookmarkManager()

    private let maxRecentlyClosed = 20

    private enum Keys {
        static let bookmarks = "bookmark.items"
        static let recentlyClosed = "bookmark.recentlyClosed"
    }

    init() {
        loadBookmarks()
        loadRecentlyClosed()
    }

    // MARK: - Bookmarks

    var bookmarkCount: Int { bookmarks.count }

    func addBookmark(title: String, url: String, favicon: String? = nil) {
        guard !bookmarks.contains(where: { $0.url == url }) else { return }
        let item = BookmarkItem(id: UUID(), title: title, url: url, favicon: favicon, createdAt: Date())
        bookmarks.insert(item, at: 0)
        saveBookmarks()
    }

    func removeBookmark(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        saveBookmarks()
    }

    func isBookmarked(url: String) -> Bool {
        bookmarks.contains { $0.url == url }
    }

    func toggleBookmark(title: String, url: String) {
        if let existing = bookmarks.first(where: { $0.url == url }) {
            removeBookmark(id: existing.id)
        } else {
            addBookmark(title: title, url: url)
        }
    }

    // MARK: - Recently Closed

    func addRecentlyClosed(title: String, url: String) {
        recentlyClosed.removeAll { $0.url == url }
        let tab = ClosedTab(id: UUID(), title: title, url: url, closedAt: Date())
        recentlyClosed.insert(tab, at: 0)
        if recentlyClosed.count > maxRecentlyClosed {
            recentlyClosed = Array(recentlyClosed.prefix(maxRecentlyClosed))
        }
        saveRecentlyClosed()
    }

    func clearRecentlyClosed() {
        recentlyClosed.removeAll()
        saveRecentlyClosed()
    }

    // MARK: - Persistence

    private func saveBookmarks() {
        guard let data = try? JSONEncoder().encode(bookmarks) else { return }
        UserDefaults.standard.set(data, forKey: Keys.bookmarks)
    }

    private func loadBookmarks() {
        guard let data = UserDefaults.standard.data(forKey: Keys.bookmarks),
              let decoded = try? JSONDecoder().decode([BookmarkItem].self, from: data) else { return }
        bookmarks = decoded
    }

    private func saveRecentlyClosed() {
        guard let data = try? JSONEncoder().encode(recentlyClosed) else { return }
        UserDefaults.standard.set(data, forKey: Keys.recentlyClosed)
    }

    private func loadRecentlyClosed() {
        guard let data = UserDefaults.standard.data(forKey: Keys.recentlyClosed),
              let decoded = try? JSONDecoder().decode([ClosedTab].self, from: data) else { return }
        recentlyClosed = decoded
    }
}

struct BookmarkItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let favicon: String?
    let createdAt: Date
}

struct ClosedTab: Identifiable, Codable {
    let id: UUID
    let title: String
    let url: String
    let closedAt: Date
}
