import SwiftUI

/// Main weather display view with state management
public struct WeatherView: View {
    
    // MARK: - State
    
    @State private var viewState: ViewState = .loading
    @State private var locationService = LocationService()
    @State private var weatherService = WeatherService()
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Body
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient based on weather state
                backgroundGradient
                    .ignoresSafeArea()
                
                // Content based on current view state
                contentView
                    .padding()
            }
            .navigationTitle("Weather")
            .navigationBarTitleDisplayMode(.large)
            .task {
                await loadWeather()
            }
            .refreshable {
                await loadWeather()
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        Group {
            switch viewState {
            case .loaded(let weather):
                weatherGradient(for: weather.condition)
            default:
                defaultGradient
            }
        }
    }
    
    private var defaultGradient: some View {
        LinearGradient(
            colors: [.blue.opacity(0.6), .cyan.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    private func weatherGradient(for condition: String) -> some View {
        let colors: [Color] = {
            switch condition.lowercased() {
            case "clear":
                return [.orange, .yellow]
            case "clouds", "cloudy":
                return [.gray, .blue]
            case "rain", "drizzle":
                return [.blue.opacity(0.7), .gray]
            case "thunderstorm":
                return [.purple, .blue.opacity(0.8)]
            case "snow":
                return [.white.opacity(0.8), .blue.opacity(0.4)]
            default:
                return [.blue.opacity(0.6), .cyan.opacity(0.3)]
            }
        }()
        
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Content Views
    
    @ViewBuilder
    private var contentView: some View {
        switch viewState {
        case .loading:
            loadingView
        case .loaded(let weather):
            weatherContentView(weather: weather)
        case .error(let error):
            errorView(error: error)
        }
    }
    
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
    
    private func weatherContentView(weather: WeatherData) -> some View {
        ScrollView {
            VStack(spacing: 30) {
                // Weather icon and condition
                VStack(spacing: 12) {
                    Image(systemName: weather.weatherSymbol)
                        .font(.system(size: 80))
                        .foregroundStyle(.white)
                        .symbolRenderingMode(.hierarchical)
                        .accessibilityLabel("Weather condition: \(weather.condition)")
                    
                    if let description = weather.description {
                        Text(description.capitalized)
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
                .padding(.vertical)
                
                // Temperature display
                Text(weather.formattedTemperature)
                    .font(.system(size: 72, weight: .thin))
                    .foregroundStyle(.white)
                    .accessibilityLabel("Temperature: \(weather.formattedTemperature)")
                
                // Weather details grid
                LazyVGrid(
                    columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ],
                    spacing: 20
                ) {
                    WeatherDetailCard(
                        icon: "humidity.fill",
                        title: "Humidity",
                        value: weather.formattedHumidity
                    )
                    
                    WeatherDetailCard(
                        icon: "wind",
                        title: "Wind Speed",
                        value: weather.formattedWindSpeed
                    )
                }
                .padding(.top, 20)
                
                // Last updated timestamp
                Text("Updated \(weather.timestamp, style: .relative) ago")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.7))
                    .padding(.top, 8)
            }
            .padding()
        }
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: 24) {
            Image(systemName: errorIcon(for: error))
                .font(.system(size: 60))
                .foregroundStyle(.white)
                .symbolRenderingMode(.hierarchical)
            
            VStack(spacing: 12) {
                Text(error.localizedDescription)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                
                if let localizedError = error as? LocalizedError,
                   let suggestion = localizedError.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                }
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
            .accessibilityHint("Retry fetching weather data")
        }
        .padding()
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Helper Methods
    
    /// Load weather data for current location
    @MainActor
    private func loadWeather() async {
        viewState = .loading
        
        do {
            // Get current location
            let coordinate = try await locationService.getCurrentLocation()
            
            // Fetch weather for location
            let weather = try await weatherService.fetchWeather(
                for: coordinate,
                temperatureUnit: .celsius,
                windSpeedUnit: .metersPerSecond
            )
            
            viewState = .loaded(weather)
            
        } catch let error as WeatherError {
            viewState = .error(error)
        } catch let error as LocationError {
            viewState = .error(WeatherError.locationError(error))
        } catch {
            viewState = .error(WeatherError.unknown(error.localizedDescription))
        }
    }
    
    /// Get appropriate SF Symbol for error type
    private func errorIcon(for error: Error) -> String {
        if let locationError = error as? LocationError {
            switch locationError {
            case .permissionDenied, .permissionRestricted:
                return "location.slash.fill"
            case .locationUnavailable, .timeout:
                return "location.fill.questionmark"
            case .unknown:
                return "exclamationmark.triangle.fill"
            }
        }
        
        if let weatherError = error as? WeatherError {
            switch weatherError {
            case .networkError:
                return "wifi.slash"
            case .invalidResponse, .apiError:
                return "exclamationmark.triangle.fill"
            case .locationError:
                return "location.slash.fill"
            case .unknown:
                return "exclamationmark.triangle.fill"
            }
        }
        
        return "exclamationmark.triangle.fill"
    }
}

// MARK: - View State

/// Represents the current state of the weather view
private enum ViewState {
    case loading
    case loaded(WeatherData)
    case error(Error)
}

// MARK: - Weather Detail Card

/// Reusable card for displaying weather metrics
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

#Preview("Weather View") {
    WeatherView()
}

#Preview("Weather Loaded") {
    struct PreviewWrapper: View {
        @State private var viewState: ViewState = .loaded(
            WeatherData(
                temperature: 22.5,
                humidity: 65,
                windSpeed: 5.2,
                condition: "clear",
                description: "clear sky",
                temperatureUnit: .celsius,
                windSpeedUnit: .metersPerSecond
            )
        )
        
        var body: some View {
            WeatherView()
        }
    }
    
    return PreviewWrapper()
}

#Preview("Error State") {
    struct PreviewWrapper: View {
        @State private var viewState: ViewState = .error(
            LocationError.permissionDenied
        )
        
        var body: some View {
            WeatherView()
        }
    }
    
    return PreviewWrapper()
}
