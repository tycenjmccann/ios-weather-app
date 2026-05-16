# Weather Feature Configuration

## Required Info.plist Entries

Add the following entries to your app's `Info.plist` file:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show weather conditions in your area.</string>
```

## API Configuration

The WeatherService uses a configurable base URL. Update the initialization in your app:

```swift
import WeatherFeature

// In your app initialization
let weatherService = WeatherService(
    baseURL: URL(string: "https://your-api-gateway-url.amazonaws.com/prod")!
)
```

## Backend API Endpoint

The feature expects a GET endpoint at `/weather` with the following query parameters:
- `lat`: Latitude (Double)
- `lon`: Longitude (Double)

### Expected Response Format

```json
{
  "main": {
    "temp": 22.5,
    "humidity": 65
  },
  "weather": [
    {
      "id": 800,
      "main": "Clear",
      "description": "clear sky"
    }
  ],
  "wind": {
    "speed": 3.5
  },
  "name": "San Francisco"
}
```

### Error Response Format

```json
{
  "error": "Error message string"
}
```

## Usage

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

## Testing

Run unit tests:
```bash
swift test
```

## Accessibility

The feature includes full VoiceOver support with:
- Descriptive accessibility labels
- Proper heading traits
- Combined elements for better navigation
- Dynamic Type support
