/**
 * Weather provider service - integrates with WeatherAPI.com
 */

import type { WeatherData, WeatherAPIResponse } from '../types/weather.types.js';
import { ExternalAPIError } from '../types/weather.types.js';
import { secretsService } from './secrets.service.js';

export class WeatherProviderService {
  private readonly BASE_URL = 'https://api.weatherapi.com/v1';
  private readonly TIMEOUT_MS = 5000;

  /**
   * Fetch weather data from WeatherAPI.com
   */
  async fetchWeather(latitude: number, longitude: number, unit: 'celsius' | 'fahrenheit' = 'celsius'): Promise<WeatherData> {
    const apiKey = await secretsService.getWeatherAPIKey();
    
    const url = new URL(`${this.BASE_URL}/current.json`);
    url.searchParams.set('key', apiKey);
    url.searchParams.set('q', `${latitude},${longitude}`);
    url.searchParams.set('aqi', 'no');

    console.log(`Fetching weather data for coordinates: ${latitude}, ${longitude}`);

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), this.TIMEOUT_MS);

      const response = await fetch(url.toString(), {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
        },
        signal: controller.signal,
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        if (response.status === 400) {
          throw new ExternalAPIError('Invalid coordinates provided', 400);
        }
        if (response.status === 401 || response.status === 403) {
          throw new ExternalAPIError('Weather API authentication failed', 502);
        }
        if (response.status === 429) {
          throw new ExternalAPIError('Weather API rate limit exceeded', 429);
        }
        throw new ExternalAPIError(`Weather API returned status ${response.status}`, 502);
      }

      const data = await response.json() as WeatherAPIResponse;
      
      return this.transformResponse(data, unit);
    } catch (error) {
      if (error instanceof ExternalAPIError) {
        throw error;
      }
      
      if ((error as Error).name === 'AbortError') {
        console.error('Weather API request timeout');
        throw new ExternalAPIError('Weather API request timeout', 504);
      }

      console.error('Weather API request failed:', error);
      throw new ExternalAPIError('Failed to fetch weather data from provider', 502);
    }
  }

  /**
   * Transform WeatherAPI.com response to our standard format
   */
  private transformResponse(data: WeatherAPIResponse, unit: 'celsius' | 'fahrenheit'): WeatherData {
    const temperature = unit === 'celsius' ? data.current.temp_c : data.current.temp_f;
    const windSpeed = unit === 'celsius' ? data.current.wind_kph : data.current.wind_mph;

    return {
      temperature,
      humidity: data.current.humidity,
      windSpeed,
      condition: data.current.condition.text,
      conditionCode: data.current.condition.code,
      timestamp: new Date().toISOString(),
      location: {
        latitude: data.location.lat,
        longitude: data.location.lon,
      },
    };
  }
}

// Singleton instance
export const weatherProviderService = new WeatherProviderService();
