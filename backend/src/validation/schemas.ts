/**
 * Zod validation schemas for weather API
 */

import { z } from 'zod';

export const coordinatesSchema = z.object({
  latitude: z.number()
    .min(-90, 'Latitude must be between -90 and 90')
    .max(90, 'Latitude must be between -90 and 90'),
  longitude: z.number()
    .min(-180, 'Longitude must be between -180 and 180')
    .max(180, 'Longitude must be between -180 and 180'),
});

export const weatherQuerySchema = z.object({
  latitude: z.string()
    .transform(val => parseFloat(val))
    .refine(val => !isNaN(val), 'Latitude must be a valid number')
    .refine(val => val >= -90 && val <= 90, 'Latitude must be between -90 and 90'),
  longitude: z.string()
    .transform(val => parseFloat(val))
    .refine(val => !isNaN(val), 'Longitude must be a valid number')
    .refine(val => val >= -180 && val <= 180, 'Longitude must be between -180 and 180'),
  unit: z.enum(['celsius', 'fahrenheit']).optional().default('celsius'),
});

export type WeatherQuery = z.infer<typeof weatherQuerySchema>;
