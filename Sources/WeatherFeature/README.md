# WeatherFeature

iOS SwiftUI weather display feature for showing current location weather conditions.

## Overview

This package provides a complete weather display feature including:
- Location services integration with CoreLocation
- Weather data fetching from backend API
- SwiftUI views with proper state management
- Comprehensive error handling
- Full accessibility support
- Unit tests

## Requirements

- iOS 18.0+
- Swift 6.0+
- Xcode 16.0+

## Configuration

### Required Info.plist Entries

Add the following entry to your app's `Info.plist` file:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show weather conditions in your area.</string>
```

### Backend API Configuration

Update the base URL in `WeatherService.swift`:

```swift
private static let defaultBaseURL = URL(string: "https://your-api-url.com/v1")!
```

Or pass a custom URL when initializing:

```swift
let weatherService = WeatherService(
    baseURL: URL(string: "https://your-backend-api.com")!
)
```

## Usage

### Basic Implementation

```swift
import SwiftUI
import WeatherFeature

@main
struct WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            WeatherView()
        }
    }
}
```

## Backend API Integration

### Endpoint Specification

```
GET /weather?lat={latitude}&lon={longitude}&units={metric|imperial}
```

**Query Parameters:**
- `lat`: Latitude (required)
- `lon`: Longitude (required)
- `units`: `metric` for Celsius, `imperial` for Fahrenheit (optional)

### Expected Response Format

```json
{
  "main": {
    "temp": 22.5,
    "humidity": 65
  },
  "weather": [
    {
      "main": "Clear",
      "description": "clear sky"
    }
  ],
  "wind": {
    "speed": 5.2
  },
  "dt": 1638360000
}
```

### Error Response Format

```json
{
  "message": "Error description",
  "code": "error_code"
}
```

## Features

### Location Services
- ✅ Request when-in-use location authorization
- ✅ Handle all permission states (granted, denied, restricted)
- ✅ Async/await location fetching with timeout (10s)
- ✅ Proper error handling and user messaging

### Weather Display
- ✅ Current temperature (Celsius/Fahrenheit)
- ✅ Humidity percentage
- ✅ Wind speed (m/s, mph, km/h)
- ✅ Weather condition with SF Symbols icons
- ✅ Dynamic background gradients
- ✅ Pull-to-refresh support
- ✅ Loading and error states

### Architecture
- ✅ Model-View (MV) pattern with Swift 6
- ✅ @Observable services with async/await
- ✅ Sendable conformance for thread safety
- ✅ No retain cycles or memory leaks
- ✅ @MainActor for UI thread safety

## Testing

Run tests with Swift Package Manager:

```bash
swift test
```

Or in Xcode:
- Press `Cmd+U` to run all tests
- Use Test Navigator (`Cmd+6`) for individual tests

### Test Coverage

- ✅ WeatherData model tests
- ✅ Error type tests (LocationError, WeatherError)
- ✅ WeatherService tests with mocked URLSession
- ✅ LocationService (requires simulator/device)

## Accessibility

All views include:
- VoiceOver labels and hints
- Semantic UI structure  
- Dynamic Type support
- High contrast compatibility
- Proper accessibility traits

## Performance

- No blocking operations on main thread
- Efficient state management with @Observable
- Minimal re-renders
- Memory-safe with Sendable conformance
- 10-second timeout for location requests

## Project Structure

```
Sources/WeatherFeature/
├── Models/
│   ├── WeatherData.swift      # Weather data model with formatting
│   └── Errors.swift            # LocationError and WeatherError types
├── Services/
│   ├── LocationService.swift  # CoreLocation wrapper with async/await
│   └── WeatherService.swift   # Weather API client
└── Views/
    └── WeatherView.swift       # Main weather display view

Tests/WeatherFeatureTests/
├── WeatherDataTests.swift      # Model tests
├── ErrorTests.swift            # Error type tests
└── WeatherServiceTests.swift   # Service tests with mocks
```

## Code Quality

Follows:
- Swift API Design Guidelines
- Google Swift Style Guide
- iOS Human Interface Guidelines
- WCAG 2.1 Level AA accessibility standards
- Swift 6 strict concurrency

## Future Enhancements

- [ ] Weather forecast (5-day, hourly)
- [ ] Multiple location support
- [ ] Weather alerts and notifications
- [ ] Historical weather data
- [ ] User preference persistence (units, locations)
- [ ] Offline caching with Core Data
- [ ] iOS Widget support
- [ ] Apple Watch companion app

## License

Copyright © 2024. All rights reserved.
