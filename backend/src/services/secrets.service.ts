/**
 * Secrets Manager service for secure API key retrieval
 */

import { SecretsManagerClient, GetSecretValueCommand } from '@aws-sdk/client-secrets-manager';

export class SecretsService {
  private client: SecretsManagerClient;
  private cache: Map<string, { value: string; expiresAt: number }>;
  private readonly CACHE_TTL_MS = 300000; // 5 minutes

  constructor(region: string = process.env.AWS_REGION || 'us-east-1') {
    this.client = new SecretsManagerClient({ region });
    this.cache = new Map();
  }

  /**
   * Get secret value with caching
   */
  async getSecret(secretName: string): Promise<string> {
    // Check cache first
    const cached = this.cache.get(secretName);
    if (cached && cached.expiresAt > Date.now()) {
      console.log(`Using cached secret for ${secretName}`);
      return cached.value;
    }

    // Fetch from Secrets Manager
    console.log(`Fetching secret from Secrets Manager: ${secretName}`);
    try {
      const command = new GetSecretValueCommand({ SecretId: secretName });
      const response = await this.client.send(command);

      if (!response.SecretString) {
        throw new Error(`Secret ${secretName} has no string value`);
      }

      // Cache the secret
      this.cache.set(secretName, {
        value: response.SecretString,
        expiresAt: Date.now() + this.CACHE_TTL_MS,
      });

      return response.SecretString;
    } catch (error) {
      console.error(`Failed to fetch secret ${secretName}:`, error);
      throw new Error(`Failed to retrieve API key from Secrets Manager`);
    }
  }

  /**
   * Get Weather API key
   */
  async getWeatherAPIKey(): Promise<string> {
    const secretName = process.env.WEATHER_API_SECRET_NAME || 'weather-api-key';
    return this.getSecret(secretName);
  }

  /**
   * Clear cache (mainly for testing)
   */
  clearCache(): void {
    this.cache.clear();
  }
}

// Singleton instance for Lambda container reuse
export const secretsService = new SecretsService();
