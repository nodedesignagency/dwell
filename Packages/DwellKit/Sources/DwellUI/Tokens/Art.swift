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

    /// Section headers: the 3D calendar ("This week") and sun with a clock ("Your day").
    public static let thisWeek = Image("icon/thisWeek", bundle: .module)
    public static let yourDay = Image("icon/yourDay", bundle: .module)

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

extension PlaceCategory {
    /// The category's 3D illustration from the design, where one exists yet.
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
