import CoreLocation

/// Represents a geographic location with coordinates
public struct Location: Sendable, Equatable {
    /// Latitude coordinate
    public let latitude: Double
    
    /// Longitude coordinate
    public let longitude: Double
    
    public init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    
    /// Create Location from CLLocationCoordinate2D
    public init(coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }
}
