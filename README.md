### 🎥 Demo Video
Watch the full crawler in action on LinkedIn:  
👉 [Watch Demo Video](https://www.linkedin.com/embed/feed/update/urn:li:ugcPost:7350978672381616128?collapsed=1)

### Do you want to see all screenshots from the project?  
👉 [All screenshots](docs/screenshots/)

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

# 🕷️ Serverless Web Crawler on AWS – Version 2

This is **Version 2** of the Serverless Web Crawler — a fully serverless solution that programmatically discovers and retrieves all unique internal links from dynamic or static websites. The crawler is optimized for React-based sites and designed for reliability, cost-efficiency, and AWS-native best practices.

While version 1 was inspired by BeABetterDev's Python implementation, version 2 is re-architected using **AWS SAM** for repeatable deployments and infrastructure-as-code. This version also separates the Initiator and Crawler logic across two distinct Lambdas using different runtimes — Python for orchestration and Node.js for crawling with Puppeteer.

## 🪜 Key Improvements in Version 2
- **SAM-powered deployments** with templated YAML
- **Environment variable setup** per Lambda function
- **Multi-language Lambda functions**: Python (Initiator) + Node.js (Crawler)
- **Automatic artifact building** via SAM from `requirements.txt` and `package.json`
- **Reserved concurrency** control to prevent over-invocation and API overloads
- **Local development support**: test with Dockerized DynamoDB + Lambda

---

## 🧠 Architecture Diagram
<img src="docs/screenshots/0-diagram.png" width="750">

---

## 🎓 Tech Stack & AWS Services
```bash
`Service`                    `Purpose`
AWS Lambda                  Initiator (Python) & Crawler (Node.js) handlers
SQS                         Queue for discovered links
DynamoDB                    Stores visited links
CloudWatch                  Logging/debugging
S3 + CloudFront             Hosts demo/test pages
Step Functions (optional)   For cost tuning workflows
```

---

## 🔄 Workflow
1. **User manually invokes** the Initiator Lambda.
2. **Initiator Lambda** writes the root URL to DynamoDB and pushes to SQS.
3. **Crawler Lambda (Node.js + Puppeteer)** pulls URLs from SQS:
   - Renders page with Chromium (Sparticuz headless build)
   - Extracts both static `<a href>` and client-side React `<Link>` routes
   - Stores visited URLs in DynamoDB
   - Pushes new unique links to SQS
4. Process repeats recursively with depth control and throttling.

---

## 🚀 Notable Features in Version 2
- **Environment Variables**: Set at deploy time using SAM templates
- **Reserved Concurrency**: Prevents flooding API targets or exceeding limits
- **Layer Auto-Building**: SAM detects `package.json` or `requirements.txt` and builds
- **Git Monorepo Strategy**:
   - `main` branch points to latest working version
   - `v1`, `v2`, etc. branches freeze prior versions for LinkedIn/blog reference

---

## 📊 Project Structure
```bash
/initiator-lambda/          # Python Lambda
/crawler-lambda/            # Node.js + Puppeteer
/layers/                    # Lambda Layers
  |- python-layer/          # Python dependencies
  |- nodejs-layer/          # Node dependencies
/docs/                      # Screenshots + guides
```

---

## 🔧 Local Dev & Testing
You can:
- Run **Dockerized DynamoDB** locally
- Spin up Lambda functions for manual testing
- Simulate SQS + DynamoDB calls without cloud deployment
- Validate `template.yaml` with `sam validate`

Screenshots and exact commands coming in future documentation updates.

---

## 🛡️ Security, DLQ, and API Rate Limits
Version 2 includes:
- DLQ (Dead Letter Queue) for failed messages (testing pending)
- Planned support for API Gateway + IP-based rate limiting in v3
- IAM-based separation of permissions for Initiator vs Crawler

---

## 🏆 Achievements
- Crawler works against dynamic React pages with nested routers
- Cold starts, concurrency, and size limits resolved
- SAM enables clean, reproducible, modular deployments

---

## 👤 Author
Milos Faktor — [LinkedIn](https://www.linkedin.com/in/milos-faktor-78b429255/)

Built and tested in Denmark, shared with the world.

---

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

### Do you want to see all screenshots from the project?  
👉 [All screenshots](docs/screenshots/)
