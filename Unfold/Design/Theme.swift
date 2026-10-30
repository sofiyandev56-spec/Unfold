import SwiftUI

/// The three areas of knowledge. Each owns one colour, and that colour means only that world.
enum World: String, CaseIterable, Identifiable, Codable {
    case swift, frameworks, ecosystem

    var id: String { rawValue }

    var title: String {
        switch self {
        case .swift: "Swift"
        case .frameworks: "Frameworks"
        case .ecosystem: "Ecosystem"
        }
    }

    var subtitle: String {
        switch self {
        case .swift: "The language and its concurrency model"
        case .frameworks: "The APIs that power Apple apps"
        case .ecosystem: "Fifty years of Apple, device by device"
        }
    }

    var symbol: String {
        switch self {
        case .swift: "swift"
        case .frameworks: "square.stack.3d.up.fill"
        case .ecosystem: "laptopcomputer.and.iphone"
        }
    }

    /// Warm orange for practice and momentum; cyan for building; purple for heritage.
    var color: Color {
        switch self {
        case .swift: Color(.displayP3, red: 1.00, green: 0.45, blue: 0.20)
        case .frameworks: Color(.displayP3, red: 0.25, green: 0.80, blue: 0.92)
        case .ecosystem: Color(.displayP3, red: 0.68, green: 0.45, blue: 1.00)
        }
    }
}

/// Unfold's semantic colours. Interactive elements use `tint`; content uses world colours;
/// the Intelligence gradient appears only when the on-device model is speaking.
enum Palette {
    static let canvas = Color(.displayP3, red: 0.016, green: 0.016, blue: 0.031)
    static let raised = Color(.displayP3, red: 0.075, green: 0.075, blue: 0.105)
    static let raisedHigh = Color(.displayP3, red: 0.115, green: 0.115, blue: 0.155)
    static let hairline = Color.white.opacity(0.09)
    static let tint = Color(.displayP3, red: 0.24, green: 0.55, blue: 1.00)
    static let correct = Color(.displayP3, red: 0.20, green: 0.84, blue: 0.42)
    /// Red only flashes for a moment: research links lingering red to anxious, worse test performance.
    static let incorrect = Color(.displayP3, red: 1.00, green: 0.29, blue: 0.29)
    static let streak = Color(.displayP3, red: 1.00, green: 0.66, blue: 0.10)
    static let intelligence: [Color] = [
        Color(.displayP3, red: 0.03, green: 0.58, blue: 1.00),
        Color(.displayP3, red: 0.79, green: 0.35, blue: 0.87),
        Color(.displayP3, red: 1.00, green: 0.18, blue: 0.33),
        Color(.displayP3, red: 1.00, green: 0.56, blue: 0.02),
    ]
}

extension Font {
    /// SF Pro Rounded: friendly, game-like display type, as in Apple Fitness and Game Center.
    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .bold) -> Font {
        .system(style, design: .rounded, weight: weight)
    }
}

/// The solid surface every content card sits on. Glass is kept for the controls above it.
struct Surface: ViewModifier {
    var radius: CGFloat = 28
    var stroke: Color = Palette.hairline

    func body(content: Content) -> some View {
        content
            .background(Palette.raised, in: .rect(cornerRadius: radius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            }
    }
}

extension View {
    func surface(radius: CGFloat = 28, stroke: Color = Palette.hairline) -> some View {
        modifier(Surface(radius: radius, stroke: stroke))
    }

    /// Small uppercase label used above titles.
    func eyebrow(_ color: Color = .secondary) -> some View {
        font(.caption.weight(.semibold)).tracking(1.2).textCase(.uppercase).foregroundStyle(color)
    }
}

/// Cards that sink slightly under the finger, like a physical button.
struct PressableStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
