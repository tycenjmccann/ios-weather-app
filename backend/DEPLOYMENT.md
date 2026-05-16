# Weather API Deployment Guide

Complete guide for deploying the Weather API backend service to AWS.

## Prerequisites

### Required Tools

- **Node.js**: Version 20.x or higher
- **npm**: Version 9.x or higher
- **AWS CLI**: Version 2.x ([Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html))
- **AWS CDK**: Version 2.x (`npm install -g aws-cdk`)
- **Git**: For version control

### AWS Account Requirements

- Active AWS account
- IAM user with appropriate permissions:
  - Lambda function management
  - API Gateway management
  - Secrets Manager access
  - CloudFormation stack management
  - CloudWatch logs and metrics
  - IAM role creation

### WeatherAPI.com Account

1. Sign up at [WeatherAPI.com](https://www.weatherapi.com/signup.aspx)
2. Get your API key from the dashboard
3. Note the free tier limits (1M calls/month)

## Step-by-Step Deployment

### 1. Configure AWS Credentials

```bash
# Configure AWS CLI with your credentials
aws configure

# Enter your credentials when prompted:
# AWS Access Key ID: YOUR_ACCESS_KEY
# AWS Secret Access Key: YOUR_SECRET_KEY
# Default region name: us-east-1
# Default output format: json

# Verify configuration
aws sts get-caller-identity
```

### 2. Clone and Setup Repository

```bash
# Clone the repository
git clone https://github.com/tycenjmccann/ios-weather-app.git
cd ios-weather-app/backend

# Install dependencies
npm install
```

### 3. Store Weather API Key in Secrets Manager

```bash
# Create the secret
aws secretsmanager create-secret \
  --name weather-api-key \
  --description "API key for WeatherAPI.com service" \
  --secret-string "YOUR_WEATHERAPI_KEY_HERE" \
  --region us-east-1

# Verify the secret was created
aws secretsmanager describe-secret \
  --secret-id weather-api-key \
  --region us-east-1
```

**Alternative: Using AWS Console**
1. Go to AWS Secrets Manager console
2. Click "Store a new secret"
3. Select "Other type of secret"
4. Add key: `apiKey`, value: `YOUR_WEATHERAPI_KEY`
5. Name: `weather-api-key`
6. Click "Store"

### 4. Bootstrap CDK (First Time Only)

If this is your first time using CDK in this AWS account/region:

```bash
# Bootstrap CDK
cdk bootstrap aws://ACCOUNT-NUMBER/us-east-1

# Replace ACCOUNT-NUMBER with your AWS account ID
# You can get your account ID with:
aws sts get-caller-identity --query Account --output text
```

### 5. Build and Test

```bash
# Build TypeScript
npm run build

# Run unit tests
npm test

# Check test coverage (must be >80%)
npm run test:coverage

# Run linter
npm run lint
```

### 6. Review Infrastructure

```bash
# Generate CloudFormation template
npm run synth

# Review the synthesized template
cat cdk.out/WeatherApiStack.template.json
```

### 7. Deploy to AWS

```bash
# Deploy the stack
npm run deploy

# For production deployment (no approval prompts)
npm run deploy:prod
```

The deployment will:
1. Create Lambda function
2. Set up API Gateway HTTP API
3. Configure IAM roles and permissions
4. Set up CloudWatch logs and alarms
5. Output the API endpoint URL

### 8. Verify Deployment

```bash
# Get the API endpoint from CloudFormation outputs
export API_ENDPOINT=$(aws cloudformation describe-stacks \
  --stack-name WeatherApiStack \
  --query 'Stacks[0].Outputs[?OutputKey==`WeatherAPIURL`].OutputValue' \
  --output text)

echo "API Endpoint: $API_ENDPOINT"

# Test the API
curl "${API_ENDPOINT}?latitude=37.7749&longitude=-122.4194"
```

Expected response:
```json
{
  "success": true,
  "data": {
    "temperature": 15.5,
    "humidity": 72,
    "windSpeed": 12.3,
    "condition": "Partly cloudy",
    "conditionCode": 1003,
    "timestamp": "2024-01-15T10:00:00Z",
    "location": {
      "latitude": 37.77,
      "longitude": -122.42
    }
  }
}
```

### 9. Run Integration Tests

```bash
# Set API endpoint and run integration tests
API_ENDPOINT=$API_ENDPOINT npm run test:integration
```

## Post-Deployment Configuration

### 1. Update CORS Settings (if needed)

Edit `backend/cdk/lib/weather-api-stack.ts`:

```typescript
corsPreflight: {
  allowOrigins: ['https://your-ios-app-domain.com'], // Update this
  allowMethods: [apigateway.CorsHttpMethod.GET],
  allowHeaders: ['Content-Type', 'Authorization'],
  maxAge: cdk.Duration.days(1),
}
```

Then redeploy:
```bash
npm run deploy
```

### 2. Set Up CloudWatch Alarms (Optional)

Configure SNS topic for alarm notifications:

```bash
# Create SNS topic
aws sns create-topic --name weather-api-alarms

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:ACCOUNT-ID:weather-api-alarms \
  --protocol email \
  --notification-endpoint your-email@example.com

# Update the CDK stack to use this topic for alarms
```

### 3. Enable AWS X-Ray (Optional)

For detailed tracing, enable X-Ray in the Lambda function:

```typescript
// In weather-api-stack.ts
const weatherFunction = new NodejsFunction(this, 'GetWeatherFunction', {
  // ... other config
  tracing: lambda.Tracing.ACTIVE,
});
```

Redeploy after changes.

## Environment-Specific Deployments

### Development Environment

```bash
# Deploy to dev
cdk deploy WeatherApiStack-dev --context environment=dev
```

### Production Environment

```bash
# Deploy to production with additional safeguards
cdk deploy WeatherApiStack-prod \
  --context environment=prod \
  --require-approval broadening
```

## Monitoring and Maintenance

### View Logs

```bash
# Tail Lambda logs
aws logs tail /aws/lambda/weather-api-get-weather --follow

# View last 10 minutes of logs
aws logs tail /aws/lambda/weather-api-get-weather \
  --since 10m \
  --format short
```

### Check Metrics

```bash
# Get Lambda invocation count (last hour)
aws cloudwatch get-metric-statistics \
  --namespace AWS/Lambda \
  --metric-name Invocations \
  --dimensions Name=FunctionName,Value=weather-api-get-weather \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 3600 \
  --statistics Sum
```

### Update Weather API Key

```bash
# Update the secret
aws secretsmanager update-secret \
  --secret-id weather-api-key \
  --secret-string "NEW_API_KEY_HERE"

# Lambda will pick up the new key within 5 minutes (cache TTL)
```

## Rollback Procedure

If deployment fails or issues occur:

```bash
# Rollback to previous version
aws cloudformation rollback-stack --stack-name WeatherApiStack

# Or delete and redeploy
npm run destroy
npm run deploy
```

## Cleanup and Teardown

To remove all resources:

```bash
# Destroy the stack
npm run destroy

# Optionally delete the secret
aws secretsmanager delete-secret \
  --secret-id weather-api-key \
  --force-delete-without-recovery
```

## Troubleshooting

### Common Issues

**1. CDK Bootstrap Error**
```
Error: This stack uses assets, so the toolkit stack must be deployed
```
Solution: Run `cdk bootstrap`

**2. Permissions Error**
```
User is not authorized to perform: lambda:CreateFunction
```
Solution: Ensure your IAM user has the required permissions

**3. Secret Not Found**
```
Error: Secrets Manager can't find the specified secret
```
Solution: Verify the secret exists and the name matches exactly

**4. API Returns 502**
```
{"success": false, "error": {"code": "EXTERNAL_API_ERROR"}}
```
Solution: Check that Weather API key is valid and properly stored

### Debug Mode

Enable detailed logging:

```bash
# Update Lambda environment variable
aws lambda update-function-configuration \
  --function-name weather-api-get-weather \
  --environment Variables={LOG_LEVEL=debug,WEATHER_API_SECRET_NAME=weather-api-key}
```

### Performance Issues

If experiencing high latency:

1. Check cache hit rate in logs
2. Monitor WeatherAPI.com response times
3. Consider increasing Lambda memory (affects CPU)
4. Enable Lambda provisioned concurrency for consistent performance

## Cost Estimation

### AWS Costs (Approximate)

- **Lambda**: $0.20 per 1M requests + $0.0000166667 per GB-second
- **API Gateway**: $1.00 per million requests
- **CloudWatch Logs**: $0.50 per GB ingested
- **Secrets Manager**: $0.40 per secret per month

**Example Monthly Cost (10,000 requests/day):**
- Lambda: ~$1.50
- API Gateway: ~$0.30
- CloudWatch: ~$0.50
- Secrets Manager: $0.40
- **Total: ~$2.70/month**

### WeatherAPI.com Costs

- Free tier: 1M calls/month (sufficient for most apps)
- Paid plans: Start at $4/month for 10M calls

## Security Best Practices

1. **Never commit API keys** to version control
2. **Rotate API keys** regularly (every 90 days)
3. **Use least privilege** IAM policies
4. **Enable CloudTrail** for audit logging
5. **Configure CORS** restrictively in production
6. **Set up billing alarms** to avoid unexpected costs
7. **Enable AWS WAF** for API Gateway if needed

## Support and Resources

- [AWS CDK Documentation](https://docs.aws.amazon.com/cdk/)
- [AWS Lambda Best Practices](https://docs.aws.amazon.com/lambda/latest/dg/best-practices.html)
- [WeatherAPI.com Documentation](https://www.weatherapi.com/docs/)
- [Project Issues](https://github.com/tycenjmccann/ios-weather-app/issues)

## CI/CD Pipeline

The repository includes a GitHub Actions workflow for automated deployments. Configure these secrets in your repository:

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Commits to `main` branch will automatically deploy to production.
