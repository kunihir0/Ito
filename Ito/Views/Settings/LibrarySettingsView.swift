import SwiftUI

struct LibrarySettingsView: View {
    @AppStorage(UserDefaultsKeys.alwaysShowCategoryPicker) private var alwaysShowCategoryPicker: Bool = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: $alwaysShowCategoryPicker) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Prompt Category on Save")
                        Text("Show the list picker when saving a new series.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("When enabled, saving a new series will immediately show the category assignment sheet instead of saving to Uncategorized. Only applies when you have at least one custom category.")
            }
        }
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LibrarySettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            LibrarySettingsView()
        }
    }
}
