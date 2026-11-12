import Foundation

/// A point on the map, in degrees. DwellCore stays Foundation-only, so screens turn it into a
/// `CLLocationCoordinate2D` where MapKit needs one.
public struct Coordinate: Hashable, Codable, Sendable {
    public var latitude: Double
    public var longitude: Double

    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Who the user is in Dwell (brief §7.4, A.6: avatar, username, city).
public struct Profile: Hashable, Sendable {
    public var name: String
    /// Without the "@": "maya".
    public var username: String
    /// Where the user lives, as a place name: "Brooklyn". The scratch map's coverage is of it.
    public var city: String
    /// The middle of `city`. You's map is centred here, never on home or any of the user's
    /// places, so the profile never shows where they live (brief §8.2).
    public var cityCenter: Coordinate

    public init(name: String, username: String, city: String, cityCenter: Coordinate) {
        self.name = name
        self.username = username
        self.city = city
        self.cityCenter = cityCenter
    }
}

/// A clock time with no date: an out-by target ("6:30 PM").
public struct TimeOfDay: Hashable, Codable, Sendable {
    public var hour: Int
    public var minute: Int

    public init(hour: Int, minute: Int) {
        self.hour = hour
        self.minute = minute
    }

    /// This time on the calendar date `day` starts on.
    public func date(on day: DwellDay, calendar: Calendar) -> Date {
        let components = DateComponents(year: day.year, month: day.month, day: day.day, hour: hour, minute: minute)
        return calendar.date(from: components) ?? day.start(in: calendar)
    }
}
