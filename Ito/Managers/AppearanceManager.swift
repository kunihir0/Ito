import SwiftUI
import Combine

public enum AppTheme: String, CaseIterable, Identifiable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    public var id: String { self.rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

class AppearanceManager: ObservableObject {
    public static let shared = AppearanceManager()

    @AppStorage("selectedTheme") var selectedTheme: AppTheme = .system {
        willSet {
            objectWillChange.send()
        }
    }
}
