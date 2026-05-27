import Foundation

/// Errors that can occur during location operations
public enum LocationError: LocalizedError, Sendable {
    case permissionDenied
    case permissionRestricted
    case locationUnavailable
    case timeout
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied. Please enable location access in Settings."
        case .permissionRestricted:
            return "Location access is restricted on this device."
        case .locationUnavailable:
            return "Unable to determine your location. Please try again."
        case .timeout:
            return "Location request timed out. Please try again."
        case .unknown(let message):
            return "Location error: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .permissionDenied, .permissionRestricted:
            return "Open Settings and grant location permission to see weather for your current location."
        case .locationUnavailable, .timeout:
            return "Make sure you have a good signal and try again."
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}

/// Errors that can occur during weather operations
public enum WeatherError: LocalizedError, Sendable {
    case networkError(String)
    case invalidResponse
    case apiError(Int, String)
    case locationError(LocationError)
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidResponse:
            return "Invalid weather data received. Please try again."
        case .apiError(let code, let message):
            return "Weather service error (\(code)): \(message)"
        case .locationError(let error):
            return error.errorDescription
        case .unknown(let message):
            return "Weather error: \(message)"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again."
        case .invalidResponse, .apiError:
            return "Please try again in a few moments."
        case .locationError(let error):
            return error.recoverySuggestion
        case .unknown:
            return "Please try again or contact support if the problem persists."
        }
    }
}
