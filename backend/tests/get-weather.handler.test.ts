/**
 * Unit tests for Get Weather Lambda Handler
 */

import { describe, it, expect, beforeEach, vi } from 'vitest';
import type { APIGatewayProxyEventV2 } from 'aws-lambda';
import { handler } from '../src/handlers/get-weather.handler';
import { weatherService } from '../src/services/weather.service';
import type { WeatherData } from '../src/types/weather.types';

// Mock the weather service
vi.mock('../src/services/weather.service');

describe('Get Weather Handler', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const createMockEvent = (
    queryParams?: Record<string, string>
  ): APIGatewayProxyEventV2 => ({
    version: '2.0',
    routeKey: 'GET /weather',
    rawPath: '/weather',
    rawQueryString: '',
    headers: {},
    requestContext: {
      accountId: '123456789',
      apiId: 'api123',
      domainName: 'api.example.com',
      domainPrefix: 'api',
      http: {
        method: 'GET',
        path: '/weather',
        protocol: 'HTTP/1.1',
        sourceIp: '1.2.3.4',
        userAgent: 'test',
      },
      requestId: 'test-request-id',
      routeKey: 'GET /weather',
      stage: 'prod',
      time: '01/Jan/2024:00:00:00 +0000',
      timeEpoch: 1704067200000,
    },
    isBase64Encoded: false,
    queryStringParameters: queryParams,
  });

  describe('Success Cases', () => {
    it('should return weather data for valid coordinates', async () => {
      const mockWeatherData: WeatherData = {
        temperature: 22.5,
        humidity: 70,
        windSpeed: 12.3,
        condition: 'Clear',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: {
          latitude: 51.5074,
          longitude: -0.1278,
        },
      };

      vi.mocked(weatherService.getWeather).mockResolvedValue(mockWeatherData);

      const event = createMockEvent({
        latitude: '51.5074',
        longitude: '-0.1278',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(200);
      expect(result.headers?.['Content-Type']).toBe('application/json');
      expect(result.headers?.['Cache-Control']).toBe('public, max-age=600');
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(true);
      expect(body.data).toEqual(mockWeatherData);
      
      expect(weatherService.getWeather).toHaveBeenCalledWith(
        51.5074,
        -0.1278,
        'celsius'
      );
    });

    it('should handle fahrenheit unit parameter', async () => {
      const mockWeatherData: WeatherData = {
        temperature: 72.5,
        humidity: 70,
        windSpeed: 7.6,
        condition: 'Clear',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: {
          latitude: 40.7128,
          longitude: -74.0060,
        },
      };

      vi.mocked(weatherService.getWeather).mockResolvedValue(mockWeatherData);

      const event = createMockEvent({
        latitude: '40.7128',
        longitude: '-74.0060',
        unit: 'fahrenheit',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(200);
      expect(weatherService.getWeather).toHaveBeenCalledWith(
        40.7128,
        -74.0060,
        'fahrenheit'
      );
    });

    it('should default to celsius when unit not specified', async () => {
      const mockWeatherData: WeatherData = {
        temperature: 20,
        humidity: 65,
        windSpeed: 10,
        condition: 'Sunny',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: {
          latitude: 40.7128,
          longitude: -74.0060,
        },
      };

      vi.mocked(weatherService.getWeather).mockResolvedValue(mockWeatherData);

      const event = createMockEvent({
        latitude: '40.7128',
        longitude: '-74.0060',
      });

      await handler(event);

      expect(weatherService.getWeather).toHaveBeenCalledWith(
        40.7128,
        -74.0060,
        'celsius'
      );
    });
  });

  describe('Validation Errors', () => {
    it('should return 400 for missing latitude', async () => {
      const event = createMockEvent({
        longitude: '-74.0060',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(400);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('VALIDATION_ERROR');
      expect(body.error.message).toContain('latitude');
    });

    it('should return 400 for missing longitude', async () => {
      const event = createMockEvent({
        latitude: '40.7128',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(400);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should return 400 for invalid latitude range', async () => {
      const event = createMockEvent({
        latitude: '999',
        longitude: '-74.0060',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(400);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('VALIDATION_ERROR');
    });

    it('should return 400 for invalid longitude range', async () => {
      const event = createMockEvent({
        latitude: '40.7128',
        longitude: '-999',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(400);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
    });

    it('should return 400 for non-numeric latitude', async () => {
      const event = createMockEvent({
        latitude: 'invalid',
        longitude: '-74.0060',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(400);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
    });
  });

  describe('Service Errors', () => {
    it('should handle external API errors', async () => {
      const error = {
        name: 'ExternalAPIError',
        message: 'Weather API failed',
        statusCode: 502,
        code: 'EXTERNAL_API_ERROR',
      };

      vi.mocked(weatherService.getWeather).mockRejectedValue(error);

      const event = createMockEvent({
        latitude: '40.7128',
        longitude: '-74.0060',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(502);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('EXTERNAL_API_ERROR');
      expect(body.error.message).toBe('Weather API failed');
    });

    it('should handle rate limit errors', async () => {
      const error = {
        name: 'RateLimitError',
        message: 'Rate limit exceeded',
        statusCode: 429,
        code: 'RATE_LIMIT_EXCEEDED',
      };

      vi.mocked(weatherService.getWeather).mockRejectedValue(error);

      const event = createMockEvent({
        latitude: '40.7128',
        longitude: '-74.0060',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(429);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('RATE_LIMIT_EXCEEDED');
    });

    it('should handle generic errors with 500 status', async () => {
      vi.mocked(weatherService.getWeather).mockRejectedValue(
        new Error('Unexpected error')
      );

      const event = createMockEvent({
        latitude: '40.7128',
        longitude: '-74.0060',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(500);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
      expect(body.error.code).toBe('INTERNAL_ERROR');
    });
  });

  describe('Edge Cases', () => {
    it('should handle missing query parameters object', async () => {
      const event = createMockEvent();

      const result = await handler(event);

      expect(result.statusCode).toBe(400);
      
      const body = JSON.parse(result.body!);
      expect(body.success).toBe(false);
    });

    it('should handle boundary latitude values', async () => {
      const mockWeatherData: WeatherData = {
        temperature: -40,
        humidity: 80,
        windSpeed: 5,
        condition: 'Snow',
        conditionCode: 1066,
        timestamp: '2024-01-15T10:00:00Z',
        location: {
          latitude: 90,
          longitude: 0,
        },
      };

      vi.mocked(weatherService.getWeather).mockResolvedValue(mockWeatherData);

      const event = createMockEvent({
        latitude: '90',
        longitude: '0',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(200);
    });

    it('should handle boundary longitude values', async () => {
      const mockWeatherData: WeatherData = {
        temperature: 25,
        humidity: 60,
        windSpeed: 8,
        condition: 'Clear',
        conditionCode: 1000,
        timestamp: '2024-01-15T10:00:00Z',
        location: {
          latitude: 0,
          longitude: -180,
        },
      };

      vi.mocked(weatherService.getWeather).mockResolvedValue(mockWeatherData);

      const event = createMockEvent({
        latitude: '0',
        longitude: '-180',
      });

      const result = await handler(event);

      expect(result.statusCode).toBe(200);
    });
  });
});
