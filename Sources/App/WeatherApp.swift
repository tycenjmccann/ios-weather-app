import SwiftUI

@main
struct WeatherApp: App {
    
    // MARK: Properties
    
    @State private var weatherService = WeatherService()
    
    // MARK: Body
    
    var body: some Scene {
        WindowGroup {
            ForecastView(weatherService: weatherService)
                .preferredColorScheme(nil) // Respects system setting
        }
    }
}
