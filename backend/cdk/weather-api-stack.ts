/**
 * CDK Stack for Weather API
 */

import * as cdk from 'aws-cdk-lib';
import * as lambda from 'aws-cdk-lib/aws-lambda';
import * as apigateway from 'aws-cdk-lib/aws-apigatewayv2';
import * as apigatewayIntegrations from 'aws-cdk-lib/aws-apigatewayv2-integrations';
import * as secretsmanager from 'aws-cdk-lib/aws-secretsmanager';
import * as logs from 'aws-cdk-lib/aws-logs';
import * as cloudwatch from 'aws-cdk-lib/aws-cloudwatch';
import { Construct } from 'constructs';
import { NodejsFunction } from 'aws-cdk-lib/aws-lambda-nodejs';

export class WeatherApiStack extends cdk.Stack {
  constructor(scope: Construct, id: string, props?: cdk.StackProps) {
    super(scope, id, props);

    // Secret for Weather API key
    const weatherApiSecret = new secretsmanager.Secret(this, 'WeatherAPIKey', {
      secretName: 'weather-api-key',
      description: 'API key for WeatherAPI.com',
    });

    // Lambda function
    const weatherFunction = new NodejsFunction(this, 'WeatherHandler', {
      entry: 'src/handlers/get-weather.handler.ts',
      handler: 'handler',
      runtime: lambda.Runtime.NODEJS_20_X,
      timeout: cdk.Duration.seconds(10),
      memorySize: 512,
      environment: {
        WEATHER_API_SECRET_NAME: weatherApiSecret.secretName,
        NODE_ENV: 'production',
      },
      bundling: {
        minify: true,
        sourceMap: true,
        target: 'es2022',
        format: 'esm',
      },
      logRetention: logs.RetentionDays.ONE_WEEK,
    });

    // Grant secret read permissions
    weatherApiSecret.grantRead(weatherFunction);

    // HTTP API Gateway
    const httpApi = new apigateway.HttpApi(this, 'WeatherHttpApi', {
      apiName: 'weather-api',
      description: 'Weather data API',
      corsPreflight: {
        allowOrigins: ['*'],
        allowMethods: [apigateway.CorsHttpMethod.GET],
        allowHeaders: ['Content-Type', 'Authorization'],
        maxAge: cdk.Duration.days(1),
      },
    });

    // Lambda integration
    const lambdaIntegration = new apigatewayIntegrations.HttpLambdaIntegration(
      'WeatherIntegration',
      weatherFunction
    );

    // Add route
    httpApi.addRoutes({
      path: '/weather',
      methods: [apigateway.HttpMethod.GET],
      integration: lambdaIntegration,
    });

    // CloudWatch Alarms
    new cloudwatch.Alarm(this, 'WeatherAPIErrors', {
      metric: weatherFunction.metricErrors({
        period: cdk.Duration.minutes(5),
      }),
      threshold: 5,
      evaluationPeriods: 1,
      alarmDescription: 'Weather API Lambda function errors',
    });

    new cloudwatch.Alarm(this, 'WeatherAPIThrottles', {
      metric: weatherFunction.metricThrottles({
        period: cdk.Duration.minutes(5),
      }),
      threshold: 10,
      evaluationPeriods: 1,
      alarmDescription: 'Weather API Lambda function throttles',
    });

    // CloudWatch Dashboard
    new cloudwatch.Dashboard(this, 'WeatherAPIDashboard', {
      dashboardName: 'WeatherAPI',
      widgets: [
        [
          new cloudwatch.GraphWidget({
            title: 'Lambda Invocations',
            left: [weatherFunction.metricInvocations()],
          }),
          new cloudwatch.GraphWidget({
            title: 'Lambda Errors',
            left: [weatherFunction.metricErrors()],
          }),
        ],
        [
          new cloudwatch.GraphWidget({
            title: 'Lambda Duration',
            left: [weatherFunction.metricDuration()],
          }),
          new cloudwatch.GraphWidget({
            title: 'API Gateway Requests',
            left: [httpApi.metricCount()],
          }),
        ],
      ],
    });

    // Outputs
    new cdk.CfnOutput(this, 'ApiEndpoint', {
      value: httpApi.apiEndpoint,
      description: 'Weather API endpoint',
    });

    new cdk.CfnOutput(this, 'SecretArn', {
      value: weatherApiSecret.secretArn,
      description: 'Weather API secret ARN',
    });
  }
}
