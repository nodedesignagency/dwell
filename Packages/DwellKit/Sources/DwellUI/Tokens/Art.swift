import DwellCore
import SwiftUI

/// Raster art from the designs, in `Images.xcassets`. Colours live in `Colors.xcassets`,
/// which `scripts/tokens.py` owns; images live apart so the script never touches them.
public enum Art {
    /// Behind Today's header. Light only: dark mode dims it until a night version exists.
    public static let sunrise = Image("hero/sunrise", bundle: .module)
    /// The day pill on Today.
    public static let calendar = Image("icon/calendar", bundle: .module)
    /// The confirmation card.
    public static let confirmVisit = Image("illustration/confirmVisit", bundle: .module)
    /// The sample week's profile picture, until profiles are in the repository.
    public static let sampleAvatar = Image("sample/avatar", bundle: .module)
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
}
