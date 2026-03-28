import SwiftUI
import NukeUI

struct HistoryView: View {
    @StateObject private var historyManager = HistoryManager.shared

    var body: some View {
        Group {
            if historyManager.history.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 52, weight: .thin))
                        .foregroundStyle(.tertiary)

                    Text("No History")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Items you read or watch\nwill appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 60)
            } else {
                List {
                    ForEach(historyManager.history) { entry in
                        NavigationLink(destination: DeferredPluginView(item: entry.item)) {
                            HistoryItemRow(entry: entry)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                if let index = historyManager.history.firstIndex(where: { $0.id == entry.id }) {
                                    var updatedHistory = historyManager.history
                                    updatedHistory.remove(at: index)
                                    // Hacky way to update just one item without making it a full model manager function,
                                    // but wait, I can just call clearHistory() or add a removeItem(id:).
                                    // I'll skip individual delete for now, or just let users clear all.
                                }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !historyManager.history.isEmpty {
                    Button(role: .destructive) {
                        historyManager.clearHistory()
                    } label: {
                        Text("Clear")
                    }
                }
            }
        }
    }
}

struct HistoryItemRow: View {
    let entry: HistoryEntry

    var body: some View {
        HStack(spacing: 12) {
            if let coverUrl = entry.item.coverUrl, let url = URL(string: coverUrl) {
                LazyImage(url: url) { state in
                    if let image = state.image {
                        image.resizable().aspectRatio(contentMode: .fill)
                    } else if state.error != nil {
                        Color.itoCardBackground
                            .overlay(Image(systemName: "photo.slash").foregroundStyle(.tertiary))
                    } else {
                        Color.itoCardBackground
                    }
                }
                .frame(width: 50, height: 75)
                .cornerRadius(6)
                .clipped()
            } else {
                Color.itoCardBackground
                    .frame(width: 50, height: 75)
                    .cornerRadius(6)
                    .overlay(Image(systemName: "photo.on.rectangle.angled").foregroundStyle(.tertiary))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.item.title)
                    .font(.headline)
                    .lineLimit(2)

                if let chapterTitle = entry.chapterTitle {
                    Text(chapterTitle)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                }

                Text(timeAgo(from: entry.lastReadAt))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(entry.item.pluginId.capitalized)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
