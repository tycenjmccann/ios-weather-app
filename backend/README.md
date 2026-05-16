# Weather API Backend Service

Backend service for retrieving current weather data by geographic coordinates. Built with Node.js, TypeScript, AWS Lambda, and API Gateway.

## 🌟 Features

- **REST API Endpoint** - Clean GET /weather endpoint for weather data retrieval
- **WeatherAPI.com Integration** - Real-time weather data from reliable provider
- **Intelligent Caching** - In-memory cache with 10-minute TTL to reduce API calls
- **Secure API Key Management** - AWS Secrets Manager integration with caching
- **Comprehensive Error Handling** - Typed errors with proper HTTP status codes
- **Input Validation** - Zod schemas for runtime type safety
- **High Test Coverage** - Unit tests with >80% coverage requirement
- **Infrastructure as Code** - AWS CDK for repeatable deployments
- **Monitoring & Alarms** - CloudWatch metrics and alarms for production readiness

## 📡 API Specification

### GET /weather

Retrieve current weather conditions for a specific location.

#### Query Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| latitude | string | Yes | Latitude coordinate (-90 to 90) |
| longitude | string | Yes | Longitude coordinate (-180 to 180) |
| unit | string | No | Temperature unit: `celsius` (default) or `fahrenheit` |

#### Success Response (200 OK)

```json
{
  "success": true,
  "data": {
    "temperature": 22.5,
    "humidity": 65,
    "windSpeed": 15.5,
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

#### Error Responses

**400 Bad Request** - Invalid parameters
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": [...]
  }
}
```

**429 Too Many Requests** - Rate limit exceeded
```json
{
  "success": false,
  "error": {
    "code": "RATE_LIMIT_EXCEEDED",
    "message": "Weather API rate limit exceeded"
  }
}
```

**502 Bad Gateway** - External API error
```json
{
  "success": false,
  "error": {
    "code": "EXTERNAL_API_ERROR",
    "message": "Weather service authentication failed"
  }
}
```

**500 Internal Server Error** - Unexpected error
```json
{
  "success": false,
  "error": {
    "code": "INTERNAL_ERROR",
    "message": "An unexpected error occurred"
  }
}
```

## 🏗️ Architecture

### Components

- **API Gateway (HTTP API)** - Entry point with CORS configuration
- **Lambda Function** - Node.js 20.x runtime with TypeScript
- **Secrets Manager** - Secure storage for Weather API key
- **CloudWatch** - Logging, metrics, and alarms

### Caching Strategy

- **Layer**: In-memory cache in Lambda execution context
- **TTL**: 10 minutes (600 seconds)
- **Key Format**: `weather:{lat}:{lon}` (coordinates rounded to 2 decimals)
- **Benefits**: 
  - Reduces external API calls
  - Improves response time
  - Survives Lambda warm starts
  - Handles minor coordinate variations

### Service Architecture

```
iOS App → API Gateway → Lambda Handler → Weather Service
                                              ↓
                                         Cache Service
                                              ↓
                                    Weather Provider Service
                                              ↓
                                      WeatherAPI.com
```

## 🚀 Deployment

### Prerequisites

- Node.js 20.x or higher
- AWS CLI configured with appropriate credentials
- AWS CDK CLI (`npm install -g aws-cdk`)
- WeatherAPI.com API key

### Step 1: Install Dependencies

```bash
cd backend
npm install
```

### Step 2: Store Weather API Key

Create a secret in AWS Secrets Manager:

```bash
aws secretsmanager create-secret \
  --name weather-api-key \
  --description "API key for WeatherAPI.com" \
  --secret-string "your-weatherapi-key-here"
```

Or update an existing secret:

```bash
aws secretsmanager update-secret \
  --secret-id weather-api-key \
  --secret-string "your-weatherapi-key-here"
```

### Step 3: Build and Test

```bash
# Build TypeScript
npm run build

# Run tests
npm test

# Check coverage
npm run test:coverage
```

### Step 4: Deploy with CDK

```bash
# Bootstrap CDK (first time only)
cdk bootstrap

# Synthesize CloudFormation template
npm run synth

# Deploy to AWS
npm run deploy
```

### Step 5: Get API Endpoint

After deployment, the API endpoint URL will be in the CloudFormation outputs:

```bash
aws cloudformation describe-stacks \
  --stack-name WeatherApiStack \
  --query 'Stacks[0].Outputs[?OutputKey==`WeatherAPIURL`].OutputValue' \
  --output text
```

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
npm test

# Run with coverage report
npm run test:coverage

