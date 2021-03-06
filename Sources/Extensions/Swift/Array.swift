public extension Array {

	public func getOrNil(_ index: Index) -> Iterator.Element? {
		guard indices.contains(index) else {
			return nil
		}

		return self[index]
	}


	public func toArray() -> [Iterator.Element] {
		return self
	}
}


public extension Array where Iterator.Element: _Optional, Iterator.Element.Wrapped: Equatable {

	public func index(of element: Iterator.Element.Wrapped?) -> Int? {
		return index { $0.value == element }
	}
}


public func === <T: AnyObject> (a: [T], b: [T]) -> Bool {
	guard a.count == b.count else {
		return false
	}

	for index in a.indices {
		guard a[index] === b[index] else {
			return false
		}
	}

	return true
}


public func !== <T: AnyObject> (a: [T], b: [T]) -> Bool {
	return !(a === b)
}
