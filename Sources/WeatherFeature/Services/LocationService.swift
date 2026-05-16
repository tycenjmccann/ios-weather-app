import CoreLocation
import Foundation

/// Service for managing location requests and permissions
@Observable
public final class LocationService: NSObject, Sendable {
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<Location, Error>?
    
    public override init() {
        self.manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    /// Request current location with permission handling
    @MainActor
    public func requestLocation() async throws -> Location {
        // Check authorization status
        let status = manager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // Request permission
            manager.requestWhenInUseAuthorization()
            // Wait for authorization decision
            try await Task.sleep(for: .milliseconds(500))
            return try await requestLocation()
            
        case .restricted, .denied:
            throw WeatherError.locationDenied
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Permission granted, request location
            return try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                manager.requestLocation()
            }
            
        @unknown default:
            throw WeatherError.locationUnavailable
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.first else {
            continuation?.resume(throwing: WeatherError.locationUnavailable)
            continuation = nil
            return
        }
        
        let userLocation = Location(coordinate: location.coordinate)
        continuation?.resume(returning: userLocation)
        continuation = nil
    }
    
    public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                continuation?.resume(throwing: WeatherError.locationDenied)
            default:
                continuation?.resume(throwing: WeatherError.locationUnavailable)
            }
        } else {
            continuation?.resume(throwing: WeatherError.locationUnavailable)
        }
        continuation = nil
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // Authorization status changed, could trigger UI update
    }
}
