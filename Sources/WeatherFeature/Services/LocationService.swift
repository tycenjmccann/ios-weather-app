import CoreLocation
import Foundation

/// Service for managing location permissions and fetching user coordinates
@Observable
@MainActor
public final class LocationService: NSObject, Sendable {
    
    // MARK: - Properties
    
    private let manager: CLLocationManager
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    
    /// Current authorization status
    public private(set) var authorizationStatus: CLAuthorizationStatus
    
    // MARK: - Initialization
    
    public override init() {
        self.manager = CLLocationManager()
        self.authorizationStatus = manager.authorizationStatus
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Public Methods
    
    /// Request when-in-use location authorization
    public func requestAuthorization() {
        manager.requestWhenInUseAuthorization()
    }
    
    /// Fetch current location coordinates
    /// - Throws: LocationError if unable to get location
    /// - Returns: User's current coordinates
    public func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        // Check authorization status first
        switch authorizationStatus {
        case .notDetermined:
            requestAuthorization()
            // Wait for user to respond
            try await Task.sleep(for: .milliseconds(500))
            // Retry after permission request
            return try await getCurrentLocation()
            
        case .restricted:
            throw LocationError.permissionRestricted
            
        case .denied:
            throw LocationError.permissionDenied
            
        case .authorizedAlways, .authorizedWhenInUse:
            break
            
        @unknown default:
            throw LocationError.unknown("Unknown authorization status")
        }
        
        // Request location with timeout
        return try await withTimeout(seconds: 10) {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                self.manager.requestLocation()
            }
        }
    }
    
    // MARK: - Private Helpers
    
    /// Execute async operation with timeout
    private func withTimeout<T>(
        seconds: TimeInterval,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            // Add main operation
            group.addTask {
                try await operation()
            }
            
            // Add timeout task
            group.addTask {
                try await Task.sleep(for: .seconds(seconds))
                throw LocationError.timeout
            }
            
            // Return first result and cancel other task
            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationService: CLLocationManagerDelegate {
    
    nonisolated public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
        }
    }
    
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        Task { @MainActor in
            guard let location = locations.first else {
                self.continuation?.resume(throwing: LocationError.locationUnavailable)
                self.continuation = nil
                return
            }
            
            self.continuation?.resume(returning: location.coordinate)
            self.continuation = nil
        }
    }
    
    nonisolated public func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        Task { @MainActor in
            let locationError: LocationError
            
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    locationError = .permissionDenied
                case .locationUnknown:
                    locationError = .locationUnavailable
                default:
                    locationError = .unknown(error.localizedDescription)
                }
            } else {
                locationError = .unknown(error.localizedDescription)
            }
            
            self.continuation?.resume(throwing: locationError)
            self.continuation = nil
        }
    }
}
