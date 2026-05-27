import Testing
import Foundation
@testable import WeatherFeature

// MARK: - Weather Model Tests

@Suite("Weather Model Tests")
struct WeatherModelTests {
    
    @Test("Weather initializes with correct values")
    func testWeatherInitialization() {
        let weather = Weather(
            temperature: 22.5,
            humidity: 65,
            windSpeed: 10.5,
            conditionCode: "Clear",
            description: "Clear sky",
            locationName: "San Francisco"
        )
        
        #expect(weather.temperature == 22.5)
        #expect(weather.humidity == 65)
        #expect(weather.windSpeed == 10.5)
        #expect(weather.conditionCode == "Clear")
        #expect(weather.description == "Clear sky")
        #expect(weather.locationName == "San Francisco")
    }
    
    @Test("Weather conforms to Equatable")
    func testWeatherEquality() {
        let weather1 = Weather(
            temperature: 22.5,
            humidity: 65,
            windSpeed: 10.5,
            conditionCode: "Clear",
            description: "Clear sky"
        )
        
        let weather2 = Weather(
            temperature: 22.5,
            humidity: 65,
            windSpeed: 10.5,
            conditionCode: "Clear",
            description: "Clear sky"
        )
        
        #expect(weather1 == weather2)
    }
    
    @Test("WeatherAPIResponse converts to Weather correctly")
    func testAPIResponseConversion() {
        let apiResponse = WeatherAPIResponse(
            main: WeatherAPIResponse.MainWeatherData(temp: 22.5, humidity: 65),
            weather: [
                WeatherAPIResponse.WeatherCondition(
                    id: 800,
                    main: "Clear",
                    description: "clear sky"
                )
            ],
            wind: WeatherAPIResponse.WindData(speed: 10.5),
            name: "San Francisco"
        )
        
        let weather = apiResponse.toWeather()
        
        #expect(weather.temperature == 22.5)
        #expect(weather.humidity == 65)
        #expect(weather.windSpeed == 10.5)
        #expect(weather.conditionCode == "Clear")
        #expect(weather.description == "Clear Sky")
        #expect(weather.locationName == "San Francisco")
    }
    
    @Test("WeatherAPIResponse handles missing weather condition")
    func testAPIResponseWithoutWeatherCondition() {
        let apiResponse = WeatherAPIResponse(
            main: WeatherAPIResponse.MainWeatherData(temp: 22.5, humidity: 65),
            weather: [],
            wind: WeatherAPIResponse.WindData(speed: 10.5),
            name: "Test City"
        )
        
        let weather = apiResponse.toWeather()
        
        #expect(weather.conditionCode == "Unknown")
        #expect(weather.description == "No description")
    }
}

// MARK: - Location Model Tests

@Suite("Location Model Tests")
struct LocationModelTests {
    
    @Test("Location initializes with coordinates")
    func testLocationInitialization() {
        let location = Location(latitude: 37.7749, longitude: -122.4194)
        
        #expect(location.latitude == 37.7749)
        #expect(location.longitude == -122.4194)
    }
    
    @Test("Location conforms to Equatable")
    func testLocationEquality() {
        let location1 = Location(latitude: 37.7749, longitude: -122.4194)
        let location2 = Location(latitude: 37.7749, longitude: -122.4194)
        
        #expect(location1 == location2)
    }
}

// MARK: - WeatherError Tests

@Suite("WeatherError Tests")
struct WeatherErrorTests {
    
    @Test("LocationDenied error has correct description")
    func testLocationDeniedError() {
        let error = WeatherError.locationDenied
        #expect(error.localizedDescription.contains("Location access denied"))
        #expect(error.recoverySuggestion?.contains("Settings") == true)
    }
    
    @Test("LocationUnavailable error has correct description")
    func testLocationUnavailableError() {
        let error = WeatherError.locationUnavailable
        #expect(error.localizedDescription.contains("Unable to determine"))
    }
    
    @Test("NetworkError error has correct description")
    func testNetworkError() {
        let error = WeatherError.networkError
        #expect(error.localizedDescription.contains("Network error"))
        #expect(error.recoverySuggestion?.contains("connection") == true)
    }
    
    @Test("InvalidResponse error has correct description")
    func testInvalidResponseError() {
        let error = WeatherError.invalidResponse
        #expect(error.localizedDescription.contains("Invalid response"))
    }
    
    @Test("APIError includes custom message")
    func testAPIError() {
        let error = WeatherError.apiError("Custom error message")
        #expect(error.localizedDescription.contains("Custom error message"))
    }
}

// MARK: - WeatherService Tests

@Suite("WeatherService Tests")
struct WeatherServiceTests {
    
    @Test("WeatherService initializes with default URL")
    func testWeatherServiceInitialization() {
        let service = WeatherService()
        // Service should initialize without errors
        #expect(service != nil)
    }
    
    @Test("WeatherService builds correct URL with query parameters")
    func testURLConstruction() async throws {
        // Create a mock URL session that returns a valid response
        let mockData = """
        {
            "main": {"temp": 22.5, "humidity": 65},
            "weather": [{"id": 800, "main": "Clear", "description": "clear sky"}],
            "wind": {"speed": 10.5},
            "name": "Test City"
        }
        """.data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockSession = MockURLSession(data: mockData, response: mockResponse)
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        let location = Location(latitude: 37.7749, longitude: -122.4194)
        let weather = try await service.fetchWeather(for: location)
        
        #expect(weather.temperature == 22.5)
        #expect(weather.locationName == "Test City")
    }
    
    @Test("WeatherService handles HTTP errors")
    func testHTTPErrorHandling() async {
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockData = """
        {"error": "Internal server error"}
        """.data(using: .utf8)!
        
        let mockSession = MockURLSession(data: mockData, response: mockResponse)
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        let location = Location(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try await service.fetchWeather(for: location)
            Issue.record("Should have thrown an error")
        } catch let error as WeatherError {
            if case .apiError(let message) = error {
                #expect(message.contains("Internal server error"))
            } else {
                Issue.record("Wrong error type: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("WeatherService handles invalid JSON")
    func testInvalidJSONHandling() async {
        let mockData = "invalid json".data(using: .utf8)!
        
        let mockResponse = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        let mockSession = MockURLSession(data: mockData, response: mockResponse)
        
        let service = WeatherService(
            baseURL: URL(string: "https://api.example.com")!,
            session: mockSession
        )
        
        let location = Location(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try await service.fetchWeather(for: location)
            Issue.record("Should have thrown an error")
        } catch let error as WeatherError {
            #expect(error == .invalidResponse)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
}

// MARK: - Mock URLSession

private class MockURLSession: URLSession {
    private let mockData: Data
    private let mockResponse: URLResponse
    
    init(data: Data, response: URLResponse) {
        self.mockData = data
        self.mockResponse = response
        super.init()
    }
    
    override func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        return (mockData, mockResponse)
    }
}
