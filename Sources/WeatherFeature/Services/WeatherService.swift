import Foundation

/// Service for fetching weather data from the backend API
@Observable
public final class WeatherService: Sendable {
    private let baseURL: URL
    private let session: URLSession
    
    public init(
        baseURL: URL = URL(string: "https://your-api-gateway-url.amazonaws.com/prod")!,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    /// Fetch current weather for the given location
    public func fetchWeather(for location: Location) async throws -> Weather {
        // Build URL with query parameters
        var components = URLComponents(
            url: baseURL.appendingPathComponent("weather"),
            resolvingAgainstBaseURL: true
        )
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(location.latitude)),
            URLQueryItem(name: "lon", value: String(location.longitude))
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidResponse
        }
        
        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        // Perform request
        let (data, response) = try await session.data(for: request)
        
        // Validate response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WeatherError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            if let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw WeatherError.apiError(errorBody.error)
            }
            throw WeatherError.apiError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        do {
            let decoder = JSONDecoder()
            let weatherResponse = try decoder.decode(WeatherAPIResponse.self, from: data)
            return weatherResponse.toWeather()
        } catch {
            throw WeatherError.invalidResponse
        }
    }
}

// MARK: - Error Response

private struct ErrorResponse: Codable {
    let error: String
}
