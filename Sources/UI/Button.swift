import UIKit


@objc(JetPack_Button)
public class Button: View {

	private var _activityIndicator: UIActivityIndicatorView?
	private var _imageView: ImageView?
	private var _textLabel: Label?

	private var defaultAlpha = CGFloat(1)
	private var defaultBackgroundColor: UIColor?
	private var defaultBorderColor: UIColor?

	public var tapped: Closure?
	public var touchTolerance = CGFloat(75)


	public override init() {
		super.init()
	}


	public required init?(coder: NSCoder) {
		super.init(coder: coder)
	}


	public final var activityIndicator: UIActivityIndicatorView {
		get {
			return _activityIndicator ?? {
				let child = UIActivityIndicatorView(activityIndicatorStyle: .White)
				child.hidesWhenStopped = false

				_activityIndicator = child

				return child
			}()
		}
	}


	public override var alpha: CGFloat {
		get { return defaultAlpha }
		set {
			let newAlpha = newValue.clamp(min: 0, max: 1)
			guard newAlpha != defaultAlpha else {
				return
			}

			defaultAlpha = newAlpha

			updateAlpha()
		}
	}


	public var arrangement = Arrangement.ImageLeft {
		didSet {
			guard arrangement != oldValue else {
				return
			}

			setNeedsLayout()
		}
	}


	public override var backgroundColor: UIColor? {
		get { return defaultBackgroundColor }
		set {
			guard newValue != defaultBackgroundColor else {
				return
			}

			defaultBackgroundColor = newValue

			updateBackgroundColor()
		}
	}


	public override var borderColor: UIColor? {
		get { return defaultBorderColor }
		set {
			guard newValue != defaultBorderColor else {
				return
			}

			defaultBorderColor = newValue

			updateBorderColor()
		}
	}


	public override func didMoveToWindow() {
		super.didMoveToWindow()

		if window != nil {
			if let activityIndicator = _activityIndicator where activityIndicator.superview === self {
				activityIndicator.startAnimating()
			}
		}
		else {
			highlighted = false
		}
	}


	public var disabledAlpha: CGFloat? {
		didSet {
			guard disabledAlpha != oldValue else {
				return
			}

			updateAlpha()
		}
	}


	public var disabledBackgroundColor: UIColor? {
		didSet {
			guard disabledBackgroundColor != oldValue else {
				return
			}

			updateBackgroundColor()
		}
	}


	public var enabled = true {
		didSet {
			userInteractionEnabled = enabled

			guard enabled != oldValue else {
				return
			}

			updateAlpha()
			updateBackgroundColor()
		}
	}


	public var highlighted = false {
		didSet {
			guard highlighted != oldValue else {
				return
			}

			if highlightedAlpha != defaultAlpha || highlightedBackgroundColor != defaultBackgroundColor || highlightedBorderColor != defaultBorderColor {
				var animation: Animation? = highlighted ? nil : Animation(duration: 0.3)
				animation?.allowsUserInteraction = true

				animation.runAlways {
					updateAlpha()
					updateBackgroundColor()
				}
			}
		}
	}


	public var highlightedAlpha: CGFloat? = 0.5 {
		didSet {
			guard highlightedAlpha != oldValue else {
				return
			}

			updateAlpha()
		}
	}


	public var highlightedBackgroundColor: UIColor? {
		didSet {
			guard highlightedBackgroundColor != oldValue else {
				return
			}

			updateBackgroundColor()
		}
	}


	public var highlightedBorderColor: UIColor? {
		didSet {
			guard highlightedBorderColor != oldValue else {
				return
			}

			updateBorderColor()
		}
	}


	public var horizontalAlignment = HorizontalAlignment.Center {
		didSet {
			guard horizontalAlignment != oldValue else {
				return
			}

			setNeedsLayout()
		}
	}


	public var imageOffset = UIOffset() {
		didSet {
			guard imageOffset != oldValue else {
				return
			}

			setNeedsLayout()
		}
	}


	public final var imageView: ImageView {
		get {
			return _imageView ?? {
				let child = ButtonImageView(button: self)
				_imageView = child

				return child
			}()
		}
	}


