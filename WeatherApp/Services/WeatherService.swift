import Foundation
import CoreLocation
import Observation

// MARK: - Weather Service Errors

public enum WeatherServiceError: Error, LocalizedError {
    case invalidAPIKey
    case networkError(Error)
    case invalidResponse
    case rateLimitExceeded
    case serverError(Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidAPIKey:
            return "Invalid API key. Please check your OpenWeatherMap API configuration."
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Unable to process weather data. Please try again."
        case .rateLimitExceeded:
            return "API rate limit exceeded. Please try again in a few minutes."
        case .serverError(let code):
            return "Server error (code \(code)). Please try again later."
        }
    }
}

// MARK: - Weather Service Protocol

public protocol WeatherServiceProtocol: Sendable {
    func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather
    func fetchForecast(latitude: Double, longitude: Double) async throws -> [DailyForecast]
}

// MARK: - Weather Service

/// Service for fetching weather data from OpenWeatherMap API
@Observable
public final class WeatherService: WeatherServiceProtocol {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let session: URLSession
    private let decoder: JSONDecoder
    
    // MARK: - Initialization
    
    public init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
        
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    // MARK: - Public Methods
    
    /// Fetch current weather for given coordinates
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    /// - Returns: Current weather data
    /// - Throws: WeatherServiceError if request fails
    public func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        let endpoint = "\(baseURL)/weather"
        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial") // Fahrenheit
        ]
        
        guard let url = components?.url else {
            throw WeatherServiceError.invalidResponse
        }
        
        let response: OpenWeatherCurrentResponse = try await performRequest(url: url)
        
        guard let weather = response.toWeather() else {
            throw WeatherServiceError.invalidResponse
        }
        
        return weather
    }
    
    /// Fetch 5-day forecast for given coordinates
    /// - Parameters:
    ///   - latitude: Latitude coordinate
    ///   - longitude: Longitude coordinate
    /// - Returns: Array of daily forecasts
    /// - Throws: WeatherServiceError if request fails
    public func fetchForecast(latitude: Double, longitude: Double) async throws -> [DailyForecast] {
        let endpoint = "\(baseURL)/forecast"
        var components = URLComponents(string: endpoint)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial") // Fahrenheit
        ]
        
        guard let url = components?.url else {
            throw WeatherServiceError.invalidResponse
        }
        
        let response: OpenWeatherForecastResponse = try await performRequest(url: url)
        return response.toDailyForecasts()
    }
    
    // MARK: - Private Methods
    
    private func performRequest<T: Decodable>(url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw WeatherServiceError.invalidResponse
            }
        case 401:
            throw WeatherServiceError.invalidAPIKey
        case 429:
            throw WeatherServiceError.rateLimitExceeded
        case 500...599:
            throw WeatherServiceError.serverError(httpResponse.statusCode)
        default:
            throw WeatherServiceError.invalidResponse
        }
    }
}

// MARK: - Mock Weather Service for Testing

#if DEBUG
public final class MockWeatherService: WeatherServiceProtocol {
    public var shouldFail = false
    public var errorToThrow: WeatherServiceError?
    
    public init() {}
    
    public func fetchCurrentWeather(latitude: Double, longitude: Double) async throws -> Weather {
        if shouldFail, let error = errorToThrow {
            throw error
        }
        
        try await Task.sleep(for: .milliseconds(500)) // Simulate network delay
        
        return Weather(
            temperature: 72.5,
            feelsLike: 70.0,
            humidity: 65,
            windSpeed: 8.5,
            description: "partly cloudy",
            icon: "02d"
        )
    }
    
    public func fetchForecast(latitude: Double, longitude: Double) async throws -> [DailyForecast] {
        if shouldFail, let error = errorToThrow {
            throw error
        }
        
        try await Task.sleep(for: .milliseconds(500)) // Simulate network delay
        
        let calendar = Calendar.current
        return (0..<5).map { day in
            let date = calendar.date(byAdding: .day, value: day, to: Date())!
            return DailyForecast(
                date: date,
                temperatureHigh: 75.0 + Double(day),
                temperatureLow: 55.0 + Double(day),
                description: "sunny",
                icon: "01d"
            )
        }
    }
}
#endif
