/**
 * Cache service for weather data
 * Uses in-memory caching with 10-minute TTL
 */

import NodeCache from 'node-cache';
import type { CachedWeatherData, WeatherData } from '../types/weather.types.js';

export class CacheService {
  private cache: NodeCache;
  private readonly TTL_SECONDS = 600; // 10 minutes

  constructor(ttlSeconds: number = 600) {
    this.TTL_SECONDS = ttlSeconds;
    this.cache = new NodeCache({
      stdTTL: this.TTL_SECONDS,
      checkperiod: 120, // Check for expired keys every 2 minutes
      useClones: false, // Better performance,
    });
  }

  /**
   * Generate cache key from coordinates
   */
  private generateKey(latitude: number, longitude: number): string {
    // Round to 2 decimal places for cache key to handle minor coordinate variations
    const lat = latitude.toFixed(2);
    const lon = longitude.toFixed(2);
    return `weather:${lat}:${lon}`;
  }

  /**
   * Get cached weather data
   */
  get(latitude: number, longitude: number): CachedWeatherData | null {
    const key = this.generateKey(latitude, longitude);
    const cached = this.cache.get<CachedWeatherData>(key);
    
    if (cached) {
      console.log(`Cache HIT for ${key}`);
      return cached;
    }
    
    console.log(`Cache MISS for ${key}`);
    return null;
  }

  /**
   * Set weather data in cache
   */
  set(latitude: number, longitude: number, data: WeatherData): void {
    const key = this.generateKey(latitude, longitude);
    const cachedData: CachedWeatherData = {
      ...data,
      cachedAt: new Date().toISOString(),
    };
    
    this.cache.set(key, cachedData);
    console.log(`Cache SET for ${key}, TTL: ${this.TTL_SECONDS}s`);
  }

  /**
   * Clear all cached data
   */
  clear(): void {
    this.cache.flushAll();
    console.log('Cache cleared');
  }

  /**
   * Get cache statistics
   */
  getStats() {
    return this.cache.getStats();
  }
}

// Singleton instance for Lambda container reuse
export const cacheService = new CacheService();
