import SwiftUI

struct BrowseView: View {
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Image(systemName: "network")
                        .font(.system(size: 60))
                        .foregroundStyle(.secondary)
                        .padding(.top, 100)

                    Text("No Extensions Installed")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Install an extension to browse manga sources.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            .navigationTitle("Browse")
        }
        .navigationViewStyle(.stack)
    }
}

#Preview {
    BrowseView()
}
