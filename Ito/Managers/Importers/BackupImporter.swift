import Foundation

public struct ImportedBackup: Sendable {
    public let categories: [LibraryCategory]
    public let items: [LibraryItem]
    public let links: [ItemCategoryLink]
    public let history: [ReadingHistoryRecord]
    public let preferences: [AppPreference]

    nonisolated public init(
        categories: [LibraryCategory] = [],
        items: [LibraryItem] = [],
        links: [ItemCategoryLink] = [],
        history: [ReadingHistoryRecord] = [],
        preferences: [AppPreference] = []
    ) {
        self.categories = categories
        self.items = items
        self.links = links
        self.history = history
        self.preferences = preferences
    }
}

public protocol BackupImporter: Sendable {
    /// Tests if this importer can handle this specific file extension or magic bytes
    func canHandle(url: URL) -> Bool

    /// Parses the file and standardizes it into the Ito format
    func parse(url: URL) async throws -> ImportedBackup
}