	private func imageViewDidChangeSource() {
		setNeedsLayout()
		invalidateIntrinsicContentSize()
	}


	public override func intrinsicContentSize() -> CGSize {
		return sizeThatFits()
	}


	private func layoutForSize(size: CGSize) -> Layout {
		if size.isEmpty {
			return Layout()
		}

		let wantsActivityIndicator = showsActivityIndicatorAsImage
		let wantsImage = _imageView?.image != nil || _imageView?.source != nil
		let wantsText = !(_textLabel?.text.isEmpty ?? true)

		// step 1: show/hide views

		if !wantsActivityIndicator && !wantsImage && !wantsText {
			return Layout()
		}

		// lazy initialization
		let activityIndicator: UIActivityIndicatorView? = wantsActivityIndicator ? self.activityIndicator : nil
		let imageView: ImageView? = wantsImage ? self.imageView : nil
		let textLabel: Label? = wantsText ? self.textLabel : nil

		var remainingSize = size

		var activityIndicatorFrame = CGRect()
		var imageViewFrame = CGRect()
		var textLabelFrame = CGRect()

		var numberOfElements = 0
		if wantsImage || wantsActivityIndicator {
			numberOfElements += 1
		}
		if wantsText {
			numberOfElements += 1
		}

		var horizontalAlignment = self.horizontalAlignment
		var verticalAlignment = self.verticalAlignment

		let isVerticalArrangement = (arrangement == .ImageBottom || arrangement == .ImageTop)
		if isVerticalArrangement {
			// step 2: measure sizes

			if let imageView = imageView {
				if numberOfElements == 1 && verticalAlignment == .Fill && horizontalAlignment == .Fill {
					imageViewFrame.size = remainingSize
				}
				else {
					imageViewFrame.size = imageView.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(imageView.transform)

					if numberOfElements == 1 {
						if verticalAlignment == .Fill {
							imageViewFrame.height = remainingSize.height
						}
						else if horizontalAlignment == .Fill {
							imageViewFrame.width = remainingSize.width
						}
					}
				}

				remainingSize.height -= imageViewFrame.height
			}
			else if let activityIndicator = activityIndicator {
				imageViewFrame.size = activityIndicator.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(activityIndicator.transform)
				remainingSize.height -= imageViewFrame.height
			}

			if let textLabel = textLabel {
				textLabelFrame.size = textLabel.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(textLabel.transform)
				remainingSize.height -= textLabelFrame.height
			}

			// step 3: measure vertical positions

			var top = CGFloat(0)
			let bottom = size.height

			if arrangement == .ImageBottom {
				if wantsText {
					textLabelFrame.top = top
					top = textLabelFrame.bottom
				}
				if wantsImage || wantsActivityIndicator {
					imageViewFrame.top = top
				}
			}
			else {
				if wantsImage || wantsActivityIndicator {
					imageViewFrame.top = top
					top = imageViewFrame.bottom
				}
				if wantsText {
					textLabelFrame.top = top
				}
			}

			// step 4: adjust vertical positions

			if verticalAlignment == .Fill && numberOfElements < 2 {
				verticalAlignment = .Center
			}

			switch verticalAlignment {
			case .Fill:
				if arrangement == .ImageBottom {
					imageViewFrame.bottom = bottom
				}
				else {
					textLabelFrame.bottom = bottom
				}

			case .Top:
				break // already top


			case .Bottom:
				let verticalOffset = remainingSize.height
				textLabelFrame.top += verticalOffset
				imageViewFrame.top += verticalOffset

			case .Center:
				let verticalOffset = remainingSize.height / 2
				textLabelFrame.top += verticalOffset
				imageViewFrame.top += verticalOffset
			}

			// step 5: measure horizontal positions

			if wantsImage || wantsActivityIndicator {
				switch horizontalAlignment {
				case .Right:
					imageViewFrame.right = size.width

				case .Left:
					imageViewFrame.left = 0

				case .Center, .Fill:
					imageViewFrame.horizontalCenter = size.width / 2
				}
			}

			if wantsText {
				switch horizontalAlignment {
				case .Right:
					textLabelFrame.right = size.width

				case .Left:
					textLabelFrame.left = 0

				case .Center, .Fill:
					textLabelFrame.horizontalCenter = size.width / 2
				}
			}
		}
		else { // horizontal layout
			// step 2: measure sizes

			if let imageView = imageView {
				if numberOfElements == 1 && verticalAlignment == .Fill && horizontalAlignment == .Fill {
					imageViewFrame.size = remainingSize
				}
				else {
					imageViewFrame.size = imageView.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(imageView.transform)

					if numberOfElements == 1 {
						if verticalAlignment == .Fill {
							imageViewFrame.height = remainingSize.height
						}
						else if horizontalAlignment == .Fill {
							imageViewFrame.width = remainingSize.width
						}
					}
				}

				remainingSize.width -= imageViewFrame.width
			}
			else if let activityIndicator = activityIndicator {
				imageViewFrame.size = activityIndicator.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(activityIndicator.transform)
				remainingSize.width -= imageViewFrame.width
			}

			if let textLabel = textLabel {
				textLabelFrame.size = textLabel.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(textLabel.transform)
				remainingSize.width -= textLabelFrame.width
			}

			// step 3: measure horizontal positions

			var left = CGFloat(0)
			let right = size.width

			if arrangement == .ImageRight {
				if wantsText {
					textLabelFrame.left = left
					left = textLabelFrame.right
				}
				if wantsImage || wantsActivityIndicator {
					imageViewFrame.left = left
				}
			}
			else {
				if wantsImage || wantsActivityIndicator {
					imageViewFrame.left = left
					left = imageViewFrame.right
				}
				if wantsText {
					textLabelFrame.left = left
				}
			}

			// step 4: adjust horizontal positions

			if horizontalAlignment == .Fill && numberOfElements < 2 {
				horizontalAlignment = .Center
			}

			switch horizontalAlignment {
			case .Fill:
				if arrangement == .ImageRight {
					imageViewFrame.right = right
				}
				else {
					textLabelFrame.right = right
				}

			case .Left:
				break // already left

			case .Right:
				let horizontalOffset = remainingSize.width
				textLabelFrame.left += horizontalOffset
				imageViewFrame.left += horizontalOffset

			case .Center:
				let horizontalOffset = remainingSize.width / 2
				textLabelFrame.left += horizontalOffset
				imageViewFrame.left += horizontalOffset
			}

			// step 5: measure vertical positions

			if wantsImage || wantsActivityIndicator {
				switch verticalAlignment {
				case .Bottom:
					imageViewFrame.bottom = size.height

				case .Top:
					imageViewFrame.top = 0

				case .Center, .Fill:
					imageViewFrame.verticalCenter = size.height / 2
				}
			}

			if wantsText {
				switch verticalAlignment {
				case .Bottom:
					textLabelFrame.bottom = size.height

				case .Top:
					textLabelFrame.top = 0

				case .Center, .Fill:
					textLabelFrame.verticalCenter = size.height / 2
				}
			}
		}

		// step 6: apply offsets
		if wantsImage || wantsActivityIndicator {
			imageViewFrame.offsetInPlace(imageOffset)
		}
		if wantsText {
			textLabelFrame.offsetInPlace(textOffset)
		}

		// step 7: align activity indicator
		if let activityIndicator = activityIndicator {
			activityIndicatorFrame.size = activityIndicator.sizeThatFitsSize(imageViewFrame.size, allowsTruncation: true).transform(activityIndicator.transform)
			activityIndicatorFrame.center = imageViewFrame.center
		}

		return Layout(
			activityIndicatorFrame: wantsActivityIndicator ? alignToGrid(activityIndicatorFrame) : nil,
			imageViewFrame:         (wantsImage && !wantsActivityIndicator) ? alignToGrid(imageViewFrame) : nil,
			textLabelFrame:         wantsText ? alignToGrid(textLabelFrame) : nil
		)
	}


