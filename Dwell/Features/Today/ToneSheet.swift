import DwellCore
import DwellUI
import SwiftUI

/// Set your tone (screenshot, 14 Nov; brief A.1 "Set your dial", §6): slides up over Today
/// right after onboarding. The dial as on You: its art, the stop's name and line, the arc;
/// over the screen's top, a notification-style preview of today's insight re-rendering in the
/// voice the dial is on (`NotificationPreview`, laid over the status bar by the presenter).
///
/// "Set my tone" saves the stop (the design's "Yes, turn on", reworded on the user's call,
/// 14 Nov); the close button, a swipe down or a tap outside is the brief's "Later": the dial
/// stays where it was (Plain for a new account) and You's dial changes it any time. Either
/// way Today won't ask again. A light tap at each stop, as on You (`DialControl`).
///
/// Measured at 393 × 852: the card as `PromptCard` lays it out, with `ToneSky` behind; the art
/// (80) 24 below the line, the name (24) 24 below the art, its line (14, grey) 2 below, the arc
/// 24 below that and 25.5 in from the card's sides, the button 22 below the arc and 10.5 in.
struct ToneSheet: View {
    /// Set by onboarding's One last thing; Today shows this sheet while it's true.
    static let asksKey = "tone.asksOnToday"

    @Binding var dial: Double
    let onSet: () -> Void
    let onLater: () -> Void

    var body: some View {
        let stop = Dial(position: dial).stop
        PromptCard(
            title: Text(verbatim: ToneSheetCopy.title),
            titleLabel: ToneSheetCopy.title,
            message: ToneSheetCopy.message,
            actionTitle: ToneSheetCopy.action,
            closeLabel: ToneSheetCopy.later,
            onAction: onSet,
            onClose: onLater
        ) {
            VStack(spacing: 0) {
                DialArt(position: dial)
                    .padding(.top, Space.xl)
                // The words cross-fade as the dial passes into the next stop's half; the thumb
                // and the art follow the finger.
                Text(verbatim: stop.name)
                    .textRole(.pageTitle)
                    .foregroundStyle(Palette.textPrimary)
                    .contentTransition(.opacity)
                    .motion(value: stop)
                    .padding(.top, Space.xl)
                Text(verbatim: YouCopy.dialDescription(stop))
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .motion(value: stop)
                    .padding(.top, Space.xxs)
                DialControl(position: $dial, label: ToneSheetCopy.title)
                    .padding(.horizontal, 25.5)
                    .padding(.top, Space.xl)
            }
            .frame(maxWidth: .infinity)
            .padding(.bottom, 22)
        } backdrop: {
            ToneSky()
        }
    }
}
