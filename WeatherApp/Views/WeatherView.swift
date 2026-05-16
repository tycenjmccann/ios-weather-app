import SwiftUI

// MARK: - Weather View

public struct WeatherView: View {
    
    @State private var viewModel: WeatherViewModel
    
    public init(viewModel: WeatherViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.6), .cyan.opacity(0.4)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content based on state
                Group {
                    switch viewModel.state {
                    case .initial, .requestingPermission:
                        PermissionRequestView()
                        
                    case .loading:
                        LoadingView()
                        
                    case .loaded(let weather, let forecast):
                        WeatherContentView(
                            weather: weather,
                            forecast: forecast
                        )
                        
                    case .error(let message):
                        ErrorView(
                            message: message,
                            onRetry: {
                                Task {
                                    await viewModel.retry()
                                }
                            }
                        )
                    }
                }
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadWeather()
            }
        }
    }
}

// MARK: - Weather Content View

private struct WeatherContentView: View {
    let weather: Weather
    let forecast: [DailyForecast]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Current Weather
                CurrentWeatherView(weather: weather)
                
                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.horizontal)
                
                // 5-Day Forecast
                ForecastView(forecasts: forecast)
            }
            .padding()
        }
    }
}

// MARK: - Current Weather View

private struct CurrentWeatherView: View {
    let weather: Weather
    
    var body: some View {
        VStack(spacing: 16) {
            // Weather icon
            Image(systemName: weatherIcon(for: weather.icon))
                .font(.system(size: 80))
                .foregroundStyle(.white)
                .symbolRenderingMode(.multicolor)
                .accessibilityLabel("Weather condition: \(weather.description)")
            
            // Temperature
            Text("\(Int(weather.temperature))°")
                .font(.system(size: 72, weight: .thin))
                .foregroundStyle(.white)
                .accessibilityLabel("Temperature: \(Int(weather.temperature)) degrees Fahrenheit")
            
            // Description
            Text(weather.description.capitalized)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
            
            // Details
            HStack(spacing: 40) {
                WeatherDetailView(
                    icon: "drop.fill",
                    label: "Humidity",
                    value: "\(weather.humidity)%"
                )
                
                WeatherDetailView(
                    icon: "wind",
                    label: "Wind",
                    value: "\(Int(weather.windSpeed)) mph"
                )
                
                WeatherDetailView(
                    icon: "thermometer",
                    label: "Feels Like",
                    value: "\(Int(weather.feelsLike))°"
                )
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
    
    private func weatherIcon(for code: String) -> String {
        // Map OpenWeatherMap icon codes to SF Symbols
        switch code {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - Weather Detail View

private struct WeatherDetailView: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white)
            
            Text(value)
                .font(.headline)
                .foregroundStyle(.white)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
    }
}

// MARK: - Forecast View

private struct ForecastView: View {
    let forecasts: [DailyForecast]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("5-Day Forecast")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(forecasts) { forecast in
                        ForecastCardView(forecast: forecast)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Forecast Card View

private struct ForecastCardView: View {
    let forecast: DailyForecast
    
    var body: some View {
        VStack(spacing: 12) {
            // Day of week
            Text(dayOfWeek(for: forecast.date))
                .font(.headline)
                .foregroundStyle(.white)
            
            // Weather icon
            Image(systemName: weatherIcon(for: forecast.icon))
                .font(.title)
                .foregroundStyle(.white)
                .symbolRenderingMode(.multicolor)
            
            // High/Low temps
            VStack(spacing: 4) {
                Text("\(Int(forecast.temperatureHigh))°")
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                
                Text("\(Int(forecast.temperatureLow))°")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(width: 100)
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(dayOfWeek(for: forecast.date)), high \(Int(forecast.temperatureHigh)) degrees, low \(Int(forecast.temperatureLow)) degrees, \(forecast.description)")
    }
    
    private func dayOfWeek(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }
    
    private func weatherIcon(for code: String) -> String {
        // Map OpenWeatherMap icon codes to SF Symbols
        switch code {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.fill"
        case "13d", "13n": return "snow"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "cloud.fill"
        }
    }
}

// MARK: - Loading View

private struct LoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Loading weather...")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading weather data")
    }
}

// MARK: - Error View

private struct ErrorView: View {
    let message: String
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            
            Text("Oops!")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text(message)
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button(action: onRetry) {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 12)
                    .background(.white)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Retry loading weather")
        }
        .padding()
    }
}

// MARK: - Permission Request View

private struct PermissionRequestView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "location.fill")
                .font(.system(size: 60))
                .foregroundStyle(.white)
            
            Text("Location Required")
                .font(.title.bold())
                .foregroundStyle(.white)
            
            Text("We need your location to show local weather conditions.")
                .font(.body)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Text("Please grant location permission when prompted.")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Loading") {
    let mockService = MockWeatherService()
    let viewModel = WeatherViewModel(weatherService: mockService)
    return WeatherView(viewModel: viewModel)
}

#Preview("Loaded") {
    let mockService = MockWeatherService()
    let viewModel = WeatherViewModel(weatherService: mockService)
    
    Task {
        await viewModel.loadWeather()
    }
    
    return WeatherView(viewModel: viewModel)
}

#Preview("Error") {
    let mockService = MockWeatherService()
    mockService.shouldFail = true
    mockService.errorToThrow = .networkError(URLError(.notConnectedToInternet))
    
    let viewModel = WeatherViewModel(weatherService: mockService)
    
    Task {
        await viewModel.loadWeather()
    }
    
    return WeatherView(viewModel: viewModel)
}
