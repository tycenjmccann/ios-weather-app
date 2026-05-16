import Foundation

@Observable
final class WeatherService: Sendable {
    private let apiKey: String
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    init(apiKey: String = "") {
        self.apiKey = apiKey
    }
    
    func fetchCurrentWeather(for city: String) async throws -> WeatherCondition {
        // TODO: Implement API call
        fatalError("Not implemented")
    }
    
    func fetchForecast(for city: String) async throws -> WeatherForecast {
        // TODO: Implement API call
        fatalError("Not implemented")
    }
}
