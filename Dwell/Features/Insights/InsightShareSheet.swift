import DwellCore
import DwellUI
import SwiftUI
import UIKit
import UniformTypeIdentifiers

/// "Share this insight" (Insights design, 14 Nov): a sheet that slides up over the page, with
/// the card as it will be shared, the five ways to share it, and what sharing never shows.
/// From the Insights page's Share and from Share on Today's deck (brief A.2, A.7: insight
/// detail and share preview; §10, share cards).
///
/// The card shows the weeks the page was showing (4W, or 3M, and how far back); from Today,
/// the insight's own four. What's shared is a 1080 × 1920 image of the card on the page's
/// grey (`InsightShareImage`), drawn only when it's shared. Nothing on it names a place or
/// home: an insight that would (a new neighborhood) isn't shareable at all (brief §8.2).
struct InsightShareSheet: View {
    let detail: InsightDetail
    var span: InsightSpan = .fourWeeks
    var page = 0
    let now: Date
    let onClose: () -> Void

    @Environment(\.dial) private var dial
    @Environment(\.calendar) private var calendar

    var body: some View {
        ShareSheetCard(
            title: InsightCopy.shareTitle,
            closeLabel: ShareCopy.close,
            privacy: ShareCopy.privacy,
            onClose: onClose
        ) {
            InsightShareCard(detail: detail, span: span, page: page, now: now)
        } targets: {
            let item = InsightShareItem(detail: detail, span: span, page: page, now: now, dial: dial, calendar: calendar)
            ShareTargets(
                item: item,
                previewTitle: InsightCopy.shareImageTitle,
                instagramHint: InsightCopy.shareInstagramHint,
                image: { item.image() })
        }
    }
}

/// The insight as it's shared (Insights design, 14 Nov): white, corners 20, the card's shadow;
/// 16 in: the sentence as on the page, a dashed line, the weeks' bars (no window or range: a
/// shared card can't be stepped through), a dashed line, then "POWERED BY" (14, grey, set in
/// capitals) and the Dwell logo. An insight with no weeks shows Today's chart of its days, or
/// its one number.
///
/// Measured at 393 × 852: the sentence 16 below the top; 16 to the line; 16 to the bars (the
/// tallest 114); the labels; 12 to the line; 16 to the foot (the logo 0.83 of the stamp's, its
/// wordmark 14.5 tall); 16 below.
struct InsightShareCard: View {
    let detail: InsightDetail
    var span: InsightSpan = .fourWeeks
    var page = 0
    let now: Date
    /// Off for the image: the bars are drawn grown, since an image never appears.
    var growsIn = true

    @Environment(\.calendar) private var calendar

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            InsightHeadline(headline: detail.headline)
            if hasChart {
                DashedDivider()
                    .padding(.top, Space.l)
                chart
                    .padding(.top, Space.l)
                DashedDivider()
                    .padding(.top, Space.m)
            } else {
                DashedDivider()
                    .padding(.top, Space.l)
            }
            foot
                .padding(.top, Space.l)
        }
        .padding(Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }

    private var hasChart: Bool {
        detail.trend != nil || !detail.days.isEmpty || lone != nil
    }

    /// The one number, for an insight with neither weeks nor days.
    private var lone: String? {
        guard detail.trend == nil, detail.days.isEmpty else { return nil }
        guard case .text(let value)? = detail.stats.first?.value else { return nil }
        return value
    }

    @ViewBuilder
    private var chart: some View {
        if let trend = detail.trend {
            let page = min(self.page, trend.lastPage(span))
            InsightTrendChart(
                trend.bars(span: span, page: page, now: now, calendar: calendar),
                measure: trend.measure,
                tint: trend.category?.color ?? Palette.accent,
                glint: trend.category?.glint ?? Palette.accent,
                growsIn: growsIn)
        } else if !detail.days.isEmpty {
            WeekBarsChart(detail.days)
        } else if let lone {
            Text(verbatim: lone)
                .textRole(.dataHero)
                .foregroundStyle(Palette.accent)
        }
    }

    private var foot: some View {
        HStack(alignment: .center, spacing: Space.s) {
            Text(verbatim: InsightCopy.poweredBy.uppercased())
                .textRole(.caption)
                .foregroundStyle(Palette.textSecondary)
            Spacer(minLength: Space.s)
            DwellLogo(scale: 0.83)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(verbatim: "\(InsightCopy.poweredBy) Dwell"))
    }
}

