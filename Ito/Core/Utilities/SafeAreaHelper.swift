import SwiftUI

/// Helper to access current safe area insets globally or within views that don't pass it through.
public enum SafeArea {
    static var top: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window?.safeAreaInsets.top ?? 0
    }

    static var bottom: CGFloat {
        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
        let window = windowScene?.windows.first { $0.isKeyWindow }
        return window?.safeAreaInsets.bottom ?? 0
    }
}
