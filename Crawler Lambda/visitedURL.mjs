import { DynamoDBClient, GetItemCommand, PutItemCommand } from '@aws-sdk/client-dynamodb';

const ddbClient = new DynamoDBClient({ region: 'eu-north-1' });




/**
 * Check if a URL has been visited by querying DynamoDB.
 * @param {string} url - The URL to check.
 * @param {number} depth - The depth level of the crawl.
 * @returns {boolean} - Returns true if the URL was visited at this depth, otherwise false.
 */
export async function isVisited(url, runId) {
    const params = {
        TableName: 'VisitedURLs',
        Key: {
            visitedURL: { S: url },
            runId: { S: runId },
        },
    };

    try {
        const result = await ddbClient.send(new GetItemCommand(params));
        const isVisited = !!result.Item;
        console.log(`Checked isVisited for URL: ${url}, runId: ${runId}, Result: ${isVisited}`);
        return isVisited;
    } catch (error) {
        console.error(`Error in isVisited for URL: ${url}, runId: ${runId}: ${error.message}`, error);
        return false; // Default to not visited on error
    }
}




/**
 * Mark a URL as visited by writing it to DynamoDB.
 * @param {string} url - The URL to mark as visited.
 * @param {number} depth - The depth level of the crawl.
 */
export async function markVisited(url, runId, rootURL, sourceURL = null) {
    const params = {
        TableName: 'VisitedURLs',
        Item: {
            visitedURL: { S: url },
            runId: { S: runId },
            rootURL: { S: rootURL },
            sourceURL: { S: sourceURL || 'null' },
        },
    };

    try {
        await ddbClient.send(new PutItemCommand(params));
        console.log(`Successfully marked as visited: ${JSON.stringify(params.Item)}`);
    } catch (error) {
        console.error(`Error in markVisited for URL: ${url}, runId: ${runId}: ${error.message}`, error);
    }
}





/**
 * Normalize URLs to avoid duplicate tracking due to minor differences.
 * @param {string} url - The URL to normalize.
 * @returns {string} - The normalized URL.
 */
export function normalizeURL(url) {
    if (typeof url !== 'string') {
        console.warn(`Invalid URL passed to normalizeURL: ${JSON.stringify(url)}`);
        return '';
    }
    try {
        const parsedURL = new URL(url);
        parsedURL.hash = ''; // Remove any hash
        return parsedURL.toString().toLowerCase(); // Convert to lowercase
    } catch (err) {
        console.warn(`URL normalization failed for ${url}: ${err}`);
        return url.toLowerCase ? url.toLowerCase() : ''; // Fallback to lowercase if possible
    }
}
