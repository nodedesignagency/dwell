import DwellCore
import DwellUI
import SwiftUI

/// Account setup stopped (screenshots, 14 Nov; brief A.1 #2a and the account states): under
/// 16 ("Account setup stopped", the 3D ID card with a minus) or outside the beta's region
/// ("Not in your region yet", the 3D globe with a pin). The page's grey turning red, the art,
/// title and line, and "View a no-data preview". Full screen, no back button, no way back
/// into setup: the brief's date of birth is entered once.
///
/// Measured at 393 × 852: the art, words and button centred on the screen, the button (white,
/// 20 in) 20 below the line.
struct SetupStoppedPage: View {
    let stop: SetupStop
    let insets: PageInsets
    let onPreview: () -> Void

    var body: some View {
        ZStack {
            SetupBackdrop(.red)
            ViewThatFits(in: .vertical) {
                content
                    .frame(maxHeight: .infinity)
                ScrollView {
                    content
                        .padding(.top, insets.top + Space.l)
                        .padding(.bottom, insets.foot(Space.xxl))
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.hidden)
            }
        }
        .environment(\.colorScheme, .light)
    }

    private var content: some View {
        VStack(spacing: 0) {
            SetupWords(title: AccountCopy.title(stop), line: AccountCopy.line(stop)) {
                SetupArt(art)
            }
            Button(AccountCopy.noDataPreview, action: onPreview)
                .buttonStyle(.secondary)
                .padding(.top, Space.screen)
        }
        .padding(.horizontal, Space.screen)
    }

    private var art: Image {
        switch stop {
        case .underSixteen: Art.Onboarding.accountStopped
        case .notInRegion: Art.Onboarding.notInRegion
        }
    }
}
