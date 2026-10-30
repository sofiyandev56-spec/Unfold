import SwiftUI

/// The floating glass bar above every game: quit, score, and a timer or counter.
struct GameHUD: View {
    let title: String
    let score: Int
    var detail: String?
    var detailSymbol: String?
    var detailColor: Color = .primary
    /// Fraction of time left, drawn as a ring beside the detail.
    var timeLeft: Double?
    let onQuit: () -> Void

    var body: some View {
        GlassEffectContainer(spacing: 10) {
            HStack(spacing: 10) {
                Button(action: onQuit) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .glassEffect(.regular.interactive(), in: .circle)
                .accessibilityLabel("Quit game")

                // The title gives way first when the cover display is narrow.
                Text(title)
                    .font(.rounded(.headline))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.leading, 4)
                    .layoutPriority(-1)

                HStack(spacing: 6) {
                    Image(systemName: "star.fill").foregroundStyle(Palette.streak)
                    Text("\(score)")
                        .contentTransition(.numericText(value: Double(score)))
                        .monospacedDigit()
                }
                .font(.rounded(.headline))
                .padding(.horizontal, 16)
                .frame(height: 44)
                .glassEffect(.regular, in: .capsule)
                .animation(.snappy, value: score)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Score \(score)")

                if let detail {
                    HStack(spacing: 7) {
                        if let timeLeft {
                            Circle()
                                .trim(from: 0, to: timeLeft)
                                .stroke(timeLeft < 0.2 ? Palette.incorrect : detailColor,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 16, height: 16)
                        } else if let detailSymbol {
                            Image(systemName: detailSymbol).foregroundStyle(detailColor)
                        }
                        Text(detail).monospacedDigit().contentTransition(.numericText())
                    }
                    .font(.rounded(.headline))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .glassEffect(.regular, in: .capsule)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
