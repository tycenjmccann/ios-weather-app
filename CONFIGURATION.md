# Configuration

## OpenWeatherMap API Key

This app requires an OpenWeatherMap API key to function.

### Getting an API Key

1. Visit [OpenWeatherMap](https://openweathermap.org/api)
2. Sign up for a free account
3. Navigate to API Keys section
4. Generate a new API key
5. Copy the key

### Setting Up the API Key

#### Option 1: Environment Variable (Recommended)

1. In Xcode, select your scheme: Product → Scheme → Edit Scheme
2. Select "Run" in the left sidebar
3. Select "Arguments" tab
4. Under "Environment Variables", click the "+" button
5. Add:
   - Name: `OPENWEATHER_API_KEY`
   - Value: Your actual API key

#### Option 2: Direct Replacement (Not recommended for production)

1. Open `WeatherApp/WeatherApp.swift`
2. Find the line:
   ```swift
   let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_API_KEY_HERE"
   ```
3. Replace `YOUR_API_KEY_HERE` with your actual API key
4. **Note**: Do not commit this file with your actual API key

### Security Best Practices

For production apps:

1. **Never commit API keys to version control**
2. Use environment variables or configuration files (excluded from git)
3. Consider using:
   - Keychain for secure storage
   - Backend proxy to hide API keys
   - iOS Configuration files with .gitignore

### API Rate Limits

Free tier limits:
- 1,000 calls/day
- 60 calls/minute

The app handles rate limiting with appropriate error messages.

### Troubleshooting

If you see "Invalid API key" error:
1. Verify your API key is correct
2. Check if the key is activated (may take a few minutes after generation)
3. Ensure you're using the correct OpenWeatherMap endpoint

If you see "Rate limit exceeded":
1. You've exceeded the free tier limits
2. Wait a few minutes before trying again
3. Consider upgrading your OpenWeatherMap plan
