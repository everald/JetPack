import UIKit


public extension UIImage {

	@nonobjc
	public convenience init(placeholderOfSize size: CGSize) {
		guard size.isPositive else {
			fatalError("\(#function) requires a positive size")
		}
		guard let context = CGBitmapContextCreate(nil, Int(ceil(size.width)), Int(ceil(size.height)), 8, 0, CGColorSpaceCreateDeviceRGB(), CGImageAlphaInfo.PremultipliedLast.rawValue) else {
			fatalError("\(#function) could not create context")
		}
		guard let cgimage = CGBitmapContextCreateImage(context) else {
			fatalError("\(#function) could not create image from context")
		}

		self.init(CGImage: cgimage, scale: 1, orientation: .Up)
	}


	@nonobjc
	public convenience init?(named name: String, inBundle bundle: NSBundle) {
		self.init(named: name, inBundle: bundle, compatibleWithTraitCollection: nil)
	}


	@nonobjc
	public static func fromColor(color: UIColor, withSize size: CGSize = CGSize(square: 1), scale: CGFloat = 1) -> UIImage {
		let frame = CGRect(size: size)

		UIGraphicsBeginImageContextWithOptions(frame.size, false, scale)

		guard let context = UIGraphicsGetCurrentContext() else {
			fatalError("Cannot create UIGraphics image context.")
		}

		defer { UIGraphicsEndImageContext() }

		CGContextSetFillColorWithColor(context, color.CGColor)
		CGContextFillRect(context, frame)

		guard let image = UIGraphicsGetImageFromCurrentImageContext() else {
			fatalError("Cannot create image from image context.")
		}

		return image
	}


	@nonobjc
	public var hasAlphaChannel: Bool {
		guard let cgImage = CGImage else {
			return false // TODO support CIImage
		}

		let info = CGImageGetAlphaInfo(cgImage)
		switch info {
		case .First, .Last, .Only, .PremultipliedFirst, .PremultipliedLast:
			return true

		case .None, .NoneSkipFirst, .NoneSkipLast:
			return false
		}
	}


	@nonobjc
	public func imageConstrainedToSize(maximumSize: CGSize, interpolationQuality: CGInterpolationQuality = .High) -> UIImage {
		let orientedMaximumSize = imageOrientation.isLandscape ? CGSize(width: maximumSize.height, height: maximumSize.width) : maximumSize

		guard let cgImage = self.CGImage else {
			return self // TODO support CIImage
		}

		let currentSize = CGSize(width: CGImageGetWidth(cgImage), height: CGImageGetHeight(cgImage))
		let horizontalScale = orientedMaximumSize.width / currentSize.width
		let verticalScale = orientedMaximumSize.height / currentSize.height
		let scale = min(horizontalScale, verticalScale)

		var targetSize = currentSize.scaleBy(scale)
		targetSize.height = floor(targetSize.height)
		targetSize.width = floor(targetSize.width)

		if targetSize.height >= currentSize.height && targetSize.width >= currentSize.width {
			return self
		}

		// TODO handle nil color space
		guard let context = CGBitmapContextCreate(nil, Int(targetSize.width), Int(targetSize.height), CGImageGetBitsPerComponent(cgImage), 0, CGImageGetColorSpace(cgImage)!, CGImageGetBitmapInfo(cgImage).rawValue) else {
			return self // TODO when can this happen?
		}

		CGContextSetInterpolationQuality(context, interpolationQuality)
		CGContextDrawImage(context, CGRect(size: targetSize), cgImage)

		let newCoreImage = CGBitmapContextCreateImage(context)!
		let newImage = UIImage(CGImage: newCoreImage, scale: self.scale, orientation: self.imageOrientation)

		return newImage
	}


