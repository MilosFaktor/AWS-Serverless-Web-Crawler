#!/bin/bash

set -e  # Exit on any error
echo "Starting SAM deployment to '$Environment' environment from script..."

cd serverless-app-sam/

echo "Deploying to env '$Environment'"
sam deploy --config-env $Environment

STACK_NAME=$(grep -A 10 "\[$Environment.deploy.parameters\]" samconfig.toml | grep "stack_name" | cut -d'"' -f2)
echo "Stack name '$STACK_NAME'"

echo "Deployment to '$Environment' completed successfully."