import SwiftUI

// MARK: - Forecast View State

private enum ForecastViewState: Equatable {
    case idle
    case loading
    case loaded(FiveDayForecast)
    case error(String)
}

// MARK: - Forecast View

/// Main view displaying 5-day weather forecast
public struct ForecastView: View {
    
    // MARK: Properties
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var state: ForecastViewState = .idle
    @State private var temperatureUnit: TemperatureUnit = .fahrenheit
    
    private let weatherService: WeatherService
    
    // MARK: Initialization
    
    public init(weatherService: WeatherService = WeatherService()) {
        self.weatherService = weatherService
    }
    
    // MARK: Body
    
    public var body: some View {
        NavigationStack {
            Group {
                switch state {
                case .idle, .loading:
                    loadingView
                case .loaded(let forecast):
                    forecastContentView(forecast: forecast)
                case .error(let message):
                    errorView(message: message)
                }
            }
            .navigationTitle("5-Day Forecast")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    temperatureUnitPicker
                }
            }
            .task {
                await loadForecast()
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.blue)
            Text("Loading forecast...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Loading weather forecast")
    }
    
    // MARK: - Error View
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
            
            Text("Unable to Load Forecast")
                .font(.title2.bold())
            
            Text(message)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                Task {
                    await loadForecast()
                }
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .accessibilityLabel("Retry loading forecast")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Forecast Content View
    
    private func forecastContentView(forecast: FiveDayForecast) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                // Last updated timestamp
                Text(forecast.formattedLastUpdated)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                    .padding(.bottom, 16)
                    .accessibilityLabel("Forecast \(forecast.formattedLastUpdated)")
                
                // Daily forecast cards
                LazyVStack(spacing: 12) {
                    ForEach(forecast.days) { day in
                        DailyForecastCard(
                            forecast: day,
                            temperatureUnit: temperatureUnit
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .refreshable {
            await loadForecast()
        }
        .accessibilityLabel("Five day weather forecast")
    }
    
    // MARK: - Temperature Unit Picker
    
    private var temperatureUnitPicker: some View {
        Picker("Temperature Unit", selection: $temperatureUnit) {
            Text("°F").tag(TemperatureUnit.fahrenheit)
            Text("°C").tag(TemperatureUnit.celsius)
        }
        .pickerStyle(.segmented)
        .frame(width: 100)
        .accessibilityLabel("Temperature unit selector")
    }
    
    // MARK: - Data Loading
    
    @MainActor
    private func loadForecast() async {
        state = .loading
        
        do {
            let forecast = try await weatherService.fetchFiveDayForecast()
            state = .loaded(forecast)
        } catch let error as WeatherServiceError {
            state = .error(error.localizedDescription)
        } catch {
            state = .error("An unexpected error occurred. Please try again.")
        }
    }
}

// MARK: - Daily Forecast Card

/// Card displaying a single day's forecast
private struct DailyForecastCard: View {
    let forecast: DailyForecast
    let temperatureUnit: TemperatureUnit
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Date and day
            VStack(alignment: .leading, spacing: 4) {
                Text(forecast.shortDayName)
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text(forecast.formattedDate(style: .short))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80, alignment: .leading)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(forecast.dayName), \(forecast.formattedDate(style: .medium))")
            
            Spacer()
            
            // Weather icon and condition
            VStack(spacing: 4) {
                Image(systemName: forecast.condition.iconName)
                    .font(.system(size: 32))
                    .foregroundStyle(iconColor)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                
                Text(forecast.condition.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 80)
            .accessibilityLabel("\(forecast.condition.description)")
            
            Spacer()
            
            // Precipitation
            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.caption)
                    .foregroundStyle(.blue)
                    .accessibilityHidden(true)
                
                Text(forecast.precipitationPercentage)
                    .font(.subheadline.bold())
            }
            .frame(width: 50)
            .accessibilityLabel("Precipitation chance \(forecast.precipitationPercentage)")
            
            // Temperature range
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up")
                        .font(.caption2)
                        .foregroundStyle(.red)
                        .accessibilityHidden(true)
                    
                    Text(temperatureUnit.format(temperatureUnit.convert(fromKelvin: forecast.highTemp)))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                        .accessibilityHidden(true)
                    
                    Text(temperatureUnit.format(temperatureUnit.convert(fromKelvin: forecast.lowTemp)))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("High \(temperatureUnit.format(temperatureUnit.convert(fromKelvin: forecast.highTemp))), Low \(temperatureUnit.format(temperatureUnit.convert(fromKelvin: forecast.lowTemp)))")
        }
        .padding()
        .background(cardBackgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }
    
    // MARK: - Computed Properties
    
    private var cardBackgroundColor: Color {
        colorScheme == .dark ? Color(.systemGray6) : .white
    }
    
    private var shadowColor: Color {
        colorScheme == .dark ? .clear : Color.black.opacity(0.1)
    }
    
    private var iconColor: Color {
        switch forecast.condition {
        case .clear:
            return .yellow
        case .cloudy, .partlyCloudy:
            return .gray
        case .rainy:
            return .blue
        case .snowy:
            return .cyan
        case .stormy:
            return .purple
        case .foggy:
            return .gray
        case .windy:
            return .teal
        }
    }
    
    private var accessibilityLabel: String {
        """
        \(forecast.dayName), \(forecast.formattedDate(style: .medium)). \
        \(forecast.condition.description). \
        High \(temperatureUnit.format(temperatureUnit.convert(fromKelvin: forecast.highTemp))), \
        Low \(temperatureUnit.format(temperatureUnit.convert(fromKelvin: forecast.lowTemp))). \
        Precipitation chance \(forecast.precipitationPercentage).
        """
    }
}

// MARK: - Preview

#Preview("Forecast View - Light") {
    ForecastView()
        .preferredColorScheme(.light)
}

#Preview("Forecast View - Dark") {
    ForecastView()
        .preferredColorScheme(.dark)
}

#Preview("Loading State") {
    struct LoadingPreview: View {
        @State private var state: ForecastViewState = .loading
        
        var body: some View {
            NavigationStack {
                VStack {
                    ProgressView()
                }
                .navigationTitle("5-Day Forecast")
            }
        }
    }
    
    return LoadingPreview()
}

#Preview("Error State") {
    struct ErrorPreview: View {
        var body: some View {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.orange)
                
                Text("Unable to Load Forecast")
                    .font(.title2.bold())
                
                Text("Network connection error")
                    .font(.body)
                    .foregroundStyle(.secondary)
                
                Button("Try Again") {}
                    .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }
    
    return ErrorPreview()
}
