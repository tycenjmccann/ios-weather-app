# iOS Weather App

A SwiftUI weather application that displays current weather conditions and a 5-day forecast using the OpenWeatherMap API.

## Features

- **Current Weather Display**: Shows temperature, humidity, wind speed, and weather conditions
- **5-Day Forecast**: Horizontally scrollable forecast with daily high/low temperatures
- **Location Services**: Uses CoreLocation to fetch user's current position
- **Error Handling**: Comprehensive error states for network, location, and API issues
- **Loading States**: Visual feedback during data fetching
- **Accessibility**: Full VoiceOver support and Dynamic Type compatibility

## Architecture

The app follows a clean Model-View architecture using SwiftUI's `@Observable` macro for state management:

### Components

- **Models** (`Weather.swift`): Core data structures and API response mappings
  - `Weather`: Current weather conditions
  - `DailyForecast`: Daily forecast data
  - API response models with automatic conversion

- **Services** (`Services/`):
  - `LocationService`: CoreLocation wrapper for GPS coordinates
  - `WeatherService`: OpenWeatherMap API integration

- **Views** (`Views/WeatherView.swift`): SwiftUI views
  - `WeatherView`: Main container view with state management
  - `CurrentWeatherView`: Current weather display
  - `ForecastView`: 5-day forecast scroll view
  - `LoadingView`, `ErrorView`: State-specific views

- **View Models** (`ViewModels/WeatherViewModel.swift`):
  - `WeatherViewModel`: Observable state container
  - `WeatherViewState`: State enum for view states

## Requirements

- iOS 17.0+
- Xcode 15.0+
- Swift 6.1+
- OpenWeatherMap API key

## Setup

1. **Get an API Key**:
   - Sign up at [OpenWeatherMap](https://openweathermap.org/api)
   - Get a free API key

2. **Configure the API Key**:
   - Set the `OPENWEATHER_API_KEY` environment variable in your scheme, or
   - Replace `YOUR_API_KEY_HERE` in `WeatherApp.swift` with your actual key

3. **Build and Run**:
   ```bash
   # Open in Xcode
   open WeatherApp.xcodeproj
   
   # Or use command line
   xcodebuild -scheme WeatherApp -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

## API Configuration

The app uses environment variables for API key management:

```swift
let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_API_KEY_HERE"
```

### Setting Environment Variable in Xcode

1. Edit Scheme → Run → Arguments
2. Add Environment Variable:
   - Name: `OPENWEATHER_API_KEY`
   - Value: `your_actual_api_key`

## Testing

The app includes comprehensive unit tests using Swift Testing framework:

```bash
# Run tests
xcodebuild test -scheme WeatherApp -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Test Coverage

- **Model Tests**: Data structure initialization and Codable conformance
- **API Conversion Tests**: Response mapping to domain models
- **Service Tests**: Mock service behavior and error handling
- **Network Tests**: HTTP status code handling (401, 429, 500)
- **View Model Tests**: State management and async operations

Target: 80%+ code coverage for business logic

## Project Structure

```
WeatherApp/
├── Models/
│   └── Weather.swift              # Data models and API responses
├── Services/
│   ├── LocationService.swift      # CoreLocation integration
│   └── WeatherService.swift       # API client
├── ViewModels/
│   └── WeatherViewModel.swift     # State management
├── Views/
│   └── WeatherView.swift          # SwiftUI views
├── WeatherApp.swift               # App entry point
└── Info.plist                     # Location permission description

WeatherAppTests/
├── WeatherAppTests.swift          # Core unit tests
└── ServiceTests.swift             # Service and network tests
```

## Key Technologies

- **SwiftUI**: Declarative UI framework
- **@Observable**: Modern state management (iOS 17+)
- **Swift Concurrency**: Async/await for network operations
- **CoreLocation**: GPS and location permissions
- **Swift Testing**: Modern testing framework
- **URLSession**: Network requests

## Best Practices

### Code Quality
- Swift API Design Guidelines compliance
- Proper access control (private, public)
- Comprehensive error types
- No force unwraps
- Sendable-safe async boundaries

### Architecture
- Model-View pattern (no ViewModels in traditional sense)
- `@State` for local state
- `.task` modifier for async loading
- Enum-based view states

### Testing
- Unit tests for all business logic
- Mock services for predictable testing
- Network error scenario coverage
- Swift Testing framework (@Test, #expect)

## OpenWeatherMap API Endpoints

### Current Weather
```
GET https://api.openweathermap.org/data/2.5/weather
Parameters:
  - lat: Latitude
  - lon: Longitude
  - appid: API key
  - units: imperial (Fahrenheit)
```

### 5-Day Forecast
```
GET https://api.openweathermap.org/data/2.5/forecast
Parameters:
  - lat: Latitude
  - lon: Longitude
  - appid: API key
  - units: imperial (Fahrenheit)
```

## Error Handling

The app handles various error scenarios:

- **Location Errors**:
  - Permission denied/restricted
  - Location unavailable
  - Timeout (10 seconds)

- **Network Errors**:
  - Invalid API key (401)
  - Rate limit exceeded (429)
  - Server errors (500+)
  - Network connectivity issues

- **User Feedback**:
  - Clear error messages
  - Retry mechanism
  - Loading indicators

## Accessibility

- VoiceOver labels for all interactive elements
- Dynamic Type support
- Semantic views for screen readers
- Accessible weather icons with descriptions

## Future Enhancements

Potential features for future iterations:

- Multiple location support
- Weather alerts and notifications
- Historical weather data
- Weather map visualization
- Widget support
- Watch app companion
- Localization (multiple languages)
- Analytics tracking
- Background refresh

## License

This project is created for demonstration purposes as part of an agentic development workflow.

## Contributing

This is a demo project. For production use, consider:

- Secure API key storage (Keychain)
- Caching layer for offline support
- Pull-to-refresh functionality
- Unit preference settings (°F/°C)
- Location search capability
- More comprehensive error recovery
