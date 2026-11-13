import DwellCore
import SwiftUI

/// Raster art from the designs, in `Images.xcassets`. Colours live in `Colors.xcassets`,
/// which `scripts/tokens.py` owns; images live apart so the script never touches them.
public enum Art {
    /// The day pill on Today.
    public static let calendar = Image("icon/calendar", bundle: .module)
    /// The confirmation card.
    public static let confirmVisit = Image("illustration/confirmVisit", bundle: .module)
    /// The sample week's profile picture, until profiles are in the repository.
    public static let sampleAvatar = Image("sample/avatar", bundle: .module)

    /// Today's hero tiles: the 3D briefcase (At work) and sunrise (Yours).
    public static let heroWork = Image("heroIcon/work", bundle: .module)
    public static let heroYours = Image("heroIcon/yours", bundle: .module)

    /// Section headers: the 3D calendar ("This week"), sun with a clock ("Your day") and
    /// rocket ("Getting started").
    public static let thisWeek = Image("icon/thisWeek", bundle: .module)
    public static let yourDay = Image("icon/yourDay", bundle: .module)
    public static let gettingStarted = Image("icon/gettingStarted", bundle: .module)

    /// 3D art that isn't a category's.
    public enum Illustration {
        /// A pin on a folded map: a place.
        public static let place = Image("illustration/place", bundle: .module)
        /// A pin on hexagon cells: the scratch map.
        public static let cells = Image("illustration/cells", bundle: .module)
        /// A clock: time in a sentence ("Stay put for 5 minutes").
        public static let clock = Image("illustration/clock", bundle: .module)
        /// Rising bars: insights ("Waiting for your insights" on Today).
        public static let chart = Image("illustration/chart", bundle: .module)
        /// A push pin: how many places ("41 places" on You).
        public static let pushpin = Image("illustration/pushpin", bundle: .module)
        /// The globe: how much of the city is mapped ("3.2% mapped" on You).
        public static let globe = Image("illustration/globe", bundle: .module)
        /// "Work vs yours" in puffy white letters with a navy outline and a white rim: the
        /// weekly wrap's second page (the designer's art, 13 Nov). 3x: 165 × 95 pt.
        public static let workVsYours = Image("illustration/workVsYours", bundle: .module)
        /// A white wall clock's face with no hands (the designer's art, 13 Nov): the weekly
        /// wrap's earliest exit, its hands drawn in code (`WallClock`). 1080 px, square.
        public static let clockFace = Image("illustration/clockFace", bundle: .module)
    }

    /// Line icons from the design, drawn as templates so they take the ink they're given:
    /// the clock by a timeline row's duration (14), the row's chevron (8 × 14), and the
    /// arrow on "This week" (22; mirrored, it points back).
    public static let clock = Image("glyph/clock", bundle: .module).renderingMode(.template)
    public static let chevron = Image("glyph/chevron", bundle: .module).renderingMode(.template)
    public static let arrow = Image("icon/arrow", bundle: .module).renderingMode(.template)

    /// You's 3D art. Exported at 4x; each canvas is 4x the frame it's shown in, so the art
    /// keeps the design's size: section headers 20 ("Streaks", "Badges"), the profile's pills
    /// 20 (the push pin on "41 places", the globe on "3.2% mapped").
    public static let streaks = Image("icon/streaks", bundle: .module)
    public static let badges = Image("icon/badges", bundle: .module)

    /// You's flat glyphs (Solar, duotone), templates like the timeline's: the settings gear
    /// (20), the sun, alarm clock and trophy on the push switches (18), the privacy line's lock
    /// (16), the pencil by the out-by time (14).
    public enum Glyph {
        public static let pencil = Image("glyph/pencil", bundle: .module).renderingMode(.template)
        public static let settings = Image("glyph/settings", bundle: .module).renderingMode(.template)
        public static let sun = Image("glyph/sun", bundle: .module).renderingMode(.template)
        public static let alarm = Image("glyph/alarm", bundle: .module).renderingMode(.template)
        public static let trophy = Image("glyph/trophy", bundle: .module).renderingMode(.template)
        public static let lock = Image("glyph/lock", bundle: .module).renderingMode(.template)
    }

    /// A streak's day (You): lit when kept, grey when a freeze covered it, a dashed outline when
    /// missed or still to come. 20 × 24.
    public enum Flame {
        public static let kept = Image("flame/kept", bundle: .module)
        public static let frozen = Image("flame/frozen", bundle: .module)
        public static let open = Image("flame/open", bundle: .module)
    }

