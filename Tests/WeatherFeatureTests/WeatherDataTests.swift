import Testing
@testable import WeatherFeature

/// Tests for WeatherData model
struct WeatherDataTests {
    
    @Test("WeatherData formatting")
    func testFormatting() {
        let weather = WeatherData(
            temperature: 22.5,
            humidity: 65,
            windSpeed: 5.2,
            condition: "clear",
            description: "clear sky",
            temperatureUnit: .celsius,
            windSpeedUnit: .metersPerSecond
        )
        
        #expect(weather.formattedTemperature == "22.5°C")
        #expect(weather.formattedHumidity == "65%")
        #expect(weather.formattedWindSpeed == "5.2 m/s")
    }
    
    @Test("Weather symbol mapping for clear conditions")
    func testClearWeatherSymbol() {
        let weather = WeatherData(
            temperature: 25.0,
            humidity: 50,
            windSpeed: 3.0,
            condition: "clear"
        )
        
        #expect(weather.weatherSymbol == "sun.max.fill")
    }
    
    @Test("Weather symbol mapping for cloudy conditions")
    func testCloudyWeatherSymbol() {
        let weather = WeatherData(
            temperature: 18.0,
            humidity: 70,
            windSpeed: 4.0,
            condition: "clouds"
        )
        
        #expect(weather.weatherSymbol == "cloud.fill")
    }
    
    @Test("Weather symbol mapping for rainy conditions")
    func testRainyWeatherSymbol() {
        let weather = WeatherData(
            temperature: 15.0,
            humidity: 85,
            windSpeed: 6.0,
            condition: "rain"
        )
        
        #expect(weather.weatherSymbol == "cloud.rain.fill")
    }
    
    @Test("Weather symbol mapping for snowy conditions")
    func testSnowyWeatherSymbol() {
        let weather = WeatherData(
            temperature: -2.0,
            humidity: 90,
            windSpeed: 5.0,
            condition: "snow"
        )
        
        #expect(weather.weatherSymbol == "cloud.snow.fill")
    }
    
    @Test("Weather symbol mapping for thunderstorm")
    func testThunderstormSymbol() {
        let weather = WeatherData(
            temperature: 20.0,
            humidity: 80,
            windSpeed: 8.0,
            condition: "thunderstorm"
        )
        
        #expect(weather.weatherSymbol == "cloud.bolt.rain.fill")
    }
    
    @Test("Weather symbol mapping for foggy conditions")
    func testFoggyWeatherSymbol() {
        let weather = WeatherData(
            temperature: 10.0,
            humidity: 95,
            windSpeed: 2.0,
            condition: "fog"
        )
        
        #expect(weather.weatherSymbol == "cloud.fog.fill")
    }
    
    @Test("Weather symbol mapping for unknown conditions defaults to cloud.sun")
    func testUnknownWeatherSymbol() {
        let weather = WeatherData(
            temperature: 20.0,
            humidity: 60,
            windSpeed: 4.0,
            condition: "unknown"
        )
        
        #expect(weather.weatherSymbol == "cloud.sun.fill")
    }
    
    @Test("Temperature unit conversion")
    func testTemperatureUnits() {
        let celsius = WeatherData(
            temperature: 22.0,
            humidity: 50,
            windSpeed: 5.0,
            condition: "clear",
            temperatureUnit: .celsius
        )
        
        let fahrenheit = WeatherData(
            temperature: 71.6,
            humidity: 50,
            windSpeed: 5.0,
            condition: "clear",
            temperatureUnit: .fahrenheit
        )
        
        #expect(celsius.temperatureUnit == .celsius)
        #expect(fahrenheit.temperatureUnit == .fahrenheit)
        #expect(celsius.formattedTemperature == "22.0°C")
        #expect(fahrenheit.formattedTemperature == "71.6°F")
    }
    
    @Test("Wind speed unit formatting")
    func testWindSpeedUnits() {
        let mps = WeatherData(
            temperature: 20.0,
            humidity: 60,
            windSpeed: 5.5,
            condition: "clear",
            windSpeedUnit: .metersPerSecond
        )
        
        let mph = WeatherData(
            temperature: 20.0,
            humidity: 60,
            windSpeed: 12.3,
            condition: "clear",
            windSpeedUnit: .milesPerHour
        )
        
        let kmh = WeatherData(
            temperature: 20.0,
            humidity: 60,
            windSpeed: 19.8,
            condition: "clear",
            windSpeedUnit: .kilometersPerHour
        )
        
        #expect(mps.formattedWindSpeed == "5.5 m/s")
        #expect(mph.formattedWindSpeed == "12.3 mph")
        #expect(kmh.formattedWindSpeed == "19.8 km/h")
    }
    
    @Test("WeatherData Codable conformance")
    func testCodable() throws {
        let original = WeatherData(
            temperature: 22.5,
            humidity: 65,
            windSpeed: 5.2,
            condition: "clear",
            description: "clear sky"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(WeatherData.self, from: data)
        
        #expect(decoded == original)
    }
    
    @Test("WeatherData Sendable conformance compiles")
    func testSendable() async {
        let weather = WeatherData(
            temperature: 22.0,
            humidity: 60,
            windSpeed: 5.0,
            condition: "clear"
        )
        
        // This should compile without warnings due to Sendable conformance
        Task {
            let _ = weather
        }
    }
}
