# 📓 BUILD-JOURNAL.md – Serverless Web Crawler (Version 2)

This journal documents the complete journey of developing **Version 2** of the Serverless Web Crawler using AWS SAM, Node.js, and Python. It expands on the earlier version by introducing better automation, concurrency tuning, and layered local development.

---

## 🛠️ PHASE 1: Preparing the Repo & SAM Setup

### 🔹 Objective
Rebuild the previously working crawler from scratch using **AWS SAM (Serverless Application Model)** for improved versioning, automation, and deployment consistency.

### 🔹 Project Structure Created

```bash
serverless-crawler-v2/
├── template.yaml                  # SAM infrastructure template
├── initiator/                     # Python Lambda
│   ├── app.py
│   ├── requirements.txt
│   └── __init__.py
├── crawler/                       # Node.js Lambda
│   ├── index.js
│   └── package.json
└── README.md
```

### 🔹 `sam init` Not Used
This project was created **manually** (no `sam init`) to maintain full control over file structure.

---

## 🧪 PHASE 2: Local Development & First Tests

### 🔹 Environment Setup

- Created `.env.json` file with:
```json
{
  "REGION": "eu-central-1",
  "SQS_URL": "https://sqs.eu-central-1.amazonaws.com/123456789012/MyQueue",
  "MAX_DEPTH": "2",
  "TIMEOUT": "10000"
}
```

### 🔹 Local Testing
Used:
```bash
sam local invoke InitiatorFunction --env-vars .env.json -e events/test-event.json
sam local invoke CrawlerFunction --env-vars .env.json -e events/test-event-crawler.json
```

- Debugging inside Docker container worked well.
- Created Docker volume for DynamoDB local (future use).
- Verified logs in terminal — Puppeteer launched correctly.

---

## ⚙️ PHASE 3: SAM Deployment

### 🔹 Build
```bash
sam build
```

- Automatically packaged Python and Node.js functions using `requirements.txt` and `package.json`.

### 🔹 Deploy
```bash
sam deploy --guided
```

- Provided stack name, region, S3 bucket, capabilities.
- IAM roles created and connected.
- Successfully deployed full infrastructure:
  - Initiator Lambda
  - Crawler Lambda
  - SQS Queue
  - DLQ
  - DynamoDB
  - IAM Roles

---

## 🕸️ PHASE 4: Crawling Behavior & Concurrency

### 🔹 Reserved Concurrency
```yaml
ReservedConcurrentExecutions: 1
```

- This fixed parallel execution bugs in Crawler Lambda.
- Prevents simultaneous Puppeteer containers from overloading small Lambda instance.
- Helped avoid rate-limiting or runaway costs during testing.

### 🔹 React Router Page Support
- Crawled a React-based site deployed to S3.
- Dynamic `<Link to="..." />` pages were fully parsed.
- Puppeteer + Sparticuz Chromium handled navigation & JS rendering well.

---

## 🛡️ PHASE 5: DLQ & Retry Behavior

### 🔹 Dead Letter Queue
- SAM template defined DLQ + redrive policy.
- Lambda async failure routed correctly to DLQ.
- Manually tested DLQ message contents in AWS Console.
- Future: Add alert or automated redrive script.

---

## 📁 PHASE 6: Local Debugging, Versioning & Git

### 🔹 Git Branching Strategy
- Used `main` for latest stable version.
- Created `v1`, `v2`, `crawler-dev` branches.
- Committed code regularly during SAM testing phases.

### 🔹 SAM Debug Tips

- Use `sam local invoke` for isolated Lambda testing.
- Environment variables are loaded from `.env.json`.
- Log output appears in Docker stdout.
- Avoid `sam start-api` — not needed for SQS/Async triggers.

---

## ✅ PHASE 7: Deployment Outcome

### 🔹 Successfully Crawled:
- `cloudnecessities.com` (my site)
- `drugastrana.rs` (static/dynamic mix)

All links saved to DynamoDB.
Crawler gracefully shut down after max depth.
CloudWatch showed optimized Lambda runtimes (~12s).

---

## 🧠 LESSONS LEARNED

- ✅ SAM automatically installs Python/Node dependencies — no need for CodeBuild.
- ✅ Setting `ReservedConcurrentExecutions` to 1 prevents overloading Puppeteer.
- ✅ Node.js + Puppeteer + Sparticuz Chromium beats Python + Selenium on AWS Lambda.
- ✅ DLQ config is essential to capture failed crawls.
- ✅ Using `sam local invoke` is perfect for testing individual Lambdas.

---

## ⚠️ ETHICAL NOTICE

> This crawler is for **educational/demo use only**.  
> Do **not** crawl external websites repeatedly without permission.  
> Example sites used (e.g., drugastrana.rs) were crawled minimally.  

### ❗️Domain Scope & Caution

- The crawler is hard-coded to **only stay within the root domain** provided in the test event (e.g., `example.com`).  
- It will **not follow external links** (e.g., YouTube, Google, etc.).
- You can configure the crawl depth using the `MAX_DEPTH` environment variable.  
  - Example: `MAX_DEPTH=2` limits crawling to two levels deep.

> ⚠️ **Important:** If you accidentally launch the crawler on a large-scale site like Google or Wikipedia:
> - You might quickly exceed your Lambda free tier.
> - The site may throttle or block your IP.
> - You could unintentionally generate significant traffic.

🛑 Do not crawl high-traffic or sensitive websites without **explicit permission**.

This project is designed for safe experimentation on **your own site** or small test environments only. In future versions, additional safeguards like **rate limiting**, **robots.txt checking**, or **IP throttling** may be added.

---

## 🛣️ FUTURE PLANS

- Add API Gateway trigger for user input (root URL)
- Add IP-based rate limiting (via API Gateway or Lambda throttle)
- Add optional S3 output with crawled result summary
- Use Step Functions for depth-based loop control
- Create cloudformation template for one-click deploy

---

## 🔗 SAMPLE USAGE (Local Dev)

```bash
sam build
sam deploy --guided

sam local invoke InitiatorFunction --env-vars .env.json -e events/test-event.json
sam local invoke CrawlerFunction --env-vars .env.json -e events/test-event-crawler.json
```

Trigger `InitiatorFunction` manually with a test event (example.com recommended).

---

## 🧑‍💻 AUTHOR

👋 Milos Faktor  
🔗 [LinkedIn](https://www.linkedin.com/in/milos-faktor-78b429255/)  
🧠 AWS | Serverless | AI Integration

---

