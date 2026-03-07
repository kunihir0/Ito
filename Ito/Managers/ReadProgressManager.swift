import Combine
import Foundation
import SwiftUI

/// Manages reading progress, tracking which chapters have been read,
/// and the last read chapter per manga.
public class ReadProgressManager: ObservableObject {
    public static let shared = ReadProgressManager()

    // keys: manga ID, values: set of chapter IDs
    @Published public private(set) var readChapters: [String: Set<String>] = [:]

    // keys: manga ID, values: last read chapter ID
    @Published public private(set) var lastReadChapter: [String: String] = [:]

    private let readChaptersKey = "Ito.ReadChapters"
    private let lastReadChapterKey = "Ito.LastReadChapter"

    private init() {
        loadProgress()
    }

    private func loadProgress() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: readChaptersKey),
            let decoded = try? JSONDecoder().decode([String: Set<String>].self, from: data)
        {
            self.readChapters = decoded
        }

        if let data = defaults.data(forKey: lastReadChapterKey),
            let decoded = try? JSONDecoder().decode([String: String].self, from: data)
        {
            self.lastReadChapter = decoded
        }
    }

    private func saveProgress() {
        let defaults = UserDefaults.standard
        if let encoded = try? JSONEncoder().encode(readChapters) {
            defaults.set(encoded, forKey: readChaptersKey)
        }
        if let encoded = try? JSONEncoder().encode(lastReadChapter) {
            defaults.set(encoded, forKey: lastReadChapterKey)
        }
    }

    /// Mark a chapter as read
    public func markAsRead(mangaId: String, chapterId: String) {
        if readChapters[mangaId] == nil {
            readChapters[mangaId] = []
        }
        readChapters[mangaId]?.insert(chapterId)
        lastReadChapter[mangaId] = chapterId

        saveProgress()
    }

    /// Check if a chapter is read
    public func isRead(mangaId: String, chapterId: String) -> Bool {
        return readChapters[mangaId]?.contains(chapterId) ?? false
    }

    /// Get the last read chapter ID for a manga
    public func getLastRead(mangaId: String) -> String? {
        return lastReadChapter[mangaId]
    }
}
