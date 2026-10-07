import Testing
import UIKit
@testable import WildFunctionKit

@MainActor
@Suite("UIResponder+WF")
struct UIResponderWFTests {
    @Test("A view finds the controller that owns its root view")
    func findsOwningController() {
        let controller = UIViewController()
        let child = UIView()
        let grandchild = UIView()
        controller.view.addSubview(child)
        child.addSubview(grandchild)

        #expect(grandchild.wf_nearestViewController === controller)
        #expect(child.wf_nearestViewController === controller)
    }

    @Test("A controller's root view finds that controller, not its parent")
    func rootViewFindsItsOwnController() {
        let parent = UIViewController()
        let child = UIViewController()
        parent.addChild(child)
        parent.view.addSubview(child.view)
        child.didMove(toParent: parent)
        let leaf = UIView()
        child.view.addSubview(leaf)

        #expect(leaf.wf_nearestViewController === child)
        #expect(child.view.wf_nearestViewController === child)
    }

    @Test("A controller skips itself and returns its parent")
    func controllerReturnsParent() {
        let parent = UIViewController()
        let child = UIViewController()
        parent.addChild(child)
        parent.view.addSubview(child.view)
        child.didMove(toParent: parent)

        #expect(child.wf_nearestViewController === parent)
    }

    @Test("A detached view has no controller")
    func detachedViewHasNone() {
        let parent = UIView()
        let view = UIView()
        parent.addSubview(view)

        #expect(view.wf_nearestViewController == nil)
    }
}
