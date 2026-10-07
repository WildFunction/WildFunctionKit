import UIKit

extension UIResponder {
    /// The closest view controller up the responder chain, or `nil` when there is none.
    ///
    /// A view finds the controller whose root view contains it. A controller skips itself and
    /// returns the controller that contains its view, which is usually its parent.
    ///
    /// ```swift
    /// // Attach a child controller to whatever screen this view ends up on.
    /// if let parent = view.wf_nearestViewController {
    ///     parent.addChild(hostingController)
    ///     hostingController.didMove(toParent: parent)
    /// }
    /// ```
    public var wf_nearestViewController: UIViewController? {
        (next as? UIViewController) ?? next?.wf_nearestViewController
    }
}
