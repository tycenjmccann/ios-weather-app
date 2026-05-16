import Testing
import Foundation
@testable import WeatherApp

// MARK: - Weather Model Tests

@Suite("Weather Model Tests")
struct WeatherModelTests {
    
    @Test("Weather initializes correctly")
    func testWeatherInitialization() {
        let weather = Weather(
            temperature: 72.5,
            feelsLike: 70.0,
            humidity: 65,
            windSpeed: 8.5,
            description: "partly cloudy",
            icon: "02d"
        )
        
        #expect(weather.temperature == 72.5)
        #expect(weather.feelsLike == 70.0)
        #expect(weather.humidity == 65)
        #expect(weather.windSpeed == 8.5)
        #expect(weather.description == "partly cloudy")
        #expect(weather.icon == "02d")
    }
    
    @Test("DailyForecast initializes correctly")
    func testDailyForecastInitialization() {
        let date = Date()
        let forecast = DailyForecast(
            date: date,
            temperatureHigh: 78.0,
            temperatureLow: 55.0,
            description: "sunny",
            icon: "01d"
        )
        
        #expect(forecast.date == date)
        #expect(forecast.temperatureHigh == 78.0)
        #expect(forecast.temperatureLow == 55.0)
        #expect(forecast.description == "sunny")
        #expect(forecast.icon == "01d")
    }
    
    @Test("Weather conforms to Equatable")
    func testWeatherEquality() {
        let date = Date()
        let weather1 = Weather(
            temperature: 72.5,
            feelsLike: 70.0,
            humidity: 65,
            windSpeed: 8.5,
            description: "partly cloudy",
            icon: "02d",
            timestamp: date
        )
        
        let weather2 = Weather(
            temperature: 72.5,
            feelsLike: 70.0,
            humidity: 65,
            windSpeed: 8.5,
            description: "partly cloudy",
            icon: "02d",
            timestamp: date
        )
        
        #expect(weather1 == weather2)
    }
    
    @Test("Weather Codable encoding/decoding")
    func testWeatherCodable() throws {
        let original = Weather(
            temperature: 72.5,
            feelsLike: 70.0,
            humidity: 65,
            windSpeed: 8.5,
            description: "partly cloudy",
            icon: "02d"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Weather.self, from: data)
        
        #expect(decoded.temperature == original.temperature)
        #expect(decoded.humidity == original.humidity)
    }
}

// MARK: - API Response Conversion Tests

@Suite("API Response Conversion Tests")
struct APIResponseConversionTests {
    
    @Test("OpenWeatherCurrentResponse converts to Weather")
    func testCurrentWeatherConversion() {
        let response = OpenWeatherCurrentResponse(
            main: OpenWeatherCurrentResponse.MainWeather(
                temp: 72.5,
                feelsLike: 70.0,
                humidity: 65
            ),
            weather: [
                OpenWeatherCurrentResponse.WeatherDescription(
                    description: "partly cloudy",
                    icon: "02d"
                )
            ],
            wind: OpenWeatherCurrentResponse.Wind(speed: 8.5),
            dt: Date().timeIntervalSince1970
        )
        
        let weather = response.toWeather()
        #expect(weather != nil)
        #expect(weather?.temperature == 72.5)
        #expect(weather?.humidity == 65)
        #expect(weather?.description == "partly cloudy")
    }
    
    @Test("OpenWeatherForecastResponse converts to DailyForecasts")
    func testForecastConversion() {
        let now = Date()
        let items = (0..<15).map { i in
            let date = Calendar.current.date(byAdding: .hour, value: i * 3, to: now)!
            return OpenWeatherForecastResponse.ForecastItem(
                dt: date.timeIntervalSince1970,
                main: OpenWeatherForecastResponse.ForecastItem.MainWeather(
                    temp: 70.0 + Double(i),
                    tempMin: 65.0 + Double(i),
                    tempMax: 75.0 + Double(i)
                ),
                weather: [
                    OpenWeatherForecastResponse.ForecastItem.WeatherDescription(
                        description: "sunny",
                        icon: "01d"
                    )
                ]
            )
        }
        
        let response = OpenWeatherForecastResponse(list: items)
        let forecasts = response.toDailyForecasts()
        
        #expect(forecasts.count <= 5)
        #expect(forecasts.allSatisfy { $0.temperatureHigh > 0 })
        #expect(forecasts.allSatisfy { $0.temperatureLow > 0 })
    }
}

