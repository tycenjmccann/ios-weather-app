import CoreLocation
import Foundation

/// Service for fetching weather data from the backend API
@Observable
public final class WeatherService: Sendable {
    
    // MARK: - Properties
    
    private let baseURL: URL
    private let session: URLSession
    
    /// Default API endpoint - update with your actual backend URL
    private static let defaultBaseURL = URL(string: "https://api.weather.example.com/v1")!
    
    // MARK: - Initialization
    
    public init(
        baseURL: URL = defaultBaseURL,
        session: URLSession = .shared
    ) {
        self.baseURL = baseURL
        self.session = session
    }
    
    // MARK: - Public Methods
    
    /// Fetch current weather for given coordinates
    /// - Parameters:
    ///   - coordinate: Location coordinates
    ///   - temperatureUnit: Desired temperature unit
    ///   - windSpeedUnit: Desired wind speed unit
    /// - Returns: Current weather data
    /// - Throws: WeatherError if fetch fails
    public func fetchWeather(
        for coordinate: CLLocationCoordinate2D,
        temperatureUnit: WeatherData.TemperatureUnit = .celsius,
        windSpeedUnit: WeatherData.WindSpeedUnit = .metersPerSecond
    ) async throws -> WeatherData {
        // Build request URL with query parameters
        var components = URLComponents(
            url: baseURL.appendingPathComponent("weather"),
            resolvingAgainstBaseURL: true
        )
        
        components?.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lon", value: String(coordinate.longitude)),
            URLQueryItem(name: "units", value: temperatureUnit == .celsius ? "metric" : "imperial")
        ]
        
        guard let url = components?.url else {
            throw WeatherError.invalidResponse
        }
        
        // Create and configure request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        // Perform request
        do {
            let (data, response) = try await session.data(for: request)
            
            // Validate HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw WeatherError.networkError("Invalid response type")
            }
            
            // Handle HTTP error codes
            guard (200...299).contains(httpResponse.statusCode) else {
                // Try to parse error message from response body
                if let errorResponse = try? JSONDecoder().decode(
                    APIErrorResponse.self,
                    from: data
                ) {
                    throw WeatherError.apiError(
                        httpResponse.statusCode,
                        errorResponse.message
                    )
                }
                throw WeatherError.apiError(
                    httpResponse.statusCode,
                    "HTTP \(httpResponse.statusCode)"
                )
            }
            
            // Decode weather data
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .secondsSince1970
            
            let apiResponse = try decoder.decode(WeatherAPIResponse.self, from: data)
            return apiResponse.toWeatherData(
                temperatureUnit: temperatureUnit,
                windSpeedUnit: windSpeedUnit
            )
            
        } catch let error as WeatherError {
            throw error
        } catch let error as URLError {
            throw WeatherError.networkError(error.localizedDescription)
        } catch {
            throw WeatherError.invalidResponse
        }
    }
}

// MARK: - API Error Response

/// Error response from API
private struct APIErrorResponse: Codable {
    let message: String
    let code: String?
}
