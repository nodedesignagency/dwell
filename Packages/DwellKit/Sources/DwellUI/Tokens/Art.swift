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
        /// Rising bars: insights. Not on a screen yet.
        public static let chart = Image("illustration/chart", bundle: .module)
    }

    /// Line icons from the design, drawn as templates so they take the ink they're given:
    /// the clock by a timeline row's duration (14), the row's chevron (8 × 14), and the
    /// arrow on "This week" (22; mirrored, it points back).
    public static let clock = Image("glyph/clock", bundle: .module).renderingMode(.template)
    public static let chevron = Image("glyph/chevron", bundle: .module).renderingMode(.template)
    public static let arrow = Image("icon/arrow", bundle: .module).renderingMode(.template)

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
