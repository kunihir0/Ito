import Foundation
import Combine

public protocol ProgressTracking: ObservableObject {
    var readChapters: [String: Set<String>] { get }
    var readChapterNumbers: [String: Set<Float>] { get }
    var lastReadChapter: [String: String] { get }

    func markAsRead(mangaId: String, chapterId: String, chapterNum: Float?)
    func markAsWatched(animeId: String, episodeId: String, episodeNum: Float?)
    func isRead(mangaId: String, chapterId: String, chapterNum: Float?) -> Bool
    func markReadUpTo(mangaId: String, maxChapterNum: Float)
    func getLastRead(mangaId: String) -> String?
}
