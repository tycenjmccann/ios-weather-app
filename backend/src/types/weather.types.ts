/**
 * Weather API Types and Interfaces
 */

export interface Coordinates {
  latitude: number;
  longitude: number;
}

export interface WeatherData {
  temperature: number;
  humidity: number;
  windSpeed: number;
  condition: string;
  conditionCode: number;
  timestamp: string;
  location: {
    latitude: number;
    longitude: number;
  };
}

export interface WeatherAPIResponse {
  current: {
    temp_c: number;
    temp_f: number;
    humidity: number;
    wind_kph: number;
    wind_mph: number;
    condition: {
      text: string;
      code: number;
    };
  };
  location: {
    lat: number;
    lon: number;
  };
}

export interface CachedWeatherData extends WeatherData {
  cachedAt: string;
}

export class WeatherError extends Error {
  constructor(
    message: string,
    public readonly statusCode: number,
    public readonly code: string
  ) {
    super(message);
    this.name = 'WeatherError';
  }
}

export class ValidationError extends WeatherError {
  constructor(message: string) {
    super(message, 400, 'VALIDATION_ERROR');
    this.name = 'ValidationError';
  }
}

export class ExternalAPIError extends WeatherError {
  constructor(message: string, statusCode: number = 502) {
    super(message, statusCode, 'EXTERNAL_API_ERROR');
    this.name = 'ExternalAPIError';
  }
}

export class RateLimitError extends WeatherError {
  constructor(message: string = 'Rate limit exceeded') {
    super(message, 429, 'RATE_LIMIT_EXCEEDED');
    this.name = 'RateLimitError';
  }
}
