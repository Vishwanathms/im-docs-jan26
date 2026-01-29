---
marp: true
header: 'Terraform level 1 - Day 2 - **Lab 8**'
footer: 'Controlled Apply and Merge Workflow'
paginate: true
---

# Lab 8
## Controlled Apply and Merge Workflow

---

## Objective

Learn how to implement controlled infrastructure deployments using manual approval gates in Jenkins pipelines, enabling safe automated application of Terraform changes to different environments.

---

## Time Estimate

**45-60 minutes**

---

## What You'll Learn

- Implement manual approval stages in Jenkins pipelines
- Execute `terraform apply` automatically after approval
- Configure branch-specific pipeline behavior (develop vs main)
- Deploy infrastructure to development and production environments
- Handle deployment failures and rollbacks
- Understand approval workflows and change management
- View and verify applied infrastructure changes
- Implement environment-aware CI/CD workflows

---

## Prerequisites

- Completed Lab 7 (Jenkins pipeline with automated planning)
- Jenkins pipeline running and functional
- AWS credentials configured in Jenkins
- GitHub/Bitbucket repository with Jenkinsfile
- Understanding of Git branching strategy (main, develop, feature)
- Admin or authorized approver access to Jenkins

---

## High-Level Instructions

1. Review current pipeline behavior (plan-only from Lab 7)
2. Update Jenkinsfile to add manual approval stage
3. Add `terraform apply` stage that uses saved plan
4. Configure branch-specific behavior using `when` blocks
5. Test approval workflow in develop branch
6. Merge changes and test production deployment to main
7. Verify deployed infrastructure in AWS
8. Practice rollback procedures

---

## Documentation Links

