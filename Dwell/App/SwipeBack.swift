import UIKit

/// Pages that draw the design's own back button (`BackButton`) hide the system navigation
/// bar, and hiding it also turns off the swipe from the left edge that goes back. This turns
/// the swipe back on for every navigation stack that has a page to go back to, so the
/// system's behaviour stays under the design's button.
extension UINavigationController: @retroactive UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Never on the root page, and never while a push or pop is still animating.
        viewControllers.count > 1 && transitionCoordinator == nil
    }
}
