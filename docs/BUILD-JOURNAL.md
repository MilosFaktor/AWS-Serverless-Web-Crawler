# 🚀 Serverless Web Crawler – Flagship CI/CD Pipeline

⚠️ Disclaimer: The URL used in this demo is provided solely to showcase the functionality of this project. It will not work out-of-the-box when you clone the repository. I have permission to use the website shown in the demo, but you should configure your own target by setting an environment variable (e.g., ROOT_URL=<your_url>) in the Integration Test CodeBuild stage.

## 🔹 CI – Step 1: Source (Pull Request Event via AWS CodeStar Connection)

### What I Did
- Connected CodePipeline to GitHub using **AWS CodeStar Connections** (GitHub App authentication).
- Created the Source stage in the CI pipeline to trigger from **pull request events** instead of direct pushes.
- Set the **destination branch filter** to `main` (target branch), not the `feature/*` branches.
- Configured event triggers for:
  - **Created** (when a PR is opened)
  - **Updated** (when commits are pushed to the PR’s source branch)
- Left **Closed** unselected (not needed for my flow).

### Key Skill Learnings
- **PR Destination Filtering** – PR triggers filter on the *target branch*, not the *source branch*. My first attempt was `feature/*`, which didn’t work until I switched to `main`.
- **Continuous PR Updates** – Once a PR is open, any new commit to the source branch automatically triggers the pipeline without creating a new PR.
- **Granular Event Control** – Selecting only “Created” and “Updated” keeps the pipeline lean while still supporting rapid iteration.

### Challenges & How I Solved Them
- **Main Struggle:** Pipeline not triggering on feature branch commits. Thought CodePipeline could filter on source branches directly — it can’t.
- **Fix:** Set destination branch filter to `main` → worked immediately.
- **Extra Lesson:** Understanding PR event filtering will save hours of debugging in future CI/CD setups.

### Outcome
- CI pipeline starts automatically for any new or updated PR targeting `main`.
- I can commit freely to a feature branch while a PR is open, knowing CodePipeline will rebuild without manual intervention.


## 🔹 CI – Step 2: Build & Package (CodeBuild)

### What I Did
- Set up a **build-only** CodeBuild stage.  
- `buildspec.yml` stays minimal and calls a shell script that:
  1. Validates the SAM/CloudFormation template.
  2. Runs `sam build` to stage artifacts under `.aws-sam/build/`.
- Used **CodeBuild Standard (AL2 v5)** image (Python 3.11, Node 20, SAM CLI preinstalled).
- Exported only the **needed artifacts** (template + build outputs) for downstream stages and for the CD pipeline via the artifact S3 bucket.

---

### Why I Split Build/Package and Deploy
- I wanted **one deploy script** and **one SAM template** for both environments (**Dev** and **Prod**), with behavior controlled by an environment variable (`STAGE=dev|prod`).
- Keeping deploy separate lets me inject **env-specific settings** at runtime—without rebuilding artifacts.
- Stack names, params, and regions come from `STAGE` (and/or `samconfig.toml` profiles), e.g.:
  - `serverless-app-crawler-sam-dev`
  - `serverless-app-crawler-sam-prod`
- **Result**: same artifacts, same script, different stack targets — clean, DRY, and reproducible.

---

### 🧠 Key Skill Learnings
- **Artifacts = handoff contract** to later stages and CD; list only what’s required.
- Path discovery of `.aws-sam/build/` avoids “file not found” in later steps.
- Runtimes preinstalled → removing explicit installs reduced ~30s build time.
- Caching not helpful for this SAM flow; clean rebuilds keep template/code in sync.

---

### 🛠️ Challenges & Fixes
- **Which files to export?** Iterated with `logs/ls -R` and trimmed to essentials.
- Over-configuring runtimes slowed builds → relied on the standard image.
- **Packaging vs Deploy**: kept packaging logic with deploy (`sam deploy`) so env-specific uploads/params are driven by `STAGE`/profiles, not the build step.

---

### ✅ Outcome
- Lean, fast **Build & Package** that produces one set of artifacts reused for:
  - CI Step 3 (Dev deploy)
  - CI Step 4 (tests via stack outputs)
  - CD pipeline (Prod deploy)  
  — ensuring Prod runs the **exact bits** validated in CI.


## 🔹 CI Pipeline – Step 3: Deploy to Dev

### 📌 What I Did
In this stage, the CI pipeline takes the **packaged artifacts from Step 2** and deploys them into the **development stack** using AWS SAM.  

This stage is driven by:  
- A **dedicated buildspec file** for deployment.  
- A matching `deploy.sh` script.  

**Buildspec Flow**:
1. `pre_build` → Logs the target environment.
2. `build` → Runs the deployment script.
3. `post_build` → Logs completion.

---

