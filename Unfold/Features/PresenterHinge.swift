import SwiftUI

/// A glass slider that stands in for iPhone Duo's hinge on any device.
///
/// It sits on the navigation layer, so it uses Liquid Glass; everything it drives reads
/// the same `FoldState` the real hinge writes to.
struct PresenterHingeBar: View {
    @Environment(FoldState.self) private var fold
    @Environment(\.windowSize) private var window

    var body: some View {
        @Bindable var fold = fold
        HStack(spacing: 14) {
            HingeGlyph(angle: fold.presenterAngle)
                .stroke(.white, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .frame(width: 34, height: 22)
                .animation(.interactiveSpring, value: fold.presenterAngle)

            VStack(alignment: .leading, spacing: 1) {
                Text("Presenter hinge")
                    .font(.caption.weight(.semibold))
                Text("\(Int(fold.presenterAngle))° · \(fold.poseName(isLandscape: window.isLandscape))")
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            .fixedSize()

            Slider(value: $fold.presenterAngle, in: 30...180)
                .accessibilityLabel("Hinge angle")
                .accessibilityValue("\(Int(fold.presenterAngle)) degrees")

            Button {
                withAnimation(.smooth) { fold.presenterEnabled = false }
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.weight(.bold))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Hide presenter hinge")
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .glassEffect(.regular, in: .capsule)
        .frame(maxWidth: 520)
        .padding(.horizontal, 16)
        .sensoryFeedback(.selection, trigger: fold.pose)
    }
}

/// A brief capsule that confirms the app noticed a change of pose.
struct PoseToast: View {
    let name: String
    let angle: Double

    var body: some View {
        HStack(spacing: 10) {
            HingeGlyph(angle: angle)
                .stroke(.white, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: 26, height: 16)
            Text(name).font(.subheadline.weight(.semibold))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .capsule)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(name) pose")
    }
}

/// Toolbar button that shows or hides the presenter hinge.
struct PresenterToggle: View {
    @Environment(FoldState.self) private var fold

    var body: some View {
        Button {
            withAnimation(.smooth) { fold.presenterEnabled.toggle() }
        } label: {
            HingeGlyph(angle: fold.presenterEnabled ? 95 : 140)
                .stroke(fold.presenterEnabled ? Palette.tint : .primary,
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
                .frame(width: 24, height: 14)
                .animation(.bouncy, value: fold.presenterEnabled)
        }
        .accessibilityLabel(fold.presenterEnabled ? "Hide presenter hinge" : "Show presenter hinge")
    }
}
