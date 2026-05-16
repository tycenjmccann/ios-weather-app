/**
 * Lambda handler for GET /weather endpoint
 */

import type { APIGatewayProxyEventV2, APIGatewayProxyResultV2 } from 'aws-lambda';
import middy from '@middy/core';
import httpErrorHandler from '@middy/http-error-handler';
import { weatherQuerySchema } from '../validation/schemas.js';
import { weatherService } from '../services/weather.service.js';
import { ValidationError, WeatherError } from '../types/weather.types.js';

/**
 * Main Lambda handler
 */
const baseHandler = async (
  event: APIGatewayProxyEventV2
): Promise<APIGatewayProxyResultV2> => {
  console.log('Processing weather request', {
    queryParams: event.queryStringParameters,
    requestId: event.requestContext.requestId,
  });

  try {
    // Validate query parameters
    const params = event.queryStringParameters || {};
    
    if (!params.latitude || !params.longitude) {
      throw new ValidationError('Missing required parameters: latitude and longitude');
    }

    const { latitude, longitude, unit } = weatherQuerySchema.parse(params);

    // Get weather data
    const weatherData = await weatherService.getWeather(latitude, longitude, unit);

    // Success response
    return {
      statusCode: 200,
      headers: {
        'Content-Type': 'application/json',
        'Cache-Control': 'public, max-age=600', // 10 minutes
      },
      body: JSON.stringify({
        success: true,
        data: weatherData,
      }),
    };
  } catch (error) {
    console.error('Error processing weather request:', error);

    // Handle validation errors
    if (error instanceof ValidationError) {
      return {
        statusCode: error.statusCode,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: {
            code: error.code,
            message: error.message,
          },
        }),
      };
    }

    // Handle weather errors (external API, rate limits, etc.)
    if (error instanceof WeatherError) {
      return {
        statusCode: error.statusCode,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: {
            code: error.code,
            message: error.message,
          },
        }),
      };
    }

    // Handle Zod validation errors
    if ((error as any).issues) {
      const zodError = error as any;
      return {
        statusCode: 400,
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          success: false,
          error: {
            code: 'VALIDATION_ERROR',
            message: 'Invalid input parameters',
            details: zodError.issues,
          },
        }),
      };
    }

    // Generic error
    return {
      statusCode: 500,
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        success: false,
        error: {
          code: 'INTERNAL_ERROR',
          message: 'An unexpected error occurred',
        },
      }),
    };
  }
};

// Apply Middy middleware
export const handler = middy(baseHandler).use(httpErrorHandler());
