### Do you want to see all screenshots from the project?  
👉 [All screenshots](docs/screenshots/)

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

# 🕷️ Serverless Web Crawler on AWS – Version 2

This is **Version 2** of the Serverless Web Crawler — a fully serverless solution that programmatically discovers and retrieves all unique internal links from dynamic or static websites. The crawler is optimized for React-based sites and designed for reliability, cost-efficiency, and AWS-native best practices.

While version 1 was inspired by BeABetterDev's Python implementation, version 2 is re-architected using **AWS SAM** for repeatable deployments and infrastructure-as-code. The Initiator and Crawler logic across two distinct Lambdas using different runtimes — Python for orchestration and Node.js for crawling with Puppeteer.

## 🪜 Key Improvements in Version 2
- **SAM-powered deployments** with templated YAML
- **Environment variable setup** per Lambda function
- **Automatic artifact building** via SAM from `requirements.txt` and `package.json`
- **Local development support**: test with Dockerized DynamoDB + Lambda

---

## 🧠 Architecture Diagram
<img src="docs/screenshots/0-diagram.png" width="750">

---

## 🎓 Tech Stack & AWS Services
```bash
`Service`                    `Purpose`
AWS SAM                     Infrastructure as Code
AWS Lambda                  Initiator (Python) & Crawler (Node.js) handlers
SQS                         Queue for discovered links
DynamoDB                    Stores visited links
CloudWatch                  Logging/debugging
```

---

## 🔄 Workflow
1. **Initiator Lambda** writes the root URL to DynamoDB and pushes to SQS.
2. **Crawler Lambda (Node.js + Puppeteer)** pulls URLs from SQS:
   - Renders page with Chromium (Sparticuz headless build)
   - Extracts both static `<a href>` and client-side React `<Link>` routes
   - Stores visited URLs in DynamoDB
   - Pushes new unique links to SQS
3. Process repeats recursively with depth control and throttling.

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
./README.md 
./docs                          # Screenshots and documentation
└── BUILD-JOURNAL.md
./serverless-app-sam
├── Crawler Lambda
│   ├── index.mjs
│   ├── package.json            # Node.js dependencies including Puppeteer
│   ├── utils.mjs
│   └── visitedURL.mjs
├── Initiator Lambda
│   ├── initiator.py
│   ├── models
│   │   ├── VisitedURL.py
│   │   └── __init__.py
│   ├── requirements.txt        # Python dependencies
│   └── utilities
│       ├── __init__.py
│       └── util.py
├── __init__.py
├── events
│   └── event.json          # Sample event for local testing of Initiator Lambda / needs to be changed
├── samconfig.toml            # SAM configuration file
└── template.yaml               # SAM template defining the infrastructure
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
- Building CI/CD pipeline for automated testing and deployment

---

## 🏆 Achievements
- Crawler works against dynamic React pages with nested routers
- Cold starts (39.5s), concurrency, and size limits resolved
- SAM enables clean, reproducible, modular deployments !!!

## Screenshots

<img src="docs/screenshots/6 - SAM deployed resources.png" width="750">

<img src="docs/screenshots/7 - CloudFromation stack created.png" width="750"> 

<img src="docs/screenshots/10 - Initiator.png" width="750">

<img src="docs/screenshots/11 - Crawler.png" width="750">

<img src="docs/screenshots/8 - dynamoDB after crawl.png" width="750">

<img src="docs/screenshots/9 - CloudWatch metrics.png" width="750">

---

## 👤 Author
Milos Faktor — [LinkedIn](https://www.linkedin.com/in/milos-faktor-78b429255/)

Built and tested in Denmark, shared with the world.

---

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

### Do you want to see all screenshots from the project?  
👉 [All screenshots](docs/screenshots/)

#AWS #Serverless #AWSSAM #LambdaFunctions #InfrastructureAsCode #WebCrawler #Python #NodeJS #Puppeteer #DynamoDB #SQS #CloudWatch #DevOps #OpenSourceProject #BuildInPublic #LearningInPublic #CI_CD #CloudDevelopment #ReactCrawler #DynamicWebScraping #FullStackServerless #MilosFaktor #TechPortfolio
