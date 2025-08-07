#!/bin/bash

# Navigate to serverless-app-sam directory where everything is
cd serverless-app-sam/

#✅
# 1. Show the raw JSON file (debugging)
#cat cfn-outputs.json
#✅
# Parse cfn-outputs.json to get function ARN
InitiatorFunction=$(cat cfn-outputs.json | \
  jq -r '.[] | select(.OutputKey=="InitiatorFunction") | .OutputValue')

CrawlerQueueUrl=$(cat cfn-outputs.json | \
  jq -r '.[] | select(.OutputKey=="CrawlerQueueUrl") | .OutputValue')

VisitedTableName=$(cat cfn-outputs.json | \
  jq -r '.[] | select(.OutputKey=="VisitedTableName") | .OutputValue')


echo "🎯 Using function: $InitiatorFunction"
echo "🎯 Using queue: $CrawlerQueueUrl"
echo "🎯 Using table: $VisitedTableName"

# 2. Invoke Initiator Lambda
echo -e "\n🚀 Step 1: Invoking Lambda function..."
aws lambda invoke \
  --function-name "$InitiatorFunction" \
  --payload fileb://events/event.json \
  events/response_initiator_lambda.json

echo "✅ Lambda invocation completed!"
echo "📄 Response:"
cat events/response_initiator_lambda.json

# 3. Wait and poll SQS until empty
echo -e "\n⏳ Step 2: Waiting for crawling to complete..."

echo "⏸️ Initial wait: 30 seconds to allow Lambda processing to begin..."
sleep 30  # Initial wait before polling

echo "🔍 Starting queue monitoring..."
max_polls=30  # 5 minutes max after initial wait
poll_count=0
consecutive_empty=0  # Track consecutive empty polls

while [ $poll_count -lt $max_polls ]; do
    poll_count=$((poll_count + 1))
    
    # Get queue attributes
    queue_attrs=$(aws sqs get-queue-attributes \
        --queue-url "$CrawlerQueueUrl" \
        --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible \
        --output json)
    
    visible_messages=$(echo "$queue_attrs" | jq -r '.Attributes.ApproximateNumberOfMessages // "0"')
    invisible_messages=$(echo "$queue_attrs" | jq -r '.Attributes.ApproximateNumberOfMessagesNotVisible // "0"')
    total_messages=$((visible_messages + invisible_messages))
    
    echo "📊 Poll $poll_count: $total_messages messages in queue (visible: $visible_messages, processing: $invisible_messages)"
    
    if [ $total_messages -eq 0 ]; then
        consecutive_empty=$((consecutive_empty + 1))
        if [ $consecutive_empty -ge 3 ]; then  # 3 consecutive empty polls = truly done
            echo "✅ Queue confirmed empty after 3 consecutive checks!"
            break
        fi
        echo "🔄 Empty queue detected, confirming... ($consecutive_empty/3)"
    else
        consecutive_empty=0  # Reset counter if messages found
    fi
    
    sleep 10  # Wait 10 seconds between polls
done

if [ $poll_count -ge $max_polls ]; then
    echo "⚠️ Timeout: Queue still has messages after 5 minutes + 50 second initial wait"
fi

# 4. Scan DynamoDB table and save results
echo -e "\n📊 Step 3: Scanning DynamoDB table..."
aws dynamodb scan \
    --table-name "$VisitedTableName" \
    --output json > events/response_dynamodb_table.json

echo "✅ DynamoDB scan completed!"
echo "📄 DynamoDB Results saved to events/response_dynamodb_table.json"

# 5. Analyze results
record_count=$(cat events/response_dynamodb_table.json | jq '.Count')
echo "📈 Found $record_count records in DynamoDB"

# Display first few records for debugging
echo "📋 Sample records:"
cat events/response_dynamodb_table.json | jq '.Items[0:5]'

#  6. Assert success
if [ $record_count -gt 0 ]; then
    echo "✅ Integration test PASSED: Found $record_count records in DynamoDB"
    exit 0
else
    echo "❌ Integration test FAILED: No records found in DynamoDB"
    exit 1
fi
