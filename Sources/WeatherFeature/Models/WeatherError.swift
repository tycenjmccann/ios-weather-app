import Foundation

/// Errors that can occur during weather operations
public enum WeatherError: LocalizedError, Sendable {
    case locationDenied
    case locationUnavailable
    case networkError
    case invalidResponse
    case apiError(String)
    
    public var errorDescription: String? {
        switch self {
        case .locationDenied:
            return "Location access denied. Please enable location services in Settings."
        case .locationUnavailable:
            return "Unable to determine your location. Please try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .invalidResponse:
            return "Invalid response from weather service."
        case .apiError(let message):
            return "Weather service error: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .locationDenied:
            return "Go to Settings > Privacy & Security > Location Services to enable location access."
        case .locationUnavailable:
            return "Make sure location services are enabled and try again."
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidResponse, .apiError:
            return "Please try again later."
        }
    }
}