	public override func layoutSubviews() {
		let layout = layoutForSize(bounds.size)

		var subviewIndex = subviews.count
		if let imageView = _imageView, index = subviews.indexOfIdentical(imageView) {
			subviewIndex = min(subviewIndex, index)
		}
		if let textLabel = _textLabel, index = subviews.indexOfIdentical(textLabel) {
			subviewIndex = min(subviewIndex, index)
		}
		if let activityIndicator = _activityIndicator, index = subviews.indexOfIdentical(activityIndicator) {
			subviewIndex = min(subviewIndex, index)
		}

		if let imageViewFrame = layout.imageViewFrame {
			if imageView.superview == nil {
				insertSubview(imageView, atIndex: subviewIndex)
			}
			subviewIndex += 1

			imageView.bounds = CGRect(size: imageViewFrame.size)
			imageView.center = imageViewFrame.center
		}
		else {
			_imageView?.removeFromSuperview()
		}

		if let textLabelFrame = layout.textLabelFrame {
			if textLabel.superview == nil {
				insertSubview(textLabel, atIndex: subviewIndex)
			}
			subviewIndex += 1

			textLabel.bounds = CGRect(size: textLabelFrame.size)
			textLabel.center = textLabelFrame.center
		}
		else {
			_textLabel?.removeFromSuperview()
		}

		if let activityIndicatorFrame = layout.activityIndicatorFrame {
			if activityIndicator.superview == nil {
				insertSubview(activityIndicator, atIndex: subviewIndex)

				activityIndicator.startAnimating()
			}

			activityIndicator.bounds = CGRect(size: activityIndicatorFrame.size)
			activityIndicator.center = activityIndicatorFrame.center
		}
		else {
			_activityIndicator?.removeFromSuperview()
		}

		super.layoutSubviews()
	}


