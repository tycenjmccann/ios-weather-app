import SwiftUI

/// Main weather display view with state management
public struct WeatherView: View {
    @State private var viewState: ViewState = .loading
    @State private var locationService = LocationService()
    @State private var weatherService = WeatherService()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [.blue.opacity(0.6), .cyan.opacity(0.3)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Content based on state
                Group {
                    switch viewState {
                    case .loading:
                        loadingView
                    case .loaded(let weather):
                        weatherContentView(weather: weather)
                    case .error(let error):
                        errorView(error: error)
                    }
                }
                .padding()
            }
            .navigationTitle("Weather")
            .task {
                await loadWeather()
            }
            .refreshable {
                await loadWeather()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Fetching weather...")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading weather data")
    }
    
    // MARK: - Weather Content View
    
    private func weatherContentView(weather: Weather) -> some View {
        ScrollView {
            VStack(spacing: 30) {
                // Location name
                if let locationName = weather.locationName {
                    Text(locationName)
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white)
                        .accessibilityAddTraits(.isHeader)
                }
                
                // Weather icon and description
                VStack(spacing: 12) {
                    Image(systemName: weatherIcon(for: weather.conditionCode))
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("Weather condition: \(weather.description)")
                    
                    Text(weather.description)
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.9))
                }
                .padding(.vertical)
                
                // Temperature
                Text(temperatureString(weather.temperature))
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Temperature: \(temperatureAccessibilityString(weather.temperature))")
                
                // Weather details grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    WeatherDetailCard(
                        icon: "humidity",
                        title: "Humidity",
                        value: "\(weather.humidity)%"
                    )
                    
                    WeatherDetailCard(
                        icon: "wind",
                        title: "Wind Speed",
                        value: windSpeedString(weather.windSpeed)
                    )
                }
                .padding(.top, 20)
            }
            .padding()
        }
    }
    
    // MARK: - Error View
    
    private func errorView(error: WeatherError) -> some View {
        VStack(spacing: 24) {
            Image(systemName: errorIcon(for: error))
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
            
            Text(error.localizedDescription)
                .font(.headline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            Button {
                Task {
                    await loadWeather()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .foregroundStyle(.blue)
                    .padding()
                    .background(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Helper Methods
    
    private func loadWeather() async {
        viewState = .loading
        
        do {
            // Get location
            let location = try await locationService.requestLocation()
            
            // Fetch weather
            let weather = try await weatherService.fetchWeather(for: location)
            
            viewState = .loaded(weather)
        } catch let error as WeatherError {
            viewState = .error(error)
        } catch {
            viewState = .error(.networkError)
        }
    }
    
    private func weatherIcon(for condition: String) -> String {
        switch condition.lowercased() {
        case "clear":
            return "sun.max.fill"
        case "clouds":
            return "cloud.fill"
        case "rain", "drizzle":
            return "cloud.rain.fill"
        case "thunderstorm":
            return "cloud.bolt.rain.fill"
        case "snow":
            return "cloud.snow.fill"
        case "mist", "fog":
            return "cloud.fog.fill"
        default:
            return "cloud.fill"
        }
    }
    
    private func errorIcon(for error: WeatherError) -> String {
        switch error {
        case .locationDenied:
            return "location.slash.fill"
        case .locationUnavailable:
            return "location.fill.questionmark"
        case .networkError:
            return "wifi.slash"
        case .invalidResponse, .apiError:
            return "exclamationmark.triangle.fill"
        }
    }
    
    private func temperatureString(_ celsius: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        let temp = Measurement(value: celsius, unit: UnitTemperature.celsius)
        return formatter.string(from: temp)
    }
    
    private func temperatureAccessibilityString(_ celsius: Double) -> String {
        let rounded = Int(celsius.rounded())
        return "\(rounded) degrees Celsius"
    }
    
    private func windSpeedString(_ kmh: Double) -> String {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 1
        let speed = Measurement(value: kmh, unit: UnitSpeed.kilometersPerHour)
        return formatter.string(from: speed)
    }
}

// MARK: - View State

private enum ViewState {
    case loading
    case loaded(Weather)
    case error(WeatherError)
}

// MARK: - Weather Detail Card

private struct WeatherDetailCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
            
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.white.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Preview

#Preview {
    WeatherView()
}
