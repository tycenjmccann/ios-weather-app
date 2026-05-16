import Foundation

struct WeatherCondition: Codable, Sendable, Identifiable {
    let id: UUID
    let temperature: Double
    let description: String
    let icon: String
    let humidity: Int
    let windSpeed: Double
    let cityName: String
    let timestamp: Date
}

struct WeatherForecast: Codable, Sendable {
    let daily: [DayForecast]
}

struct DayForecast: Codable, Sendable, Identifiable {
    let id: UUID
    let date: Date
    let high: Double
    let low: Double
    let condition: String
    let icon: String
}
