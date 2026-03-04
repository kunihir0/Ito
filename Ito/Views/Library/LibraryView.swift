import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                        .padding(.top, 100)

                    Text("Your Library is Empty")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Manga you save or download will appear here.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Library")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    LibraryView()
}
