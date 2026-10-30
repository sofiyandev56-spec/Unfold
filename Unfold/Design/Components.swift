import SwiftUI

/// Procedural key art: a slowly breathing mesh gradient with the game's glyph,
/// in the cinematic style of Apple Arcade cover art.
struct KeyArt: View {
    let game: GameInfo
    var animated = true
    var glyphSize: CGFloat = 150
    /// Cards with a title over the art keep the glyph up top, clear of the text.
    var glyphAlignment: Alignment = .bottomTrailing

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: !animated || reduceMotion)) { context in
            let t = Float(context.date.timeIntervalSinceReferenceDate)
            MeshGradient(width: 3, height: 3, points: points(at: t), colors: colors)
        }
        .overlay(alignment: glyphAlignment) {
            Image(systemName: game.symbol)
                .font(.system(size: glyphSize, weight: .black))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.white.opacity(0.92))
                .shadow(color: game.colors[0].opacity(0.9), radius: 30)
                .rotationEffect(.degrees(-8))
                .offset(x: glyphSize * 0.12, y: glyphSize * (glyphAlignment.vertical == .top ? -0.02 : 0.1))
                .padding(.top, glyphAlignment.vertical == .top ? 24 : 0)
        }
        .overlay {
            // A gentle vignette keeps titles legible over the art.
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
        }
        .clipped()
        .accessibilityHidden(true)
    }

    private var colors: [Color] {
        let (a, b, c) = (game.colors[0], game.colors[1], game.colors[2])
        let deep = Palette.canvas
        return [b, a, deep,
                a, c, b,
                deep, b, a]
    }

    private func points(at t: Float) -> [SIMD2<Float>] {
        let s = sin(t * 0.6) * 0.12
        let k = cos(t * 0.45) * 0.12
        return [
            [0, 0], [0.5 + s * 0.6, 0], [1, 0],
            [0, 0.5 + k * 0.6], [0.5 + s, 0.5 + k], [1, 0.5 - s * 0.6],
            [0, 1], [0.5 - k * 0.6, 1], [1, 1],
        ]
    }
}

/// A coloured capsule that names a world. Content, not chrome, so it is solid rather than glass.
struct WorldChip: View {
    let world: World

    var body: some View {
        Label(world.title, systemImage: world.symbol)
            .font(.caption.weight(.semibold))
            .foregroundStyle(world.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(world.color.opacity(0.16), in: .capsule)
    }
}

/// Concentric mastery rings, one per world, echoing Activity rings.
struct RingStack: View {
    var values: [(Double, Color)]
    var lineWidth: CGFloat = 16
    var gap: CGFloat = 4

    @State private var appeared = false

    var body: some View {
        ZStack {
            ForEach(Array(values.enumerated()), id: \.offset) { index, item in
                let inset = CGFloat(index) * (lineWidth + gap)
                ZStack {
                    Circle().stroke(item.1.opacity(0.18), lineWidth: lineWidth)
                    Circle()
                        .trim(from: 0, to: appeared ? max(item.0, 0.001) : 0.001)
                        .stroke(
                            AngularGradient(colors: [item.1.opacity(0.75), item.1], center: .center),
                            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .shadow(color: item.1.opacity(0.5), radius: 6)
                }
                .padding(inset + lineWidth / 2)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 1.2, dampingFraction: 0.8).delay(0.15)) { appeared = true }
        }
        .accessibilityElement()
        .accessibilityLabel("Mastery rings")
    }
}

/// A side view of a hinge: two plates meeting at the fold, opened to `angle` degrees.
struct HingeGlyph: Shape {
    var angle: Double

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let pivot = CGPoint(x: rect.midX, y: rect.maxY - 2)
        let length = min(rect.width / 2, rect.height) - 2
        // The left plate rests flat; the right plate rises as the hinge closes.
        path.move(to: CGPoint(x: pivot.x - length, y: pivot.y))
        path.addLine(to: pivot)
        let radians = (180 - angle) * .pi / 180
        path.addLine(to: CGPoint(x: pivot.x + cos(radians) * length, y: pivot.y - sin(radians) * length))
        return path
    }
}

/// An animated rainbow edge that marks content written by Apple Intelligence.
struct IntelligenceGlow: ViewModifier {
    var radius: CGFloat = 24
    var active = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            TimelineView(.animation(paused: !active || reduceMotion)) { context in
                let angle = context.date.timeIntervalSinceReferenceDate * 40
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(
                        AngularGradient(colors: Palette.intelligence + [Palette.intelligence[0]],
                                        center: .center, angle: .degrees(angle)),
                        lineWidth: 1.5
                    )
                    .shadow(color: Palette.intelligence[1].opacity(active ? 0.6 : 0), radius: 10)
            }
            .allowsHitTesting(false)
        }
    }
}

extension View {
    func intelligenceGlow(radius: CGFloat = 24, active: Bool = true) -> some View {
        modifier(IntelligenceGlow(radius: radius, active: active))
    }
}

/// The sparkle that stands for Coach, filled with the Intelligence gradient.
struct CoachMark: View {
    var size: CGFloat = 28

    var body: some View {
        Image(systemName: "sparkles")
            .font(.system(size: size * 0.55, weight: .semibold))
            .foregroundStyle(LinearGradient(colors: Palette.intelligence, startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: size, height: size)
            .background(Palette.raisedHigh, in: .circle)
            .accessibilityHidden(true)
    }
}

/// A quiet backdrop for game screens: the game's colours, heavily blurred behind content.
struct GameBackdrop: View {
    let colors: [Color]

    var body: some View {
        // The glows live in an overlay so their size never widens the game's layout.
        Palette.canvas
            .overlay {
                ZStack {
                    Circle().fill(colors[0].opacity(0.35)).frame(width: 420).blur(radius: 120).offset(x: -140, y: -260)
                    Circle().fill(colors[2].opacity(0.28)).frame(width: 380).blur(radius: 120).offset(x: 160, y: 300)
                }
            }
            .clipped()
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

/// A big friendly stat: value over caption.
struct StatTile: View {
    let value: String
    let caption: String
    var color: Color = .primary

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.rounded(.title2, weight: .heavy))
                .foregroundStyle(color)
                .contentTransition(.numericText())
                .monospacedDigit()
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .surface(radius: 22)
        .accessibilityElement(children: .combine)
    }
}
