import SwiftUI

/// How the device is being held, derived from the hinge angle.
enum Pose: Equatable {
    /// A phone without a hinge, such as iPhone 18 Pro Max.
    case slab
    /// Folded shut, so the cover display is in use.
    case closed
    /// Partly open: a book when the crease is vertical, a laptop when it is horizontal.
    case halfOpen
    /// Fully open and flat.
    case flat
}

/// The single source of truth for the hinge.
///
/// On iPhone Duo the angle comes from `onHingeChange` (iOS 27.1). The presenter hinge
/// drives the same values from a slider so every fold interaction can be shown on any
/// iPhone, the Simulator, or a projector.
@Observable
final class FoldState {
    enum Source { case hardware, presenter, none }

    private(set) var hardwareAngle: Double?
    var presenterEnabled = false
    var presenterAngle: Double = 180

    var source: Source {
        if presenterEnabled { return .presenter }
        return hardwareAngle == nil ? .none : .hardware
    }

    /// Degrees: 0 is shut, 180 is flat. `nil` when there is no hinge to read.
    var angle: Double? {
        presenterEnabled ? presenterAngle : hardwareAngle
    }

    var pose: Pose {
        guard let angle else { return .slab }
        if angle < 25 { return .closed }
        if angle < 165 { return .halfOpen }
        return .flat
    }

    /// The angle while the hinge can be played with. When the device is shut, people are
    /// using the cover display, so games fall back to touch instead of reading 0° as input.
    var playableAngle: Double? {
        guard let angle, pose == .halfOpen || pose == .flat else { return nil }
        return angle
    }

    /// 0 when flat, rising to 1 as the device folds to 90°. Drives fold-linked animation.
    var foldAmount: Double {
        guard let angle = playableAngle else { return 0 }
        return min(max((180 - angle) / 90, 0), 1)
    }

    func hingeChanged(degrees: Double?) {
        hardwareAngle = degrees
    }

    /// The name people use for the current pose; it depends on which way the crease runs.
    func poseName(isLandscape: Bool) -> String {
        switch pose {
        case .slab: "Single display"
        case .closed: "Closed"
        case .halfOpen: isLandscape ? "Book" : "Laptop"
        case .flat: "Flat"
        }
    }
}

extension EnvironmentValues {
    /// This window's full size, safe areas included: the physical crease runs through its centre.
    /// Per window, because iPhone Duo's cover and inner displays each host their own.
    @Entry var windowSize: CGSize = .zero
}

extension CGSize {
    /// Landscape on the inner display means a vertical crease (book); portrait means horizontal (laptop).
    var isLandscape: Bool { width > height }
}

/// Measures the window and publishes it as `windowSize` to everything inside, sheets included.
struct WindowSizeReader: ViewModifier {
    @State private var size: CGSize = .zero

    func body(content: Content) -> some View {
        content
            .environment(\.windowSize, size)
            .onGeometryChange(for: CGSize.self) { proxy in
                // Add the insets back: the crease sits at the centre of the whole display,
                // and `.global` frames are measured from its true edge.
                let insets = proxy.safeAreaInsets
                return CGSize(width: proxy.size.width + insets.leading + insets.trailing,
                              height: proxy.size.height + insets.top + insets.bottom)
            } action: { size = $0 }
    }
}

extension View {
    /// Feeds iPhone Duo's live hinge angle into `fold`.
    @ViewBuilder
    func tracksHinge(_ fold: FoldState) -> some View {
        if #available(iOS 27.1, *) {
            onHingeChange { _, context in
                fold.hingeChanged(degrees: context.hinge?.angle.degrees)
            }
        } else {
            self
        }
    }
}

/// Where the display folds, in the local space of the view that asked.
struct Crease: Equatable {
    var frame: CGRect

    /// A vertical crease splits the view into left and right pages.
    var isVertical: Bool { frame.height >= frame.width }
}

extension GeometryProxy {
    /// The physical fold reported by iOS 27.1, or a stand-in while the presenter hinge is bent.
    func crease(for fold: FoldState, window: CGSize) -> Crease? {
        if #available(iOS 27.1, *) {
            let local = frame(in: .local)
            if let region = reservedRegions(kind: .division).first(where: { $0.isActive }) {
                let clipped = region.frame.intersection(local)
                if !clipped.isNull, clipped.width > 0 || clipped.height > 0 {
                    return Crease(frame: clipped)
                }
            }
        }
        // The stand-in only appears on windows big enough to be iPhone Duo's inner display.
        guard fold.source == .presenter, fold.pose == .halfOpen,
              min(window.width, window.height) >= 560 else { return nil }
        // A book-style hinge halves the window's longer side; convert that line into local space.
        let gap: CGFloat = 28
        let origin = frame(in: .global).origin
        let crease: CGRect
        if window.isLandscape {
            let x = window.width / 2 - origin.x
            crease = CGRect(x: x - gap / 2, y: 0, width: gap, height: size.height)
        } else {
            let y = window.height / 2 - origin.y
            crease = CGRect(x: 0, y: y - gap / 2, width: size.width, height: gap)
        }
        // A view that doesn't straddle the crease lies on one page and lays out normally.
        let local = CGRect(origin: .zero, size: size)
        let inside = window.isLandscape ? (crease.minX > 40 && crease.maxX < size.width - 40)
                                        : (crease.minY > 40 && crease.maxY < size.height - 40)
        return inside && local.intersects(crease) ? Crease(frame: crease) : nil
    }
}