/// The shared image's canvas: 1080 × 1920 (brief §10's story size, as the postcard shares),
/// the card centred on the page's grey, 20 from the sides. In light, whatever the phone's mode.
/// No share-card template is designed yet; this is the card as the sheet shows it.
struct InsightShareImage: View {
    let detail: InsightDetail
    let span: InsightSpan
    let page: Int
    let now: Date

    static let size = CGSize(width: 393, height: 393 * 1920 / 1080)

    var body: some View {
        ZStack {
            Palette.background
            InsightShareCard(detail: detail, span: span, page: page, now: now, growsIn: false)
                .padding(.horizontal, Space.screen)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}

/// What the share sheet hands on: a PNG of `InsightShareImage`, drawn only when a target asks
/// for it (as the postcard's is). Save, Copy and Messages draw it when they're touched.
nonisolated struct InsightShareItem: Transferable {
    let detail: InsightDetail
    let span: InsightSpan
    let page: Int
    let now: Date
    let dial: Dial
    let calendar: Calendar

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .png) { item in
            guard let data = await MainActor.run(body: { item.image()?.pngData() }) else {
                throw CocoaError(.fileWriteUnknown)
            }
            return data
        }
        .suggestedFileName("Insight.png")
    }

    /// The 1080 × 1920 image.
    @MainActor
    func image() -> UIImage? {
        let canvas = InsightShareImage(detail: detail, span: span, page: page, now: now)
            .environment(\.dial, dial)
            .environment(\.calendar, calendar)
            .environment(\.colorScheme, .light)
        let renderer = ImageRenderer(content: canvas)
        renderer.proposedSize = ProposedViewSize(InsightShareImage.size)
        renderer.scale = 1080 / InsightShareImage.size.width
        return renderer.uiImage
    }
}

// MARK: - Shared with the page

/// The insight's sentence, as the page and the shared card set it: data in ink with its art and
/// the words at 70% (`VoicedSentenceView`, 24, as Time's headline), or a written-out line in ink.
struct InsightHeadline: View {
    let headline: InsightDetail.Headline

    var body: some View {
        switch headline {
        case .sentence(let sentence):
            VoicedSentenceView(sentence, role: .voiceHero, ink: Palette.textOnHero, dataInk: Palette.textPrimary)
        case .line(let line):
            VoiceText(line)
                .textRole(.voiceHero)
                .foregroundStyle(Palette.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension InsightTrend {
    /// A window of weeks as the chart draws them. 4W labels every bar ("Oct 5", "Last week");
    /// 3M only the first week of each month ("Sep"). Weeks before Dwell was recording keep
    /// their slot, with no bar and no label.
    func bars(span: InsightSpan, page: Int, now: Date, calendar: Calendar) -> [InsightTrendChart.Bar] {
        window(span, page: page, calendar: calendar).map { week in
            let label: String? = switch span {
            case .fourWeeks: InsightCopy.barLabel(week.period, focus: focus, now: now, calendar: calendar)
            case .threeMonths: week.period.first.day <= 7 ? InsightCopy.monthLabel(week.period, calendar: calendar) : nil
            }
            return InsightTrendChart.Bar(
                id: week.id,
                label: week.value == nil ? nil : label,
                name: InsightCopy.weekName(week.period, calendar: calendar),
                value: week.value,
                isFocus: week.period == focus)
        }
    }
}
