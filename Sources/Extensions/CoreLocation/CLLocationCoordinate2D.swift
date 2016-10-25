import CoreLocation


public extension CLLocationCoordinate2D {

	@warn_unused_result
	public func distanceTo(coordinate: CLLocationCoordinate2D) -> CLLocationDistance {
		return CLLocation(coordinate: self).distanceFromLocation(CLLocation(coordinate: coordinate))
	}
}


extension CLLocationCoordinate2D: Hashable {

	public var hashValue: Int {
		return latitude.hashValue ^ longitude.hashValue
	}
}


public func == (a: CLLocationCoordinate2D, b: CLLocationCoordinate2D) -> Bool {
	return a.latitude == b.latitude && a.longitude == b.longitude
}
