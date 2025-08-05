#!/bin/bash

set -e  # Exit on any error
echo "Starting SAM deployment to '$Environment' environment from script..."

# Ensure we're in the right directory
if [ ! -f "template.yaml" ]; then
    echo "Navigating to serverless-app-sam directory..."
    cd serverless-app-sam/
fi

echo "Deploying to env '$Environment'"
echo "Using samconfig.toml configuration"

sam deploy --config-env $Environment

# Get stack name from config
STACK_NAME=$(grep -A 10 "\[$Environment.deploy.parameters\]" samconfig.toml | grep "stack_name" | cut -d'"' -f2)
echo "Stack name '$STACK_NAME'"

# Verify deployment
echo "Verifying deployment..."
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text)
echo "Stack status: $STACK_STATUS"

if [[ "$STACK_STATUS" == *"COMPLETE"* ]]; then
    echo "✅ Deployment to '$Environment' completed successfully!"
else
    echo "❌ Deployment might have issues. Stack status: $STACK_STATUS"
    exit 1
fi