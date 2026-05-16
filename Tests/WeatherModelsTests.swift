import Testing
import Foundation
@testable import WeatherApp

// MARK: - Weather Models Tests

@Suite("Weather Models Tests")
struct WeatherModelsTests {
    
    // MARK: - WeatherCondition Tests
    
    @Test("WeatherCondition icon names are correct")
    func testWeatherConditionIcons() {
        #expect(WeatherCondition.clear.iconName == "sun.max.fill")
        #expect(WeatherCondition.cloudy.iconName == "cloud.fill")
        #expect(WeatherCondition.partlyCloudy.iconName == "cloud.sun.fill")
        #expect(WeatherCondition.rainy.iconName == "cloud.rain.fill")
        #expect(WeatherCondition.snowy.iconName == "cloud.snow.fill")
        #expect(WeatherCondition.stormy.iconName == "cloud.bolt.rain.fill")
        #expect(WeatherCondition.foggy.iconName == "cloud.fog.fill")
        #expect(WeatherCondition.windy.iconName == "wind")
    }
    
    @Test("WeatherCondition descriptions are user-friendly")
    func testWeatherConditionDescriptions() {
        #expect(WeatherCondition.clear.description == "Clear")
        #expect(WeatherCondition.cloudy.description == "Cloudy")
        #expect(WeatherCondition.partlyCloudy.description == "Partly Cloudy")
        #expect(WeatherCondition.rainy.description == "Rainy")
    }
    
    // MARK: - DailyForecast Tests
    
    @Test("DailyForecast initialization")
    func testDailyForecastInit() {
        let date = Date()
        let forecast = DailyForecast(
            date: date,
            highTemp: 300.0,
            lowTemp: 290.0,
            condition: .clear,
            precipitationChance: 0.3,
            icon: "01d"
        )
        
        #expect(forecast.date == date)
        #expect(forecast.highTemp == 300.0)
        #expect(forecast.lowTemp == 290.0)
        #expect(forecast.condition == .clear)
        #expect(forecast.precipitationChance == 0.3)
        #expect(forecast.icon == "01d")
    }
    
    @Test("DailyForecast precipitation percentage formatting")
    func testPrecipitationPercentageFormatting() {
        let forecast = DailyForecast(
            date: Date(),
            highTemp: 300.0,
            lowTemp: 290.0,
            condition: .rainy,
            precipitationChance: 0.75,
            icon: "10d"
        )
        
        #expect(forecast.precipitationPercentage == "75%")
    }
    
    @Test("DailyForecast day name extraction")
    func testDayNameExtraction() {
        let calendar = Calendar.current
        let monday = calendar.date(from: DateComponents(year: 2024, month: 1, weekday: 2))!
        
        let forecast = DailyForecast(
            date: monday,
            highTemp: 300.0,
            lowTemp: 290.0,
            condition: .clear,
            precipitationChance: 0.0,
            icon: "01d"
        )
        
        #expect(forecast.dayName == "Monday")
        #expect(forecast.shortDayName == "Mon")
    }
    
    @Test("DailyForecast equality")
    func testDailyForecastEquality() {
        let date = Date()
        let id = UUID()
        
        let forecast1 = DailyForecast(
            id: id,
            date: date,
            highTemp: 300.0,
            lowTemp: 290.0,
            condition: .clear,
            precipitationChance: 0.0,
            icon: "01d"
        )
        
        let forecast2 = DailyForecast(
            id: id,
            date: date,
            highTemp: 300.0,
            lowTemp: 290.0,
            condition: .clear,
            precipitationChance: 0.0,
            icon: "01d"
        )
        
        #expect(forecast1 == forecast2)
    }
    
    // MARK: - FiveDayForecast Tests
    
    @Test("FiveDayForecast initialization")
    func testFiveDayForecastInit() {
        let days = (0..<5).map { day in
            DailyForecast(
                date: Date().addingTimeInterval(Double(day) * 86400),
                highTemp: 300.0,
                lowTemp: 290.0,
                condition: .clear,
                precipitationChance: 0.0,
                icon: "01d"
            )
        }
        
        let forecast = FiveDayForecast(days: days)
        #expect(forecast.days.count == 5)
    }
    
    @Test("FiveDayForecast formatted last updated")
    func testFormattedLastUpdated() {
        let forecast = FiveDayForecast(days: [], lastUpdated: Date())
        #expect(forecast.formattedLastUpdated.contains("Updated"))
    }
    
    // MARK: - TemperatureUnit Tests
    
    @Test("TemperatureUnit symbols")
    func testTemperatureUnitSymbols() {
        #expect(TemperatureUnit.fahrenheit.symbol == "°F")
        #expect(TemperatureUnit.celsius.symbol == "°C")
    }
    
    @Test("Kelvin to Fahrenheit conversion")
    func testKelvinToFahrenheit() {
        let kelvin = 300.0 // ~80°F
        let fahrenheit = TemperatureUnit.fahrenheit.convert(fromKelvin: kelvin)
        #expect(abs(fahrenheit - 80.33) < 0.1)
    }
    
    @Test("Kelvin to Celsius conversion")
    func testKelvinToCelsius() {
        let kelvin = 300.0 // ~27°C
        let celsius = TemperatureUnit.celsius.convert(fromKelvin: kelvin)
        #expect(abs(celsius - 26.85) < 0.1)
    }
    
    @Test("Temperature formatting with unit")
    func testTemperatureFormatting() {
        let fahrenheit = TemperatureUnit.fahrenheit.format(75.5)
        #expect(fahrenheit == "76°F")
        
        let celsius = TemperatureUnit.celsius.format(24.3)
        #expect(celsius == "24°C")
    }
    
    // MARK: - Codable Tests
    
    @Test("DailyForecast Codable encoding/decoding")
    func testDailyForecastCodable() throws {
        let original = DailyForecast(
            date: Date(),
            highTemp: 300.0,
            lowTemp: 290.0,
            condition: .rainy,
            precipitationChance: 0.6,
            icon: "10d"
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DailyForecast.self, from: data)
        
        #expect(decoded.highTemp == original.highTemp)
        #expect(decoded.lowTemp == original.lowTemp)
        #expect(decoded.condition == original.condition)
        #expect(decoded.precipitationChance == original.precipitationChance)
    }
    
    @Test("FiveDayForecast Codable encoding/decoding")
    func testFiveDayForecastCodable() throws {
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
        let original = FiveDayForecast(days: days)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(FiveDayForecast.self, from: data)
        
        #expect(decoded.days.count == original.days.count)
        #expect(decoded.days.first?.condition == .clear)
    }
}
