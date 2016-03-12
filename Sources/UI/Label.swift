import UIKit


@objc(JetPack_Label)
public /* non-final */ class Label: View {

	private lazy var delegateProxy: DelegateProxy = DelegateProxy(label: self)

	private let layoutManager = LayoutManager()
	private let linkTapRecognizer = UITapGestureRecognizer()
	private let textContainer = NSTextContainer()
	private let textStorage = NSTextStorage()

	public private(set) var lastDrawnFinalizedText: NSAttributedString?
	public private(set) var lastUsedFinalTextColor: UIColor?

	public var linkTapped: (NSURL -> Void)?


	public override init() {
		super.init()

		opaque = false

		layoutManager.addTextContainer(textContainer)

		textContainer.lineFragmentPadding = 0
		textContainer.maximumNumberOfLines = maximumNumberOfLines ?? 0
		textContainer.lineBreakMode = lineBreakMode

		textStorage.addLayoutManager(layoutManager)

		setUpLinkTapRecognizer()
	}


	public required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	@NSCopying
	public var attributedText = NSAttributedString() {
		didSet {
			guard attributedText != oldValue else {
				return
			}

			invalidateIntrinsicContentSize()
			setNeedsUpdateFinalizedText()
		}
	}


	public override func drawRect(rect: CGRect) {
		lastDrawnFinalizedText = finalizeText()

		let textContainerOrigin = originForTextContainer()
		let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
		layoutManager.drawBackgroundForGlyphRange(glyphRange, atPoint: textContainerOrigin)
		layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: textContainerOrigin)
	}


	public var font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody) {
		didSet {
			guard font != oldValue else {
				return
			}

			invalidateIntrinsicContentSize()
			setNeedsUpdateFinalizedText()
		}
	}


	private func finalTextColorDidChange() {
		setNeedsUpdateFinalizedText()
	}


	private func finalizeText() -> NSAttributedString {
		let finalTextColor = UIColor(CGColor: (labelPresentationLayer ?? labelLayer).finalTextColor) // can change due to animation
		if finalTextColor != lastUsedFinalTextColor {
			lastUsedFinalTextColor = finalTextColor
		}
		else if let finalizedText = _finalizedText {
			return finalizedText
		}

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = horizontalAlignment
		paragraphStyle.lineBreakMode = lineBreakMode

		let attributedText = self.attributedText
		let finalizedText = NSMutableAttributedString(string: attributedText.string, attributes: [
			NSFontAttributeName: font,
			NSForegroundColorAttributeName: finalTextColor,
			NSParagraphStyleAttributeName: paragraphStyle
		])

		var hasLinks = false

		attributedText.enumerateAttributesInRange(NSRange(forString: finalizedText.string), options: [.LongestEffectiveRangeNotRequired]) { attributes, range, _ in
			if !hasLinks && attributes[NSLinkAttributeName] != nil {
				hasLinks = true
			}

			finalizedText.addAttributes(attributes, range: range)
		}

		textStorage.setAttributedString(finalizedText)
		linkTapRecognizer.enabled = hasLinks

		_finalizedText = finalizedText.copy() as? NSAttributedString
		_links = nil
		_numberOfLines = nil

		return finalizedText
	}


	private var _finalizedText: NSAttributedString?
	public final var finalizedText: NSAttributedString {
		return finalizeText()
	}


	@objc
	private func handleLinkTapRecognizer() {
		guard let link = linkAtPoint(linkTapRecognizer.locationInView(self)) else {
			return
		}

		linkTapped?(link.url)
	}


	public var horizontalAlignment = NSTextAlignment.Natural {
		didSet {
			guard horizontalAlignment != oldValue else {
				return
			}

			setNeedsUpdateFinalizedText()
		}
	}


	private var labelLayer: LabelLayer {
		return layer as! LabelLayer
	}


	private var labelPresentationLayer: LabelLayer? {
		return layer.presentationLayer() as? LabelLayer
	}


	@warn_unused_result
	public final override class func layerClass() -> AnyObject.Type {
		return LabelLayer.self
	}


	public override func layoutSubviews() {
		super.layoutSubviews()

		textContainer.size = bounds.size.insetBy(padding)

		if finalizedText != lastDrawnFinalizedText {
			setNeedsDisplay()
		}
	}


	public var lineBreakMode = NSLineBreakMode.ByWordWrapping {
		didSet {
			guard lineBreakMode != oldValue else {
				return
			}

			textContainer.lineBreakMode = lineBreakMode

			invalidateIntrinsicContentSize()
			setNeedsUpdateFinalizedText()
		}
	}


	private func linkAtPoint(point: CGPoint) -> Link? {
		for link in links {
			for frame in link.frames where frame.contains(point) {
				return link
			}
		}

		return nil
	}


	private var _links: [Link]?
	private var links: [Link] {
		if let links = _links {
			return links
		}

		let finalizedText = self.finalizedText
		let textContainerOrigin = originForTextContainer()

		var links = [Link]()
		finalizedText.enumerateAttribute(NSLinkAttributeName, inRange: NSRange(forString: finalizedText.string), options: []) { url, range, _ in
			guard let url = url as? NSURL else {
				return
			}

			links.append(Link(range: range, frames: [], url: url))
		}

		links = links.map { link in
			let glyphRange = layoutManager.glyphRangeForCharacterRange(link.range, actualCharacterRange: nil)

			var frames = [CGRect]()
			layoutManager.enumerateEnclosingRectsForGlyphRange(glyphRange, withinSelectedGlyphRange: NSRange(location: NSNotFound, length: 0), inTextContainer: textContainer) { frame, _ in
				frames.append(frame.offsetBy(dx: textContainerOrigin.x, dy: textContainerOrigin.y))
			}

			return Link(range: link.range, frames: frames, url: link.url)
		}

		_links = links
		return links
	}


	public var maximumNumberOfLines: Int? = 1 {
		didSet {
			if let maximumNumberOfLines = maximumNumberOfLines {
				precondition(maximumNumberOfLines > 0, "Label.maximumNumberOfLines must be either larger than zero or nil.")
			}

			guard maximumNumberOfLines != oldValue else {
				return
			}

			textContainer.maximumNumberOfLines = maximumNumberOfLines ?? 0

			invalidateIntrinsicContentSize()
			setNeedsDisplay()
		}
	}


	public var minimumScaleFactor = CGFloat(1) {
		didSet {
			minimumScaleFactor = minimumScaleFactor.clamp(min: 0, max: 1)

			guard minimumScaleFactor != oldValue else {
				return
			}

			invalidateIntrinsicContentSize()
			setNeedsDisplay()
		}
	}


	private var _numberOfLines: Int?
	public var numberOfLines: Int {
		if let numberOfLines = _numberOfLines {
			return numberOfLines
		}

		finalizeText()

		var numberOfLines = 0
		var glyphIndex = 0
		let numberOfGlyphs = layoutManager.numberOfGlyphs

		while (glyphIndex < numberOfGlyphs) {
			var lineRange = NSRange()
			layoutManager.lineFragmentRectForGlyphAtIndex(glyphIndex, effectiveRange: &lineRange)

			glyphIndex = NSMaxRange(lineRange)

			numberOfLines += 1
		}

		_numberOfLines = numberOfLines
		return numberOfLines
	}


	@warn_unused_result
	private func originForTextContainer() -> CGPoint {
		let padding = self.padding
		let bounds = self.bounds

		let isRightToLeft: Bool
		if #available(iOS 9.0, *) {
			isRightToLeft = UIView.userInterfaceLayoutDirectionForSemanticContentAttribute(semanticContentAttribute) == .RightToLeft
		}
		else {
			isRightToLeft = UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft
		}

		let textFrame = alignToGrid(layoutManager.usedRectForTextContainer(textContainer))

		var textContainerOrigin = CGPoint()

		switch horizontalAlignment {
		case .Right, .Justified where isRightToLeft, .Natural where isRightToLeft:
			textContainerOrigin.left = bounds.width - padding.right - textFrame.width

		case .Left, .Justified, .Natural:
			textContainerOrigin.left = padding.left

		case .Center:
			textContainerOrigin.left = padding.left + ((bounds.width - padding.left - padding.right - textFrame.width) / 2)
		}

		switch verticalAlignment {
		case .Bottom:
			textContainerOrigin.top = bounds.height - padding.bottom - textFrame.height

		case .Center:
			textContainerOrigin.top = padding.top + ((bounds.height - padding.top - padding.bottom - textFrame.height) / 2)

		case .Top:
			textContainerOrigin.top = padding.top
		}

		textContainerOrigin.left -= textFrame.left
		textContainerOrigin.top -= textFrame.top

		return alignToGrid(textContainerOrigin)
	}


	public var padding = UIEdgeInsets.zero {
		didSet {
			guard padding != oldValue else {
				return
			}

			invalidateIntrinsicContentSize()
			setNeedsDisplay()
		}
	}


	public override func pointInside(point: CGPoint, withEvent event: UIEvent?, additionalHitZone: UIEdgeInsets) -> Bool {
		guard super.pointInside(point, withEvent: event, additionalHitZone: additionalHitZone) else {
			return false
		}
		guard userInteractionLimitedToLinks else {
			return true
		}

		return linkAtPoint(point) != nil
	}


	private func setNeedsUpdateFinalizedText() {
		guard _finalizedText != nil else {
			return
		}

		_finalizedText = nil
		_numberOfLines = nil
		setNeedsLayout()
	}


	private func setUpLinkTapRecognizer() {
		let recognizer = linkTapRecognizer
		recognizer.enabled = false
		recognizer.addTarget(self, action: "handleLinkTapRecognizer")

		addGestureRecognizer(recognizer)
	}


	@warn_unused_result
	public override func sizeThatFitsSize(maximumSize: CGSize) -> CGSize {
		let padding = self.padding

		finalizeText()

		let savedTextContainerSize = textContainer.size
		textContainer.size = maximumSize.insetBy(padding)
		defer { textContainer.size = savedTextContainerSize }

		let textSize = alignToGrid(layoutManager.usedRectForTextContainer(textContainer).size)

		return textSize.insetBy(padding.inverse)
	}


	public var text: String {
		get { return attributedText.string }
		set { attributedText = NSAttributedString(string: newValue) }
	}


	public var textColor = UIColor.darkTextColor() {
		didSet {
			guard textColor != oldValue else {
				return
			}

			updateFinalTextColor()
		}
	}


	private func updateFinalTextColor() {
		let finalTextColor = textColor.tintedWithColor(tintColor)
		if finalTextColor != lastUsedFinalTextColor {
			_finalizedText = nil
		}

		if finalTextColor.CGColor != labelLayer.finalTextColor {
			labelLayer.finalTextColor = finalTextColor.CGColor
		}
	}


	public var userInteractionLimitedToLinks = true


	public override func tintColorDidChange() {
		super.tintColorDidChange()

		updateFinalTextColor()
	}


	public var verticalAlignment = VerticalAlignment.Center {
		didSet {
			guard verticalAlignment != oldValue else {
				return
			}

			_links = nil
			setNeedsDisplay()
		}
	}


	public override func willResizeToSize(newSize: CGSize) {
		super.willResizeToSize(newSize)

		_numberOfLines = nil
	}



	private final class DelegateProxy: NSObject {

		private unowned var label: Label


		private init(label: Label) {
			self.label = label
		}
	}



	private final class LabelLayer: Layer {

		@objc @NSManaged
		private dynamic var finalTextColor: CGColor


		private override init() {
			super.init()

			finalTextColor = UIColor.darkTextColor().CGColor
		}


		private required init(layer: AnyObject) {
			super.init(layer: layer)
		}


		private required init?(coder: NSCoder) {
			fatalError("init(coder:) has not been implemented")
		}


		private override func actionForKey(key: String) -> CAAction? {
			switch key {
			case "finalTextColor":
				if let animation = super.actionForKey("backgroundColor") as? CABasicAnimation {
					animation.fromValue = finalTextColor
					animation.keyPath = key

					return animation
				}

				fallthrough

			default:
				return super.actionForKey(key)
			}
		}


		private override class func needsDisplayForKey(key: String) -> Bool {
			switch key {
			case "finalTextColor": return true
			default: return super.needsDisplayForKey(key)
			}
		}
	}



	private final class LayoutManager: NSLayoutManager {

		@objc(JetPack_linkAttributes)
		private dynamic class var linkAttributes: [NSObject : AnyObject] {
			return [:]
		}


		private override class func initialize() {
			guard self == LayoutManager.self else {
				return
			}


			let defaultLinkAttributesSelector = obfuscatedSelector("_", "default", "Link", "Attributes")
			copyMethodWithSelector(defaultLinkAttributesSelector, fromType: object_getClass(NSLayoutManager.self), toType: object_getClass(self))
			swizzleMethodInType(object_getClass(self), fromSelector: "JetPack_linkAttributes", toSelector: defaultLinkAttributesSelector)
		}
	}



	private struct Link {

		private var range: NSRange
		private var frames: [CGRect]
		private var url: NSURL
	}
	
	
	
	public enum VerticalAlignment {
		case Bottom
		case Center
		case Top
	}
}



extension Label.DelegateProxy: UIGestureRecognizerDelegate {

	@objc
	private func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
		return label.linkAtPoint(touch.locationInView(label)) != nil
	}
}