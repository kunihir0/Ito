import SwiftUI
import Nuke
import NukeUI
import ito_runner

struct IdentifiableNovelChapter: Identifiable {
    let id: String
    let chapter: Novel.Chapter
    init(_ chapter: Novel.Chapter) {
        self.id = chapter.key
        self.chapter = chapter
    }
}

struct NovelView: View {
    let runner: ItoRunner
    @State var novel: Novel
    let pluginId: String

    @State private var isLoaded = false
    @State private var errorMessage: String?
    @State private var readingChapter: IdentifiableNovelChapter?

    @State private var showTrackerSearch = false
    @State private var showTrackerEdit = false
    @State private var trackingMedia: AnilistMedia?
    @State private var isDescriptionExpanded = false

    @EnvironmentObject var progressManager: ReadProgressManager
    @ObservedObject var libraryManager = LibraryManager.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header: Cover + Info
                HStack(alignment: .top, spacing: 16) {
                    if let coverURL = novel.cover, let url = URL(string: coverURL) {
                        LazyImage(url: url) { state in
                            if let image = state.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(8)
                                    .clipped()
                            } else if state.error != nil {
                                Color.red.opacity(0.3)
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(8)
                            } else {
                                Color.gray.opacity(0.3)
                                    .frame(width: 100, height: 150)
                                    .cornerRadius(8)
                            }
                        }
                        .processors([.resize(width: 200)])
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(novel.title)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let artist = novel.artist, !artist.isEmpty {
                            Text("Artist: \(artist)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        } else if let authors = novel.authors, !authors.isEmpty {
                            Text("Author: \(authors.joined(separator: ", "))")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            if let status = statusText(for: novel.status) {
                                Text(status)
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }

                            Text(pluginId.capitalized)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.secondary.opacity(0.2))
                                .cornerRadius(4)
                        }

                        // Action Buttons
                        HStack(spacing: 12) {
                            Button(action: {
                                LibraryManager.shared.toggleSaveNovel(novel: novel, pluginId: pluginId)
                            }) {
                                HStack {
                                    Image(systemName: libraryManager.isSaved(id: novel.key) ? "bookmark.fill" : "bookmark")
                                    Text(libraryManager.isSaved(id: novel.key) ? "Saved" : "Save")
                                }
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(6)
                            }

                            // Tracker Sync Button
                            if TrackerManager.shared.isAnilistAuthenticated {
                                Button(action: {
                                    if let existingId = TrackerManager.shared.getAnilistId(for: novel.key) {
                                        // Construct a partial AnilistMedia object
                                        self.trackingMedia = AnilistMedia(id: existingId, title: novel.title, titleRomaji: nil, coverImage: novel.cover, format: "NOVEL", episodes: nil, chapters: nil)
                                    } else {
                                        showTrackerSearch = true
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: TrackerManager.shared.getAnilistId(for: novel.key) != nil ? "checkmark.circle.fill" : "arrow.triangle.2.circlepath")
                                        Text(TrackerManager.shared.getAnilistId(for: novel.key) != nil ? "Tracking" : "Track")
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(TrackerManager.shared.getAnilistId(for: novel.key) != nil ? Color.purple.opacity(0.2) : Color.green.opacity(0.2))
                                    .foregroundColor(TrackerManager.shared.getAnilistId(for: novel.key) != nil ? .purple : .green)
                                    .cornerRadius(6)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(.horizontal)
                .sheet(isPresented: $showTrackerSearch) {
                    TrackerSearchSheet(title: novel.title, isAnime: false) { media, progress in
                        print("Tracked: \(media.title) (ID: \(media.id))")

                        // Link the tracker ID even if not saved in Library
                        TrackerManager.shared.link(localId: novel.key, anilistId: media.id)

                        if let prog = progress, UserDefaults.standard.object(forKey: "Ito.AutoSyncAnilistToLocal") as? Bool ?? true {
                            ReadProgressManager.shared.markReadUpTo(mangaId: novel.key, maxChapterNum: Float(prog))
                        }
                    }
                }
                .sheet(item: $trackingMedia) { media in
                    TrackerDetailsSheet(media: media, onSave: { progress in
                        if let prog = progress, UserDefaults.standard.object(forKey: "Ito.AutoSyncAnilistToLocal") as? Bool ?? true {
                            ReadProgressManager.shared.markReadUpTo(mangaId: novel.key, maxChapterNum: Float(prog))
                        }
                    }, onDelete: {
                        TrackerManager.shared.unlink(localId: novel.key)
                    })
                }

                // Tags
                if let tags = novel.tags, !tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            ForEach(tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.15))
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Description
                if let description = novel.description, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(description)
                            .font(.body)
                            .lineLimit(isDescriptionExpanded ? nil : 3)

                        Text(isDescriptionExpanded ? "Tap to show less" : "Tap to show more")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal)
                    .contentShape(Rectangle()) // Makes the whole VStack tappable
                    .onTapGesture {
                        withAnimation {
                            isDescriptionExpanded.toggle()
                        }
                    }
                }

                Divider()

                // Chapters
                if !isLoaded && errorMessage == nil {
                    ProgressView("Loading Chapters...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else {
                    if let chapters = novel.chapters, !chapters.isEmpty {

                        // Read / Resume Button
                        if let target = resumeReadingChapter {
                            let isResume = progressManager.getLastRead(mangaId: novel.key) != nil
                            Button(action: {
                                self.readingChapter = IdentifiableNovelChapter(target)
                            }) {
                                HStack {
                                    Image(systemName: isResume ? "book.fill" : "play.fill")
                                    Text(isResume ? "Resume Reading" : "Start Reading")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 8)
                        }

                        Text("Chapters")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        LazyVStack(spacing: 0) {
                            ForEach(chapters, id: \.key) { chapter in
                                let isRead = progressManager.isRead(
                                    mangaId: novel.key, chapterId: chapter.key, chapterNum: chapter.chapter)

                                Button(action: {
                                    self.readingChapter = IdentifiableNovelChapter(chapter)
                                }) {
                                    HStack(alignment: .center, spacing: 12) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            if let title = chapter.title, !title.isEmpty {
                                                Text(title)
                                                    .font(.body)
                                                    .fontWeight(isRead ? .regular : .semibold)
                                                    .foregroundColor(isRead ? .secondary : .primary)
                                                    .lineLimit(2)
                                            } else {
                                                Text("Chapter \(chapter.chapter ?? 0)")
                                                    .font(.body)
                                                    .fontWeight(isRead ? .regular : .semibold)
                                                    .foregroundColor(isRead ? .secondary : .primary)
                                                    .lineLimit(1)
                                            }

                                            HStack(spacing: 6) {
                                                if let date = chapter.dateUpdated {
                                                    Text(
                                                        "\(Date(timeIntervalSince1970: TimeInterval(date)).formatted(.dateTime.year().month().day()))"
                                                    )
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                }

                                                if let scanlator = chapter.scanlator {
                                                    Text("•")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                    Text(scanlator)
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                        .lineLimit(1)
                                                }
                                            }
                                        }

                                        Spacer()

                                        // Paywall logic
                                        if let paywalled = chapter.paywalled, paywalled {
                                            Image(systemName: "lock.fill")
                                                .foregroundColor(.yellow)
                                                .font(.caption)
                                                .padding(6)
                                                .background(Color.yellow.opacity(0.2))
                                                .clipShape(Circle())
                                        } else if isRead {
                                            Image(systemName: "checkmark.circle")
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(.systemBackground))
                                    // Slight dimming for the entire row if read
                                    .opacity(isRead ? 0.6 : 1.0)
                                }
                                .buttonStyle(.plain)

                                Divider()
                            }
                        }
                    } else {
                        Text("No chapters found.")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle(novel.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(item: $readingChapter) { wrapper in
            NovelReaderView(runner: runner, novel: novel, currentChapter: wrapper.chapter)
        }
        .task {
            await loadDetails()
        }
    }

    private func loadDetails() async {
        guard !isLoaded else { return }
        do {
            let updatedNovel = try await runner.getNovelUpdate(novel: novel)
            await MainActor.run {
                self.novel = updatedNovel
                self.isLoaded = true
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoaded = true
            }
        }
    }

    private var resumeReadingChapter: Novel.Chapter? {
        guard let chapters = novel.chapters, !chapters.isEmpty else { return nil }

        let chronologicalChapters = chapters.reversed()

        if let firstUnread = chronologicalChapters.first(where: { !progressManager.isRead(mangaId: novel.key, chapterId: $0.key, chapterNum: $0.chapter) }) {
            return firstUnread
        }

        return chapters.first
    }

    private func statusText(for status: Novel.Status) -> String? {
        switch status {
        case .Ongoing: return "Ongoing"
        case .Completed: return "Completed"
        case .Cancelled: return "Cancelled"
        case .Hiatus: return "Hiatus"
        case .Unknown: return nil
        }
    }
}
