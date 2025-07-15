import chromium from '@sparticuz/chromium';
import puppeteer from 'puppeteer-core';
import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { enqueueAll, batchGetItems } from './utils.mjs';
import { markVisited, isVisited, normalizeURL } from './visitedURL.mjs';

// --- CONFIGURATIONS ---
// Maximum depth of crawling from the root URL
const MAX_DEPTH = 3;

// SQS URL where discovered links are queued
const sqsUrl = 'URL of SQS';

// DynamoDB Client for reading/writing visited URLs
const ddbClient = new DynamoDBClient({ region: 'eu-north-1' });

// --- HELPER FUNCTIONS ---
async function scrollToEnd(page) {
    // Scroll through the page to ensure lazy-loaded content is fully loaded
    await page.evaluate(async () => {
        await new Promise((resolve) => {
            let totalHeight = 0;
            let distance = 200;
            const timer = setInterval(() => {
                window.scrollBy(0, distance);
                totalHeight += distance;
                if (totalHeight >= document.body.scrollHeight) {
                    clearInterval(timer);
                    resolve();
                }
            }, 200);
        });
    });
}

async function loadPage(page, url) {
    // Load the page and wait until network is mostly idle
    try {
        await page.goto(url, { waitUntil: 'networkidle2', timeout: 12000 });
        await scrollToEnd(page);
        return true;
    } catch {
        return false;
    }
}

function getHostname(url) {
    try {
        return new URL(url).hostname;
    } catch {
        return null;
    }
}

async function extractLinks(page, rootURL) {
    // Extract all internal, valid HTTP links from the current page
    const rootHostname = getHostname(rootURL);
    const links = await page.evaluate((rootURL) => {
        const elements = Array.from(document.querySelectorAll('a[href], a[to]'));
        return elements.map(el => el.getAttribute('href') || el.getAttribute('to'))
            .filter(link => link && !link.startsWith('#') && !link.startsWith('mailto'))
            .map(link => link.startsWith('/') ? new URL(link, rootURL).href : link);
    }, rootURL);

    // Filter out links that end in .pdf
    const filteredLinks = Array.from(new Set(links))
        .map(l => normalizeURL(l))
        .filter(l => l.startsWith('http') && !l.toLowerCase().endsWith('.pdf'));

    console.log(`Extracted ${filteredLinks.length} valid links (excluding PDFs) from ${rootURL}`);

    return filteredLinks.filter(link => getHostname(link) === getHostname(rootURL));
}


async function crawlPage(browser, url, rootURL, depth, runId, sourceURL) {
    // --- ROADMAP / FLOW ---
    // 1. Check if depth exceeded MAX_DEPTH; if so, mark visited and skip
    // 2. Check if URL already visited (skip if visited)
    // 3. Open new page in browser, attempt to load URL
    // 4. If load successful, extract internal links
    // 5. Mark current URL as visited
    // 6. Find which links are unvisited, enqueue them to SQS
    // 7. Close the page and return

    depth = depth || 1;
    if (depth > MAX_DEPTH) {
        await markVisited(url, runId, rootURL, sourceURL); 
        return;
    }

    let alreadyVisited = false;
    if (!(url === rootURL && depth === 1)) {
        alreadyVisited = await isVisited(url, runId);
    }

    if (alreadyVisited) return;

    const page = await browser.newPage();


    await page.setRequestInterception(true);

    page.on('request', (req) => {
        const resourceType = req.resourceType();
        if (resourceType === 'image' || resourceType === 'font' || resourceType === 'media' || resourceType === 'stylesheet') {
            req.abort();
        } else {
            req.continue();
        }
    });

    try {
        const success = await loadPage(page, url);
        if (!success) {
            await markVisited(url, runId, rootURL, sourceURL);
            return;
        }

        const links = await extractLinks(page, rootURL);
        await markVisited(url, runId, rootURL, sourceURL);

        const visitedLinks = await batchGetItems(links, runId);
        const visitedSet = new Set(visitedLinks);

        const unvisitedLinks = links
            .filter(link => !visitedSet.has(link))
            .map(link => ({
                visitedURL: link,
                sourceURL: url,
                rootURL,
                runId,
                depth: depth + 1,
            }));

        if (unvisitedLinks.length > 0) {
            await enqueueAll(unvisitedLinks, runId, url, rootURL, sqsUrl);
        }

    } catch {
        await markVisited(url, runId, rootURL, sourceURL);
    } finally {
        await page.close();
    }
}

// --- LAMBDA HANDLER ---
export const handler = async (event) => {
    try {
        const messages = event.Records.map(record => JSON.parse(record.body));
        const batchSize = 10;

        const browser = await puppeteer.launch({
            executablePath: await chromium.executablePath(),
            args: chromium.args,
            defaultViewport: chromium.defaultViewport,
            headless: chromium.headless,
        });

        for (let i = 0; i < messages.length; i += batchSize) {
            const batch = messages.slice(i, i + batchSize);
            for (const message of batch) {
                const { visitedURL, runId, rootURL, depth, sourceURL } = message;
                await crawlPage(browser, visitedURL, rootURL, depth, runId, sourceURL);
            }
        }

        // Brief pause before closing
        await new Promise(resolve => setTimeout(resolve, 500));
        await browser.close();

        return { statusCode: 200, body: JSON.stringify({ message: `Processed ${messages.length} links` }) };
    } catch (error) {
        return { statusCode: 500, body: JSON.stringify({ error: error.message }) };
    }
};