### 🛠 `deploy.sh` Script Highlights
- Ensures it’s in the correct working directory (`serverless-app-sam/`).
- Resolves the **stack name dynamically** from the `samconfig.toml` environment section.
- Checks the current CloudFormation **stack status** before deployment.
- Handles **failed/incomplete stacks** (`ROLLBACK_COMPLETE`, `CREATE_FAILED`, etc.) by deleting them and waiting for completion.
- Runs `sam deploy` using the **env-specific settings** in `samconfig.toml`.
- If deployment fails, checks if the stack is simply **already up to date** and allows the pipeline to continue.
- Generates **two versions of stack outputs**:
  - Full JSON
  - Simplified key-value JSON (for downstream stages)
- Publishes all required files as **DeployArtifacts** for later stages like testing and production deploy.

---

### 🚧 Challenges I Overcame
- **IAM Permissions Roadblock**:  
  - This was the single biggest blocker in this stage.  
  - CodeBuild needs permissions for every AWS service your SAM app interacts with: CloudFormation, Lambda, DynamoDB, S3, API Gateway, etc.  
  - Without the right IAM policy, deployment fails mid-pipeline.  
  - Initially, I troubleshot **one missing permission at a time** — slow and frustrating.

- **Solution**:  
  - Use **different IAM roles** for development and production:
    - **Dev IAM Role** → Loose permissions for fast iteration.
    - **Prod IAM Role** → Strict least-privilege before go-live.
  - Learned to **auto-handle ROLLBACK** and failed stack states so they don’t block deployments.
  - Learned to detect **"no changes"** and continue without failing the pipeline.
  - Fixed artifact paths so files in `serverless-app-sam/` are correctly picked up by CodePipeline.

---

### 🧠 Key Learnings
- If something isn’t working in AWS, **check IAM policies or security groups first** — most common blockers.
- Keep **build and deploy** as separate stages so the same deploy script can be reused for multiple environments just by changing `$Environment`.
- Using **different IAM roles** for dev and prod balances speed and security.
- Always store outputs in both **full** and **simplified** formats for easier test automation.

---

### ✅ Outcome
- Fully deployed **Dev stack** with clean CloudFormation outputs stored as artifacts.
- Deployment resilient to failed states.
- IAM issues documented and resolved.
- Workflow ready to extend to **Prod deployment** with minimal changes.


## 🔹 CI Pipeline – Step 4: Integration Testing

### 🎯 Purpose of This Stage
This is the **full end-to-end verification step** for the pipeline.  
By this point, the **Dev stack** has been freshly deployed in **Step 3**, so this stage confirms that the application **actually works as intended** — not just that CloudFormation deployed it.

This stage runs the **entire serverless flow**:

1. Invoke **Initiator Lambda**.
2. Let it publish a message to **SQS**.
3. Allow SQS to trigger **Crawler Lambda**.
4. Crawler Lambda scrapes the target website and stores results in **DynamoDB**.
5. Confirm DynamoDB has at least **1 record** from the test run.

This is not a unit test — it’s a **real functional test** across multiple AWS services, ensuring all components communicate correctly.

---

### 🛠 What Actually Happens in This Stage

The stage is executed by **CodeBuild** using a **dedicated buildspec.yml** for integration testing.  
That buildspec calls `integration_test.sh`, which performs:

#### 1. Load stack outputs from artifacts
- Uses `cfn-outputs.json` and `cfn-outputs-simple.json` from Step 3.
- Extracts Lambda ARN, SQS URL, and DynamoDB table name dynamically — **no hardcoding**.

#### 2. Extract resource identifiers with `jq`
- `InitiatorFunction` → Lambda ARN.
- `CrawlerQueueUrl` → SQS queue URL.
- `VisitedTableName` → DynamoDB table name.

#### 3. Invoke Initiator Lambda
- Sends test event (`event.json`) to Lambda.
- **Key Fix:** Use `fileb://` instead of `file://` for payload to avoid JSON parsing issues in AWS CLI.

#### 4. Wait before polling SQS
- Added a **30-second initial delay** before polling.
- Prevents false negatives due to async delays in Lambda + SQS.

#### 5. Poll SQS until empty
- Checks both **visible** and **in-flight** messages.
- Declares queue “done” only if empty for **3 consecutive polls** (10s apart).

#### 6. Scan DynamoDB table
- Runs `aws dynamodb scan` and saves to `response_dynamodb_table.json`.
- Extracts record count to determine pass/fail.

#### 7. Pass/Fail criteria
- ✅ PASS → At least 1 record in DynamoDB.
- ❌ FAIL → No records found or SQS timeout.

---

### 🚧 Challenges I Overcame

- **Artifacts Not Passing Through**  
  - First run failed because `cfn-outputs.json` wasn’t in Step 3 artifacts.
  - CodePipeline doesn’t auto-share files — must be explicitly listed.

- **Payload Format Issue**  
  - Missing `b` in `fileb://` caused repeated Lambda invocation failures.

- **Timing Issues**  
  - Without delay, poller started too early and missed messages.
  - Added **3-empty-check rule** to handle intermittent empty queue states.

---

