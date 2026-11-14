import DwellCore
import SwiftUI

/// A visit's time on its day (Visit edit, 14 Nov): the day from 4 AM to 4 AM as a grey track,
/// the visit on it in blue with its arrival and departure in white, and the hours under it.
///
/// Measured from the screenshot at 393 × 852: the track 48 tall, corners 10 (`spanTrack`);
/// the visit 3 in from its top and bottom, corners 7, `span` lightening to `spanEdge` over its
/// last 22 at each end, where it's dragged; the times 14 medium, 8 in from its ends; the hours
/// 14 regular in grey, 8 below.
///
/// Drag an end to move it, or the split's line once a split is chosen; the visit's own rules
/// (`VisitDraft`) round to 5 minutes and keep it between its neighbours, so `onMove` hands over
/// where the finger is and the caller decides where the end goes. An end that can't move (a
/// visit still going, one merged with the next) doesn't respond. When the visit is too short
/// for its times, they sit on the track beside it. VoiceOver adjusts each end and the split
/// 5 minutes at a time.
///
/// The hours are placed at their own times, every 4 hours from the day's start, so the visit
/// lines up with them; the design spreads its six evenly from edge to edge and labels the last
/// "12 PM" (QUESTIONS.md).
public struct VisitSpanTrack: View {
    public nonisolated enum Handle: Hashable, Sendable {
        case arrival, departure, split
    }

    @ScaledMetric(relativeTo: .subheadline) private var trackHeight: CGFloat = 48
    @ScaledMetric(relativeTo: .subheadline) private var axisHeight: CGFloat = 18

    private let day: DateInterval
    private let arrival: Date
    private let end: Date
    private let endsNow: Bool
    private let split: Date?
    private let movable: Set<Handle>
    private let calendar: Calendar
    private let step: TimeInterval
    private let onMove: (Handle, Date) -> Void

    @State private var dragging: Handle?
    @State private var grab: CGFloat = 0
    @State private var widths: [Handle: CGFloat] = [:]

    /// The visit's ends sit this far in from the block's.
    private static let inset: CGFloat = 8
    /// How far from an end a touch still takes hold of it.
    private static let reach: CGFloat = 36

    /// - Parameters:
    ///   - day: the Dwell day, 4 AM to 4 AM.
    ///   - end: where the visit ends as it stands: now while it's still going.
    ///   - endsNow: the visit is still going, so its end reads "Now".
    ///   - split: where a split waiting for Save falls, if one is.
    ///   - movable: which handles respond.
    public init(
        day: DateInterval,
        arrival: Date,
        end: Date,
        endsNow: Bool,
        split: Date? = nil,
        movable: Set<Handle>,
        calendar: Calendar,
        step: TimeInterval = VisitDraft.step,
        onMove: @escaping (Handle, Date) -> Void
    ) {
        self.day = day
        self.arrival = arrival
        self.end = end
        self.endsNow = endsNow
        self.split = split
        self.movable = movable
        self.calendar = calendar
        self.step = step
        self.onMove = onMove
    }

    public var body: some View {
        VStack(spacing: Space.s) {
            GeometryReader { proxy in
                track(width: proxy.size.width)
            }
            .frame(height: trackHeight)
            .background { measurer }
            // Mirrored for right-to-left: the day still runs from the leading edge.
            .environment(\.layoutDirection, .leftToRight)

            axis
                .frame(height: axisHeight)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(verbatim: VisitEditCopy.span))
    }

    // MARK: Track

    private func track(width: CGFloat) -> some View {
        let start = x(for: arrival, width: width)
        let finish = max(x(for: end, width: width), start + 6)
        let block = CGRect(x: start, y: 3, width: finish - start, height: trackHeight - 6)
        let fits = timesFit(in: block.width)
        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: Radius.track)
                .fill(Palette.spanTrack)

            SpanBlock(width: block.width)
                .frame(width: block.width, height: block.height)
                .offset(x: block.minX, y: block.minY)

            if fits {
                HStack(spacing: 0) {
                    timeText(arrivalText, color: Palette.inverseText)
                    Spacer(minLength: Self.inset)
                    timeText(endText, color: Palette.inverseText)
                }
                .padding(.horizontal, Self.inset)
                .frame(width: block.width, height: trackHeight)
                .offset(x: block.minX)
            } else {
                beside(block: block, width: width)
            }

            if let split {
                SplitMark(time: ClockText.time(split, calendar: calendar))
                    .frame(height: trackHeight)
                    .fixedSize(horizontal: true, vertical: false)
                    .position(x: x(for: split, width: width), y: trackHeight / 2)
            }