	public var showsActivityIndicatorAsImage = false {
		didSet {
			guard showsActivityIndicatorAsImage != oldValue else {
				return
			}

			setNeedsLayout()
		}
	}


	public override func sizeThatFitsSize(maximumSize: CGSize) -> CGSize {
		if maximumSize.isEmpty {
			return .zero
		}

		let wantsActivityIndicator = showsActivityIndicatorAsImage
		let wantsImage = (_imageView?.image != nil || _imageView?.source != nil)
		let wantsText = !(_textLabel?.text.isEmpty ?? true)

		// lazy initialization
		let activityIndicator: UIActivityIndicatorView? = wantsActivityIndicator ? self.activityIndicator : nil
		let imageView: ImageView? = wantsImage ? self.imageView : nil
		let textLabel: Label? = wantsText ? self.textLabel : nil

		var fittingSize = CGSize()
		var remainingSize = maximumSize

		switch arrangement {
		case .ImageBottom, .ImageTop: // vertical
			if let imageView = imageView {
				let imageViewSize = imageView.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(imageView.transform)

				fittingSize.height += imageViewSize.height
				fittingSize.width = max(fittingSize.width, imageViewSize.width)
				remainingSize.height -= imageViewSize.height
			}
			else if let activityIndicator = activityIndicator {
				let activityIndicatorSize = activityIndicator.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(activityIndicator.transform)

				fittingSize.height += activityIndicatorSize.height
				fittingSize.width = max(fittingSize.width, activityIndicatorSize.width)
				remainingSize.height -= activityIndicatorSize.height
			}

			if let textLabel = textLabel {
				let textLabelSize = textLabel.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(textLabel.transform)

				fittingSize.height += textLabelSize.height
				fittingSize.width = max(fittingSize.width, textLabelSize.width)
			}

		case .ImageLeft, .ImageRight: // horizontal
			if let imageView = imageView {
				let imageViewSize = imageView.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(imageView.transform)

				fittingSize.width += imageViewSize.width
				fittingSize.height = max(fittingSize.height, imageViewSize.height)
				remainingSize.width -= imageViewSize.width
			}
			else if let activityIndicator = activityIndicator {
				let activityIndicatorSize = activityIndicator.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(activityIndicator.transform)

				fittingSize.width += activityIndicatorSize.width
				fittingSize.height = max(fittingSize.height, activityIndicatorSize.height)
				remainingSize.width -= activityIndicatorSize.width
			}

			if let textLabel = textLabel {
				let textLabelSize = textLabel.sizeThatFitsSize(remainingSize, allowsTruncation: true).transform(textLabel.transform)

				fittingSize.width += textLabelSize.width
				fittingSize.height = max(fittingSize.height, textLabelSize.height)
			}
		}
		
		return alignToGrid(fittingSize)
	}


