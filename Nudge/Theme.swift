import SwiftUI

// Shared visual language for Nudge: soft rounded cards, generous spacing,
// and a single user-chosen accent color rather than a busy palette — ADHD
// UX guidance favors low visual noise over a "lively" multi-color UI.

struct AccentButtonStyle: ButtonStyle {
    var accent: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
    }
}

extension View {
    /// The soft card surface used across the Today screen and Customize.
    func nudgeCard(cornerRadius: CGFloat = 20) -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.nudgeCardBackground)
            )
    }
}

extension Color {
    static let nudgeCardBackground = Color(light: Color.white, dark: Color(hex: "1C1C1E"))
    static let nudgeTextSecondary = Color(light: Color(hex: "6B6B70"), dark: Color(hex: "9B9BA1"))

    /// Convenience initializer that picks a color per current appearance
    /// without needing an asset-catalog color set for every shade used here.
    init(light: Color, dark: Color) {
        self = Color(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
    }
}
