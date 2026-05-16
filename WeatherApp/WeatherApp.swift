import SwiftUI

@main
struct WeatherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        // Initialize services
        // Note: In production, API key should be loaded from Configuration or Environment
        let apiKey = ProcessInfo.processInfo.environment["OPENWEATHER_API_KEY"] ?? "YOUR_API_KEY_HERE"
        let weatherService = WeatherService(apiKey: apiKey)
        let viewModel = WeatherViewModel(weatherService: weatherService)
        
        WeatherView(viewModel: viewModel)
    }
}

#Preview {
    ContentView()
}