            handles(block: block, width: width)
        }
        .frame(width: width, height: trackHeight, alignment: .topLeading)
        .contentShape(.rect)
        .gesture(drag(block: block, width: width))
    }

    /// Both times beside a visit too short to hold them, on the side with more room.
    private func beside(block: CGRect, width: CGFloat) -> some View {
        let text = "\(arrivalText) – \(endText)"
        let leftRoom = block.minX
        let rightRoom = width - block.maxX
        let onRight = rightRoom >= leftRoom
        return timeText(text, color: Palette.textPrimary)
            .minimumScaleFactor(0.7)
            .frame(width: max(0, (onRight ? rightRoom : leftRoom) - Self.inset * 1.5),
                   height: trackHeight,
                   alignment: onRight ? .leading : .trailing)
            .offset(x: onRight ? block.maxX + Self.inset : Self.inset / 2)
    }

    private func timeText(_ text: String, color: Color) -> some View {
        Text(verbatim: text)
            .textRole(.caption, weight: .medium)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var arrivalText: String { ClockText.time(arrival, calendar: calendar) }

    private var endText: String {
        endsNow ? VisitEditCopy.now : ClockText.time(end, calendar: calendar)
    }

    /// Whether the two times, and a split's chip, fit inside the visit.
    private func timesFit(in blockWidth: CGFloat) -> Bool {
        let times = (widths[.arrival] ?? 60) + (widths[.departure] ?? 60) + Self.inset * 3
        let chip = split == nil ? 0 : (widths[.split] ?? 64) + Self.inset * 2
        return times + chip <= blockWidth
    }

    /// The times at their natural widths, measured out of sight.
    private var measurer: some View {
        HStack {
            measured(arrivalText, .arrival)
            measured(endText, .departure)
            if let split {
                SplitMark(time: ClockText.time(split, calendar: calendar))
                    .fixedSize()
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { widths[.split] = $0 }
            }
        }
        .fixedSize()
        .hidden()
        .accessibilityHidden(true)
    }

    private func measured(_ text: String, _ handle: Handle) -> some View {
        timeText(text, color: .clear)
            .fixedSize()
            .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { widths[handle] = $0 }
    }

    // MARK: Dragging

    private func drag(block: CGRect, width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 2)
            .onChanged { value in
                if dragging == nil {
                    guard let handle = handle(near: value.startLocation.x, block: block, width: width, moving: value.translation.width) else { return }
                    dragging = handle
                    grab = value.startLocation.x - position(of: handle, block: block, width: width)
                }
                guard let current = dragging else { return }
                onMove(current, date(at: value.location.x - grab, width: width))
            }
            .onEnded { _ in
                dragging = nil
            }
    }

    /// The handle a touch takes hold of: the nearest movable one within reach, or inside the
    /// visit. Where both ends are close together, the way the finger moves decides.
    private func handle(near x: CGFloat, block: CGRect, width: CGFloat, moving: CGFloat) -> Handle? {
        let candidates = movable.filter { $0 != .split || split != nil }
        let inside = x >= block.minX - Self.reach / 2 && x <= block.maxX + Self.reach / 2
        let near = candidates
            .map { ($0, abs(position(of: $0, block: block, width: width) - x)) }
            .filter { $0.1 <= Self.reach || inside }
            .sorted { $0.1 < $1.1 }
        guard let nearest = near.first else { return nil }
        if candidates.contains(.arrival), candidates.contains(.departure), block.width < Self.reach,
           nearest.0 != .split {
            return moving < 0 ? .arrival : .departure
        }
        return nearest.0
    }

    private func position(of handle: Handle, block: CGRect, width: CGFloat) -> CGFloat {
        switch handle {
        case .arrival: block.minX
        case .departure: block.maxX
        case .split: split.map { x(for: $0, width: width) } ?? block.midX
        }
    }

    // MARK: VoiceOver

    /// An element for each end and the split, over where each sits, adjusting 5 minutes at a time.
    private func handles(block: CGRect, width: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            handleElement(.arrival, at: block.minX, label: VisitEditCopy.arrived, value: arrivalText, date: arrival)
            if let split {
                handleElement(.split, at: x(for: split, width: width), label: VisitEditCopy.splitAt,
                              value: ClockText.time(split, calendar: calendar), date: split)
            }
            handleElement(.departure, at: block.maxX, label: VisitEditCopy.left, value: endText, date: end)
        }
    }

    private func handleElement(_ handle: Handle, at x: CGFloat, label: String, value: String, date: Date) -> some View {
        Color.clear
            .frame(width: 44, height: trackHeight)
            .position(x: x, y: trackHeight / 2)
            .allowsHitTesting(false)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: label))
            .accessibilityValue(Text(verbatim: value))
            .modifier(Adjustable(isOn: movable.contains(handle)) { direction in
                switch direction {
                case .increment: onMove(handle, date.addingTimeInterval(step))
                case .decrement: onMove(handle, date.addingTimeInterval(-step))
                @unknown default: break
                }
            })
    }

    // MARK: Axis

    /// Every 4 hours from the day's start, each at its own time; the first and last kept
    /// inside the track.
    private var axis: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(marks, id: \.self) { mark in
                    let markX = position(of: mark, width: proxy.size.width)
                    let trackWidth = proxy.size.width
                    Text(verbatim: ClockText.hourMark(mark, calendar: calendar))
                        .textRole(.caption)
                        .foregroundStyle(Palette.textSecondary)
                        .lineLimit(1)
                        .fixedSize()
                        .alignmentGuide(.leading) { size in
                            let centred = size[HorizontalAlignment.center] - markX
                            return min(max(centred, size.width - trackWidth), 0)
                        }
                }
            }
            .frame(width: proxy.size.width, alignment: .topLeading)
        }
        .environment(\.layoutDirection, .leftToRight)
        .accessibilityHidden(true)
    }

    private var marks: [Date] {
        stride(from: 0.0, through: day.duration, by: 4 * 3600).map { day.start.addingTimeInterval($0) }
    }

    // MARK: Scale

    /// Where an hour mark's middle falls.
    private func position(of mark: Date, width: CGFloat) -> CGFloat {
        x(for: mark, width: width)
    }

    private func x(for date: Date, width: CGFloat) -> CGFloat {
        guard day.duration > 0 else { return 0 }
        let share = date.timeIntervalSince(day.start) / day.duration
        return CGFloat(min(max(share, 0), 1)) * width
    }

    private func date(at x: CGFloat, width: CGFloat) -> Date {
        guard width > 0 else { return day.start }
        let share = Double(min(max(x, 0), width) / width)
        return day.start.addingTimeInterval(share * day.duration)
    }
}

