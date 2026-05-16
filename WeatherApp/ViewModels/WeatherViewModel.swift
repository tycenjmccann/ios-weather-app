import Foundation
import CoreLocation
import Observation

// MARK: - Weather View State

/// State enum for weather view
public enum WeatherViewState: Equatable {
    case initial
    case requestingPermission
    case loading
    case loaded(Weather, [DailyForecast])
    case error(String)
    
    public static func == (lhs: WeatherViewState, rhs: WeatherViewState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial),
             (.requestingPermission, .requestingPermission),
             (.loading, .loading):
            return true
        case let (.loaded(w1, f1), .loaded(w2, f2)):
            return w1 == w2 && f1 == f2
        case let (.error(e1), .error(e2)):
            return e1 == e2
        default:
            return false
        }
    }
}

// MARK: - Weather View Model

/// Observable state container for weather view
@MainActor
@Observable
public final class WeatherViewModel {
    
    // MARK: - Properties
    
    public private(set) var state: WeatherViewState = .initial
    
    private let locationService: LocationService
    private let weatherService: WeatherServiceProtocol
    
    // MARK: - Initialization
    
    public init(
        locationService: LocationService = LocationService(),
        weatherService: WeatherServiceProtocol
    ) {
        self.locationService = locationService
        self.weatherService = weatherService
    }
    
    // MARK: - Public Methods
    
    /// Load weather data - checks permissions and fetches weather
    public func loadWeather() async {
        // Check current authorization status
        let status = locationService.authorizationStatus
        
        switch status {
        case .notDetermined:
            state = .requestingPermission
            locationService.requestPermission()
            // User will need to grant permission, then retry
            return
            
        case .denied:
            state = .error(LocationError.permissionDenied.localizedDescription)
            return
            
        case .restricted:
            state = .error(LocationError.permissionRestricted.localizedDescription)
            return
            
        case .authorizedAlways, .authorizedWhenInUse:
            await fetchWeatherData()
            
        @unknown default:
            state = .error("Unknown authorization status")
        }
    }
    
    /// Retry loading weather data after an error
    public func retry() async {
        await loadWeather()
    }
    
    // MARK: - Private Methods
    
    private func fetchWeatherData() async {
        state = .loading
        
        do {
            // Get current location
            let coordinates = try await locationService.getCurrentLocation()
            
            // Fetch weather and forecast concurrently
            async let currentWeather = weatherService.fetchCurrentWeather(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            async let forecast = weatherService.fetchForecast(
                latitude: coordinates.latitude,
                longitude: coordinates.longitude
            )
            
            let (weather, dailyForecast) = try await (currentWeather, forecast)
            state = .loaded(weather, dailyForecast)
            
        } catch let error as LocationError {
            state = .error(error.localizedDescription)
        } catch let error as WeatherServiceError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("An unexpected error occurred: \(error.localizedDescription)")
        }
    }
}
