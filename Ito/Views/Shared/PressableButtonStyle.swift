import SwiftUI

/// Gives NavigationLink a native-feeling scale press without losing the tap highlight.
public struct PressableButtonStyle: ButtonStyle {
    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeInOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Allows observing the press state of a Button.
public struct PressRecordingButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    public init(isPressed: Binding<Bool>) {
        self._isPressed = isPressed
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { pressed in isPressed = pressed }
    }
}
