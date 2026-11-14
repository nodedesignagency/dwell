import Foundation

/// How Dwell writes a time of day: "1:31 PM", "8:02 AM – 8:59 AM", "1:31 PM → now".
///
/// Always formatted in the calendar's time zone and locale, so previews pinned to the
/// sample week read the same everywhere. Times use the system's own spacing (iOS puts a
/// narrow no-break space before AM and PM).
public enum ClockText {
    /// "1:31 PM"
    public static func time(_ date: Date, calendar: Calendar) -> String {
        date.formatted(style(calendar, date: .omitted, time: .shortened))
    }

    /// "6:30 PM": a time of day with no date, like an out-by target.
    public static func time(of time: TimeOfDay, calendar: Calendar) -> String {
        let components = DateComponents(year: 2026, month: 1, day: 15, hour: time.hour, minute: time.minute)
        guard let date = calendar.date(from: components) else { return "\(time.hour):\(time.minute)" }
        return self.time(date, calendar: calendar)
    }

    /// "Sun": a day under a flame or a bar.
    public static func weekday(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).weekday(.abbreviated))
    }

    /// "Friday": a day of the week in full (the weekly wrap's earliest exit).
    public static func weekdayName(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).weekday(.wide))
    }

    /// "Oct 19": a week, by its first day, under a flame.
    public static func monthDay(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).month(.abbreviated).day())
    }

    /// "March 12, 2026": a date in full (the weekly wrap's "Visiting since").
    public static func fullDate(_ date: Date, calendar: Calendar) -> String {
        date.formatted(style(calendar).month(.wide).day().year())
    }

    /// "1:31": the time without AM or PM, for voiced lines like "Here since 1:31."
    public static func bareTime(_ date: Date, calendar: Calendar) -> String {
        var text = time(date, calendar: calendar)
        for symbol in [calendar.amSymbol, calendar.pmSymbol] where !symbol.isEmpty {
            text = text.replacingOccurrences(of: symbol, with: "")
        }
        return text.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\u{202F}")))
    }

    /// "4AM", "10PM": an hour on a chart's axis, without minutes or the space before AM and PM
    /// (Time design). Locales on a 24-hour clock get "04", "22".
    public static func hour(_ hour: Int, calendar: Calendar) -> String {
        let date = calendar.date(from: DateComponents(year: 2026, month: 1, day: 5, hour: hour)) ?? Date(timeIntervalSince1970: 0)
        let text = date.formatted(style(calendar).hour(.defaultDigits(amPM: .abbreviated)))
        return text.replacingOccurrences(of: "\u{202F}", with: "").replacingOccurrences(of: " ", with: "")
    }

    /// "8:02 AM – 8:59 AM" for a finished stretch, "1:31 PM → now" while it is still going.
    public static func span(from start: Date, to end: Date?, calendar: Calendar) -> String {
        guard let end else { return "\(time(start, calendar: calendar)) → now" }
        return "\(time(start, calendar: calendar)) – \(time(end, calendar: calendar))"
    }

    /// "Mon, Oct 19": a day named in a sentence or on a button.
    public static func dayName(_ day: DwellDay, calendar: Calendar) -> String {
        day.start(in: calendar).formatted(style(calendar).weekday(.abbreviated).month(.abbreviated).day())
    }

    /// "Oct 19 – 25", or "Sep 28 – Oct 4" across a month: a week named on a label.
    public static func dayRange(_ first: DwellDay, _ last: DwellDay, calendar: Calendar) -> String {
        let start = first.start(in: calendar)
        let end = last.start(in: calendar)
        let month = style(calendar).month(.abbreviated)
        let day = style(calendar).day()
        let tail = first.month == last.month ? end.formatted(day) : "\(end.formatted(month)) \(end.formatted(day))"
        return "\(start.formatted(month)) \(start.formatted(day)) – \(tail)"
    }

    private static func style(
        _ calendar: Calendar,
        date: Date.FormatStyle.DateStyle? = nil,
        time: Date.FormatStyle.TimeStyle? = nil
    ) -> Date.FormatStyle {
        Date.FormatStyle(
            date: date, time: time,
            locale: calendar.locale ?? .current, calendar: calendar, timeZone: calendar.timeZone)
    }
}
