import Foundation
import SwiftUI

/// Quản lý bookmark/yêu thích — lưu URL + title + favicon, tổ chức theo folder.
final class FavoriteManager: ObservableObject {
    @Published var favorites: [Favorite] = []
    @Published var searchQuery: String = ""

    static let shared = FavoriteManager()
    private let storageKey = "favorites.storage"

    init() {
        loadFavorites()
    }

    var filteredFavorites: [Favorite] {
        guard !searchQuery.isEmpty else { return favorites }
        let query = searchQuery.lowercased()
        return favorites.filter { $0.title.lowercased().contains(query) || $0.url.lowercased().contains(query) }
    }

    var folders: [String] {
        Array(Set(favorites.compactMap(\.folder))).sorted()
    }

    func favorites(in folder: String?) -> [Favorite] {
        favorites.filter { $0.folder == folder }
    }

    func addFavorite(_ favorite: Favorite) {
        if let index = favorites.firstIndex(where: { $0.id == favorite.id }) {
            favorites[index] = favorite
        } else {
            favorites.append(favorite)
        }
        saveFavorites()
    }

    func removeFavorite(_ favorite: Favorite) {
        favorites.removeAll { $0.id == favorite.id }
        saveFavorites()
    }

    func updateFavorite(_ favorite: Favorite) {
        if let index = favorites.firstIndex(where: { $0.id == favorite.id }) {
            favorites[index] = favorite
            saveFavorites()
        }
    }

    func exportFavorites() -> Data? {
        try? JSONEncoder().encode(favorites)
    }

    func importFavorites(from data: Data) {
        guard let decoded = try? JSONDecoder().decode([Favorite].self, from: data) else { return }
        for fav in decoded {
            if !favorites.contains(where: { $0.url == fav.url }) {
                favorites.append(fav)
            }
        }
        saveFavorites()
    }

    private func saveFavorites() {
        if let data = try? JSONEncoder().encode(favorites) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadFavorites() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([Favorite].self, from: data) else {
            return
        }
        favorites = decoded
    }
}

struct Favorite: Codable, Identifiable, Equatable {
    let id: UUID
    var title: String
    var url: String
    var favicon: String?
    var folder: String?
    var createdAt: Date

    init(id: UUID = UUID(), title: String, url: String, favicon: String? = nil, folder: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.url = url
        self.favicon = favicon
        self.folder = folder
        self.createdAt = createdAt
    }
}
