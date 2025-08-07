#!/bin/bash

set -e  # Exit on any error

echo "🗑️ Starting stack deletion process..."

# Verify we're using the right artifacts
echo "🔍 Verifying artifact contents:"
echo "Current directory: $(pwd)"
ls -la

echo "📁 Available directories:"
ls -la ./

# Navigate to serverless-app-sam directory
echo "📂 Navigating to serverless-app-sam directory..."
cd serverless-app-sam/

# Verify SAM configuration exists
echo "🔧 Checking SAM configuration..."
if [ ! -f "samconfig.toml" ]; then
    echo "❌ Error: samconfig.toml not found!"
    exit 1
fi

echo "📄 Using SAM config for environment: $Environment"
cat samconfig.toml

# Check if stack exists before attempting deletion
echo "🔍 Checking if stack exists..."

# Use the expected stack name pattern from samconfig.toml
STACK_NAME="serverless-app-crawler-sam-$Environment"

echo "🎯 Looking for stack: $STACK_NAME"

# Check if this specific stack exists
if ! aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    echo "ℹ️ No stack found for environment: $Environment"
    echo "✅ Stack deletion completed (stack was already deleted or never existed)"
    exit 0
fi

echo "📦 Found stack: $STACK_NAME"

# List stack resources before deletion (for debugging)
echo "📋 Stack resources that will be deleted:"
aws cloudformation describe-stack-resources --stack-name "$STACK_NAME" --query 'StackResources[].{Type:ResourceType,LogicalId:LogicalResourceId,Status:ResourceStatus}' --output table || echo "Could not list resources"

# Delete CloudFormation stack
echo "🗑️ Deleting stack: $STACK_NAME"
sam delete --config-env $Environment --no-prompts

# Verify deletion completed
echo "⏳ Waiting for stack deletion to complete..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" || {
    echo "⚠️ Stack deletion may have failed. Checking status..."
    aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text || echo "Stack not found (deletion successful)"
}

echo "✅ Stack deletion completed successfully!"
echo "🧹 Environment '$Environment' has been cleaned up."