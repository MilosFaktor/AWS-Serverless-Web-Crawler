#!/bin/bash
# filepath: /home/milos/Desktop_Ubuntu/aws/public_projects/Serverless_Web_Crawler/codepipeline/scripts/delete_stack.sh

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

# Pre-cleanup: Remove Lambda Event Source Mappings manually
echo "🧹 Pre-cleanup: Removing Lambda Event Source Mappings..."
CRAWLER_FUNCTION_NAME=$(aws cloudformation describe-stack-resources --stack-name "$STACK_NAME" --logical-resource-id "CrawlerFunction" --query 'StackResources[0].PhysicalResourceId' --output text 2>/dev/null || echo "")

if [ ! -z "$CRAWLER_FUNCTION_NAME" ]; then
    echo "🔧 Found Lambda function: $CRAWLER_FUNCTION_NAME"
    
    # List and delete event source mappings
    EVENT_SOURCE_MAPPINGS=$(aws lambda list-event-source-mappings --function-name "$CRAWLER_FUNCTION_NAME" --query 'EventSourceMappings[].UUID' --output text 2>/dev/null || echo "")
    
    if [ ! -z "$EVENT_SOURCE_MAPPINGS" ]; then
        for UUID in $EVENT_SOURCE_MAPPINGS; do
            echo "🗑️ Deleting event source mapping: $UUID"
            aws lambda delete-event-source-mapping --uuid "$UUID" || echo "⚠️ Failed to delete mapping $UUID"
        done
        
        # Wait for event source mappings to be deleted
        echo "⏳ Waiting for event source mappings to be deleted..."
        sleep 10
    else
        echo "ℹ️ No event source mappings found"
    fi
else
    echo "ℹ️ CrawlerFunction not found or already deleted"
fi

# Delete CloudFormation stack
echo "🗑️ Deleting stack: $STACK_NAME"
sam delete --config-env $Environment --no-prompts || {
    echo "⚠️ Initial delete failed, attempting force cleanup..."
    
    # If sam delete fails, try CloudFormation directly
    echo "🔨 Attempting direct CloudFormation deletion..."
    aws cloudformation delete-stack --stack-name "$STACK_NAME"
    
    # Wait for deletion with timeout
    echo "⏳ Waiting for stack deletion to complete (with timeout)..."
    timeout 300 aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME" || {
        echo "⚠️ Stack deletion timed out or failed"
        
        # Check final status
        STACK_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text 2>/dev/null || echo "STACK_NOT_FOUND")
        echo "📊 Final stack status: $STACK_STATUS"
        
        if [ "$STACK_STATUS" = "DELETE_FAILED" ]; then
            echo "❌ Stack deletion failed. Manual cleanup may be required."
            echo "🔍 Failed resources:"
            aws cloudformation describe-stack-events --stack-name "$STACK_NAME" --query 'StackEvents[?ResourceStatus==`DELETE_FAILED`].{Resource:LogicalResourceId,Reason:ResourceStatusReason}' --output table || echo "Could not get failed resources"
            exit 1
        elif [ "$STACK_STATUS" = "STACK_NOT_FOUND" ]; then
            echo "✅ Stack successfully deleted!"
        else
            echo "⚠️ Stack in unexpected state: $STACK_STATUS"
            exit 1
        fi
    }
}

# Verify deletion completed
echo "⏳ Final verification..."
if aws cloudformation describe-stacks --stack-name "$STACK_NAME" >/dev/null 2>&1; then
    FINAL_STATUS=$(aws cloudformation describe-stacks --stack-name "$STACK_NAME" --query 'Stacks[0].StackStatus' --output text)
    echo "⚠️ Stack still exists with status: $FINAL_STATUS"
    exit 1
else
    echo "✅ Stack deletion completed successfully!"
    echo "🧹 Environment '$Environment' has been cleaned up."
fi