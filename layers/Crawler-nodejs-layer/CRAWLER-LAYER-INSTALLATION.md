### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

# 🛠 Lambda Layers Installation Guide

This guide explains how to prepare and deploy Lambda layers for the Serverless Web Crawler project.

We use two separate layers:  

**Dependencies Layer** – contains all Node.js dependencies from `package.json`.  
**Chromium Layer** – contains Sparticuz Chromium for Puppeteer to work in AWS Lambda.  

By using layers, we keep the Lambda function lightweight and avoid deployment size limits.

---

## 📁 Layer 1: Dependencies Layer

This layer contains all Node.js libraries required by the Crawler Lambda, including:  
``` bash
`@aws-sdk/client-dynamodb`
`@aws-sdk/client-sqs`
`puppeteer-core`
`uuid`
`tar-fs`
`follow-redirects`
```

## Install Instructions

1. **Create Layer Directory:**
``` bash
mkdir -p crawler-layer/nodejs
cd crawler-layer/nodejs
```

2. **Copy your existing package.json file into this directory:**
``` bash
cp /path/to/package.json .
```

3. **Install all dependencies locally into node_modules:**
``` bash
npm install --only=production
```

4. **Return to the parent folder and zip the directory:**
``` bash
cd ..
zip -r crawler-dependencies-layer.zip nodejs
```

5. **Upload to AWS Lambda:**
- Upload crawler-dependencies-layer.zip to an S3 bucket in your AWS account:
``` bash
aws s3 cp crawler-dependencies-layer.zip s3://your-bucket-name/layers/crawler-dependencies-layer.zip
```

- Go to AWS Lambda > Layers in the AWS Console.

- Click Create layer.

- Name it crawler-dependencies-layer.

- Choose Upload from S3 and provide the S3 URL:
``` bash
s3://your-bucket-name/layers/crawler-dependencies-layer.zip
```

- Set Runtime: Node.js 20.x.

- Attach this layer to your Crawler Lambda Function in Code > Layers and add the correct ARN of the layer.
(You can find the Layer ARN in the Lambda console after creating the layer, under “Versions.”)

## 📁 Layer 2: Chromium Layer (Sparticuz)
This layer contains the Chromium binary optimized for AWS Lambda.

We use the prebuilt package from [Sparticuz Chromium v130.0.0](https://github.com/Sparticuz/chromium/releases/tag/v130.0.0)

## Install Instructions
1. **Download Sparticuz Chromium**

- Download the prebuilt release:

- File: `chromium-v130.0.0-layer.zip`

2. **Upload to AWS Lambda**

- Go to AWS Lambda > Layers.

- Click Create layer.

- Name it chromium-layer.

- Upload `chromium-v130.0.0-layer.zip.`

- Set Runtime: Node.js 20.x.

3. **Attach to Lambda Function**

- In your Crawler Lambda Function:

- Go to Code > Layers > Add a Layer.

### Want the full build journey with errors, fixes, lessons, and AWS tweaks?  
👉 [BUILD-JOURNAL.md](docs/BUILD-JOURNAL.md)

### 🎥 Demo Video
Watch the full crawler in action on LinkedIn:  
👉 [Watch Demo Video](https://www.linkedin.com/embed/feed/update/urn:li:ugcPost:7350978672381616128?collapsed=1)

### Do you want to see all screenshots from project? 
👉 [All screenshots](docs/screenshots/)

## 🧑‍💻 Author
👋 Milos Faktor 💼 [LinkedIn](https://www.linkedin.com/in/milos-faktor-78b429255/)
