import Foundation

// MARK: - Weather Condition

/// Represents different weather conditions with associated icons
public enum WeatherCondition: String, Codable, Sendable, CaseIterable {
    case clear
    case cloudy
    case partlyCloudy = "partly_cloudy"
    case rainy
    case snowy
    case stormy
    case foggy
    case windy
    
    /// SF Symbol name for the weather condition
    public var iconName: String {
        switch self {
        case .clear:
            return "sun.max.fill"
        case .cloudy:
            return "cloud.fill"
        case .partlyCloudy:
            return "cloud.sun.fill"
        case .rainy:
            return "cloud.rain.fill"
        case .snowy:
            return "cloud.snow.fill"
        case .stormy:
            return "cloud.bolt.rain.fill"
        case .foggy:
            return "cloud.fog.fill"
        case .windy:
            return "wind"
        }
    }
    
    /// User-facing description of the condition
    public var description: String {
        switch self {
        case .clear:
            return "Clear"
        case .cloudy:
            return "Cloudy"
        case .partlyCloudy:
            return "Partly Cloudy"
        case .rainy:
            return "Rainy"
        case .snowy:
            return "Snowy"
        case .stormy:
            return "Stormy"
        case .foggy:
            return "Foggy"
        case .windy:
            return "Windy"
        }
    }
}

// MARK: - Daily Forecast

/// Represents a single day's weather forecast
public struct DailyForecast: Codable, Sendable, Identifiable, Equatable {
    public let id: UUID
    public let date: Date
    public let highTemp: Double
    public let lowTemp: Double
    public let condition: WeatherCondition
    public let precipitationChance: Double // 0.0 - 1.0
    public let icon: String
    
    public init(
        id: UUID = UUID(),
        date: Date,
        highTemp: Double,
        lowTemp: Double,
        condition: WeatherCondition,
        precipitationChance: Double,
        icon: String
    ) {
        self.id = id
        self.date = date
        self.highTemp = highTemp
        self.lowTemp = lowTemp
        self.condition = condition
        self.precipitationChance = precipitationChance
        self.icon = icon
    }
    
    /// Formatted date string (e.g., "Monday" or "Mon, Jan 15")
    public func formattedDate(style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        return formatter.string(from: date)
    }
    
    /// Formatted day name (e.g., "Monday")
    public var dayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }
    
    /// Short day name (e.g., "Mon")
    public var shortDayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    /// Precipitation chance as percentage string (e.g., "30%")
    public var precipitationPercentage: String {
        String(format: "%.0f%%", precipitationChance * 100)
    }
}

// MARK: - Five Day Forecast

/// Represents a 5-day weather forecast
public struct FiveDayForecast: Codable, Sendable, Equatable {
    public let days: [DailyForecast]
    public let lastUpdated: Date
    
    public init(days: [DailyForecast], lastUpdated: Date = Date()) {
        self.days = days
        self.lastUpdated = lastUpdated
    }
    
    /// Formatted last updated time (e.g., "Updated 5 minutes ago")
    public var formattedLastUpdated: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return "Updated \(formatter.localizedString(for: lastUpdated, relativeTo: Date()))"
    }
}

// MARK: - Temperature Unit

/// Temperature unit preference
public enum TemperatureUnit: String, Codable, Sendable {
    case fahrenheit
    case celsius
    
    public var symbol: String {
        switch self {
        case .fahrenheit:
            return "°F"
        case .celsius:
            return "°C"
        }
    }
    
    /// Convert temperature from Kelvin to the specified unit
    public func convert(fromKelvin kelvin: Double) -> Double {
        switch self {
        case .fahrenheit:
            return (kelvin - 273.15) * 9/5 + 32
        case .celsius:
            return kelvin - 273.15
        }
    }
    
    /// Format temperature with unit symbol
    public func format(_ temperature: Double) -> String {
        String(format: "%.0f%@", temperature, symbol)
    }
}
