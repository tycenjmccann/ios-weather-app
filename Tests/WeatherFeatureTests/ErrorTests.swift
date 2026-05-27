import Testing
@testable import WeatherFeature

/// Tests for error types
struct ErrorTests {
    
    // MARK: - LocationError Tests
    
    @Test("LocationError permission denied has correct description")
    func testLocationErrorPermissionDenied() {
        let error = LocationError.permissionDenied
        
        #expect(error.errorDescription?.contains("permission denied") == true)
        #expect(error.recoverySuggestion?.contains("Settings") == true)
    }
    
    @Test("LocationError permission restricted has correct description")
    func testLocationErrorPermissionRestricted() {
        let error = LocationError.permissionRestricted
        
        #expect(error.errorDescription?.contains("restricted") == true)
        #expect(error.recoverySuggestion != nil)
    }
    
    @Test("LocationError location unavailable has correct description")
    func testLocationErrorUnavailable() {
        let error = LocationError.locationUnavailable
        
        #expect(error.errorDescription?.contains("Unable to determine") == true)
        #expect(error.recoverySuggestion?.contains("try again") == true)
    }
    
    @Test("LocationError timeout has correct description")
    func testLocationErrorTimeout() {
        let error = LocationError.timeout
        
        #expect(error.errorDescription?.contains("timed out") == true)
        #expect(error.recoverySuggestion?.contains("try again") == true)
    }
    
    @Test("LocationError unknown includes custom message")
    func testLocationErrorUnknown() {
        let customMessage = "Custom error message"
        let error = LocationError.unknown(customMessage)
        
        #expect(error.errorDescription?.contains(customMessage) == true)
    }
    
    // MARK: - WeatherError Tests
    
    @Test("WeatherError network error has correct description")
    func testWeatherErrorNetwork() {
        let message = "Connection failed"
        let error = WeatherError.networkError(message)
        
        #expect(error.errorDescription?.contains(message) == true)
        #expect(error.recoverySuggestion?.contains("internet connection") == true)
    }
    
    @Test("WeatherError invalid response has correct description")
    func testWeatherErrorInvalidResponse() {
        let error = WeatherError.invalidResponse
        
        #expect(error.errorDescription?.contains("Invalid") == true)
        #expect(error.recoverySuggestion?.contains("try again") == true)
    }
    
    @Test("WeatherError API error includes status code")
    func testWeatherErrorAPI() {
        let statusCode = 500
        let message = "Internal server error"
        let error = WeatherError.apiError(statusCode, message)
        
        #expect(error.errorDescription?.contains(String(statusCode)) == true)
        #expect(error.errorDescription?.contains(message) == true)
    }
    
    @Test("WeatherError location error wraps LocationError")
    func testWeatherErrorLocationError() {
        let locationError = LocationError.permissionDenied
        let error = WeatherError.locationError(locationError)
        
        #expect(error.errorDescription == locationError.errorDescription)
        #expect(error.recoverySuggestion == locationError.recoverySuggestion)
    }
    
    @Test("WeatherError unknown includes custom message")
    func testWeatherErrorUnknown() {
        let customMessage = "Unknown error occurred"
        let error = WeatherError.unknown(customMessage)
        
        #expect(error.errorDescription?.contains(customMessage) == true)
    }
    
    // MARK: - Error Sendable Tests
    
    @Test("LocationError is Sendable")
    func testLocationErrorSendable() async {
        let error = LocationError.permissionDenied
        
        // This should compile without warnings
        Task {
            let _ = error
        }
    }
    
    @Test("WeatherError is Sendable")
    func testWeatherErrorSendable() async {
        let error = WeatherError.invalidResponse
        
        // This should compile without warnings
        Task {
            let _ = error
        }
    }
}
