import DwellCore
import SwiftUI

// The pieces account setup is built from (screens, 14 Nov: Save your world, the birthday, One
// last thing, the two stops), measured from the screenshots at 393 × 852: the pages' colour,
// the Apple and phone buttons, the legal line and the date wheel.

// MARK: - The pages' colour

/// An account step's colour, edge to edge: the page's grey down to a quarter of the way, then
/// through a warm cream to its colour at the foot. Stops read from the screenshots down the
/// screen's edge (230, 350, 500, 650 and 852 of 852). The same in dark: onboarding stays light.
public struct SetupBackdrop: View {
    public enum Style: Sendable {
        /// Save your world: gold.
        case gold
        /// The birthday: peach to pink.
        case peach
        /// One last thing: lime to green.
        case lime
        /// The stops (Account setup stopped, Not in your region yet): pink to red.
        case red
    }

    private let style: Style

    public init(_ style: Style) {
        self.style = style
    }

    public var body: some View {
        let (cream, light, middle, foot) = colors
        LinearGradient(
            stops: [
                .init(color: Palette.background, location: 0.27),
                .init(color: cream, location: 0.411),
                .init(color: light, location: 0.587),
                .init(color: middle, location: 0.763),
                .init(color: foot, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom)
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }

    private var colors: (Color, Color, Color, Color) {
        switch style {
        case .gold: (Palette.setupCream, Palette.setupGoldLight, Palette.setupGold, Palette.setupGoldFoot)
        case .peach: (Palette.setupCream, Palette.setupPeachLight, Palette.setupPeach, Palette.setupPeachFoot)
        case .lime: (Palette.setupCream, Palette.setupLimeLight, Palette.setupLime, Palette.setupLimeFoot)
        case .red: (Palette.setupRose, Palette.setupRedLight, Palette.setupRed, Palette.setupRedFoot)
        }
    }
}

// MARK: - Buttons

/// Sign in with Apple, drawn as the design draws it (Save your world): a black capsule 44 tall,
/// full width, Apple's logo (24 tall) 22 in from the leading end and "Continue with Apple"
/// (18 medium, white) centred. Apple's guidelines allow a custom button in black with the logo
/// and one of its titles; the sign-in itself is Apple's own sheet (`ASAuthorizationController`
/// in the app). Pressed, it dims.
public struct AppleCapsuleButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 44
    @ScaledMetric(relativeTo: .body) private var logo: CGFloat = 24
    @ScaledMetric(relativeTo: .body) private var logoInset: CGFloat = 22

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.action)
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            // Clear of the logo on both sides, so the words stay centred on the button.
            .padding(.horizontal, logoInset + logo + Space.s)
            .frame(maxWidth: .infinity, minHeight: height)
            .overlay(alignment: .leading) {
                Image(systemName: "applelogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: logo)
                    .foregroundStyle(.white)
                    .padding(.leading, logoInset)
                    .accessibilityHidden(true)
            }
            .background(.black, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}

extension ButtonStyle where Self == AppleCapsuleButtonStyle {
    /// Sign in with Apple as the design draws it.
    public static var apple: AppleCapsuleButtonStyle { AppleCapsuleButtonStyle() }
}

/// A light grey capsule under a black one: "Continue with phone number" (Save your world).
/// 44 tall, full width, `mutedButton` with the label 18 medium in ink. Pressed, it dims.
public struct MutedCapsuleButtonStyle: ButtonStyle {
    @ScaledMetric(relativeTo: .body) private var height: CGFloat = 44

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .textRole(.action)
            .foregroundStyle(Palette.textPrimary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, Space.l)
            .frame(maxWidth: .infinity, minHeight: height)
            .background(Palette.mutedButton, in: .capsule)
            .contentShape(.capsule)
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

extension ButtonStyle where Self == MutedCapsuleButtonStyle {
    public static var muted: MutedCapsuleButtonStyle { MutedCapsuleButtonStyle() }
}

// MARK: - Legal line

/// A small centred line with links in it: "By continuing you agree to the Terms and Privacy
/// Policy, …" (Save your world). 14 regular in grey, lines 20 apart; the links in ink,
/// underlined. A tap on a link calls `onOpen` with its URL. VoiceOver reads the line and
/// offers the links in its rotor.
public struct LinkedLine: View {
    /// A run of the line: words, or words that open a link.
    public enum Part: Hashable, Sendable {
        case text(String)
        case link(String, URL)
    }

    private let parts: [Part]
    private let onOpen: (URL) -> Void
    @ScaledMetric(relativeTo: .subheadline) private var lineSpacing: CGFloat = 3.4

    public init(_ parts: [Part], onOpen: @escaping (URL) -> Void) {
        self.parts = parts
        self.onOpen = onOpen
    }

    public var body: some View {
        Text(attributed)
            .textRole(.caption)
            .foregroundStyle(Palette.textSecondary)
            .tint(Palette.textPrimary)
            .lineSpacing(lineSpacing)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .environment(\.openURL, OpenURLAction { url in
                onOpen(url)
                return .handled
            })
    }

    private var attributed: AttributedString {
        var line = AttributedString()
        for part in parts {
            switch part {
            case .text(let words):
                line += AttributedString(words)
            case .link(let words, let url):
                var link = AttributedString(words)
                link.link = url
                link.underlineStyle = Text.LineStyle.single
                line += link
            }
        }
        return line
    }
}

// MARK: - Date wheel

/// The design's date wheel ("When's your birthday?"): month, day and year on a white card,
/// three rows showing, the middle one in ink and the others fading to the card's edges, a
/// ruler of ticks down each side. Built from scrolling columns that snap to a row, since the
/// system's wheel draws its own band and curve. Each column is one VoiceOver element that
/// adjusts a step at a time ("Month, March"); a tap on a faded row picks it.
///
/// Measured at 393 × 852: the card (`surface`, corners 20, the card shadow) 155 tall; rows 49
/// apart, 24 regular; the columns centred on the card, the month's 127 wide, the day's 44,
/// the year's 95, in the order the locale writes a date ("March 14, 1995"; Italian "14 marzo
/// 1995"). The ticks (`separator`, 1 thick) start 8 in from each side: 19 over the middle
/// 126, the top, middle and bottom ones 19.5 long, the rest 9.5. The wheel keeps its size at
/// every text size, as the system's does.
public struct DateWheel: View {
    @Binding private var date: BirthDate
    private let years: ClosedRange<Int>
    @Environment(\.calendar) private var calendar
    @Environment(\.locale) private var locale

    static let height: CGFloat = 155
    static let rowHeight: CGFloat = 49

    public init(date: Binding<BirthDate>, years: ClosedRange<Int>) {
        _date = date
        self.years = years
    }

    private enum Part: Hashable {
        case month, day, year
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(order, id: \.self) { part in
                column(part)
            }
        }
        .frame(height: Self.height)
        .mask {
            // Ink in the middle row, fading toward the card's edges (read from the screenshot:
            // the rows above and below go from about 46% of ink next to the middle to 12%).
            LinearGradient(
                stops: [
                    .init(color: .black.opacity(0.08), location: 0),
                    .init(color: .black.opacity(0.15), location: 0.16),
                    .init(color: .black.opacity(0.27), location: 0.21),
                    .init(color: .black.opacity(0.46), location: 0.26),
                    .init(color: .black, location: 0.34),
                    .init(color: .black, location: 0.66),
                    .init(color: .black.opacity(0.46), location: 0.74),
                    .init(color: .black.opacity(0.27), location: 0.79),
                    .init(color: .black.opacity(0.15), location: 0.84),
                    .init(color: .black.opacity(0.08), location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom)
        }
        .frame(maxWidth: .infinity)
        .background { RulerTicks() }
        .card(radius: Radius.xl)
        .dynamicTypeSize(.large)
    }

    @ViewBuilder
    private func column(_ part: Part) -> some View {
        switch part {
        case .month:
            WheelColumn(
                items: Array(1...12),
                selection: Binding(get: { date.month }, set: { date.setMonth($0) }),
                width: 127,
                label: AccountCopy.month,
                text: monthName)
        case .day:
            WheelColumn(
                items: Array(1...BirthDate.days(inMonth: date.month, year: date.year)),
                selection: Binding(get: { date.day }, set: { date.setDay($0) }),
                width: 44,
                label: AccountCopy.day,
                text: { "\($0)" })
        case .year:
            WheelColumn(
                items: Array(years),
                selection: Binding(get: { date.year }, set: { date.setYear($0) }),
                width: 95,
                label: AccountCopy.year,
                text: { String($0) })
        }
    }

    private func monthName(_ month: Int) -> String {
        let names = calendar.standaloneMonthSymbols
        return names.indices.contains(month - 1) ? names[month - 1] : "\(month)"
    }

    /// Month, day and year in the order the locale writes a date.
    private var order: [Part] {
        let pattern = DateFormatter.dateFormat(fromTemplate: "MMMMdy", options: 0, locale: locale) ?? "MMMM d, y"
        let letters: [(Part, Character)] = [(Part.month, "M"), (Part.day, "d"), (Part.year, "y")]
        let found: [(Part, String.Index)] = letters.compactMap { part, letter in
            pattern.firstIndex(of: letter).map { (part, $0) }
        }
        guard found.count == 3 else { return [.month, .day, .year] }
        return found.sorted { $0.1 < $1.1 }.map(\.0)
    }
}

/// One column of the date wheel: rows 49 apart that scroll and snap so one sits in the middle.
private struct WheelColumn: View {
    let items: [Int]
    @Binding var selection: Int
    let width: CGFloat
    let label: String
    let text: (Int) -> String

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var position: Int?

    init(items: [Int], selection: Binding<Int>, width: CGFloat, label: String, text: @escaping (Int) -> String) {
        self.items = items
        _selection = selection
        self.width = width
        self.label = label
        self.text = text
        _position = State(initialValue: selection.wrappedValue)
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(items, id: \.self) { item in
                    Text(verbatim: text(item))
                        .textRole(.pageTitle, weight: .regular)
                        .foregroundStyle(Palette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: width, height: DateWheel.rowHeight)
                        .contentShape(.rect)
                        .onTapGesture { pick(item) }
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $position, anchor: .center)
        .scrollTargetBehavior(.viewAligned)
        .contentMargins(.vertical, (DateWheel.height - DateWheel.rowHeight) / 2, for: .scrollContent)
        .scrollIndicators(.hidden)
        .frame(width: width, height: DateWheel.height)
        .onChange(of: position) { _, row in
            if let row, row != selection { selection = row }
        }
        .onChange(of: selection) { _, value in
            // Set from outside, or kept in the month (31 March to February is the 28th).
            if position != value { pick(value) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: label))
        .accessibilityValue(Text(verbatim: text(selection)))
        .accessibilityAdjustableAction { direction in
            guard let index = items.firstIndex(of: selection) else { return }
            switch direction {
            case .increment: if index + 1 < items.count { pick(items[index + 1]) }
            case .decrement: if index > 0 { pick(items[index - 1]) }
            @unknown default: break
            }
        }
    }

    private func pick(_ item: Int) {
        withAnimation(reduceMotion ? nil : Motion.standard) {
            position = item
        }
        if selection != item { selection = item }
    }
}

/// The ruler down each side of the date wheel. Decoration only.
private struct RulerTicks: View {
    var body: some View {
        Canvas { context, size in
            let count = 19
            let span: CGFloat = 126
            let inset: CGFloat = 8
            let top = (size.height - span) / 2
            var ticks = Path()
            for index in 0..<count {
                let y = top + CGFloat(index) * span / CGFloat(count - 1)
                let isLong = index == 0 || index == count / 2 || index == count - 1
                let length: CGFloat = isLong ? 19.5 : 9.5
                ticks.move(to: CGPoint(x: inset, y: y))
                ticks.addLine(to: CGPoint(x: inset + length, y: y))
                ticks.move(to: CGPoint(x: size.width - inset - length, y: y))
                ticks.addLine(to: CGPoint(x: size.width - inset, y: y))
            }
            context.stroke(ticks, with: .color(Palette.separator), lineWidth: 1)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
