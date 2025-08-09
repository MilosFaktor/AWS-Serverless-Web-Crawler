## 🔹 CD Pipeline – Step 1: Source (Push to Main Trigger)

### What I Did
- Configured AWS CodePipeline (CD) to **trigger only on push events to the `main` branch** in GitHub.  
- This stage listens for commits merged into `main` — which can only happen after:
  1. CI pipeline finishes successfully.  
  2. Manual approval is granted.  
  3. GitHub Status Check passes.  
- Authentication via **GitHub App** (same as CI pipeline) to avoid personal access tokens and simplify webhook management.

### Key Learnings
- It’s crucial to **isolate CD from CI**:  
  - CI pipeline = validate & approve code for production.  
  - CD pipeline = take *already approved code* and deploy it.
- Push-to-main trigger ensures **production is always deployed from a known good commit** — no manual artifact uploads, no skipping the approval process.

### Outcome
- Source stage now acts as the **entry point to production deployment**.
- Guarantees that only **approved, tested, and reviewed** changes make it to production.



## 🔹 CD Pipeline – Step 2: Deploy to Production

### What I Did
- Reused the **same `deploy.sh` script and `buildspec-deploy.yml`** from the Dev deployment stage in CI.  
- Changed **environment variables** to target the `prod` environment:
  - `STACK_NAME=serverless-webcrawler-prod`
  - `ENV=prod`
  - Separate **IAM role** with stricter permissions for production deployment.
- Deployment is fully automated using **`sam deploy --no-confirm-changeset`** for speed and reliability.
- Outputs from this stage are stored in artifacts for record-keeping and debugging.

### Key Learnings
- **Same artifacts, different targets** — by separating build (CI) from deploy (CD), I avoided rebuilding the Lambda packages.  
  This ensures the code deployed to Prod is exactly the one tested in Dev.
- **Separate IAM roles** for Dev and Prod are critical:
  - Dev role = more permissive for testing and iteration.
  - Prod role = least privilege, locked down to prevent accidental changes.
- CloudFormation stack names must be **unique per environment** to avoid overwriting resources.

### Challenges & Fixes
- Spent significant time figuring out **how to pass build artifacts from the Dev build** so that Prod deployment uses the exact tested package.
- First, I experimented with creating my own S3 bucket for artifact storage, but this added unnecessary complexity.
- Then, I discovered that CodePipeline already stores build artifacts in its own managed S3 bucket:
  1. In the Dev **Build stage**, I clicked **View Artifacts** in the CodeBuild invocation.
  2. Located the automatically created S3 bucket and found the exact artifact folder path (e.g., `CICD-Web-Crawler-Pip/BuildArtif/...`).
  3. Set the CD pipeline’s **Source** stage to pull directly from this S3 location.
- This ensures **Prod always gets the exact same tested build from Dev**, eliminating rebuild differences.

### Outcome
- Production deployment is now **predictable, reproducible, and isolated** from Dev.
- No accidental resource sharing between environments.
- Deployments take only a few minutes and require **zero manual intervention** once triggered.



## 🔹 CD – Step 3: Dev Stack Deletion

### What I Did
- Added a final cleanup stage to **delete the Dev stack** after a successful Prod deployment.
- Used AWS CLI in a CodeBuild job:
  ```bash
  aws cloudformation delete-stack --stack-name "$STACK_NAME"
  aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
  ```
- Ensures no unused Dev resources remain, avoiding costs and confusion.

## Key Learnings
- Automated cleanup prevents resource drift and keeps AWS accounts tidy.
- `aws cloudformation wait` is useful to ensure the stack is fully deleted before the pipeline completes.
- IAM permissions must allow all necessary delete actions for resources in the stack.

## Challenges & Fixes
- **Challenge:** Stack deletion failed because **Lambda event source mappings (SQS triggers)** were still attached.  
  **Fix:** In `delete_stack.sh`, resolve the `CrawlerFunction` physical name, `list-event-source-mappings`, delete each mapping, wait briefly, then proceed with deletion.

- **Challenge:** Missing IAM permissions during cleanup (especially Lambda mapping ops).  
  **Fix:** Granted the CodeBuild role `lambda:ListEventSourceMappings`, `lambda:DeleteEventSourceMapping`, plus the necessary CloudFormation/SQS/DynamoDB/Lambda delete actions.

## Outcome
After every merge to `main`:
1. Production stack is deployed from tested artifacts.
2. Dev stack is deleted automatically.

**Result:** Clean, cost-efficient AWS account and ready-to-use Dev environment for the next feature branch.

✅ **Final CD Pipeline Flow**  
Push to `main` → Source Trigger → Deploy-to-Prod (reusing Dev artifacts) → Delete Dev stack → Clean, tested Production release.
