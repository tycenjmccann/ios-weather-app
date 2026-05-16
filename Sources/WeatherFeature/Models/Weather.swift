import Foundation

/// Represents current weather conditions for a location
public struct Weather: Codable, Sendable, Equatable {
    /// Temperature in Celsius
    public let temperature: Double
    
    /// Relative humidity as a percentage (0-100)
    public let humidity: Int
    
    /// Wind speed in kilometers per hour
    public let windSpeed: Double
    
    /// Weather condition code from API
    public let conditionCode: String
    
    /// Human-readable weather description
    public let description: String
    
    /// Location name
    public let locationName: String?
    
    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        conditionCode: String,
        description: String,
        locationName: String? = nil
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.conditionCode = conditionCode
        self.description = description
        self.locationName = locationName
    }
}

// MARK: - API Response Models

/// API response wrapper for weather data
struct WeatherAPIResponse: Codable, Sendable {
    let main: MainWeatherData
    let weather: [WeatherCondition]
    let wind: WindData
    let name: String
    
    struct MainWeatherData: Codable, Sendable {
        let temp: Double
        let humidity: Int
    }
    
    struct WeatherCondition: Codable, Sendable {
        let id: Int
        let main: String
        let description: String
    }
    
    struct WindData: Codable, Sendable {
        let speed: Double
    }
    
    /// Convert API response to domain Weather model
    func toWeather() -> Weather {
        Weather(
            temperature: main.temp,
            humidity: main.humidity,
            windSpeed: wind.speed,
            conditionCode: weather.first?.main ?? "Unknown",
            description: weather.first?.description.capitalized ?? "No description",
            locationName: name
        )
    }
}
