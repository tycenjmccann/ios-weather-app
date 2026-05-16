import Foundation
import CoreLocation
import Observation

// MARK: - Location Errors

public enum LocationError: Error, LocalizedError {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case timeout
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission was denied. Please enable location access in Settings."
        case .permissionRestricted:
            return "Location services are restricted on this device."
        case .locationUnavailable:
            return "Unable to determine your location. Please try again."
        case .timeout:
            return "Location request timed out. Please try again."
        }
    }
}

// MARK: - Location Service

/// Service for managing location permissions and fetching coordinates
@MainActor
@Observable
public final class LocationService: NSObject {
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    private var locationContinuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    
    public private(set) var authorizationStatus: CLAuthorizationStatus
    
    // MARK: - Initialization
    
    public override init() {
        self.locationManager = CLLocationManager()
        self.authorizationStatus = locationManager.authorizationStatus
        super.init()
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Public Methods
    
    /// Request location permissions if not already determined
    public func requestPermission() {
        guard authorizationStatus == .notDetermined else { return }
        locationManager.requestWhenInUseAuthorization()
    }
    
    /// Fetch the user's current location
    /// - Returns: The user's current coordinates
    /// - Throws: LocationError if permission denied or location unavailable
    public func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        // Check authorization status
        switch authorizationStatus {
        case .denied:
            throw LocationError.permissionDenied
        case .restricted:
            throw LocationError.permissionRestricted
        case .notDetermined:
            // Request permission and wait
            requestPermission()
            throw LocationError.permissionDenied // User needs to grant permission first
        case .authorizedAlways, .authorizedWhenInUse:
            break
        @unknown default:
            throw LocationError.locationUnavailable
        }
        
        // Request location with timeout
        return try await withTimeout(seconds: 10) {
            try await withCheckedThrowingContinuation { continuation in
                self.locationContinuation = continuation
                self.locationManager.requestLocation()
            }
        }
    }
    
    // MARK: - Private Helpers
    
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }
            
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw LocationError.timeout
            }
            
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else {
            locationContinuation?.resume(throwing: LocationError.locationUnavailable)
            locationContinuation = nil
            return
        }
        
        locationContinuation?.resume(returning: location.coordinate)
        locationContinuation = nil
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationContinuation?.resume(throwing: LocationError.locationUnavailable)
        locationContinuation = nil
    }
}
