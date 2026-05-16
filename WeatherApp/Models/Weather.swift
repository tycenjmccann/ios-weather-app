import Foundation

// MARK: - Weather Models

/// Represents current weather conditions
public struct Weather: Codable, Sendable, Equatable {
    public let temperature: Double
    public let feelsLike: Double
    public let humidity: Int
    public let windSpeed: Double
    public let description: String
    public let icon: String
    public let timestamp: Date
    
    public init(
        temperature: Double,
        feelsLike: Double,
        humidity: Int,
        windSpeed: Double,
        description: String,
        icon: String,
        timestamp: Date = Date()
    ) {
        self.temperature = temperature
        self.feelsLike = feelsLike
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.description = description
        self.icon = icon
        self.timestamp = timestamp
    }
}

/// Represents a daily forecast entry
public struct DailyForecast: Codable, Sendable, Equatable, Identifiable {
    public let id: UUID
    public let date: Date
    public let temperatureHigh: Double
    public let temperatureLow: Double
    public let description: String
    public let icon: String
    
    public init(
        id: UUID = UUID(),
        date: Date,
        temperatureHigh: Double,
        temperatureLow: Double,
        description: String,
        icon: String
    ) {
        self.id = id
        self.date = date
        self.temperatureHigh = temperatureHigh
        self.temperatureLow = temperatureLow
        self.description = description
        self.icon = icon
    }
}

// MARK: - OpenWeatherMap API Response Models

/// Response structure for current weather endpoint
struct OpenWeatherCurrentResponse: Codable {
    let main: MainWeather
    let weather: [WeatherDescription]
    let wind: Wind
    let dt: TimeInterval
    
    struct MainWeather: Codable {
        let temp: Double
        let feelsLike: Double
        let humidity: Int
        
        enum CodingKeys: String, CodingKey {
            case temp
            case feelsLike = "feels_like"
            case humidity
        }
    }
    
    struct WeatherDescription: Codable {
        let description: String
        let icon: String
    }
    
    struct Wind: Codable {
        let speed: Double
    }
}

extension OpenWeatherCurrentResponse {
    func toWeather() -> Weather? {
        guard let weatherDesc = weather.first else { return nil }
        return Weather(
            temperature: main.temp,
            feelsLike: main.feelsLike,
            humidity: main.humidity,
            windSpeed: wind.speed,
            description: weatherDesc.description,
            icon: weatherDesc.icon,
            timestamp: Date(timeIntervalSince1970: dt)
        )
    }
}

/// Response structure for 5-day forecast endpoint
struct OpenWeatherForecastResponse: Codable {
    let list: [ForecastItem]
    
    struct ForecastItem: Codable {
        let dt: TimeInterval
        let main: MainWeather
        let weather: [WeatherDescription]
        
        struct MainWeather: Codable {
            let temp: Double
            let tempMin: Double
            let tempMax: Double
            
            enum CodingKeys: String, CodingKey {
                case temp
                case tempMin = "temp_min"
                case tempMax = "temp_max"
            }
        }
        
        struct WeatherDescription: Codable {
            let description: String
            let icon: String
        }
    }
}

extension OpenWeatherForecastResponse {
    func toDailyForecasts() -> [DailyForecast] {
        // Group forecast items by day and aggregate high/low temps
        let calendar = Calendar.current
        var dailyData: [Date: (high: Double, low: Double, description: String, icon: String)] = [:]
        
        for item in list {
            let date = Date(timeIntervalSince1970: item.dt)
            let dayStart = calendar.startOfDay(for: date)
            
            guard let weatherDesc = item.weather.first else { continue }
            
            if var existing = dailyData[dayStart] {
                existing.high = max(existing.high, item.main.tempMax)
                existing.low = min(existing.low, item.main.tempMin)
                dailyData[dayStart] = existing
            } else {
                dailyData[dayStart] = (
                    high: item.main.tempMax,
                    low: item.main.tempMin,
                    description: weatherDesc.description,
                    icon: weatherDesc.icon
                )
            }
        }
        
        // Convert to DailyForecast array, sorted by date
        return dailyData
            .sorted { $0.key < $1.key }
            .prefix(5) // Take only 5 days
            .map { date, data in
                DailyForecast(
                    date: date,
                    temperatureHigh: data.high,
                    temperatureLow: data.low,
                    description: data.description,
                    icon: data.icon
                )
            }
    }
}
