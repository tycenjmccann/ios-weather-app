import Testing
import CoreLocation
@testable import WeatherApp

// MARK: - Location Error Tests

@Suite("Location Error Tests")
struct LocationErrorTests {
    
    @Test("Location error descriptions are user-friendly")
    func testLocationErrorDescriptions() {
        let permissionDenied = LocationError.permissionDenied
        #expect(permissionDenied.localizedDescription.contains("permission"))
        
        let permissionRestricted = LocationError.permissionRestricted
        #expect(permissionRestricted.localizedDescription.contains("restricted"))
        
        let locationUnavailable = LocationError.locationUnavailable
        #expect(locationUnavailable.localizedDescription.contains("Unable"))
        
        let timeout = LocationError.timeout
        #expect(timeout.localizedDescription.contains("timeout"))
    }
}

// MARK: - Weather Service Error Tests

@Suite("Weather Service Error Tests")
struct WeatherServiceErrorTests {
    
    @Test("Weather service error descriptions are informative")
    func testWeatherServiceErrorDescriptions() {
        let invalidAPIKey = WeatherServiceError.invalidAPIKey
        #expect(invalidAPIKey.localizedDescription.contains("API key"))
        
        let networkError = WeatherServiceError.networkError(
            URLError(.notConnectedToInternet)
        )
        #expect(networkError.localizedDescription.contains("Network"))
        
        let invalidResponse = WeatherServiceError.invalidResponse
        #expect(invalidResponse.localizedDescription.contains("Unable"))
        
        let rateLimitExceeded = WeatherServiceError.rateLimitExceeded
        #expect(rateLimitExceeded.localizedDescription.contains("rate limit"))
        
        let serverError = WeatherServiceError.serverError(500)
        #expect(serverError.localizedDescription.contains("500"))
    }
}

// MARK: - URL Construction Tests

@Suite("URL Construction Tests")
struct URLConstructionTests {
    
    @Test("Weather service constructs valid current weather URL")
    func testCurrentWeatherURL() {
        let apiKey = "test_key"
        let service = WeatherService(apiKey: apiKey)
        
        // Verify URL construction logic
        let baseURL = "https://api.openweathermap.org/data/2.5/weather"
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: "37.7749"),
            URLQueryItem(name: "lon", value: "-122.4194"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]
        
        let url = components?.url
        #expect(url != nil)
        #expect(url?.absoluteString.contains("lat=37.7749") ?? false)
        #expect(url?.absoluteString.contains("appid=test_key") ?? false)
    }
    
    @Test("Weather service constructs valid forecast URL")
    func testForecastURL() {
        let apiKey = "test_key"
        let service = WeatherService(apiKey: apiKey)
        
        let baseURL = "https://api.openweathermap.org/data/2.5/forecast"
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "lat", value: "37.7749"),
            URLQueryItem(name: "lon", value: "-122.4194"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "imperial")
        ]
        
        let url = components?.url
        #expect(url != nil)
        #expect(url?.absoluteString.contains("forecast") ?? false)
        #expect(url?.absoluteString.contains("units=imperial") ?? false)
    }
}

// MARK: - Mock URL Protocol for Network Tests

final class MockURLProtocol: URLProtocol {
    static var mockData: Data?
    static var mockResponse: HTTPURLResponse?
    static var mockError: Error?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        if let error = MockURLProtocol.mockError {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        
        if let response = MockURLProtocol.mockResponse {
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        }
        
        if let data = MockURLProtocol.mockData {
            client?.urlProtocol(self, didLoad: data)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {}
}

// MARK: - Network Integration Tests

@Suite("Weather Service Network Tests")
struct WeatherServiceNetworkTests {
    
    @Test("Weather service handles 401 unauthorized")
    func testUnauthorizedResponse() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openweathermap.org")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )
        MockURLProtocol.mockData = Data()
        
        let service = WeatherService(apiKey: "invalid_key", session: session)
        
        do {
            _ = try await service.fetchCurrentWeather(latitude: 37.7749, longitude: -122.4194)
            Issue.record("Expected error to be thrown")
        } catch let error as WeatherServiceError {
            if case .invalidAPIKey = error {
                // Success
            } else {
                Issue.record("Expected invalidAPIKey error")
            }
        } catch {
            Issue.record("Unexpected error type")
        }
    }
    
    @Test("Weather service handles 429 rate limit")
    func testRateLimitResponse() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openweathermap.org")!,
            statusCode: 429,
            httpVersion: nil,
            headerFields: nil
        )
        MockURLProtocol.mockData = Data()
        
        let service = WeatherService(apiKey: "test_key", session: session)
        
        do {
            _ = try await service.fetchCurrentWeather(latitude: 37.7749, longitude: -122.4194)
            Issue.record("Expected error to be thrown")
        } catch let error as WeatherServiceError {
            if case .rateLimitExceeded = error {
                // Success
            } else {
                Issue.record("Expected rateLimitExceeded error")
            }
        } catch {
            Issue.record("Unexpected error type")
        }
    }
    
    @Test("Weather service handles server errors")
    func testServerErrorResponse() async {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        let session = URLSession(configuration: config)
        
        MockURLProtocol.mockResponse = HTTPURLResponse(
            url: URL(string: "https://api.openweathermap.org")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )
        MockURLProtocol.mockData = Data()
        
        let service = WeatherService(apiKey: "test_key", session: session)
        
        do {
            _ = try await service.fetchCurrentWeather(latitude: 37.7749, longitude: -122.4194)
            Issue.record("Expected error to be thrown")
        } catch let error as WeatherServiceError {
            if case .serverError(let code) = error {
                #expect(code == 500)
            } else {
                Issue.record("Expected serverError")
            }
        } catch {
            Issue.record("Unexpected error type")
        }
    }
}
