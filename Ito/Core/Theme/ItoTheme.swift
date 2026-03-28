import SwiftUI

public enum ItoSpacing {
    public static let xs: CGFloat = 4
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
}

public enum ItoCornerRadius {
    public static let small: CGFloat = 6
    public static let medium: CGFloat = 10
    public static let large: CGFloat = 14
    public static let pill: CGFloat = 99
}

public extension Font {
    static let itoTitle = Font.title2.weight(.bold)
    static let itoHeadline = Font.headline
    static let itoBody = Font.subheadline
    static let itoCaption = Font.caption.weight(.medium)
    static let itoBadge = Font.caption2.weight(.bold)
}

public extension Color {
    static let itoAccent = Color.accentColor
    static let itoSecondaryText = Color(.secondaryLabel)
    static let itoCardBackground = Color(.secondarySystemFill)
    static let itoBadgeBackground = Color(.tertiarySystemFill)
}
