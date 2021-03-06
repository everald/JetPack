import Foundation


public extension FileManager {

	@nonobjc
	public func asyncRemoveItem(_ item: URL, handler: ((Result<Void>) -> Void)? = nil) {
		asyncWithHandler(handler, errorMessage: "Cannot remove item '\(item)'") {
			return try self.removeItem(at: item)
		}
	}


	@nonobjc
	fileprivate func asyncWithHandler <ValueType> (_ handler: ((Result<ValueType>) -> Void)?, errorMessage: @autoclosure @escaping () -> String, action: @escaping () throws -> ValueType) {
		onBackgroundQueue(qos: .utility) {
			do {
				let value = try action()
				handler?(.success(value))
			}
			catch let error {
				return self.reportError(error, withMessage: errorMessage(), toHandler: handler)
			}
		}
	}


	@nonobjc
	public func itemExistsAtURL(_ url: URL) -> Bool {
		guard url.isFileURL, let path = url.path.nonEmpty else {
			return false
		}

		return fileExists(atPath: path)
	}


	@nonobjc
	fileprivate func reportError <ValueType> (_ error: Error, withMessage message: @autoclosure () -> String, function: StaticString = #function, file: StaticString = #file, line: UInt = #line, toHandler handler: ((Result<ValueType>) -> Void)?) {
		guard let handler = handler else {
			log("'\(message())': \(error)", function: function, file: file, line: line)
			return
		}

		handler(.failure(error))
	}
}