/// The visit on the track: `span`, lightening to `spanEdge` over the last 22 at each end.
private struct SpanBlock: View {
    let width: CGFloat

    var body: some View {
        let edge = min(22 / max(width, 1), 0.5)
        let stops: [Gradient.Stop] = [
            Gradient.Stop(color: Palette.spanEdge, location: 0),
            Gradient.Stop(color: Palette.span, location: edge),
            Gradient.Stop(color: Palette.span, location: 1 - edge),
            Gradient.Stop(color: Palette.spanEdge, location: 1),
        ]
        RoundedRectangle(cornerRadius: Radius.track - 3)
            .fill(LinearGradient(stops: stops, startPoint: .leading, endPoint: .trailing))
    }
}

/// Where a split falls: a white line down the visit, its time on a white chip in the middle.
private struct SplitMark: View {
    let time: String

    var body: some View {
        ZStack {
            Rectangle()
                .fill(Palette.ring)
                .frame(width: 2)
                .padding(.vertical, 3)
            Text(verbatim: time)
                .textRole(.footnote, weight: .medium)
                .foregroundStyle(Palette.textPrimary)
                .lineLimit(1)
                .padding(.horizontal, Space.s)
                .padding(.vertical, Space.xxs)
                .background(Palette.ring, in: .capsule)
                .environment(\.colorScheme, .light)
        }
        .accessibilityHidden(true)
    }
}

/// Makes an element adjustable only when its handle can move.
private struct Adjustable: ViewModifier {
    let isOn: Bool
    let adjust: (AccessibilityAdjustmentDirection) -> Void

    func body(content: Content) -> some View {
        if isOn {
            content.accessibilityAdjustableAction(adjust)
        } else {
            content
        }
    }
}

private struct SpanTrackPreview: View {
    // 8:45 AM to 5:30 PM, as the design.
    @State private var arrival = SampleData.today.start(in: SampleData.calendar).addingTimeInterval(4.75 * 3600)
    @State private var departure = SampleData.today.start(in: SampleData.calendar).addingTimeInterval(13.5 * 3600)

    var body: some View {
        VisitSpanTrack(
            day: SampleData.today.interval(in: SampleData.calendar),
            arrival: arrival, end: departure, endsNow: false,
            movable: [.arrival, .departure], calendar: SampleData.calendar
        ) { handle, date in
            let rounded = Date(timeIntervalSinceReferenceDate: (date.timeIntervalSinceReferenceDate / 300).rounded() * 300)
            switch handle {
            case .arrival: arrival = min(rounded, departure.addingTimeInterval(-300))
            case .departure: departure = max(rounded, arrival.addingTimeInterval(300))
            case .split: break
            }
        }
        .padding(Space.l)
    }
}

#Preview("Span · drag the ends") {
    SpanTrackPreview()
}
