import CoreLocation
import Testing
@testable import WeatherFeature

/// Tests for WeatherService
struct WeatherServiceTests {
    
    // MARK: - Mock URLSession
    
    /// Mock URLSession for testing
    final class MockURLSession: URLSession {
        var mockData: Data?
        var mockResponse: HTTPURLResponse?
        var mockError: Error?
        
        override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
            if let error = mockError {
                throw error
            }
            
            guard let data = mockData, let response = mockResponse else {
                throw URLError(.badServerResponse)
            }
            
            return (data, response)
        }
    }
    
    // MARK: - Tests
    
    @Test("Fetch weather successfully")
    func testFetchWeatherSuccess() async throws {
        // Prepare mock response
        let mockSession = MockURLSession()
        let apiResponse = WeatherAPIResponse(
            main: WeatherAPIResponse.MainWeather(temp: 22.5, humidity: 65),
            weather: [
                WeatherAPIResponse.WeatherCondition(
                    main: "Clear",
                    description: "clear sky"
                )
            ],
            wind: WeatherAPIResponse.Wind(speed: 5.2),
            dt: Date().timeIntervalSince1970
        )
        
        let encoder = JSONEncoder()
        mockSession.mockData = try encoder.encode(apiResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/weather")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        // Create service with mock session
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        // Test
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let weather = try await service.fetchWeather(for: coordinate)
        
        #expect(weather.temperature == 22.5)
        #expect(weather.humidity == 65)
        #expect(weather.windSpeed == 5.2)
        #expect(weather.condition == "Clear")
        #expect(weather.description == "clear sky")
    }
    
    @Test("Fetch weather handles network error")
    func testFetchWeatherNetworkError() async {
        // Prepare mock session with error
        let mockSession = MockURLSession()
        mockSession.mockError = URLError(.notConnectedToInternet)
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        // Test
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try await service.fetchWeather(for: coordinate)
            Issue.record("Expected WeatherError.networkError to be thrown")
        } catch let error as WeatherError {
            if case .networkError = error {
                // Expected error
            } else {
                Issue.record("Expected WeatherError.networkError, got \\(error)")
            }
        } catch {
            Issue.record("Expected WeatherError, got \\(error)")
        }
    }
    
    @Test("Fetch weather handles HTTP error")
    func testFetchWeatherHTTPError() async throws {
        // Prepare mock response with error
        let mockSession = MockURLSession()
        let errorResponse = """
        {
            "message": "API key invalid",
            "code": "invalid_api_key"
        }
        """.data(using: .utf8)!
        
        mockSession.mockData = errorResponse
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/weather")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        // Test
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try await service.fetchWeather(for: coordinate)
            Issue.record("Expected WeatherError.apiError to be thrown")
        } catch let error as WeatherError {
            if case .apiError(let code, let message) = error {
                #expect(code == 401)
                #expect(message.contains("API key"))
            } else {
                Issue.record("Expected WeatherError.apiError, got \\(error)")
            }
        } catch {
            Issue.record("Expected WeatherError, got \\(error)")
        }
    }
    
    @Test("Fetch weather handles invalid response")
    func testFetchWeatherInvalidResponse() async {
        // Prepare mock response with invalid JSON
        let mockSession = MockURLSession()
        mockSession.mockData = "invalid json".data(using: .utf8)!
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/weather")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        // Test
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try await service.fetchWeather(for: coordinate)
            Issue.record("Expected WeatherError.invalidResponse to be thrown")
        } catch let error as WeatherError {
            if case .invalidResponse = error {
                // Expected error
            } else {
                Issue.record("Expected WeatherError.invalidResponse, got \\(error)")
            }
        } catch {
            Issue.record("Expected WeatherError, got \\(error)")
        }
    }
    
    @Test("Fetch weather with different temperature units")
    func testFetchWeatherWithUnits() async throws {
        // Prepare mock response
        let mockSession = MockURLSession()
        let apiResponse = WeatherAPIResponse(
            main: WeatherAPIResponse.MainWeather(temp: 72.0, humidity: 60),
            weather: [
                WeatherAPIResponse.WeatherCondition(
                    main: "Clear",
                    description: "clear sky"
                )
            ],
            wind: WeatherAPIResponse.Wind(speed: 10.0),
            dt: Date().timeIntervalSince1970
        )
        
        let encoder = JSONEncoder()
        mockSession.mockData = try encoder.encode(apiResponse)
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.example.com/weather")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        // Test with Fahrenheit
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let weather = try await service.fetchWeather(
            for: coordinate,
            temperatureUnit: .fahrenheit,
            windSpeedUnit: .milesPerHour
        )
        
        #expect(weather.temperatureUnit == .fahrenheit)
        #expect(weather.windSpeedUnit == .milesPerHour)
        #expect(weather.temperature == 72.0)
        #expect(weather.windSpeed == 10.0)
    }
    
    @Test("WeatherService is Sendable")
    func testSendable() async {
        let service = WeatherService()
        
        // This should compile without warnings
        Task {
            let _ = service
        }
    }
}
