import SwiftUI

/// The whole look in one place: white paper, black ink, one calm green.
enum Theme {
    // Always light, whatever the system setting: white paper, black ink, one calm green.
    static let paper = Color.white
    static let card = Color(red: 0.965, green: 0.965, blue: 0.957)
    static let accent = Color(red: 0.227, green: 0.384, blue: 0.306)
    static let soft = Color(red: 0.227, green: 0.384, blue: 0.306).opacity(0.10)

    /// Reading width. Lines longer than this get tiring, whatever the window size.
    static let column: CGFloat = 640
}

/// A soft white card with a quiet shadow. Used for every block of content.
struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Theme.card)
                    .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 3)
            )
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

/// The one strong button on a screen.
struct PrimaryButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 13)
            .background(Capsule().fill(Theme.accent))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .contentShape(Capsule())
    }
}

/// Everything else that can be clicked: quiet, but with a large target.
struct QuietButton: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(Theme.accent)
            .padding(.horizontal, 18)
            .padding(.vertical, 11)
            .background(Capsule().fill(Theme.soft))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .contentShape(Capsule())
    }
}

/// A small label above a section, like the headings in System Settings.
struct Eyebrow: View {
    var text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(0.8)
            .foregroundStyle(.secondary)
    }
}