# Watch mode for development
npm test -- --watch
```

### Coverage Requirements

- **Lines**: 80%
- **Functions**: 80%
- **Branches**: 80%
- **Statements**: 80%

### Test Structure

```
backend/tests/
├── cache.service.test.ts          # Cache layer tests
├── weather-provider.service.test.ts # External API integration tests
├── weather.service.test.ts        # Service orchestration tests
├── get-weather.handler.test.ts    # Lambda handler tests
└── validation.test.ts             # Input validation tests
```

### Manual API Testing

```bash
# Test with curl
curl "https://your-api-id.execute-api.region.amazonaws.com/weather?latitude=37.7749&longitude=-122.4194"

# Test with different units
curl "https://your-api-id.execute-api.region.amazonaws.com/weather?latitude=51.5074&longitude=-0.1278&unit=celsius"
```

## 📊 Monitoring

### CloudWatch Metrics

- **Lambda Invocations**: Total requests
- **Lambda Errors**: Failed executions
- **Lambda Duration**: Execution time
- **Lambda Throttles**: Rate limiting events
- **API Gateway Requests**: Total API calls
- **API Gateway Latency**: Response time

### CloudWatch Alarms

The stack includes pre-configured alarms:

1. **High Error Rate Alarm**
   - Triggers when errors exceed 5 in 5 minutes
   - Action: SNS notification (configure SNS topic)

2. **Throttle Alarm**
   - Triggers on any Lambda throttling
   - Action: SNS notification

### Viewing Logs

```bash
# View recent Lambda logs
aws logs tail /aws/lambda/weather-api-get-weather --follow

# Search for errors
aws logs filter-log-events \
  --log-group-name /aws/lambda/weather-api-get-weather \
  --filter-pattern "ERROR"
```

## 🔒 Security

### API Key Management

- API keys stored in AWS Secrets Manager
- In-memory caching of secrets (5-minute TTL)
- No hardcoded credentials
- Automatic secret rotation supported

### Lambda Permissions

- Minimal IAM permissions (principle of least privilege)
- Only granted: `secretsmanager:GetSecretValue`
- No public access to Lambda function

### CORS Configuration

Current CORS settings (adjust for production):
- Allowed Origins: `*` (configure specific domains)
- Allowed Methods: `GET`
- Allowed Headers: `Content-Type`, `Authorization`
- Max Age: 1 day

## 🛠️ Development

### Project Structure

```
backend/
├── src/
│   ├── handlers/
│   │   └── get-weather.handler.ts   # Lambda entry point
│   ├── services/
│   │   ├── cache.service.ts         # In-memory caching
│   │   ├── secrets.service.ts       # AWS Secrets Manager
│   │   ├── weather-provider.service.ts # WeatherAPI.com integration
│   │   └── weather.service.ts       # Service orchestration
│   ├── types/
│   │   └── weather.types.ts         # TypeScript types and errors
│   └── validation/
│       └── schemas.ts               # Zod validation schemas
├── tests/                           # Unit tests
├── cdk/                            # Infrastructure as code
│   ├── bin/
│   │   └── app.ts                  # CDK app entry
│   └── lib/
│       └── weather-api-stack.ts    # Stack definition
├── package.json
├── tsconfig.json
├── vitest.config.ts
└── README.md
```

### Code Standards

- **TypeScript Strict Mode**: Enabled
- **ESM Modules**: import/export syntax
- **Error Handling**: Typed errors, never throw strings
- **Validation**: Zod for runtime validation
- **Logging**: Structured JSON logs

## 📝 Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| WEATHER_API_SECRET_NAME | Secrets Manager secret name | weather-api-key |
| AWS_REGION | AWS region | us-east-1 |
| NODE_OPTIONS | Node.js options | --enable-source-maps |
| LOG_LEVEL | Logging level | info |

## 🐛 Troubleshooting

### Common Issues

**Error: Weather API authentication failed**
- Check that API key is correctly stored in Secrets Manager
- Verify Lambda has permission to read the secret
- Confirm API key is valid on WeatherAPI.com

**Error: Rate limit exceeded**
- Check WeatherAPI.com plan limits
- Verify caching is working (check CloudWatch logs)
- Consider upgrading API plan

**High latency**
- Check cache hit rate in logs
- Monitor external API response times
- Consider increasing Lambda memory

**Cold start issues**
- Lambda warm starts reuse cache
- Consider provisioned concurrency for critical workloads

## 📚 API Provider

This service uses **WeatherAPI.com** for weather data.

- **Free Tier**: 1M calls/month
- **Documentation**: https://www.weatherapi.com/docs/
- **Sign Up**: https://www.weatherapi.com/signup.aspx

## 📄 License

MIT

## 👥 Contributing

1. Create feature branch
2. Write tests for new functionality
3. Ensure >80% test coverage
4. Follow TypeScript/ESLint standards
5. Submit pull request
