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

# Get stack name from config
STACK_NAME=$(grep -A 10 "\[$Environment.deploy.parameters\]" samconfig.toml | grep "stack_name" | cut -d'"' -f2)
echo "Stack name '$STACK_NAME'"

# Verify deployment
echo "Checking current stack status..."
STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text)
echo "Current stack status: $STACK_STATUS"

# Handle different stack states
if [[ "$STACK_STATUS" == "ROLLBACK_COMPLETE" ]] || [[ "$STACK_STATUS" == "ROLLBACK_FAILED" ]] || [[ "$STACK_STATUS" == "CREATE_FAILED" ]]; then
    echo "⚠️ Stack is in failed state ($STACK_STATUS). Deleting stack..."
    aws cloudformation delete-stack --stack-name $STACK_NAME
    
    echo "⏳ Waiting for stack deletion to complete..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
    echo "✅ Stack deleted successfully"
    
elif [[ "$STACK_STATUS" == "DELETE_IN_PROGRESS" ]]; then
    echo "⏳ Stack is being deleted. Waiting for completion..."
    aws cloudformation wait stack-delete-complete --stack-name $STACK_NAME
    echo "✅ Stack deletion completed"
    
elif [[ "$STACK_STATUS" == *"IN_PROGRESS"* ]]; then
    echo "⏳ Stack operation in progress ($STACK_STATUS). Waiting..."
    sleep 30
    # Retry status check
    STACK_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "DOES_NOT_EXIST")
    echo "📊 Updated stack status: $STACK_STATUS"
fi

echo "🚀 Deploying SAM application..."
sam deploy --config-env $Environment

# Verify deployment status AFTER sam deploy
FINAL_STATUS=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].StackStatus' --output text)
echo "📊 Final stack status: $FINAL_STATUS"

if [[ "$FINAL_STATUS" == *"COMPLETE"* ]]; then
    echo "✅ Deployment to '$Environment' completed successfully!"
    
    # Display stack outputs
    echo "📋 Stack Outputs:"
    aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[].{Key:OutputKey,Value:OutputValue}' --output table
else
    echo "❌ Deployment failed. Stack status: $FINAL_STATUS"
    exit 1
fi