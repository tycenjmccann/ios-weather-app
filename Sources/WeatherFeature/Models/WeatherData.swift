import Foundation

/// Represents current weather conditions for a location
public struct WeatherData: Codable, Sendable, Equatable {
    /// Temperature in the specified unit
    public let temperature: Double
    
    /// Humidity percentage (0-100)
    public let humidity: Int
    
    /// Wind speed in the specified unit
    public let windSpeed: Double
    
    /// Weather condition identifier (e.g., "clear", "rain", "clouds")
    public let condition: String
    
    /// Optional weather description (e.g., "clear sky", "light rain")
    public let description: String?
    
    /// Temperature unit (celsius or fahrenheit)
    public let temperatureUnit: TemperatureUnit
    
    /// Wind speed unit (metersPerSecond or milesPerHour)
    public let windSpeedUnit: WindSpeedUnit
    
    /// Timestamp when weather data was fetched
    public let timestamp: Date
    
    public init(
        temperature: Double,
        humidity: Int,
        windSpeed: Double,
        condition: String,
        description: String? = nil,
        temperatureUnit: TemperatureUnit = .celsius,
        windSpeedUnit: WindSpeedUnit = .metersPerSecond,
        timestamp: Date = Date()
    ) {
        self.temperature = temperature
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.condition = condition
        self.description = description
        self.temperatureUnit = temperatureUnit
        self.windSpeedUnit = windSpeedUnit
        self.timestamp = timestamp
    }
    
    // MARK: - Units
    
    public enum TemperatureUnit: String, Codable, Sendable {
        case celsius = "C"
        case fahrenheit = "F"
    }
    
    public enum WindSpeedUnit: String, Codable, Sendable {
        case metersPerSecond = "m/s"
        case milesPerHour = "mph"
        case kilometersPerHour = "km/h"
    }
    
    // MARK: - Formatting
    
    /// Formatted temperature string with unit symbol
    public var formattedTemperature: String {
        String(format: "%.1f°%@", temperature, temperatureUnit.rawValue)
    }
    
    /// Formatted humidity string with percentage
    public var formattedHumidity: String {
        "\(humidity)%"
    }
    
    /// Formatted wind speed with unit
    public var formattedWindSpeed: String {
        String(format: "%.1f %@", windSpeed, windSpeedUnit.rawValue)
    }
    
    /// SF Symbol name for weather condition
    public var weatherSymbol: String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds", "cloudy":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog", "haze":
            return "cloud.fog.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}

// MARK: - API Response Model

/// Response model from weather API
struct WeatherAPIResponse: Codable {
    let main: MainWeather
    let weather: [WeatherCondition]
    let wind: Wind
    let dt: TimeInterval
    
    struct MainWeather: Codable {
        let temp: Double
        let humidity: Int
    }
    
    struct WeatherCondition: Codable {
        let main: String
        let description: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
    
    /// Convert API response to domain model
    func toWeatherData(
        temperatureUnit: WeatherData.TemperatureUnit = .celsius,
        windSpeedUnit: WeatherData.WindSpeedUnit = .metersPerSecond
    ) -> WeatherData {
        WeatherData(
            temperature: main.temp,
            humidity: main.humidity,
            windSpeed: wind.speed,
            condition: weather.first?.main ?? "unknown",
            description: weather.first?.description,
            temperatureUnit: temperatureUnit,
            windSpeedUnit: windSpeedUnit,
            timestamp: Date(timeIntervalSince1970: dt)
        )
    }
}
