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

    /// "1:31": the time without AM or PM, for voiced lines like "Here since 1:31."
    public static func bareTime(_ date: Date, calendar: Calendar) -> String {
        var text = time(date, calendar: calendar)
        for symbol in [calendar.amSymbol, calendar.pmSymbol] where !symbol.isEmpty {
            text = text.replacingOccurrences(of: symbol, with: "")
        }
        return text.trimmingCharacters(in: .whitespaces.union(CharacterSet(charactersIn: "\u{202F}")))
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
