import SwiftUI
import Combine

public class SnackBarManager: ObservableObject {
    public static let shared = SnackBarManager()

    @Published public var isShowing: Bool = false
    @Published public var savedItemId: String?

    private var hideWorkItem: DispatchWorkItem?

    private init() {}

    public func showSaved(itemId: String) {
        // Cancel any pending hide
        hideWorkItem?.cancel()

        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
            self.savedItemId = itemId
            self.isShowing = true
        }

        let workItem = DispatchWorkItem { [weak self] in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                self?.isShowing = false
            }
        }
        self.hideWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: workItem)
    }
}

public struct SnackBarOverlay: View {
    @StateObject private var manager = SnackBarManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var showingSheetForId: String?

    public init() {}

    public var body: some View {
        ZStack(alignment: .bottom) {
            Color.clear // Transparent root covering safe area
                .ignoresSafeArea()

            if manager.isShowing {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)

                    Text("Saved to Uncategorized")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        // Dynamic Type Safe height handled by padding

                    Spacer()

                    Button {
                        if let id = manager.savedItemId {
                            showingSheetForId = id
                            withAnimation {
                                manager.isShowing = false
                            }
                        }
                    } label: {
                        Text("Move")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44) // HIG Target
                    }
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
                }
                .padding(.vertical, 12)
                .padding(.leading, 16)
                .padding(.trailing, 8) // Accommodate the pill capsule
                .background(.ultraThinMaterial)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.12), radius: 10, x: 0, y: 5)
                .padding(.horizontal, 16)
                .transition(
                    reduceMotion
                    ? .opacity
                    : .move(edge: .bottom).combined(with: .opacity)
                )
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 10) // Floats above home indicator
        }
        .sheet(item: Binding(
            get: { showingSheetForId.map { SheetIdentifiable(id: $0) } },
            set: { showingSheetForId = $0?.id }
        )) { wrapper in
            CategoryAssignmentSheet(itemId: wrapper.id)
        }
    }
}

private struct SheetIdentifiable: Identifiable {
    let id: String
}
