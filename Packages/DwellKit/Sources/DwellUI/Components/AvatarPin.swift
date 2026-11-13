import SwiftUI

/// The profile picture as a map pin (You design): the photo in a white ring, 133 across, with a
/// tail pointing down from the ring, softly shadowed, and a blurred shadow on the map where the
/// tip touches it.
///
/// Measured from the Figma close-up (13 Nov): the ring 3.5 wide; the tail's straight sides
/// leaning in 0.64 for every point down (about 33° from upright), 18.5 across where they leave
/// the ring, meeting 12.7 below it in a tip rounded at 2; the shadow under the tip about 22 × 8, at
/// its darkest about 30% darker than the map, reaching 6 below the tip.
///
/// The ring and the tail are separate shapes filled together: drawn as one path, the tail ran
/// the other way round to the circle, so where they overlapped they cancelled out and the map
/// showed through the bottom of the ring (12 Nov).
public struct AvatarPin: View {
    static let diameter: CGFloat = 133
    static let ring: CGFloat = 3.5
    /// From the ring's bottom to the tail's tip.
    static let tail: CGFloat = 12.7
    private let image: Image?

    public init(_ image: Image?) {
        self.image = image
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Where the tip touches the map.
            Ellipse()
                .fill(.black.opacity(0.4))
                .frame(width: 22, height: 8)
                .blur(radius: 3)
                .offset(y: Self.diameter + Self.tail - 1 - 4)
            ZStack(alignment: .top) {
                Circle()
                    .fill(Palette.ring)
                    .frame(width: Self.diameter, height: Self.diameter)
                PinTail(tail: Self.tail)
                    .fill(Palette.ring)
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
            Avatar(image, size: Self.diameter - Self.ring * 2)
                .padding(Self.ring)
        }
        .frame(width: Self.diameter, height: Self.diameter + Self.tail, alignment: .top)
        .accessibilityHidden(true)
    }
}

/// The pin's tail: two straight sides from inside the ring down to a rounded tip `tail` below
/// the ring's bottom. Drawn in a frame as wide as the ring and as tall as the ring and tail.
nonisolated private struct PinTail: Shape {
    let tail: CGFloat
    /// How far each side moves in for every point down.
    let lean: CGFloat = 0.64
    let tipRadius: CGFloat = 2

    func path(in rect: CGRect) -> Path {
        let ringBottom = rect.minY + rect.width
        let centre = rect.midX
        // The sharp point the two sides would meet at, below the rounded tip.
        let sine = lean / (1 + lean * lean).squareRoot()
        let apex = CGPoint(x: centre, y: ringBottom + tail + tipRadius * (1 / sine - 1))
        // The sides start well inside the ring, so the join is hidden under it.
        let top = ringBottom - 20
        let half = lean * (apex.y - top)
        var path = Path()
        path.move(to: CGPoint(x: centre - half, y: top))
        path.addArc(tangent1End: apex, tangent2End: CGPoint(x: centre + half, y: top), radius: tipRadius)
        path.addLine(to: CGPoint(x: centre + half, y: top))
        path.closeSubpath()
        return path
    }
}
