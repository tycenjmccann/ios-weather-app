# Weather API Backend

Backend service for retrieving current weather data by coordinates.

## Features

- REST API endpoint for weather data retrieval  
- Integration with WeatherAPI.com
- In-memory caching (10-minute TTL)
- Secure API key management with AWS Secrets Manager
- Comprehensive error handling with Zod validation
- Unit tests with >80% coverage
- AWS Lambda + API Gateway deployment
- CloudWatch monitoring and alarms

## API Endpoint

### GET /weather

**Query Parameters:**
- `latitude` (required): -90 to 90
- `longitude` (required): -180 to 180  
- `unit` (optional): celsius or fahrenheit

**Success Response (200):**
```json
{
  "success": true,
  "data": {
    "temperature": 22.5,
    "humidity": 65,
    "windSpeed": 15,
    "condition": "Partly cloudy",
    "conditionCode": 1003,
    "timestamp": "2024-01-15T10:00:00Z",
    "location": {
      "latitude": 37.7749,
      "longitude": -122.4194
    }
  }
}
```

## Architecture

- **API Gateway (HTTP API)** - REST endpoint with CORS
- **Lambda Function** - Node.js 20.x with TypeScript
- **Secrets Manager** - Secure API key storage
- **CloudWatch** - Logging, metrics, alarms

### Caching
- In-memory cache with 10-minute TTL
- Cache key: `weather:{lat}:{lon}` (rounded to 2 decimals)
- Survives Lambda warm starts

## Deployment

1. Store Weather API key in Secrets Manager:
```bash
aws secretsmanager create-secret \
  --name weather-api-key \
  --secret-string "your-api-key"
```

2. Deploy with CDK:
```bash
npm install
npm run deploy
```

## Testing

```bash
npm test
npm run test:coverage
```

## Monitoring

CloudWatch dashboard includes:
- Lambda invocations, errors, duration
- API Gateway requests
- Alarms for errors and throttles