- [Jenkins Pipeline Input Step](https://www.jenkins.io/doc/pipeline/steps/pipeline-input-step/)
- [Terraform Apply Command](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [Jenkins When Directive](https://www.jenkins.io/doc/book/pipeline/syntax/#when)
- [Terraform Destroy (Rollback)](https://developer.hashicorp.com/terraform/cli/commands/destroy)
- [GitOps Principles](https://www.gitops.tech/)

---

## Understanding the Complete Workflow

### Lab 7 vs Lab 8

**Lab 7 (Plan-Only Workflow):**
```
PR Created → Jenkins runs → Plan generated → Review plan → Merge PR
(No infrastructure changes made)
```

**Lab 8 (Plan + Apply Workflow):**
```
PR Created → Jenkins plans → Review → Merge PR →
Jenkins plans again → Manual Approval → Apply → Infrastructure Updated
```

---

## Branch-Specific Behavior

### Develop Branch (Development Environment)
- **On PR:** Plan only (same as Lab 7)
- **After merge:** Plan → Approval → Apply to dev environment

### Main Branch (Production Environment)
- **On PR:** Plan only
- **After merge:** Plan → Approval (stricter) → Apply to production

---

## Detailed Instructions

### Step 1: Review Current Pipeline

**Verify Lab 7 pipeline is working:**

1. Go to Jenkins dashboard
2. Open your pipeline job: `terraform-pipeline-UserX`
3. Review recent builds
4. Confirm all stages pass: Checkout, Init, Validate, Format Check, Plan, Archive

**Current limitation:**
- Pipeline only plans changes
- No infrastructure is actually deployed
- Manual `terraform apply` still needed

---

### Step 2: Update Jenkinsfile with Approval Stage

**Navigate to your repository:**
```bash
cd ~/lab6  # Your existing project
git checkout develop
git pull origin develop
git checkout -b feature/add-approval-and-apply
```

**Update your Jenkinsfile:**

Add the following stage after the "Archive Plan" stage:

```groovy
        stage('Manual Approval') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
                not {
                    changeRequest()  // Don't ask for approval on PRs
                }
            }
            steps {
                script {
                    // Display plan summary before asking for approval
                    echo '========================================='
                    echo 'TERRAFORM PLAN COMPLETED'
                    echo '========================================='
                    echo 'Review the plan output in build artifacts before approving.'
                    echo "Build artifacts: ${env.BUILD_URL}artifact/"
                    echo ''
                    echo "Environment: ${env.BRANCH_NAME == 'main' ? 'PRODUCTION' : 'DEVELOPMENT'}"
                    echo '========================================='

                    // Request approval
                    input message: """Approve Terraform Apply?

Environment: ${env.BRANCH_NAME == 'main' ? 'PRODUCTION ⚠️' : 'DEVELOPMENT'}
Branch: ${env.BRANCH_NAME}
Build: ${env.BUILD_NUMBER}

Review plan artifacts before approving!""",
                          ok: 'Apply Changes',
                          submitter: 'admin,devops'  // Only these users can approve
                }
            }
        }
```

---

### Step 3: Add Terraform Apply Stage

Add this stage after the "Manual Approval" stage:

```groovy
        stage('Terraform Apply') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
                not {
                    changeRequest()  // Don't apply on PRs
                }
            }
            steps {
                echo '========== Applying Terraform Changes =========='
                script {
                    env.APPLYING_TO = env.BRANCH_NAME == 'main' ? 'PRODUCTION' : 'DEVELOPMENT'
                    echo "Applying to ${env.APPLYING_TO} environment..."
                }

                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        # Apply using the saved plan from previous stage
                        terraform apply -input=false tfplan

                        # Capture apply result
                        if [ $? -eq 0 ]; then
                            echo "✓ Terraform apply completed successfully"
                        else
                            echo "✗ Terraform apply failed!"
                            exit 1
                        fi
                    '''
                }
            }
        }
```

---

### Step 4: Add Post-Apply Output Stage

Add this stage after "Terraform Apply":

```groovy
        stage('Display Outputs') {
            when {
                anyOf {
                    branch 'develop'
                    branch 'main'
                }
                not {
                    changeRequest()
                }
            }
            steps {
                echo '========== Terraform Outputs =========='
                withCredentials([
                    string(credentialsId: 'aws-access-key-id', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-access-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        # Display all outputs
                        terraform output

                        # Save outputs to file
                        terraform output -json > terraform-outputs.json

                        echo ""
                        echo "✓ Infrastructure deployed successfully!"
                        echo "Check outputs above for access information"
                    '''
                }

                // Archive outputs
                archiveArtifacts artifacts: 'terraform-outputs.json',
                                allowEmptyArchive: true
            }
        }
```

---

### Step 5: Understanding the `when` Directive

**The `when` block controls stage execution:**

```groovy
when {
    anyOf {
        branch 'develop'      // Run on develop branch
        branch 'main'         // OR run on main branch
    }
    not {
        changeRequest()       // BUT NOT on Pull Requests
    }
}
```

**What this means:**
- **PR to develop:** Plan runs, apply does NOT run
- **Merge to develop:** Plan runs, approval requested, apply runs
- **PR to main:** Plan runs, apply does NOT run
- **Merge to main:** Plan runs, approval requested, apply runs

---

### Step 6: Commit and Push Updated Jenkinsfile

```bash
# Verify changes
git diff Jenkinsfile

# Stage and commit
git add Jenkinsfile
git commit -m "feat: Add manual approval and terraform apply stages

- Add manual approval gate before apply
- Implement terraform apply stage using saved plan
- Add post-apply output display
- Configure branch-specific behavior
- Prevent apply on PRs (plan-only)
"

# Push feature branch
git push -u origin feature/add-approval-and-apply
```

---

### Step 7: Create Pull Request to Develop

**On GitHub/Bitbucket:**

1. Create Pull Request
   - From: `feature/add-approval-and-apply`
   - To: `develop`
   - Title: "Add manual approval and terraform apply stages"

2. Wait for Jenkins pipeline to run

**Expected behavior:**
- Pipeline triggers automatically
- All planning stages run
- **Approval stage: SKIPPED** (because it's a PR)
- **Apply stage: SKIPPED** (because it's a PR)
- Plan artifacts saved for review

3. Review plan output in Jenkins artifacts
4. If plan looks good, merge the PR

---

### Step 8: Test Approval Workflow on Develop

**After merging PR:**

1. **Watch Jenkins automatically start new build**
   - Build triggers because code was merged to develop
   - This is NOT a PR, so apply stages will run

2. **Pipeline runs through planning stages**
   - Checkout, Init, Validate, Format, Plan, Archive
   - All should pass as before

3. **Pipeline pauses at Manual Approval stage**

**You'll see:**
```
========================================
TERRAFORM PLAN COMPLETED
========================================
Review the plan output in build artifacts before approving.

Environment: DEVELOPMENT
========================================

Approve Terraform Apply?
Environment: DEVELOPMENT
Branch: develop
Build: #5

[Proceed] or [Abort]
```

---

### Step 9: Review Plan Before Approving

**IMPORTANT: Always review the plan before approving!**

1. Click on build number (e.g., #5)
2. Click **"Build Artifacts"**
3. Download and review `plan-output.txt`
4. Verify changes are expected:
   - Number of resources to add/change/destroy
   - No unintended deletions
   - Correct resource names and configurations

**Questions to ask before approving:**
- Are these the changes I expect?
- Am I deploying to the correct environment?
- Have I tested this code?
- Do I have a rollback plan?
- Is this the right time to deploy?

---

### Step 10: Approve and Apply

**If plan looks correct:**

1. Go back to the pipeline page
2. Click **"Proceed"** or **"Apply Changes"**
3. Watch the pipeline continue:
   - Terraform Apply stage runs
   - Infrastructure is created/updated in AWS
   - Outputs are displayed
   - Outputs archived as JSON

**Console output will show:**
```
========== Applying Terraform Changes ==========
Applying to DEVELOPMENT environment...

terraform apply -input=false tfplan

aws_vpc.main: Creating...
aws_vpc.main: Creation complete after 3s
...
✓ Terraform apply completed successfully

========== Terraform Outputs ==========
instance_public_ip = "54.123.45.67"
vpc_id = "vpc-abc123"
web_url = "http://54.123.45.67"
```

---

### Step 11: Verify Deployed Infrastructure

**In AWS Console:**

1. Log into AWS Console
2. Ensure region is **ap-south-1**
3. Navigate to **EC2** → **Instances**
4. Find your instance with tag: `Owner = UserX`
5. Verify:
   - Instance is running
   - Security group attached
   - VPC is correct
   - Tags are present

**Test the web server:**
```bash
# Get the web URL from pipeline outputs
# Example: http://54.123.45.67

curl http://your-instance-public-ip

# Or open in browser
```

**Expected response:**
```html
<h1>Hello from Terraform!</h1>
<p>This server was provisioned by UserX</p>
<p>Environment: dev</p>
```

---

### Step 12: Test Production Deployment (Optional)

**To test full workflow on main branch:**

1. **Create PR from develop to main**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b prepare-production-release
   # Make any final adjustments
   git push -u origin prepare-production-release
   ```

2. **Create PR:** `prepare-production-release` → `main`

3. **Review and merge**
   - Pipeline runs plan only (no apply on PR)
   - Review plan carefully
   - Get team approval
   - Merge PR

4. **Approve production deployment**
   - Pipeline starts on main branch
   - Pauses at approval with "PRODUCTION ⚠️" warning
   - Review plan extra carefully
   - Click "Proceed" to deploy to production

---

## Understanding Approval Stages

### Why Manual Approval?

**Without approval:**
- Every merge auto-deploys infrastructure
- No human verification
- Risky for production
- Hard to prevent mistakes

**With approval:**
- Human reviews plan before apply
- Can cancel if something looks wrong
- Controlled deployment timing
- Audit trail of who approved

### Approval Best Practices

1. **Always review the plan** - Don't blindly approve
2. **Check the environment** - Dev vs Production
3. **Verify timing** - Is now the right time?
4. **Have rollback ready** - Know how to undo
5. **Communicate** - Tell team about deployments
6. **Use proper approvers** - Production needs senior approval

---

## Approval Workflow Diagram

```
Code Merged
    ↓
Jenkins Builds
    ↓
Terraform Plan
    ↓
Save Plan Artifacts
    ↓
[PAUSE - AWAITING APPROVAL]
    ↓
Human Reviews Plan
    ↓
Decision Point:
    ├─ Approve → Terraform Apply → Infrastructure Updated ✓
    └─ Reject → Pipeline Aborted → No Changes Made

```

---

## Handling Failed Applies

### If Terraform Apply Fails

**Common failures:**
1. AWS service limits reached
2. Resource name conflicts
3. Permission errors
4. Network connectivity issues

**What happens:**
- Apply stage fails
- Pipeline marked as failed
- Partial infrastructure may be created
- State file updated with created resources

**How to recover:**

```bash
# Check what was actually created
terraform show

# Try to fix and re-apply
terraform apply

# Or destroy partial infrastructure
terraform destroy
```

---

## Rollback Procedures

### Rollback Option 1: Revert Code

**If you need to undo changes:**

```bash
# Revert the merge commit
git revert HEAD

# Push revert
git push origin develop

# Jenkins will trigger
# Approve the apply
# Terraform will update to previous state
```

### Rollback Option 2: Terraform Destroy

**To completely remove infrastructure:**

```bash
# Manually run destroy (use carefully!)
terraform destroy

# Or update Jenkinsfile with destroy stage
```

**WARNING:** Destroy is destructive and permanent!

---

## Common Issues & Troubleshooting

### Issue: Approval Stage Not Appearing

**Cause:** Running on PR or incorrect branch

**Solution:**
- Approval only runs on `develop` or `main` branches
- Approval is SKIPPED on Pull Requests
- Verify you've merged the PR (not just created it)

### Issue: "User X is not allowed to approve"

**Error message:**
```
User alice is not in the list of approved submitters
```

**Solution:**
```groovy
// Update submitter list in Jenkinsfile
input message: 'Approve?',
      submitter: 'admin,devops,alice'  // Add your username
```

---

## Common Issues (continued)

### Issue: Apply Fails with "No saved plan"

**Error:**
```
Error: Saved plan is stale
```

**Cause:** Time passed between plan and apply, state changed

**Solution:**
- Re-run the pipeline
- Plan and apply happen in same build
- Don't wait too long between approval requests

### Issue: Apply Succeeds But Resources Not Visible

**Check:**
1. Correct AWS region (ap-south-1)
2. Correct AWS account
3. Resource tags (search by Owner = UserX)
4. State file shows resources created

**Verify:**
```bash
terraform state list
terraform output
```

---

## Optional Challenge: Add Slack Notifications

**Challenge 1: Notify on Approval Needed**

```groovy
stage('Manual Approval') {
    steps {
        // Send Slack notification
        slackSend color: 'warning',
                  message: "Approval needed for ${env.JOB_NAME} - ${env.BUILD_URL}"

        // Request approval
        input message: 'Approve?', ok: 'Deploy'
    }
}
```

**Challenge 2: Notify on Deployment Success**

```groovy
post {
    success {
        slackSend color: 'good',
                  message: "Deployment successful: ${env.JOB_NAME} to ${env.BRANCH_NAME}"
    }
}
```

---

## Optional Challenge: Multi-Approver Workflow

**Challenge 3: Require Multiple Approvals for Production**

```groovy
stage('Senior Approval') {
    when {
        branch 'main'
    }
    steps {
        input message: 'Senior approval required for production',
              ok: 'Approve',
              submitter: 'senior-devops,cto'
    }
}

stage('Final Confirmation') {
    when {
        branch 'main'
    }
    steps {
        input message: 'Final confirmation before production deployment',
              ok: 'Deploy to Production',
              submitter: 'admin'
    }
}
```

---

## Optional Challenge: Approval Timeout

**Challenge 4: Auto-Reject After Timeout**

```groovy
stage('Manual Approval') {
    steps {
        timeout(time: 30, unit: 'MINUTES') {
            input message: 'Approve within 30 minutes',
                  ok: 'Deploy'
        }
    }
}
```

If no one approves within 30 minutes, pipeline fails automatically.

---

## Success Validation

**You've successfully completed this lab if:**

1. Jenkinsfile updated with approval and apply stages
2. Pipeline runs plan-only on Pull Requests
3. Pipeline requests approval after merge to develop/main
4. Can successfully approve and deploy infrastructure
5. Infrastructure visible in AWS after apply
6. Terraform outputs displayed in Jenkins
7. Can explain when to approve vs reject
8. Understand branch-specific pipeline behavior

---

## Key Takeaways

**Complete GitOps Workflow Achieved**

- Infrastructure deployed through Git commits
- Automated validation prevents broken code
- Manual approval prevents unwanted changes
- Different environments handled by branches
- Full audit trail of all changes
- Rollback capability through Git

**Lab 7 + Lab 8 = Production-Ready CI/CD**
- Lab 7: Automated testing (plan)
- Lab 8: Controlled deployment (apply with approval)
- Together: Complete infrastructure delivery pipeline

---

## Branching Strategy Summary

**Feature Branch:**
- Developer works here
- No pipeline triggers on commits

**Pull Request to Develop:**
- Pipeline runs: Plan only
- Review before merge
- No infrastructure changes

**Develop Branch (after merge):**
- Pipeline runs: Plan → Approval → Apply
- Deploys to development environment
- Test changes here

**Main Branch (after merge from develop):**
- Pipeline runs: Plan → Approval → Apply
- Deploys to production environment
- Production-ready code only

---

## Clean Up

**If you want to destroy test infrastructure:**

**Option 1: Via Jenkins (Recommended)**

Add destroy stage to Jenkinsfile:
```groovy
stage('Destroy (Manual)') {
    when {
        expression {
            return params.DESTROY == true
        }
    }
    steps {
        input message: 'Confirm destroy?', ok: 'Destroy All'
        sh 'terraform destroy -auto-approve'
    }
}
```

**Option 2: Manually**

```bash
cd ~/lab6
terraform destroy
```

---

## Best Practices Summary

### Approval Workflow
- ✓ Always review plan before approving
- ✓ Use restrictive submitter lists
- ✓ Different approvers for dev vs prod
- ✓ Set approval timeouts
- ✓ Document approval criteria

### Pipeline Design
- ✓ Plan on PRs, apply on merge
- ✓ Use saved plan files
- ✓ Archive all outputs
- ✓ Clear environment indicators
- ✓ Proper error handling

### Safety
- ✓ Never auto-apply to production
- ✓ Test in develop first
- ✓ Have rollback procedures
- ✓ Monitor apply execution
- ✓ Use least-privilege permissions

---

## Additional Resources

- [Jenkins Pipeline Input Step](https://www.jenkins.io/doc/pipeline/steps/pipeline-input-step/)
- [Terraform Apply Documentation](https://developer.hashicorp.com/terraform/cli/commands/apply)
- [GitOps Principles](https://www.gitops.tech/)
- [Jenkins When Conditions](https://www.jenkins.io/doc/book/pipeline/syntax/#when)
- [Terraform State Management](https://developer.hashicorp.com/terraform/language/state)
- [Infrastructure as Code Best Practices](https://docs.aws.amazon.com/prescriptive-guidance/latest/choose-iac-tool/best-practices.html)

---

# Questions?

Great job completing Lab 8!

You now have a complete, production-ready CI/CD pipeline for Terraform infrastructure deployments with proper approval gates and environment controls.

**Next:** Day 3 will build on this foundation with modules, workspaces, and policy enforcement!
