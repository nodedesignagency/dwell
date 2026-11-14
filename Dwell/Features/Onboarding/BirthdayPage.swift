import DwellCore
import DwellUI
import SwiftUI

/// Account setup, step 2: When's your birthday? (screenshot, 14 Nov; brief A.1 #2: "date of
/// birth (once, never stored)"). The 3D cake over peach turning pink, the title and its line;
/// the sheet: "Select your birth date", the design's date wheel, Continue.
///
/// The date lives only on this page: Continue turns it into one answer, 16 or older or not,
/// and that answer is all that leaves it. Under 16 setup stops for good (Account setup
/// stopped, no way back).
///
/// The wheel starts on today, not on an answer that passes, and gives no hint where the line
/// is; Continue waits (dimmed) for a year before this one, so an untouched wheel never answers
/// for anyone. The design shows a date already picked (March 14, 1995).
///
/// Measured at 393 × 852: the sheet 265 tall; the label (14, grey) 16.5 below its top and
/// 15.5 in, 4.5 above the wheel's card (15.5 in, 155 tall); Continue (navy, 9.6 in) 12 below
/// the card, 16 above the sheet's foot.
struct BirthdayPage: View {
    let insets: PageInsets
    @Binding var birthday: BirthDate
    let years: ClosedRange<Int>
    let canContinue: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        SetupPage(
            backdrop: .peach,
            insets: insets,
            title: AccountCopy.birthdayTitle,
            line: AccountCopy.birthdayLine,
            onBack: onBack
        ) {
            SetupArt(Art.Onboarding.birthday)
        } sheet: {
            VStack(alignment: .leading, spacing: 0) {
                Text(verbatim: AccountCopy.birthdayLabel)
                    .textRole(.caption)
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, 15.5)
                    .accessibilityHidden(true)
                DateWheel(date: $birthday, years: years)
                    .padding(.horizontal, 15.5)
                    .padding(.top, 4.5)
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(Text(verbatim: AccountCopy.birthdayLabel))
                Button(AccountCopy.continue, action: onContinue)
                    .buttonStyle(.primary(role: .action))
                    .disabled(!canContinue)
                    .opacity(canContinue ? 1 : 0.4)
                    .motion(value: canContinue)
                    .padding(.horizontal, 9.6)
                    .padding(.top, Space.m)
            }
            .padding(.top, 16.5)
            .padding(.bottom, Space.l)
        }
    }
}
