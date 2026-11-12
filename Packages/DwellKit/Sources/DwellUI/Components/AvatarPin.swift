import SwiftUI

/// The profile picture as a map pin (You design): the photo in a white ring 4 wide, 133 across,
/// with a tail 20 wide pointing 14 down from the ring, softly shadowed. Read from the
/// screenshot.
public struct AvatarPin: View {
    static let diameter: CGFloat = 133
    static let ring: CGFloat = 4
    static let tail: CGFloat = 14
    private let image: Image?

    public init(_ image: Image?) {
        self.image = image
    }

    public var body: some View {
        ZStack(alignment: .top) {
            PinShape(tail: Self.tail)
                .fill(Palette.ring)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            Avatar(image, size: Self.diameter - Self.ring * 2)
                .padding(Self.ring)
        }
        .frame(width: Self.diameter, height: Self.diameter + Self.tail, alignment: .top)
        .accessibilityHidden(true)
    }
}

/// A circle as wide as the shape with a short tail under it, its tip rounded.
nonisolated private struct PinShape: Shape {
    let tail: CGFloat

    func path(in rect: CGRect) -> Path {
        let diameter = rect.width
        let centre = CGPoint(x: rect.midX, y: rect.minY + diameter / 2)
        var path = Path(ellipseIn: CGRect(x: rect.minX, y: rect.minY, width: diameter, height: diameter))
        let bottom = rect.minY + diameter
        let half: CGFloat = 10
        // Starts inside the circle so the two shapes join without a seam.
        path.move(to: CGPoint(x: centre.x - half, y: bottom - 6))
        path.addLine(to: CGPoint(x: centre.x - 2.5, y: bottom + tail - 2))
        path.addQuadCurve(to: CGPoint(x: centre.x + 2.5, y: bottom + tail - 2), control: CGPoint(x: centre.x, y: bottom + tail + 1))
        path.addLine(to: CGPoint(x: centre.x + half, y: bottom - 6))
        path.closeSubpath()
        return path
    }
}
