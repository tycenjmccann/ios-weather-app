/**
 * Unit tests for Weather Provider Service
 */

import { describe, it, expect, beforeEach, vi, afterEach } from 'vitest';
import { WeatherProviderService } from '../src/services/weather-provider.service';
import { ExternalAPIError } from '../src/types/weather.types';
import { secretsService } from '../src/services/secrets.service';

// Mock the secrets service
vi.mock('../src/services/secrets.service');

// Mock fetch globally
global.fetch = vi.fn();

describe('WeatherProviderService', () => {
  let service: WeatherProviderService;
  const mockApiKey = 'test-api-key-123';

  beforeEach(() => {
    service = new WeatherProviderService();
    vi.mocked(secretsService.getWeatherAPIKey).mockResolvedValue(mockApiKey);
  });

  afterEach(() => {
    vi.clearAllMocks();
  });

  describe('fetchWeather', () => {
    it('should fetch and transform weather data successfully (celsius)', async () => {
      const mockApiResponse = {
        location: {
          lat: 40.71,
          lon: -74.01,
        },
        current: {
          temp_c: 20.5,
          temp_f: 68.9,
          humidity: 65,
          wind_kph: 15.5,
          wind_mph: 9.6,
          condition: {
            text: 'Partly cloudy',
            code: 1003,
          },
        },
      };

      vi.mocked(global.fetch).mockResolvedValue({
        ok: true,
        json: async () => mockApiResponse,
      } as Response);

      const result = await service.fetchWeather(40.7128, -74.0060, 'celsius');

      expect(result).toEqual({
        temperature: 20.5,
        humidity: 65,
        windSpeed: 15.5,
        condition: 'Partly cloudy',
        conditionCode: 1003,
        timestamp: expect.any(String),
        location: {
          latitude: 40.71,
          longitude: -74.01,
        },
      });

      expect(secretsService.getWeatherAPIKey).toHaveBeenCalled();
    });

    it('should fetch and transform weather data successfully (fahrenheit)', async () => {
      const mockApiResponse = {
        location: {
          lat: 40.71,
          lon: -74.01,
        },
        current: {
          temp_c: 20.5,
          temp_f: 68.9,
          humidity: 65,
          wind_kph: 15.5,
          wind_mph: 9.6,
          condition: {
            text: 'Partly cloudy',
            code: 1003,
          },
        },
      };

      vi.mocked(global.fetch).mockResolvedValue({
        ok: true,
        json: async () => mockApiResponse,
      } as Response);

      const result = await service.fetchWeather(40.7128, -74.0060, 'fahrenheit');

      expect(result.temperature).toBe(68.9);
      expect(result.windSpeed).toBe(9.6);
    });

    it('should throw ExternalAPIError for 400 status', async () => {
      vi.mocked(global.fetch).mockResolvedValue({
        ok: false,
        status: 400,
      } as Response);

      await expect(
        service.fetchWeather(999, 999)
      ).rejects.toThrow(ExternalAPIError);

      await expect(
        service.fetchWeather(999, 999)
      ).rejects.toMatchObject({
        statusCode: 400,
        message: 'Invalid coordinates provided',
      });
    });

    it('should throw ExternalAPIError for 401 status', async () => {
      vi.mocked(global.fetch).mockResolvedValue({
        ok: false,
        status: 401,
      } as Response);

      await expect(
        service.fetchWeather(40.7128, -74.0060)
      ).rejects.toThrow(ExternalAPIError);

      await expect(
        service.fetchWeather(40.7128, -74.0060)
      ).rejects.toMatchObject({
        statusCode: 502,
        message: 'Weather API authentication failed',
      });
    });

    it('should throw ExternalAPIError for 429 rate limit', async () => {
      vi.mocked(global.fetch).mockResolvedValue({
        ok: false,
        status: 429,
      } as Response);

      await expect(
        service.fetchWeather(40.7128, -74.0060)
      ).rejects.toMatchObject({
        statusCode: 429,
        message: 'Weather API rate limit exceeded',
      });
    });

    it('should throw ExternalAPIError for timeout', async () => {
      vi.mocked(global.fetch).mockRejectedValue(
        Object.assign(new Error('Timeout'), { name: 'AbortError' })
      );

      await expect(
        service.fetchWeather(40.7128, -74.0060)
      ).rejects.toMatchObject({
        statusCode: 504,
        message: 'Weather API request timeout',
      });
    });

    it('should throw ExternalAPIError for network errors', async () => {
      vi.mocked(global.fetch).mockRejectedValue(new Error('Network error'));

      await expect(
        service.fetchWeather(40.7128, -74.0060)
      ).rejects.toMatchObject({
        statusCode: 502,
        message: 'Failed to fetch weather data from provider',
      });
    });

    it('should include API key in request', async () => {
      const mockApiResponse = {
        location: { lat: 40.71, lon: -74.01 },
        current: {
          temp_c: 20.5,
          temp_f: 68.9,
          humidity: 65,
          wind_kph: 15.5,
          wind_mph: 9.6,
          condition: { text: 'Sunny', code: 1000 },
        },
      };

      vi.mocked(global.fetch).mockResolvedValue({
        ok: true,
        json: async () => mockApiResponse,
      } as Response);

      await service.fetchWeather(40.7128, -74.0060);

      expect(global.fetch).toHaveBeenCalledWith(
        expect.stringContaining(`key=${mockApiKey}`),
        expect.any(Object)
      );
    });
  });
});
