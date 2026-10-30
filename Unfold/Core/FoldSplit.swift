import SwiftUI

/// Places two views on either side of the fold.
///
/// Following the HIG's displacement principle, the views are moved rather than redesigned:
/// with a crease they sit on each page; without one they sit side by side on wide displays
/// and stacked on tall ones.
struct FoldSplit<Primary: View, Secondary: View>: View {
    @Environment(FoldState.self) private var fold
    @Environment(\.windowSize) private var window

    var primaryFraction: CGFloat = 0.5
    var spacing: CGFloat = 16
    @ViewBuilder var primary: Primary
    @ViewBuilder var secondary: Secondary

    var body: some View {
        GeometryReader { geo in
            let crease = geo.crease(for: fold, window: window)
            let frames = layout(in: geo.size, crease: crease)

            ZStack(alignment: .topLeading) {
                primary
                    .frame(width: frames.0.width, height: frames.0.height)
                    .offset(x: frames.0.minX, y: frames.0.minY)
                secondary
                    .frame(width: frames.1.width, height: frames.1.height)
                    .offset(x: frames.1.minX, y: frames.1.minY)
                if let crease {
                    CreaseLight(crease: crease)
                        .transition(.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .animation(.smooth(duration: 0.5), value: crease)
            .animation(.smooth(duration: 0.5), value: geo.size)
            .animation(.smooth(duration: 0.5), value: primaryFraction)
        }
    }

    private func layout(in size: CGSize, crease: Crease?) -> (CGRect, CGRect) {
        if let crease {
            // Leave breathing room either side of the hinge, as the HIG asks for custom layouts.
            let inset = spacing / 2
            if crease.isVertical {
                let left = CGRect(x: 0, y: 0, width: max(crease.frame.minX - inset, 0), height: size.height)
                let rightX = crease.frame.maxX + inset
                return (left, CGRect(x: rightX, y: 0, width: max(size.width - rightX, 0), height: size.height))
            }
            let top = CGRect(x: 0, y: 0, width: size.width, height: max(crease.frame.minY - inset, 0))
            let bottomY = crease.frame.maxY + inset
            return (top, CGRect(x: 0, y: bottomY, width: size.width, height: max(size.height - bottomY, 0)))
        }
        if size.width > size.height * 1.1 {
            let width = (size.width - spacing) * primaryFraction
            return (CGRect(x: 0, y: 0, width: width, height: size.height),
                    CGRect(x: width + spacing, y: 0, width: size.width - width - spacing, height: size.height))
        }
        let height = (size.height - spacing) * primaryFraction
        return (CGRect(x: 0, y: 0, width: size.width, height: height),
                CGRect(x: 0, y: height + spacing, width: size.width, height: size.height - height - spacing))
    }
}

/// A soft line of light along the fold so people can see the layout respond to it.
struct CreaseLight: View {
    let crease: Crease

    var body: some View {
        let gradient = LinearGradient(
            colors: [.clear, .white.opacity(0.35), .clear],
            startPoint: crease.isVertical ? .top : .leading,
            endPoint: crease.isVertical ? .bottom : .trailing
        )
        Group {
            if crease.isVertical {
                Capsule().fill(gradient).frame(width: 2, height: crease.frame.height * 0.8)
            } else {
                Capsule().fill(gradient).frame(width: crease.frame.width * 0.8, height: 2)
            }
        }
        .shadow(color: .white.opacity(0.5), radius: 8)
        .position(x: crease.frame.midX, y: crease.frame.midY)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
