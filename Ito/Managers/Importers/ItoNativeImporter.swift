import Foundation
import GRDB

public struct ItoNativeImporter: BackupImporter {
    public func canHandle(url: URL) -> Bool {
        return url.pathExtension.lowercased() == "itobackup"
    }

    public func parse(url: URL) async throws -> ImportedBackup {
        let backupPool = try DatabasePool(path: url.path)

        // Ensure atomic reading of the backup representation
        return try await backupPool.read { db in
            let categories = try LibraryCategory.fetchAll(db)
            let items = try LibraryItem.fetchAll(db)
            let links = try ItemCategoryLink.fetchAll(db)

            let history: [ReadingHistoryRecord]
            if try db.tableExists("readingHistory") {
                history = try ReadingHistoryRecord.fetchAll(db)
            } else {
                history = []
            }

            let preferences: [AppPreference]
            if try db.tableExists("appPreference") {
                preferences = try AppPreference.fetchAll(db)
            } else {
                preferences = []
            }

            return ImportedBackup(
                categories: categories,
                items: items,
                links: links,
                history: history,
                preferences: preferences
            )
        }
    }
}
