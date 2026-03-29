import Combine
import Foundation
import GRDB
import SwiftUI
import ito_runner

// MARK: - PRE-FLIGHT: Preferences

public enum LibraryLayoutStyle: Int {
    case tabbed = 0
    case sectioned = 1
}

public enum UserDefaultsKeys {
    public static let legacyLibraryItems = "ito_library_items"
    public static let backupLibraryItems = "ito_library_items_backup"
    public static let layoutStyle = "ito_library_layout_style"
    public static let alwaysShowCategoryPicker = "ito_always_show_category_picker"
}

// MARK: - PHASE 1: Models

public struct LibraryCategory: Codable, Identifiable, Hashable, Sendable, FetchableRecord, PersistableRecord {
    public var id: String
    public var name: String
    public var sortOrder: Int
    public var isSystemCategory: Bool
    public var createdAt: Date

    public init(id: String = UUID().uuidString, name: String, sortOrder: Int, isSystemCategory: Bool = false, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.isSystemCategory = isSystemCategory
        self.createdAt = createdAt
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let name = Column(CodingKeys.name)
        public static let sortOrder = Column(CodingKeys.sortOrder)
        public static let isSystemCategory = Column(CodingKeys.isSystemCategory)
        public static let createdAt = Column(CodingKeys.createdAt)
    }
}

// Ensure decoding from legacy JSON still works seamlessly while bridging to SQLite
public struct LibraryItem: Codable, Identifiable, Hashable, Sendable, FetchableRecord, PersistableRecord {
    public let id: String
    public let title: String
    public let coverUrl: String?
    public let pluginId: String
    public let isAnime: Bool
    public var pluginType: PluginType?

    // We store the raw payload so we can easily instantiate an Anime/Manga/Novel object when the user clicks it.
    public let rawPayload: Data

    // AniList Tracker Mapping
    public var anilistId: Int?

    public var effectiveType: PluginType {
        if let pt = pluginType { return pt }
        return isAnime ? .anime : .manga
    }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let title = Column(CodingKeys.title)
        public static let coverUrl = Column(CodingKeys.coverUrl)
        public static let pluginId = Column(CodingKeys.pluginId)
        public static let isAnime = Column(CodingKeys.isAnime)
        public static let pluginType = Column(CodingKeys.pluginType)
        public static let rawPayload = Column(CodingKeys.rawPayload)
        public static let anilistId = Column(CodingKeys.anilistId)
    }

    public static func == (lhs: LibraryItem, rhs: LibraryItem) -> Bool {
        return lhs.id == rhs.id && lhs.anilistId == rhs.anilistId
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(anilistId)
    }
}

public struct ItemCategoryLink: Codable, Hashable, Sendable, FetchableRecord, PersistableRecord {
    public let itemId: String
    public let categoryId: String
    public let addedAt: Date

    public init(itemId: String, categoryId: String, addedAt: Date = Date()) {
        self.itemId = itemId
        self.categoryId = categoryId
        self.addedAt = addedAt
    }

    public enum Columns {
        public static let itemId = Column(CodingKeys.itemId)
        public static let categoryId = Column(CodingKeys.categoryId)
        public static let addedAt = Column(CodingKeys.addedAt)
    }
}

// MARK: - Associations
extension LibraryItem {
    static let itemCategoryLinks = hasMany(ItemCategoryLink.self)
    static let categories = hasMany(LibraryCategory.self, through: itemCategoryLinks, using: ItemCategoryLink.category)
}

extension LibraryCategory {
    static let itemCategoryLinks = hasMany(ItemCategoryLink.self)
    static let items = hasMany(LibraryItem.self, through: itemCategoryLinks, using: ItemCategoryLink.item)
}

extension ItemCategoryLink {
    static let item = belongsTo(LibraryItem.self)
    static let category = belongsTo(LibraryCategory.self)
}