	@nonobjc
	public func imageCroppedToSize(maximumSize: CGSize) -> UIImage {
		let orientedMaximumSize = imageOrientation.isLandscape ? CGSize(width: maximumSize.height, height: maximumSize.width) : maximumSize
		guard let cgImage = self.CGImage else {
			return self
		}

		let currentSize = CGSize(width: CGImageGetWidth(cgImage), height: CGImageGetHeight(cgImage))

		let targetSize = CGSize(
			width:  min(currentSize.width, orientedMaximumSize.width),
			height: min(currentSize.height, orientedMaximumSize.height)
		)

		if targetSize.height >= currentSize.height && targetSize.width >= currentSize.width {
			return self
		}

		// TODO handle nil color space
		guard let context = CGBitmapContextCreate(nil, Int(targetSize.width), Int(targetSize.height), CGImageGetBitsPerComponent(cgImage), 0, CGImageGetColorSpace(cgImage)!, CGImageGetBitmapInfo(cgImage).rawValue) else {
			return self // TODO when can this happen?
		}

		let drawFrame = CGRect(
			left:   floor((targetSize.width - currentSize.width) / 2),
			top:    floor((targetSize.height - currentSize.height) / 2),
			width:  currentSize.width,
			height: currentSize.height
		)
		CGContextDrawImage(context, drawFrame, cgImage)

		let newCoreImage = CGBitmapContextCreateImage(context)!
		let newImage = UIImage(CGImage: newCoreImage, scale: self.scale, orientation: self.imageOrientation)

		return newImage
	}


	@nonobjc
	public func imageWithAlpha(alpha: CGFloat) -> UIImage {
		guard alpha <= 0 else {
			return self
		}

		return imageWithBlendMode(.SourceIn, destinationColor: UIColor(white: 0, alpha: alpha))
	}


	@nonobjc
	private func imageWithBlendMode(blendMode: CGBlendMode, color: UIColor, colorIsDestination: Bool) -> UIImage {
		let frame = CGRect(size: size)

		UIGraphicsBeginImageContextWithOptions(frame.size, !hasAlphaChannel, scale)

		if colorIsDestination {
			color.set()
			UIRectFill(frame)

			drawInRect(frame, blendMode: blendMode, alpha: 1)
		}
		else {
			drawInRect(frame)

			color.set()
			UIRectFillUsingBlendMode(frame, blendMode)
		}

		guard var image = UIGraphicsGetImageFromCurrentImageContext() else {
			fatalError("Why does this still return an implicit optional? When can it be nil?")
		}

		UIGraphicsEndImageContext()

		if image.capInsets != capInsets {
			image = image.resizableImageWithCapInsets(capInsets)
		}
		if image.renderingMode != renderingMode {
			image = image.imageWithRenderingMode(renderingMode)
		}

		return image
	}


	@nonobjc
	public func imageWithBlendMode(blendMode: CGBlendMode, destinationColor: UIColor) -> UIImage {
		return imageWithBlendMode(blendMode, color: destinationColor, colorIsDestination: true)
	}


	@nonobjc
	public func imageWithBlendMode(blendMode: CGBlendMode, sourceColor: UIColor) -> UIImage {
		return imageWithBlendMode(blendMode, color: sourceColor, colorIsDestination: false)
	}


	@nonobjc
	public func imageWithHueFromColor(color: UIColor) -> UIImage {
		return imageWithBlendMode(.Hue, sourceColor: color)
	}


	@nonobjc
	public func imageWithColor(color: UIColor) -> UIImage {
		return imageWithBlendMode(.SourceIn, sourceColor: color)
	}


	/**
		Decompresses the underlying and potentially compressed image data (like PNG or JPEG).

		You can use this to force decompression on a background thread prior to using this image on the main thread
		so subsequent operations like rendering are faster.
	*/
	@nonobjc
	public func inflate() {
		guard let cgImage = CGImage, let dataProvider = CGImageGetDataProvider(cgImage) else {
			return
		}

		CGDataProviderCopyData(dataProvider)
	}


	@nonobjc
	public func luminocityImage() -> UIImage {
		return imageWithBlendMode(.Luminosity, destinationColor: .whiteColor())
	}
}



public extension UIImageOrientation {

	public init?(CGImageOrientation: Int) {
		switch CGImageOrientation {
		case 1: self = .Up
		case 2: self = .UpMirrored
		case 3: self = .Down
		case 4: self = .DownMirrored
		case 5: self = .LeftMirrored
		case 6: self = .Right
		case 7: self = .RightMirrored
		case 8: self = .Left
		default: return nil
		}
	}


	public var isLandscape: Bool {
		switch self {
		case .Left, .LeftMirrored, .Right, .RightMirrored:
			return true

		case .Down, .DownMirrored, .Up, .UpMirrored:
			return false
		}
	}


	public var isPortrait: Bool {
		return !isLandscape
	}
}
