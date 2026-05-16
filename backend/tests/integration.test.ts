/**
 * Integration test example for Weather API
 * 
 * This test can be run against a deployed environment to verify
 * end-to-end functionality. Set the API_ENDPOINT environment variable
 * to your deployed API Gateway URL.
 * 
 * Usage:
 *   API_ENDPOINT=https://xyz.execute-api.us-east-1.amazonaws.com npm run test:integration
 */

import { describe, it, expect } from 'vitest';

const API_ENDPOINT = process.env.API_ENDPOINT;

describe('Weather API Integration Tests', () => {
  // Skip tests if API_ENDPOINT is not set
  const skipIfNoEndpoint = API_ENDPOINT ? it : it.skip;

  skipIfNoEndpoint('should return weather data for valid coordinates', async () => {
    const response = await fetch(
      `${API_ENDPOINT}/weather?latitude=37.7749&longitude=-122.4194`
    );

    expect(response.status).toBe(200);
    expect(response.headers.get('content-type')).toContain('application/json');

    const data = await response.json();
    
    expect(data).toHaveProperty('success', true);
    expect(data).toHaveProperty('data');
    expect(data.data).toHaveProperty('temperature');
    expect(data.data).toHaveProperty('humidity');
    expect(data.data).toHaveProperty('windSpeed');
    expect(data.data).toHaveProperty('condition');
    expect(data.data).toHaveProperty('location');
    expect(data.data.location).toHaveProperty('latitude');
    expect(data.data.location).toHaveProperty('longitude');
  });

  skipIfNoEndpoint('should return 400 for missing latitude', async () => {
    const response = await fetch(
      `${API_ENDPOINT}/weather?longitude=-122.4194`
    );

    expect(response.status).toBe(400);

    const data = await response.json();
    
    expect(data).toHaveProperty('success', false);
    expect(data).toHaveProperty('error');
    expect(data.error).toHaveProperty('code', 'VALIDATION_ERROR');
  });

  skipIfNoEndpoint('should return 400 for invalid latitude range', async () => {
    const response = await fetch(
      `${API_ENDPOINT}/weather?latitude=999&longitude=-122.4194`
    );

    expect(response.status).toBe(400);

    const data = await response.json();
    
    expect(data).toHaveProperty('success', false);
    expect(data.error.code).toBe('VALIDATION_ERROR');
  });

  skipIfNoEndpoint('should handle fahrenheit unit', async () => {
    const response = await fetch(
      `${API_ENDPOINT}/weather?latitude=37.7749&longitude=-122.4194&unit=fahrenheit`
    );

    expect(response.status).toBe(200);

    const data = await response.json();
    
    expect(data.success).toBe(true);
    expect(data.data.temperature).toBeGreaterThan(30); // Fahrenheit is usually > 30
  });

  skipIfNoEndpoint('should return cached data on second request', async () => {
    // First request
    const response1 = await fetch(
      `${API_ENDPOINT}/weather?latitude=51.5074&longitude=-0.1278`
    );
    const data1 = await response1.json();
    const timestamp1 = data1.data.timestamp;

    // Wait 1 second
    await new Promise(resolve => setTimeout(resolve, 1000));

    // Second request (should hit cache)
    const response2 = await fetch(
      `${API_ENDPOINT}/weather?latitude=51.5074&longitude=-0.1278`
    );
    const data2 = await response2.json();
    const timestamp2 = data2.data.timestamp;

    // Timestamps should be the same if cached
    expect(timestamp2).toBe(timestamp1);
  }, 15000);

  skipIfNoEndpoint('should have proper CORS headers', async () => {
    const response = await fetch(
      `${API_ENDPOINT}/weather?latitude=37.7749&longitude=-122.4194`
    );

    expect(response.headers.get('access-control-allow-origin')).toBeTruthy();
  });

  skipIfNoEndpoint('should respond within acceptable time', async () => {
    const startTime = Date.now();
    
    const response = await fetch(
      `${API_ENDPOINT}/weather?latitude=40.7128&longitude=-74.0060`
    );
    
    const endTime = Date.now();
    const responseTime = endTime - startTime;

    expect(response.status).toBe(200);
    expect(responseTime).toBeLessThan(3000); // Should respond within 3 seconds
  });
});
