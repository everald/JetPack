import UIKit


@objc(JetPack_ViewController)
public /* non-final */ class ViewController: UIViewController {

	public typealias SeguePreparation = (segue: UIStoryboardSegue) -> Void

	private var viewLayoutAnimation: Animation?
	private var seguePreparation: SeguePreparation?


	public init() {
		super.init(nibName: nil, bundle: nil)

		// use decorationInsetsDidChangeWithAnimation(_:) instead
		automaticallyAdjustsScrollViewInsets = false
	}


	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}


	public func decorationInsetsDidChangeWithAnimation(animation: Animation?) {
		for childViewController in childViewControllers {
			childViewController.invalidateDecorationInsetsWithAnimation(animation)
		}
	}


	@available(*, unavailable, message="override viewDidLayoutSubviewsWithAnimation(_:) instead")
	public final override func decorationInsetsDidChangeWithAnimation(animationWrapper: Animation.Wrapper?) {
		decorationInsetsDidChangeWithAnimation(animationWrapper?.animation)
	}


	public override func dismissViewController(animated animated: Bool = true, completion: Closure? = nil) {
		super.dismissViewControllerAnimated(animated, completion: completion)
	}


	@available(*, unavailable, renamed="dismissViewController")
	public final override func dismissViewControllerAnimated(flag: Bool, completion: Closure?) {
		presentedViewController?.dismissViewController(completion: completion)
	}


	public override class func initialize() {
		guard self == ViewController.self else {
			return
		}

		copyMethodInType(object_getClass(self), fromSelector: #selector(overridesPreferredInterfaceOrientationForPresentation), toSelector: obfuscatedSelector("does", "Override", "Preferred", "Interface", "Orientation", "For", "Presentation"))
	}


	public override func loadView() {
		view = View()
		view.frame = UIScreen.mainScreen().bounds // required or else UISplitViewController's overlay animation gets broken
	}


	@objc
	private static func overridesPreferredInterfaceOrientationForPresentation() -> Bool {
		// UIKit will behave differently if we override preferredInterfaceOrientationForPresentation.
		// Let's pretend we don't since we're just re-implementing the default behavior.
		return overridesSelector(#selector(preferredInterfaceOrientationForPresentation), ofBaseClass: ViewController.self)
	}


	public func performSegueWithIdentifier(identifier: String, sender: AnyObject? = nil, preparation: SeguePreparation?) {
		seguePreparation = preparation
		defer { seguePreparation = nil }

		performSegueWithIdentifier(identifier, sender: sender)
	}


	public override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
		return ViewController.defaultPreferredInterfaceOrientationForPresentation()
	}


	@available(*, unavailable, message="override prepareForSegue(_:sender:preparation:) instead")
	public final override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
		let preparation = seguePreparation
		seguePreparation = nil

		prepareForSegue(segue, sender: sender, preparation: preparation)
	}


	public func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?, preparation: SeguePreparation?) {
		preparation?(segue: segue)
	}


	public final func setViewNeedsLayout(animation animation: Animation? = nil) {
		guard isViewLoaded() else {
			return
		}

		viewLayoutAnimation = animation
		view.setNeedsLayout()
	}


	public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return ViewController.defaultSupportedInterfaceOrientationsForModalPresentationStyle(modalPresentationStyle)
	}


	@available(*, unavailable, message="override viewDidLayoutSubviewsWithAnimation(_:) instead")
	public final override func viewDidLayoutSubviews() {
		let animation = decorationInsetsAnimation?.animation ?? viewLayoutAnimation
		viewLayoutAnimation = nil

		super.viewDidLayoutSubviews()

		viewDidLayoutSubviewsWithAnimation(animation)
	}


	public func viewDidLayoutSubviewsWithAnimation(animation: Animation?) {
		// override in subclasses
	}
}
