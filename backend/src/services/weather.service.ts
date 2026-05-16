/**
 * Main weather service - orchestrates caching and provider calls
 */

import type { WeatherData } from '../types/weather.types.js';
import { cacheService } from './cache.service.js';
import { weatherProviderService } from './weather-provider.service.js';

export class WeatherService {
  /**
   * Get weather data with caching
   */
  async getWeather(latitude: number, longitude: number, unit: 'celsius' | 'fahrenheit' = 'celsius'): Promise<WeatherData> {
    // Try cache first
    const cached = cacheService.get(latitude, longitude);
    if (cached) {
      console.log('Returning cached weather data');
      return cached;
    }

    // Fetch from provider
    console.log('Cache miss - fetching from weather provider');
    const weatherData = await weatherProviderService.fetchWeather(latitude, longitude, unit);

    // Store in cache
    cacheService.set(latitude, longitude, weatherData);

    return weatherData;
  }

  /**
   * Get cache statistics (for monitoring)
   */
  getCacheStats() {
    return cacheService.getStats();
  }
}

// Singleton instance
export const weatherService = new WeatherService();
