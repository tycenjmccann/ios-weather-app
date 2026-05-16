#!/usr/bin/env node
import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { WeatherApiStack } from './weather-api-stack.js';

const app = new cdk.App();

new WeatherApiStack(app, 'WeatherApiStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Weather API backend service',
});
