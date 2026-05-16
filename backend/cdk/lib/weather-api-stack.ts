/**
 * CDK Stack for Weather API Infrastructure
 */

import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigatewayIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as iam from 'aws-cdk-lib/aws-iam';
import { Construct } from 'constructs';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';
import * as path from 'path';

export class WeatherApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Secret for Weather API key
    const weatherApiSecret = new secretsmanager.Secret(this, 'WeatherAPIKey', {
      secretName: 'weather-api-key',
      description: 'API key for WeatherAPI.com service',
      generateSecretString: {
        secretStringTemplate: JSON.stringify({}),
        generateStringKey: 'apiKey',
      },
    });

    // Lambda function for weather endpoint
    const weatherFunction = new NodejsFunction(this, 'GetWeatherFunction', {
      functionName: 'weather-api-get-weather',
      runtime: lambda.Runtime.NODEJS_20_X,
      handler: 'handler',
      entry: path.join(__dirname, '../../src/handlers/get-weather.handler.ts'),
      timeout: cdk.Duration.seconds(30),
      memorySize: 512,
      environment: {
        WEATHER_API_SECRET_NAME: weatherApiSecret.secretName,
        NODE_OPTIONS: '--enable-source-maps',
        LOG_LEVEL: 'info',
      },
      bundling: {
        minify: true,
        sourceMap: true,
        target: 'es2022',
        externalModules: ['@aws-sdk/*'],
      },
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    // Grant Lambda permission to read secret
    weatherApiSecret.grantRead(weatherFunction);

    // HTTP API Gateway
    const httpApi = new apigateway.HttpApi(this, 'WeatherHttpApi', {
      apiName: 'weather-api',
      description: 'Weather API for iOS app',
      corsPreflight: {
        allowOrigins: ['*'], // Configure based on your needs
        allowMethods: [apigateway.CorsHttpMethod.GET],
        allowHeaders: ['Content-Type', 'Authorization'],
        maxAge: cdk.Duration.days(1),
      },
    });

    // Lambda integration
    const weatherIntegration = new apigatewayIntegrations.HttpLambdaIntegration(
      'WeatherIntegration',
      weatherFunction
    );

    // Add route
    httpApi.addRoutes({
      path: '/weather',
      methods: [apigateway.HttpMethod.GET],
      integration: weatherIntegration,
    });

    // CloudWatch alarms for monitoring
    const errorMetric = weatherFunction.metricErrors({
      period: cdk.Duration.minutes(5),
    });

    new cdk.aws_cloudwatch.Alarm(this, 'WeatherFunctionErrorAlarm', {
      metric: errorMetric,
      threshold: 5,
      evaluationPeriods: 1,
      alarmDescription: 'Alert when weather function errors exceed threshold',
      treatMissingData: cdk.aws_cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    const throttleMetric = weatherFunction.metricThrottles({
      period: cdk.Duration.minutes(5),
    });

    new cdk.aws_cloudwatch.Alarm(this, 'WeatherFunctionThrottleAlarm', {
      metric: throttleMetric,
      threshold: 1,
      evaluationPeriods: 1,
      alarmDescription: 'Alert when weather function is throttled',
      treatMissingData: cdk.aws_cloudwatch.TreatMissingData.NOT_BREACHING,
    });

    // Outputs
    new cdk.CfnOutput(this, 'APIEndpoint', {
      value: httpApi.apiEndpoint,
      description: 'Weather API endpoint URL',
      exportName: 'WeatherAPIEndpoint',
    });

    new cdk.CfnOutput(this, 'WeatherAPIURL', {
      value: `${httpApi.apiEndpoint}/weather`,
      description: 'Full weather endpoint URL',
    });

    new cdk.CfnOutput(this, 'SecretName', {
      value: weatherApiSecret.secretName,
      description: 'Secrets Manager secret name for Weather API key',
    });

    new cdk.CfnOutput(this, 'FunctionName', {
      value: weatherFunction.functionName,
      description: 'Weather Lambda function name',
    });
  }
}