### 🧠 Key Learnings
- Integration tests need **both correct artifacts and timing** to work reliably.
- Async AWS services like **SQS + Lambda** require **deliberate wait logic**.
- `fileb://` vs `file://` in AWS CLI is a **tiny but critical** difference.
- Always verify **artifact passing** between stages before complex automation.

---

### ✅ Outcome
This stage now:
- Dynamically reads resource names from stack outputs (**no hardcoding**).
- Waits properly for async processing to finish.
- Produces **detailed JSON artifacts** for Lambda responses & DynamoDB results.
- Serves as a **reliable pass/fail gate** before production deployment.


## 🔹 CI – Step 5: Manual Approval, SNS Notification & GitHub Status Check Enforcement

### 🛠 What I Did
- Added a **Manual Approval** action at the end of the CI pipeline.
- Linked it to an **SNS topic** to send an email containing:
  - 📎 Link to the GitHub Pull Request (PR) for review/merge.
  - 📎 Link to the CodePipeline approval page.
- Added a **post-approval CodeBuild job** in the same stage to run `post_approval.sh` which:
  - Posts to the **GitHub Status API** with `"state": "success"`.
  - Uses a **GITHUB_TOKEN** stored in **AWS Secrets Manager** for authentication.
  - Passes `CODEBUILD_RESOLVED_SOURCE_VERSION` to target the correct commit.

---

### ⚙️ How It Behaves
1. CI runs through:
   - **Build**
   - **Deploy-to-Dev**
   - **Integration Tests**
2. If all pass, pipeline **pauses** at the **Manual Approval** step and sends the **SNS email**.
3. After approval:
   - The **post-approval CodeBuild job** runs.
   - Posts the **success status** to GitHub.
4. **GitHub Branch Protection** requires this status check before merges.

✅ **Merge Button is Locked Until:**
- Pipeline finishes all prior steps.
- Manual approval in CodePipeline is given.
- Status check from CodeBuild posts successfully.

---

### 🧠 Key Learnings
- Manual approval in CodePipeline alone is only a **soft safeguard** — without a GitHub rule, merges could bypass it.
- Linking a post-approval CodeBuild job to **GitHub’s Status API** and marking it **required** in branch protection makes it a **hard gate**.
- **Secrets Manager** securely passes tokens to CodeBuild without exposing them in logs.
- SNS notification + status check = **visibility (email)** + **enforcement (GitHub lock)**.

---

### 🚧 Challenges & Fixes
- Fixed file path issues when calling `post_approval.sh` in CodeBuild (`chmod +x ./codepipeline/scripts/post_approval.sh`).
- Corrected GitHub repo name in API call (initially pointed to the wrong repo).
- Granted `sns:Publish` permission to the CodePipeline role.
- Verified SNS subscription to ensure email notifications work.

---

### ✅ Outcome
- CI is **fully automated** up to an **enforced approval checkpoint**.
- **Approval → Status Check → Merge** = clean, tested build flows into CD.
- Merge without approval is **blocked by GitHub** until status check passes.
- SNS email provides **quick links** to the PR and approval screen for convenience.



## 🔹 GitHub Flow + Pipeline Merge Protection – Avoiding Unwanted Production Merges

### 🛠 What I Did
- Adopted the **GitHub Flow** branching model:
  - `main` → always production-ready, protected.
  - `feature/*` → all new work and changes are developed here.
- Added **branch protection rules** on `main` (enforced even for admins).
- Configured rules so:
  - ❌ Direct commits to `main` are blocked.
  - ✅ All changes must come via a **Pull Request** from `feature/*` → `main`.
  - ✅ PR merges are only allowed if **all required status checks** pass.
- Integrated **AWS CodePipeline** with the **GitHub Status API**:
  - Added a **post-approval step** at the end of the pipeline that sends a `"success"` status to the relevant commit in GitHub.
  - Used **AWS Secrets Manager** to securely store the GitHub token for authentication.
  - Configured the GitHub branch rule so the **merge button remains locked** until the pipeline posts a green status.

---

### ⚙️ How It Behaves
1. Developer pushes changes to a `feature/*` branch.
2. A PR is opened to merge into `main`.
3. **CodePipeline** runs:
   - Build
   - Deploy-to-Dev
   - Tests
   - Manual Approval (SNS notification sent for visibility)
4. Upon manual approval:
   - **Post-approval script** runs, posting `"success"` to the GitHub Status API for that commit.
5. Only after the status check passes does GitHub allow the merge.
6. Merging into `main` triggers the **CD pipeline** to deploy to production.

---

### 🧠 Key Learnings
- **GitHub Flow** is lightweight, simple, and works perfectly with CI/CD.
- Protecting `main` — even for admins — removes the temptation to “just push it.”
- **Branch protection + pipeline-driven status checks** = hard security gate for production.
- SNS + Manual Approval still adds human oversight before status check passes.
- This pattern **prevents accidental merges, untested code, or hotfix mistakes** from ever reaching production.

---

### ✅ Outcome
Every deployment to `main` now follows:

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
 