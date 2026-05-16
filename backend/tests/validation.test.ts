/**
 * Unit tests for Validation Schemas
 */

import { describe, it, expect } from 'vitest';
import { coordinatesSchema, weatherQuerySchema } from '../src/validation/schemas';

describe('Validation Schemas', () => {
  describe('coordinatesSchema', () => {
    it('should validate valid coordinates', () => {
      const validData = {
        latitude: 40.7128,
        longitude: -74.0060,
      };

      const result = coordinatesSchema.safeParse(validData);
      
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data).toEqual(validData);
      }
    });

    it('should accept boundary latitude values', () => {
      expect(coordinatesSchema.safeParse({ latitude: 90, longitude: 0 }).success).toBe(true);
      expect(coordinatesSchema.safeParse({ latitude: -90, longitude: 0 }).success).toBe(true);
    });

    it('should accept boundary longitude values', () => {
      expect(coordinatesSchema.safeParse({ latitude: 0, longitude: 180 }).success).toBe(true);
      expect(coordinatesSchema.safeParse({ latitude: 0, longitude: -180 }).success).toBe(true);
    });

    it('should reject latitude above 90', () => {
      const result = coordinatesSchema.safeParse({
        latitude: 91,
        longitude: 0,
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0].message).toContain('90');
      }
    });

    it('should reject latitude below -90', () => {
      const result = coordinatesSchema.safeParse({
        latitude: -91,
        longitude: 0,
      });

      expect(result.success).toBe(false);
    });

    it('should reject longitude above 180', () => {
      const result = coordinatesSchema.safeParse({
        latitude: 0,
        longitude: 181,
      });

      expect(result.success).toBe(false);
      if (!result.success) {
        expect(result.error.issues[0].message).toContain('180');
      }
    });

    it('should reject longitude below -180', () => {
      const result = coordinatesSchema.safeParse({
        latitude: 0,
        longitude: -181,
      });

      expect(result.success).toBe(false);
    });

    it('should reject missing latitude', () => {
      const result = coordinatesSchema.safeParse({
        longitude: -74.0060,
      });

      expect(result.success).toBe(false);
    });

    it('should reject missing longitude', () => {
      const result = coordinatesSchema.safeParse({
        latitude: 40.7128,
      });

      expect(result.success).toBe(false);
    });
  });

  describe('weatherQuerySchema', () => {
    it('should validate and transform valid string coordinates', () => {
      const validData = {
        latitude: '40.7128',
        longitude: '-74.0060',
      };

      const result = weatherQuerySchema.safeParse(validData);
      
      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.latitude).toBe(40.7128);
        expect(result.data.longitude).toBe(-74.0060);
        expect(result.data.unit).toBe('celsius'); // default
      }
    });

    it('should transform string coordinates to numbers', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '51.5074',
        longitude: '-0.1278',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(typeof result.data.latitude).toBe('number');
        expect(typeof result.data.longitude).toBe('number');
      }
    });

    it('should accept celsius unit', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '40.7128',
        longitude: '-74.0060',
        unit: 'celsius',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.unit).toBe('celsius');
      }
    });

    it('should accept fahrenheit unit', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '40.7128',
        longitude: '-74.0060',
        unit: 'fahrenheit',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.unit).toBe('fahrenheit');
      }
    });

    it('should default unit to celsius when not provided', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '40.7128',
        longitude: '-74.0060',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.unit).toBe('celsius');
      }
    });

    it('should reject invalid unit values', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '40.7128',
        longitude: '-74.0060',
        unit: 'kelvin',
      });

      expect(result.success).toBe(false);
    });

    it('should reject non-numeric latitude strings', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: 'invalid',
        longitude: '-74.0060',
      });

      expect(result.success).toBe(false);
    });

    it('should reject non-numeric longitude strings', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '40.7128',
        longitude: 'invalid',
      });

      expect(result.success).toBe(false);
    });

    it('should reject latitude string values out of range', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '999',
        longitude: '0',
      });

      expect(result.success).toBe(false);
    });

    it('should reject longitude string values out of range', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '0',
        longitude: '999',
      });

      expect(result.success).toBe(false);
    });

    it('should handle decimal string coordinates', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '40.71278976',
        longitude: '-74.00601234',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.latitude).toBeCloseTo(40.71278976);
        expect(result.data.longitude).toBeCloseTo(-74.00601234);
      }
    });

    it('should accept zero values', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '0',
        longitude: '0',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.latitude).toBe(0);
        expect(result.data.longitude).toBe(0);
      }
    });

    it('should accept negative string numbers', () => {
      const result = weatherQuerySchema.safeParse({
        latitude: '-45.5',
        longitude: '-123.456',
      });

      expect(result.success).toBe(true);
      if (result.success) {
        expect(result.data.latitude).toBe(-45.5);
        expect(result.data.longitude).toBe(-123.456);
      }
    });
  });
});