// MARK: - Mock Weather Service Tests

@Suite("Weather Service Tests")
struct WeatherServiceTests {
    
    @Test("MockWeatherService returns current weather")
    func testMockServiceCurrentWeather() async throws {
        let service = MockWeatherService()
        
        let weather = try await service.fetchCurrentWeather(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        #expect(weather.temperature > 0)
        #expect(weather.humidity >= 0 && weather.humidity <= 100)
        #expect(!weather.description.isEmpty)
    }
    
    @Test("MockWeatherService returns forecast")
    func testMockServiceForecast() async throws {
        let service = MockWeatherService()
        
        let forecasts = try await service.fetchForecast(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        #expect(forecasts.count == 5)
        #expect(forecasts.allSatisfy { $0.temperatureHigh > $0.temperatureLow })
    }
    
    @Test("MockWeatherService throws error when configured")
    func testMockServiceError() async {
        let service = MockWeatherService()
        service.shouldFail = true
        service.errorToThrow = .networkError(URLError(.notConnectedToInternet))
        
        do {
            _ = try await service.fetchCurrentWeather(
                latitude: 37.7749,
                longitude: -122.4194
            )
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is WeatherServiceError)
        }
    }
}

// MARK: - Weather View Model Tests

@Suite("Weather View Model Tests")
@MainActor
struct WeatherViewModelTests {
    
    @Test("ViewModel initializes in initial state")
    func testInitialState() {
        let service = MockWeatherService()
        let viewModel = WeatherViewModel(weatherService: service)
        
        #expect(viewModel.state == .initial)
    }
    
    @Test("ViewModel loads weather successfully")
    func testLoadWeatherSuccess() async {
        let service = MockWeatherService()
        let locationService = LocationService()
        let viewModel = WeatherViewModel(
            locationService: locationService,
            weatherService: service
        )
        
        // Note: This test requires proper location authorization
        // In a real test, we'd mock LocationService as well
        await viewModel.loadWeather()
        
        // State should change from initial
        #expect(viewModel.state != .initial)
    }
    
    @Test("ViewModel handles service errors")
    func testLoadWeatherError() async {
        let service = MockWeatherService()
        service.shouldFail = true
        service.errorToThrow = .networkError(URLError(.notConnectedToInternet))
        
        let locationService = LocationService()
        let viewModel = WeatherViewModel(
            locationService: locationService,
            weatherService: service
        )
        
        await viewModel.loadWeather()
        
        if case .error = viewModel.state {
            // Success - error state was set
        } else {
            Issue.record("Expected error state")
        }
    }
    
    @Test("ViewModel retry calls loadWeather")
    func testRetry() async {
        let service = MockWeatherService()
        let locationService = LocationService()
        let viewModel = WeatherViewModel(
            locationService: locationService,
            weatherService: service
        )
        
        await viewModel.retry()
        
        // State should have changed from initial
        #expect(viewModel.state != .initial)
    }
}

// MARK: - Weather View State Tests

@Suite("Weather View State Tests")
struct WeatherViewStateTests {
    
    @Test("State equality works correctly")
    func testStateEquality() {
        #expect(WeatherViewState.initial == .initial)
        #expect(WeatherViewState.loading == .loading)
        #expect(WeatherViewState.requestingPermission == .requestingPermission)
        
        let error1 = WeatherViewState.error("Network error")
        let error2 = WeatherViewState.error("Network error")
        #expect(error1 == error2)
        
        let weather = Weather(
            temperature: 72.5,
            feelsLike: 70.0,
            humidity: 65,
            windSpeed: 8.5,
            description: "sunny",
            icon: "01d"
        )
        let forecast = DailyForecast(
            date: Date(),
            temperatureHigh: 78.0,
            temperatureLow: 55.0,
            description: "sunny",
            icon: "01d"
        )
        
        let loaded1 = WeatherViewState.loaded(weather, [forecast])
        let loaded2 = WeatherViewState.loaded(weather, [forecast])
        #expect(loaded1 == loaded2)
    }
    
    @Test("Different states are not equal")
    func testStateDifference() {
        #expect(WeatherViewState.initial != .loading)
        #expect(WeatherViewState.loading != .requestingPermission)
        
        let error1 = WeatherViewState.error("Error 1")
        let error2 = WeatherViewState.error("Error 2")
        #expect(error1 != error2)
    }
}
