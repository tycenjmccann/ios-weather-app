/**
 * Unit tests for Weather Service
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import { WeatherService } from '../src/services/weather.service';
import { cacheService } from '../src/services/cache.service';
import { weatherProviderService } from '../src/services/weather-provider.service';

// Mock the dependencies
vi.mock('../src/services/cache.service');
vi.mock('../src/services/weather-provider.service');

describe('WeatherService', () => {
  let weatherService: WeatherService;

  beforeEach(() => {
    weatherService = new WeatherService();
    vi.clearAllMocks();
  });

  describe('getWeather', () => {
    it('should return cached data when available', async () => {
      const mockCachedData = {
        temperature: 20,
        humidity: 65,
        windSpeed: 10,
        condition: 'Sunny',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: { latitude: 40.7128, longitude: -74.0060 },
        cachedAt: '2024-01-15T10:00:00Z',
      };

      vi.mocked(cacheService.get).mockReturnValue(mockCachedData);

      const result = await weatherService.getWeather(40.7128, -74.0060);

      expect(result).toEqual(mockCachedData);
      expect(cacheService.get).toHaveBeenCalledWith(40.7128, -74.0060);
      expect(weatherProviderService.fetchWeather).not.toHaveBeenCalled();
    });

    it('should fetch from provider when cache misses', async () => {
      const mockWeatherData = {
        temperature: 20,
        humidity: 65,
        windSpeed: 10,
        condition: 'Sunny',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: { latitude: 40.7128, longitude: -74.0060 },
      };

      vi.mocked(cacheService.get).mockReturnValue(null);
      vi.mocked(weatherProviderService.fetchWeather).mockResolvedValue(mockWeatherData);

      const result = await weatherService.getWeather(40.7128, -74.0060, 'celsius');

      expect(result).toEqual(mockWeatherData);
      expect(cacheService.get).toHaveBeenCalledWith(40.7128, -74.0060);
      expect(weatherProviderService.fetchWeather).toHaveBeenCalledWith(40.7128, -74.0060, 'celsius');
      expect(cacheService.set).toHaveBeenCalledWith(40.7128, -74.0060, mockWeatherData);
    });

    it('should cache fetched data', async () => {
      const mockWeatherData = {
        temperature: 20,
        humidity: 65,
        windSpeed: 10,
        condition: 'Sunny',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: { latitude: 40.7128, longitude: -74.0060 },
      };

      vi.mocked(cacheService.get).mockReturnValue(null);
      vi.mocked(weatherProviderService.fetchWeather).mockResolvedValue(mockWeatherData);

      await weatherService.getWeather(40.7128, -74.0060);

      expect(cacheService.set).toHaveBeenCalledWith(40.7128, -74.0060, mockWeatherData);
    });

    it('should propagate errors from provider', async () => {
      const error = new Error('Provider error');
      
      vi.mocked(cacheService.get).mockReturnValue(null);
      vi.mocked(weatherProviderService.fetchWeather).mockRejectedValue(error);

      await expect(
        weatherService.getWeather(40.7128, -74.0060)
      ).rejects.toThrow('Provider error');
    });
  });

  describe('getCacheStats', () => {
    it('should return cache statistics', () => {
      const mockStats = {
        keys: 5,
        hits: 10,
        misses: 3,
        ksize: 5,
        vsize: 1024,
      };

      vi.mocked(cacheService.getStats).mockReturnValue(mockStats);

      const stats = weatherService.getCacheStats();

      expect(stats).toEqual(mockStats);
      expect(cacheService.getStats).toHaveBeenCalled();
    });
  });
});
