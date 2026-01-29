# Lab 7
## Integrate Terraform with Jenkins Pipeline

---

## Objective

Learn how to automate Terraform workflows using Jenkins CI/CD pipelines to validate, format-check, and plan infrastructure changes automatically on Pull Requests.

---

## Time Estimate

**45-60 minutes**

---

## What You'll Learn

- Understand CI/CD concepts for Infrastructure as Code
- Set up Jenkins for Terraform automation
- Create a Jenkinsfile with declarative pipeline syntax
- Automate `terraform init`, `validate`, and `plan` on PRs
- Use SCM polling for pipeline triggers

---

## Prerequisites

- Completed Lab 6

---

## High-Level Instructions

1. Create GitHub account and personal access token
2. Access Jenkins
3. Create a new Jenkins Pipeline job
4. Create a Jenkinsfile in your repository
5. Configure SCM polling
6. Test the pipeline by creating a Pull Request
7. Verify Terraform plan runs automatically
8. View Terraform plan output in console logs

---

## Documentation Links

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Jenkins Pipeline Syntax](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Terraform in CI/CD](https://developer.hashicorp.com/terraform/tutorials/automation/automate-terraform)
- [Jenkins Terraform Plugin](https://plugins.jenkins.io/terraform/)
---

## Detailed Instructions

### Step 1: Create Personal Access Token

**Create a Personal Access Token on GitHub:**
1. Go to GitHub → **Settings** → **Developer settings** → **Personal access tokens** → **Fine-grained tokens**
2. Click **Generate new token**
3. Give it a name: `default-token`
4. Set expiration as needed
5. Under **Repository access**, select **Only select repositories** and choose your repository
6. Under **Permissions**, click **Add permissions** and set:
   - **Commit statuses**: Read and write
   - **Contents**: Read and write
   - **Metadata**: Read-only (required, auto-selected)
   - **Pull requests**: Read and write
7. Click **Generate token**
8. **Copy and save the token** - you won't be able to see it again!

---

### Step 2: Access Jenkins

**Using Instructor-Provided Jenkins**
1. Navigate to the Jenkins URL provided by your instructor
2. Login with your assigned credentials
3. You should see the Jenkins dashboard


### Step 3: Create Jenkins Multibranch Pipeline Job

1. From Jenkins dashboard, click **New Item**
2. Enter item name: `terraform-pipeline-UserX` (replace UserX with your ID)
3. Select **Multibranch Pipeline**
4. Click **OK**
5. In the configuration page:
   - **Description:** "Terraform CI/CD pipeline for automated validation and planning"

**Branch Sources:**
1. Click **Add source** → **GitHub**
2. Configure:
   - **Project Repository:** Your GitHub repository URL
     - Example: `https://github.com/your-username/terraform-aws-project-UserX.git`
   - **Credentials:** Add your Git personal token (name it `default-token` - this is required for PR comments to work)


**Build Configuration:**
   - **Mode:** by Jenkinsfile
   - **Script Path:** `Jenkinsfile`

**Scan Multibranch Pipeline Triggers:**
   - ✓ Check **Periodically if not otherwise run**
   - **Interval:** 1 minute


6. Click **Save**
7. Jenkins will automatically scan your repository and discover branches

---

### Step 4: Create Jenkinsfile in Your Repository

**Create a new feature branch:**
```bash
cd ~/lab6  # Your existing project from Lab 6
git checkout develop
git pull origin develop
git checkout -b feature/add-jenkins-pipeline
```

**Copy Jenkinsfile from solution:**
```bash
cp ~/day2/labs/lab7/lab7-solution/lab7.1.Jenkinsfile-simple-plan Jenkinsfile
```

---

### Step 4 (continued): Understanding the Jenkinsfile

**Pipeline Structure:**

- **`agent any`** - Run on any available Jenkins agent
- **`stages`** - Define the pipeline workflow
- **`post`** - Actions to run after pipeline completes

**Stage Breakdown:**

1. **Checkout** - Get code from Git repository
2. **Terraform Init** - Initialize Terraform, download providers
3. **Terraform Validate** - Check configuration syntax
4. **Terraform Plan** - Generate execution plan using staging.tfvars (output shown in console)

**Post Actions:**
- `cleanWs()` - Cleans up workspace after pipeline completes (always runs)

---

### Step 5: Commit and Push Jenkinsfile

```bash
# Add Jenkinsfile
git add Jenkinsfile

# Commit
git commit -m "ci: Add Jenkins pipeline for Terraform automation"

# Push to remote
git push -u origin feature/add-jenkins-pipeline
```

**Verify on GitHub:**
Open your repository and confirm the Jenkinsfile is there in add-jenkins-pipeline branch.

---

### Step 6: Test Pipeline Manually (First Run)

Test the pipeline manually:

1. Go to Jenkins dashboard
2. Click on your pipeline job: `terraform-pipeline-UserX`
3. Click **Build Now**
4. Click on the build number (e.g., #1) when it appears
5. Click **Console Output** to watch the pipeline run

**Expected behavior:**
- Checkout stage: Clones your repository
- Init stage: Downloads AWS provider
- Validate stage: Validates your Terraform code
- Plan stage: Creates execution plan using staging.tfvars (shown in console output)

---

### Step 6 (continued): Troubleshooting First Run

**If init fails:**
- Check network connectivity from Jenkins to AWS
- Verify terraform.tf provider configuration
- Check Jenkins has Terraform installed

---

### Step 7: Automatic Branch and PR Discovery (SCM Polling)

**Jenkins will automatically discover changes using SCM polling:**

You already configured this in Step 3:
- **Scan Multibranch Pipeline Triggers:** Periodically if not otherwise run (1 minute)
- This means Jenkins checks your repository every minute for new branches, commits, and Pull Requests

**How it works:**
1. You push code or create a Pull Request
2. Within 1 minute, Jenkins scans the repository
3. New branches/PRs are discovered automatically
4. Pipeline runs on detected changes

**Manual scan (for immediate testing):**
1. Go to your Multibranch Pipeline job: `terraform-pipeline-UserX`
2. Click **Scan Multibranch Pipeline Now** to force immediate scan
3. Click **Scan Multibranch Pipeline Log** to see what was discovered

**No additional configuration needed!** Polling is simpler and works well for training.


### Step 8: Test Automatic Pipeline Trigger

**Create a Pull Request to trigger the pipeline:**

```bash
# Make a small change to test automation
echo "# Testing Jenkins automation" >> README.md

git add README.md
git commit -m "docs: Test Jenkins polling integration"
git push
```

**Create PR on GitHub:**
1. Go to your repository
2. Create Pull Request from `feature/add-jenkins-pipeline` to `develop`
3. Title: "Add Jenkins CI/CD pipeline"
4. Create the PR

**Watch Jenkins (polling will detect the PR):**
1. Go to Jenkins dashboard
2. Navigate to your Multibranch Pipeline: `terraform-pipeline-UserX`
3. Wait up to 1 minute for the scan to detect the PR
4. You should see a new PR item appear (e.g., "PR-1")
5. Click on the PR item to see the build
6. The pipeline will run automatically

**Tip:** You can click **Scan Multibranch Pipeline Now** to force immediate scan instead of waiting

---

### Step 9: Verify Pipeline Results

**In Jenkins:**
1. Navigate to your Multibranch Pipeline job
2. Click on the PR item (e.g., "PR-1")
3. Click on the build number (e.g., #1)
4. Click **Console Output**
5. Verify all stages passed:
   - ✓ Checkout
   - ✓ Terraform Init
   - ✓ Terraform Validate
   - ✓ Terraform Plan

**View Plan Output:**
1. Scroll through the Console Output
2. Find the "Terraform Plan" stage output
3. Review the Terraform plan details showing what resources will be created/modified

---

### Step 10: Merge the Pull Request

If all checks pass:

1. On GitHub, review your PR
2. Verify Jenkins build succeeded (green checkmark)
3. Click **Merge pull request**
4. Confirm merge
5. Delete the feature branch

**Update local repository:**
```bash
git checkout develop
git pull origin develop
git branch -d feature/add-jenkins-pipeline
```

---

## Understanding CI/CD for Infrastructure

### What Just Happened?

**Automated Quality Gates:**
1. **Init** - Ensures dependencies are available
2. **Validate** - Catches syntax errors early
3. **Plan** - Shows what changes will be made

**Benefits:**
- Catch errors before merging code
- Consistent validation across all team members
- Documented infrastructure changes (plan output in console)
- No more "it works on my machine"
- Faster feedback loop

---

## CI/CD Workflow Diagram

```
Developer → Creates PR
    ↓
Jenkins → Polls GitHub for changes
    ↓
Jenkins → Automatically runs pipeline
    ↓
    ├─ Checkout code
    ├─ Terraform init
    ├─ Terraform validate
    └─ Terraform plan
    ↓
Jenkins → Posts results to PR
    ↓
Team → Reviews plan in PR
    ↓
Approved → Merge to develop
```

---

## Clean Up

**Keep your pipeline** - you'll enhance it in Lab 8!

**Optional: Clean up test builds**
1. Go to Jenkins job
2. Click on old builds
3. Click **Delete build**

**Keep your repository:**
- The Jenkinsfile will be used in Lab 8
- The SCM polling configuration will continue to work

---

## Key Takeaways

**CI/CD for Infrastructure as Code**

- Automation catches errors before they reach production
- Pipelines enforce quality and consistency
- Jenkins integrates seamlessly with Git workflows
- Plan output provides visibility into infrastructure changes
- SCM polling enables automatic pipeline triggers
- Keep pipelines simple and focused

---

## Additional Resources

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)


