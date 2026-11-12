import SwiftUI

/// A privacy fact, stated where it applies (brief §8.2; You design: "Only you can see your
/// map"): a lock and one line, centred on a grey bar the width of the cards. Read from the
/// screenshot: bar #EEEEEE, 38 tall, corners 8; lock 14, 6 to the words (14, #484848).
public struct PrivacyBar: View {
    @ScaledMetric(relativeTo: .subheadline) private var lockSize: CGFloat = 14
    private let text: String

    public init(_ text: String) {
        self.text = text
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock.fill") // [ICON NEEDED] the design's lock
                .resizable()
                .scaledToFit()
                .frame(width: lockSize, height: lockSize)
                .foregroundStyle(Palette.privacyIcon)
                .accessibilityHidden(true)
            Text(verbatim: text)
                .textRole(.caption)
                .foregroundStyle(Palette.privacyText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Space.l)
        .padding(.vertical, 10.5)
        .frame(maxWidth: .infinity)
        .background(Palette.privacy, in: .rect(cornerRadius: Radius.s))
        .accessibilityElement(children: .combine)
    }
}
