import Foundation
import Observation

// MARK: - Weather Service Protocol

public protocol WeatherServiceProtocol: Sendable {
    func fetchFiveDayForecast() async throws -> FiveDayForecast
}

// MARK: - Weather Service Error

public enum WeatherServiceError: LocalizedError, Sendable {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case decodingError(Error)
    case apiError(statusCode: Int, message: String)
    case noData
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL configuration"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .decodingError:
            return "Failed to parse weather data"
        case .apiError(let statusCode, let message):
            return "API error (\(statusCode)): \(message)"
        case .noData:
            return "No weather data available"
        }
    }
    
    public var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Please check your internet connection and try again."
        case .apiError:
            return "Please try again later."
        default:
            return "Please try refreshing the data."
        }
    }
}

// MARK: - API Response Models

private struct WeatherAPIResponse: Codable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: MainData
        let weather: [WeatherData]
        let pop: Double // Probability of precipitation
        
        struct MainData: Codable {
            let tempMin: Double
            let tempMax: Double
            
            enum CodingKeys: String, CodingKey {
                case tempMin = "temp_min"
                case tempMax = "temp_max"
            }
        }
        
        struct WeatherData: Codable {
            let main: String
            let description: String
            let icon: String
        }
    }
}

// MARK: - Weather Service

/// Service for fetching weather forecast data
@Observable
public final class WeatherService: WeatherServiceProtocol {
    
    // MARK: Properties
    
    private let apiKey: String
    private let baseURL: String
    private let session: URLSession
    private let cache: WeatherCache
    
    // MARK: Initialization
    
    public init(
        apiKey: String = "demo_api_key",
        baseURL: String = "https://api.openweathermap.org/data/2.5",
        session: URLSession = .shared,
        cache: WeatherCache = WeatherCache()
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
        self.cache = cache
    }
    
    // MARK: Public Methods
    
    /// Fetch 5-day weather forecast
    /// - Returns: Five day forecast with daily data
    /// - Throws: WeatherServiceError if the request fails
    public func fetchFiveDayForecast() async throws -> FiveDayForecast {
        // Check cache first
        if let cachedForecast = cache.getForecast(), cache.isForecastValid() {
            return cachedForecast
        }
        
        // Build URL with query parameters
        guard var components = URLComponents(string: "\(baseURL)/forecast") else {
            throw WeatherServiceError.invalidURL
        }
        
        components.queryItems = [
            URLQueryItem(name: "lat", value: "37.7749"),  // San Francisco (demo)
            URLQueryItem(name: "lon", value: "-122.4194"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "cnt", value: "40") // 5 days * 8 (3-hour intervals)
        ]
        
        guard let url = components.url else {
            throw WeatherServiceError.invalidURL
        }
        
        // Perform network request
        let (data, response) = try await session.data(from: url)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherServiceError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw WeatherServiceError.apiError(statusCode: httpResponse.statusCode, message: message)
        }
        
        // Decode response
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        let apiResponse: WeatherAPIResponse
        do {
            apiResponse = try decoder.decode(WeatherAPIResponse.self, from: data)
        } catch {
            throw WeatherServiceError.decodingError(error)
        }
        
        // Process forecast data into daily forecasts
        let dailyForecasts = try processDailyForecasts(from: apiResponse)
        let forecast = FiveDayForecast(days: dailyForecasts)
        
        // Cache the result
        cache.saveForecast(forecast)
        
        return forecast
    }
    
    // MARK: Private Methods
    
    /// Process API response into daily forecasts
    private func processDailyForecasts(from response: WeatherAPIResponse) throws -> [DailyForecast] {
        guard !response.list.isEmpty else {
            throw WeatherServiceError.noData
        }
        
        // Group forecasts by day
        let calendar = Calendar.current
        var dailyData: [Date: [WeatherAPIResponse.ForecastItem]] = [:]
        
        for item in response.list {
            let date = Date(timeIntervalSince1970: item.dt)
            let dayStart = calendar.startOfDay(for: date)
            dailyData[dayStart, default: []].append(item)
        }
        
        // Convert to DailyForecast objects (skip today, take next 5 days)
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: Date())!)
        let sortedDays = dailyData.keys.sorted()
            .filter { $0 >= tomorrow }
            .prefix(5)
        
        return sortedDays.compactMap { day -> DailyForecast? in
            guard let items = dailyData[day], !items.isEmpty else { return nil }
            
            // Calculate high/low temps for the day
            let temps = items.map { $0.main.tempMax }
            let highTemp = temps.max() ?? 0
            let lowTemp = items.map { $0.main.tempMin }.min() ?? 0
            
            // Use the most common weather condition
            let conditions = items.compactMap { $0.weather.first?.main }
            let condition = mostCommon(in: conditions) ?? "Clear"
            
            // Average precipitation chance
            let avgPrecipitation = items.map { $0.pop }.reduce(0, +) / Double(items.count)
            
            // Get icon from first item
            let icon = items.first?.weather.first?.icon ?? "01d"
            
            return DailyForecast(
                date: day,
                highTemp: highTemp,
                lowTemp: lowTemp,
                condition: mapWeatherCondition(from: condition),
                precipitationChance: avgPrecipitation,
                icon: icon
            )
        }
    }
    
    /// Map API weather condition to app's WeatherCondition enum
    private func mapWeatherCondition(from apiCondition: String) -> WeatherCondition {
        switch apiCondition.lowercased() {
        case "clear":
            return .clear
        case "clouds":
            return .cloudy
        case "rain", "drizzle":
            return .rainy
        case "snow":
            return .snowy
        case "thunderstorm":
            return .stormy
        case "mist", "fog", "haze":
            return .foggy
        default:
            return .partlyCloudy
        }
    }
    
    /// Find most common element in array
    private func mostCommon<T: Hashable>(in array: [T]) -> T? {
        let counts = array.reduce(into: [:]) { counts, element in
            counts[element, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key
    }
}

// MARK: - Weather Cache

/// Simple in-memory cache for weather forecast data
public final class WeatherCache: Sendable {
    private let lock = NSLock()
    private var cachedForecast: FiveDayForecast?
    private var cacheTime: Date?
    private let cacheValidityDuration: TimeInterval = 1800 // 30 minutes
    
    public init() {}
    
    public func saveForecast(_ forecast: FiveDayForecast) {
        lock.lock()
        defer { lock.unlock() }
        cachedForecast = forecast
        cacheTime = Date()
    }
    
    public func getForecast() -> FiveDayForecast? {
        lock.lock()
        defer { lock.unlock() }
        return cachedForecast
    }
    
    public func isForecastValid() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard let cacheTime = cacheTime else { return false }
        return Date().timeIntervalSince(cacheTime) < cacheValidityDuration
    }
    
    public func clearCache() {
        lock.lock()
        defer { lock.unlock() }
        cachedForecast = nil
        cacheTime = nil
    }
}
