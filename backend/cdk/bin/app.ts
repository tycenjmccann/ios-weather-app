#!/usr/bin/env node
/**
 * CDK App entry point for Weather API
 */

import 'source-map-support/register';
import * as cdk from 'aws-cdk-lib';
import { WeatherApiStack } from './lib/weather-api-stack';

const app = new cdk.App();

new WeatherApiStack(app, 'WeatherApiStack', {
  env: {
    account: process.env.CDK_DEFAULT_ACCOUNT,
    region: process.env.CDK_DEFAULT_REGION || 'us-east-1',
  },
  description: 'Weather API backend service infrastructure',
});
