import { v4 as uuidv4 } from 'uuid';
import { DynamoDBClient, BatchGetItemCommand, BatchWriteItemCommand } from '@aws-sdk/client-dynamodb';
import { SQSClient, SendMessageBatchCommand } from '@aws-sdk/client-sqs';
import { normalizeURL } from './visitedURL.mjs';

const ddbClient = new DynamoDBClient({ region: 'eu-north-1' });
const sqsClient = new SQSClient({ region: 'eu-north-1' });

export async function markAllVisited(targets, runId, sourceUrl, rootUrl) {
    const putRequests = targets.map(url => ({
        PutRequest: {
            Item: {
                visitedURL: { S: normalizeURL(url) },
                runId: { S: runId },
                sourceURL: { S: normalizeURL(sourceUrl) },
                rootURL: { S: normalizeURL(rootUrl) },
            },
        },
    }));

    await ddbClient.send(new BatchWriteItemCommand({ RequestItems: { VisitedURLs: putRequests } }));
}

export async function enqueueAll(targets, runId, sourceUrl, rootURL, sqsUrl) {
    const messages = targets.map(link => ({
        Id: uuidv4(),
        MessageBody: JSON.stringify({
            visitedURL: link.visitedURL,
            sourceURL: sourceUrl,
            rootURL: rootURL,
            runId,
            depth: link.depth || 1,
        }),
    }));

    const chunkSize = 10;
    for (let i = 0; i < messages.length; i += chunkSize) {
        const chunk = messages.slice(i, i + chunkSize);
        try {
            await sqsClient.send(new SendMessageBatchCommand({
                QueueUrl: sqsUrl,
                Entries: chunk,
            }));
            console.log(`Successfully sent batch of ${chunk.length} messages to SQS.`);
        } catch (error) {
            console.error(`Error sending batch of messages to SQS:`, error);
            throw error;
        }
    }
}

export async function batchGetItems(urls, runId) {
    if (!urls.length) return [];

    const keys = urls.map(url => ({
        visitedURL: { S: normalizeURL(url) },
        runId: { S: runId },
    }));

    try {
        const response = await ddbClient.send(new BatchGetItemCommand({
            RequestItems: { VisitedURLs: { Keys: keys } },
        }));
        const results = response.Responses?.VisitedURLs?.map(item => item.visitedURL.S) || [];
        console.log(`BatchGetItems response for runId: ${runId}: ${JSON.stringify(results)}`);
        return results;
    } catch (error) {
        console.error(`Error in batchGetItems: ${error.message}`, error);
        return [];
    }
}