	public override func subviewDidInvalidateIntrinsicContentSize(view: UIView) {
		setNeedsLayout()
		invalidateIntrinsicContentSize()
	}


	public final var textLabel: Label {
		get {
			return _textLabel ?? {
				let child = ButtonLabel(button: self)
				child.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
				child.textColor = .tintColor()

				_textLabel = child

				return child
			}()
		}
	}


	private func textLabelDidChangeAttributedText() {
		setNeedsLayout()
		invalidateIntrinsicContentSize()
	}


	public var textOffset = UIOffset() {
		didSet {
			guard textOffset != oldValue else {
				return
			}

			setNeedsLayout()
		}
	}


	public override func tintColorDidChange() {
		super.tintColorDidChange()

		updateBackgroundColor()
		updateBorderColor()
	}


	public func touchIsAcceptableForTap(touch: UITouch, event: UIEvent?) -> Bool {
		return pointInside(touch.locationInView(self), withEvent: event, additionalHitZone: additionalHitZone.increaseBy(UIEdgeInsets(all: touchTolerance)))
	}


	public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let touch = touches.first where touchIsAcceptableForTap(touch, event: event) {
			highlighted = true
		}
		else {
			highlighted = false
		}
	}


	public override func touchesCancelled(touches: Set<UITouch>, withEvent event: UIEvent?) {
		highlighted = false
	}


	public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
		highlighted = false

		if enabled, let tapped = tapped, touch = touches.first where touchIsAcceptableForTap(touch, event: event) {
			tapped()
		}
	}


	public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let touch = touches.first where touchIsAcceptableForTap(touch, event: event) {
			highlighted = true
		}
		else {
			highlighted = false
		}
	}
	

	private func updateAlpha() {
		let alpha: CGFloat
		if !enabled, let disabledAlpha = disabledAlpha {
			alpha = disabledAlpha
		}
		else if highlighted, let highlightedAlpha = highlightedAlpha {
			alpha = highlightedAlpha
		}
		else {
			alpha = defaultAlpha
		}

		super.alpha = alpha
	}


	private func updateBackgroundColor() {
		let backgroundColor: UIColor?
		if !enabled, let disabledBackgroundColor = disabledBackgroundColor {
			backgroundColor = disabledBackgroundColor
		}
		else if highlighted, let highlightedBackgroundColor = highlightedBackgroundColor {
			backgroundColor = highlightedBackgroundColor
		}
		else {
			backgroundColor = defaultBackgroundColor
		}

		super.backgroundColor = backgroundColor
	}


	private func updateBorderColor() {
		let borderColor: UIColor?
		if highlighted, let highlightedBorderColor = highlightedBorderColor {
			borderColor = highlightedBorderColor
		}
		else {
			borderColor = defaultBorderColor
		}

		super.borderColor = borderColor
	}


	public var verticalAlignment = VerticalAlignment.Center {
		didSet {
			guard verticalAlignment != oldValue else {
				return
			}

			setNeedsLayout()
		}
	}



	public enum Arrangement {
		case ImageBottom
		case ImageLeft
		case ImageRight
		case ImageTop
	}


	public enum HorizontalAlignment {
		case Center
		case Fill
		case Left
		case Right
	}


	public enum VerticalAlignment {
		case Bottom
		case Center
		case Fill
		case Top
	}
}



private struct Layout {

	private var activityIndicatorFrame: CGRect?
	private var imageViewFrame: CGRect?
	private var textLabelFrame: CGRect?
}



private final class ButtonImageView: ImageView {

	private weak var button: Button?


	private init(button: Button) {
		self.button = button

		super.init()
	}


	private required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}


	private override var source: Source? {
		didSet {
			button?.imageViewDidChangeSource()
		}
	}
}



private final class ButtonLabel: Label {

	private weak var button: Button?


	private init(button: Button) {
		self.button = button

		super.init()
	}


	private override var attributedText: NSAttributedString {
		didSet {
		guard attributedText != oldValue else {
			return
		}

		button?.textLabelDidChangeAttributedText()
		}
	}


	private required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
}
