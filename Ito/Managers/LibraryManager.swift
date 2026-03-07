import Combine
import Foundation
import SwiftUI
import ito_runner

public struct LibraryItem: Codable, Identifiable, Hashable {
    public let id: String
    public let title: String
    public let coverUrl: String?
    public let pluginId: String
    public let isAnime: Bool
    
    // We store the raw payload so we can easily instantiate an Anime/Manga object when the user clicks it.
    public let rawPayload: Data
}

public class LibraryManager: ObservableObject {
    public static let shared = LibraryManager()
    
    @Published public private(set) var items: [LibraryItem] = []
    
    private let defaultsKey = "ito_library_items"
    
    private init() {
        loadLibrary()
    }
    
    public func isSaved(id: String) -> Bool {
        return items.contains(where: { $0.id == id })
    }
    
    public func toggleSaveManga(manga: Manga, pluginId: String) {
        if isSaved(id: manga.key) {
            items.removeAll(where: { $0.id == manga.key })
        } else {
            if let payload = try? JSONEncoder().encode(manga) {
                let item = LibraryItem(id: manga.key, title: manga.title, coverUrl: manga.cover, pluginId: pluginId, isAnime: false, rawPayload: payload)
                items.append(item)
            }
        }
        saveLibrary()
    }
    
    public func toggleSaveAnime(anime: Anime, pluginId: String) {
        if isSaved(id: anime.key) {
            items.removeAll(where: { $0.id == anime.key })
        } else {
            if let payload = try? JSONEncoder().encode(anime) {
                let item = LibraryItem(id: anime.key, title: anime.title, coverUrl: anime.cover, pluginId: pluginId, isAnime: true, rawPayload: payload)
                items.append(item)
            }
        }
        saveLibrary()
    }
    
    private func loadLibrary() {
        if let data = UserDefaults.standard.data(forKey: defaultsKey) {
            if let decoded = try? JSONDecoder().decode([LibraryItem].self, from: data) {
                self.items = decoded
            }
        }
    }
    
    private func saveLibrary() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}