import Testing
import Foundation
@testable import WeatherApp

// MARK: - Mock URL Protocol

final class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Handler is unavailable.")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {}
}

// MARK: - Weather Service Tests

@Suite("Weather Service Tests")
struct WeatherServiceTests {
    
    // MARK: - Setup
    
    func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }
    
    func createSuccessResponse() -> Data {
        let json = """
        {
            "list": [
                {
                    "dt": \(Date().addingTimeInterval(86400).timeIntervalSince1970),
                    "main": {
                        "temp_min": 290.0,
                        "temp_max": 300.0
                    },
                    "weather": [
                        {
                            "main": "Clear",
                            "description": "clear sky",
                            "icon": "01d"
                        }
                    ],
                    "pop": 0.1
                },
                {
                    "dt": \(Date().addingTimeInterval(86400 * 2).timeIntervalSince1970),
                    "main": {
                        "temp_min": 285.0,
                        "temp_max": 295.0
                    },
                    "weather": [
                        {
                            "main": "Clouds",
                            "description": "cloudy",
                            "icon": "02d"
                        }
                    ],
                    "pop": 0.3
                },
                {
                    "dt": \(Date().addingTimeInterval(86400 * 3).timeIntervalSince1970),
                    "main": {
                        "temp_min": 288.0,
                        "temp_max": 298.0
                    },
                    "weather": [
                        {
                            "main": "Rain",
                            "description": "light rain",
                            "icon": "10d"
                        }
                    ],
                    "pop": 0.7
                },
                {
                    "dt": \(Date().addingTimeInterval(86400 * 4).timeIntervalSince1970),
                    "main": {
                        "temp_min": 292.0,
                        "temp_max": 302.0
                    },
                    "weather": [
                        {
                            "main": "Clear",
                            "description": "clear sky",
                            "icon": "01d"
                        }
                    ],
                    "pop": 0.0
                },
                {
                    "dt": \(Date().addingTimeInterval(86400 * 5).timeIntervalSince1970),
                    "main": {
                        "temp_min": 287.0,
                        "temp_max": 297.0
                    },
                    "weather": [
                        {
                            "main": "Snow",
                            "description": "light snow",
                            "icon": "13d"
                        }
                    ],
                    "pop": 0.5
                }
            ]
        }
        """
        return json.data(using: .utf8)!
    }
    
    // MARK: - Success Tests
    
    @Test("Fetch forecast returns 5-day data")
    func testFetchForecastSuccess() async throws {
        let session = createMockSession()
        let cache = WeatherCache()
        let service = WeatherService(session: session, cache: cache)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.createSuccessResponse())
        }
        
        let forecast = try await service.fetchFiveDayForecast()
        
        #expect(forecast.days.count == 5)
        #expect(forecast.days[0].condition == .clear)
        #expect(forecast.days[1].condition == .cloudy)
        #expect(forecast.days[2].condition == .rainy)
    }
    
    @Test("Forecast data has correct temperature range")
    func testForecastTemperatureRange() async throws {
        let session = createMockSession()
        let cache = WeatherCache()
        let service = WeatherService(session: session, cache: cache)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.createSuccessResponse())
        }
        
        let forecast = try await service.fetchFiveDayForecast()
        let firstDay = forecast.days[0]
        
        #expect(firstDay.highTemp == 300.0)
        #expect(firstDay.lowTemp == 290.0)
    }
    
    @Test("Forecast data includes precipitation chances")
    func testPrecipitationChances() async throws {
        let session = createMockSession()
        let cache = WeatherCache()
        let service = WeatherService(session: session, cache: cache)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, self.createSuccessResponse())
        }
        
        let forecast = try await service.fetchFiveDayForecast()
        
        #expect(forecast.days[0].precipitationChance == 0.1)
        #expect(forecast.days[2].precipitationChance == 0.7)
    }
    
    // MARK: - Error Tests
    
    @Test("Invalid response returns error")
    func testInvalidResponse() async {
        let session = createMockSession()
        let cache = WeatherCache()
        let service = WeatherService(session: session, cache: cache)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, Data())
        }
        
        do {
            _ = try await service.fetchFiveDayForecast()
            Issue.record("Expected error to be thrown")
        } catch let error as WeatherServiceError {
            if case .apiError(let statusCode, _) = error {
                #expect(statusCode == 404)
            } else {
                Issue.record("Expected API error")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    @Test("Invalid JSON returns decoding error")
    func testInvalidJSON() async {
        let session = createMockSession()
        let cache = WeatherCache()
        let service = WeatherService(session: session, cache: cache)
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )!
            let invalidJSON = "{ invalid json }".data(using: .utf8)!
            return (response, invalidJSON)
        }
        
        do {
            _ = try await service.fetchFiveDayForecast()
            Issue.record("Expected error to be thrown")
        } catch let error as WeatherServiceError {
            if case .decodingError = error {
                // Expected error type
            } else {
                Issue.record("Expected decoding error, got: \(error)")
            }
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }
    
    // MARK: - Cache Tests
    
    @Test("Cache stores and retrieves forecast")
    func testCacheStoreAndRetrieve() {
        let cache = WeatherCache()
        let days = [
            DailyForecast(
                date: Date(),
                highTemp: 300.0,
                lowTemp: 290.0,
                condition: .clear,
                precipitationChance: 0.1,
                icon: "01d"
            )
        ]
        let forecast = FiveDayForecast(days: days)
        
        cache.saveForecast(forecast)
        let retrieved = cache.getForecast()
        
        #expect(retrieved != nil)
        #expect(retrieved?.days.count == 1)
    }
    
    @Test("Cache validity check")
    func testCacheValidity() {
        let cache = WeatherCache()
        let days = [
            DailyForecast(
                date: Date(),
                highTemp: 300.0,
                lowTemp: 290.0,
                condition: .clear,
                precipitationChance: 0.1,
                icon: "01d"
            )
        ]
        let forecast = FiveDayForecast(days: days)
        
        cache.saveForecast(forecast)
        #expect(cache.isForecastValid())
    }
    
    @Test("Cache clear removes data")
    func testCacheClear() {
        let cache = WeatherCache()
        let days = [
            DailyForecast(
                date: Date(),
                highTemp: 300.0,
                lowTemp: 290.0,
                condition: .clear,
                precipitationChance: 0.1,
                icon: "01d"
            )
        ]
        let forecast = FiveDayForecast(days: days)
        
        cache.saveForecast(forecast)
        cache.clearCache()
        
        #expect(cache.getForecast() == nil)
        #expect(!cache.isForecastValid())
    }
    
    @Test("Service uses cached data when valid")
    func testServiceUsesCachedData() async throws {
        let session = createMockSession()
        let cache = WeatherCache()
        
        // Pre-populate cache
        let days = (0..<5).map { day in
            DailyForecast(
                date: Date().addingTimeInterval(Double(day + 1) * 86400),
                highTemp: 300.0,
                lowTemp: 290.0,
                condition: .clear,
                precipitationChance: 0.0,
                icon: "01d"
            )
        }
        let cachedForecast = FiveDayForecast(days: days)
        cache.saveForecast(cachedForecast)
        
        let service = WeatherService(session: session, cache: cache)
        
        // Should return cached data without making network request
        let forecast = try await service.fetchFiveDayForecast()
        #expect(forecast.days.count == 5)
    }
}
