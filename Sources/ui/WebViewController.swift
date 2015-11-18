import UIKit
import WebKit


public /* non-final */ class WebViewController: ViewController {

	private lazy var activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)

	private let configuration: WKWebViewConfiguration
	private var initialNavigation: WKNavigation?

	public var initialUrl: NSURL?
	public var opensLinksExternally = false


	public init(configuration: WKWebViewConfiguration = WKWebViewConfiguration()) {
		self.configuration = configuration

		super.init()
	}


	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	public var animatesInitialLoading = false {
		didSet {
			guard animatesInitialLoading != oldValue else {
				return
			}

			if !animatesInitialLoading && isViewLoaded() {
				webView.alpha = 1
				webView.userInteractionEnabled = true
			}
		}
	}


	public override func decorationInsetsDidChangeWithAnimation(animation: Animation?) {
		super.decorationInsetsDidChangeWithAnimation(animation)

		Animation.run(animation) {
			webView.scrollView.setContentInset(innerDecorationInsets, maintainingVisualContentOffset: true)
			webView.scrollView.scrollIndicatorInsets = outerDecorationInsets

			if activityIndicator.superview != nil {
				view.setNeedsLayout()

				if animation != nil {
					view.layoutIfNeeded()
				}
			}
		}
	}


	public func handleEmailLink(link: NSURL) -> Bool {
		guard opensLinksExternally else {
			return false
		}

		UIApplication.sharedApplication().openURL(link)
		return true
	}


	public func handleLink(link: NSURL) -> Bool {
		switch link.scheme {
		case "mailto":        return handleEmailLink(link)
		case "http", "https": return handleWebLink(link)
		default:              return handleUnknownLink(link)
		}
	}


	public func handleUnknownLink(link: NSURL) -> Bool {
		guard opensLinksExternally else {
			return false
		}

		UIApplication.sharedApplication().openURL(link)
		return true
	}


	public func handleWebLink(link: NSURL) -> Bool {
		guard opensLinksExternally else {
			return false
		}

		UIApplication.sharedApplication().openURL(link)
		return true
	}


	private func setUp() {
		view.backgroundColor = .whiteColor()

		setUpWebView()
		setUpActivityIndicator()
	}


	private func setUpActivityIndicator() {
		let child = activityIndicator
		child.startAnimating()
	}


	private func setUpWebView() {
		view.addSubview(webView)
	}


	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		let viewBounds = view.bounds

		if activityIndicator.superview != nil {
			var activityIndicatorFrame = CGRect()
			activityIndicatorFrame.size = activityIndicator.sizeThatFits()
			activityIndicatorFrame.center = viewBounds.insetBy(innerDecorationInsets).center
			activityIndicator.frame = view.alignToGrid(activityIndicatorFrame)
		}

		webView.frame = view.bounds
	}


	public override func viewDidLoad() {
		super.viewDidLoad()

		setUp()
	}


	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)

		if let initialUrl = initialUrl {
			self.initialUrl = nil

			if webView.URL == nil && !webView.loading {
				initialNavigation = webView.loadRequest(NSURLRequest(URL: initialUrl))

				if initialNavigation != nil && animatesInitialLoading {
					webView.alpha = 0
					webView.userInteractionEnabled = false

					view.addSubview(activityIndicator)
				}
			}
		}
	}


	public private(set) lazy var webView: WKWebView = {
		let child = WKWebView(frame: .zero, configuration: self.configuration)
		child.navigationDelegate = self
		child.UIDelegate = self

		return child
	}()
}


extension WebViewController: WKNavigationDelegate {

	public func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: WKNavigationActionPolicy -> Void) {
		if navigationAction.navigationType == .LinkActivated, let url = navigationAction.request.URL {
			decisionHandler(handleLink(url) ? .Cancel : .Allow)
			return
		}

		decisionHandler(.Allow)
	}


	public func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
		if navigation == initialNavigation {
			initialNavigation = nil

			if animatesInitialLoading {
				Animation(duration: 0.5).runWithCompletion { complete in
					webView.alpha = 1
					webView.userInteractionEnabled = true

					activityIndicator.alpha = 0

					complete { _ in
						self.activityIndicator.removeFromSuperview()
					}
				}
			}
		}
	}
}


extension WebViewController: WKUIDelegate {}