    /// The dial's art (You): one 3D icon for each stop, from the design: a sprout (Peace), sun
    /// behind clouds (Calm), three pills (Plain), a lightning bolt (Push), a flame (Grind).
    /// Trimmed to the art, so `DialArt` sizes them alike.
    public static func dial(_ stop: Dial.Stop) -> Image {
        Image("dial/\(stop.rawValue)", bundle: .module)
    }

    /// The tab bar's icons, from the design. Drawn for light; their dark versions invert the
    /// tones (white outline, dark fill), derived by us.
    public enum Tab {
        public static let today = Image("tab/today", bundle: .module)
        public static let map = Image("tab/map", bundle: .module)
        public static let time = Image("tab/time", bundle: .module)
        public static let you = Image("tab/you", bundle: .module)
    }
}

extension Art {
    /// A badge's medal at its tier, where the design has one yet (Explorer at gold so far).
    /// Locked badges show their medal in grey (`BadgeTile`). 25 square.
    public static func badge(_ kind: Badge.Kind, tier: Badge.Tier?) -> Image? {
        switch (kind, tier) {
        case (.explorer, .gold), (.explorer, nil): Image("badge/explorerGold", bundle: .module)
        default: nil
        }
    }

    /// A category's 3D illustration, where the design has one yet.
    public static func illustration(_ category: PlaceCategory) -> Image? {
        category.illustrationName.map { Image($0, bundle: .module) }
    }

    /// What the Getting started shuffle turns through while Dwell waits for the first stop:
    /// the house first (as in the design, and the one left standing under Reduce Motion),
    /// every other category with 3D art, then a place pin and the map's cells. Category art
    /// joins by itself once it's listed in `PlaceCategory.illustrationName`.
    public static var firstStopIcons: [Image] {
        var icons: [Image] = []
        let categories = [PlaceCategory.home] + PlaceCategory.allCases.filter { $0 != .home }
        for category in categories {
            if let art = illustration(category) {
                icons.append(art)
            }
        }
        return icons + [Illustration.place, Illustration.cells]
    }
}

extension PlaceCategory {
    /// The category's 3D illustration from the design, where one exists yet. Add each new
    /// one here (art in `categoryIcon/`): headlines, the confirmation card and the Getting
    /// started shuffle all pick it up.
    var illustrationName: String? {
        switch self {
        case .work: "categoryIcon/work"
        case .home: "categoryIcon/home"
        case .foodAndDrink: "categoryIcon/foodAndDrink"
        default: nil
        }
    }

    /// The category's flat glyph from the design (Solar, bold duotone), where one exists yet.
    /// Vector templates: they take whatever ink they're given, the second tone at 50%.
    var glyphName: String? {
        switch self {
        case .work: "glyph/work"
        case .home: "glyph/home"
        case .foodAndDrink: "glyph/foodAndDrink"
        default: nil
        }
    }
}

extension Art {
    /// The 3D art that pops out around a wrap page's title (Weekly wrap design: an alarm clock,
    /// a briefcase, a flame and a trophy). Stand-ins until the designer's four arrive
    /// [ICON NEEDED]: the headline's clock for the alarm clock, the hero tile's briefcase,
    /// You's streak flame, and You's badge medal for the trophy. Upload them at 4x of 56 pt
    /// (224 px) into `sticker/` and point each case here.
    public static func sticker(_ sticker: WrapSticker) -> Image {
        switch sticker {
        case .alarmClock: Illustration.clock
        case .briefcase: heroWork
        case .flame: streaks
        case .trophy: badges
        }
    }
}

extension Art {
    /// The Insights tiles' 3D art (Insights design): the alarm clock by the week's time, the
    /// briefcase by your usual (Today's At work tile), the sunrise by the WFH days (Today's
    /// Yours tile). The alarm clock is a stand-in, the headline's clock, until the design's
    /// arrives [ICON NEEDED] (the weekly wrap waits on the same one). The chart stands by an
    /// insight's lone number.
    public static func insightStat(_ icon: InsightStat.Icon) -> Image {
        switch icon {
        case .alarmClock: Illustration.clock
        case .briefcase: heroWork
        case .sunrise: heroYours
        case .chart: Illustration.chart
        }
    }
}

extension InsightStat.Tint {
    /// The glow behind a tile's art.
    public var color: Color {
        switch self {
        case .category(let category): category.color
        case .yours: Palette.yours
        case .accent: Palette.accent
        }
    }
}
