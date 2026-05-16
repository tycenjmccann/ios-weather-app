/**
 * Unit tests for Cache Service
 */

import { describe, it, expect, beforeEach } from 'vitest';
import { CacheService } from '../src/services/cache.service';
import type { WeatherData } from '../src/types/weather.types';

describe('CacheService', () => {
  let cacheService: CacheService;

  beforeEach(() => {
    // Create fresh instance with short TTL for testing
    cacheService = new CacheService(1); // 1 second TTL
  });

  describe('get and set', () => {
    it('should store and retrieve weather data', () => {
      const mockData: WeatherData = {
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

      cacheService.set(51.5074, -0.1278, mockData);
      const result = cacheService.get(51.5074, -0.1278);

      expect(result).toBeDefined();
      expect(result?.temperature).toBe(22.5);
      expect(result?.humidity).toBe(70);
      expect(result?.condition).toBe('Clear');
      expect(result?.cachedAt).toBeDefined();
    });

    it('should return null for cache miss', () => {
      const result = cacheService.get(40.7128, -74.0060);
      expect(result).toBeNull();
    });

    it('should handle coordinate rounding in cache keys', () => {
      const mockData: WeatherData = {
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

      // Set with precise coordinates
      cacheService.set(40.71281234, -74.00601234, mockData);
      
      // Get with slightly different coordinates (should hit due to rounding)
      const result = cacheService.get(40.71279876, -74.00599876);
      
      expect(result).toBeDefined();
      expect(result?.temperature).toBe(20);
    });

    it('should add cachedAt timestamp when storing data', () => {
      const mockData: WeatherData = {
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

      cacheService.set(40.7128, -74.0060, mockData);
      const result = cacheService.get(40.7128, -74.0060);

      expect(result?.cachedAt).toBeDefined();
      expect(typeof result?.cachedAt).toBe('string');
      expect(new Date(result!.cachedAt).getTime()).toBeLessThanOrEqual(Date.now());
    });

    it('should expire cached data after TTL', async () => {
      const mockData: WeatherData = {
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

      cacheService.set(40.7128, -74.0060, mockData);
      
      // Verify it's cached
      let result = cacheService.get(40.7128, -74.0060);
      expect(result).toBeDefined();

      // Wait for TTL to expire (1 second + buffer)
      await new Promise(resolve => setTimeout(resolve, 1200));

      // Should be expired
      result = cacheService.get(40.7128, -74.0060);
      expect(result).toBeNull();
    });
  });

  describe('clear', () => {
    it('should clear all cached data', () => {
      const mockData: WeatherData = {
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

      cacheService.set(40.7128, -74.0060, mockData);
      cacheService.set(51.5074, -0.1278, mockData);

      cacheService.clear();

      expect(cacheService.get(40.7128, -74.0060)).toBeNull();
      expect(cacheService.get(51.5074, -0.1278)).toBeNull();
    });
  });

  describe('getStats', () => {
    it('should return cache statistics', () => {
      const mockData: WeatherData = {
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

      cacheService.set(40.7128, -74.0060, mockData);
      cacheService.get(40.7128, -74.0060); // Hit
      cacheService.get(51.5074, -0.1278); // Miss

      const stats = cacheService.getStats();

      expect(stats).toBeDefined();
      expect(stats.keys).toBe(1);
      expect(stats.hits).toBeGreaterThan(0);
      expect(stats.misses).toBeGreaterThan(0);
    });
  });
});
