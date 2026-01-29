# Module 8: CI/CD Pipeline Fundamentals

**Automating Terraform with Jenkins**

---

# Learning Objectives

By the end of this module, you will understand:

- Why we automate Terraform instead of running it manually
- What CI/CD means and how it helps infrastructure teams
- How Jenkins pipelines work with Terraform
- How to read and understand a Jenkinsfile
- How branch-based workflows control deployments

---

# Why Automate Terraform?

## The Problem with Manual Workflow

When developers run Terraform manually:

1. Write Terraform code locally
2. Run `terraform plan` on their machine
3. Run `terraform apply` manually
4. Push code to Git

**What can go wrong:**

- Different results on different machines
- No record of who applied what changes
- Easy to skip validation steps
- Easy to apply to the wrong environment
- No approval process for production changes

---

## The Solution: CI/CD Pipelines

**CI/CD** stands for Continuous Integration / Continuous Deployment.

- **Continuous Integration (CI):** Automatically test code when pushed
- **Continuous Deployment (CD):** Automatically deploy approved changes

For Terraform, this means:

```
Code Push → Auto Validate → Auto Plan → Human Approval → Auto Apply
```

**Benefits:**

- Same process every time (consistency)
- Full history of all changes (audit trail)
- Required approval before production changes (safety)
- Errors caught early (fast feedback)

---

# Key Concepts

## What is a Pipeline?

Think of a pipeline like a factory assembly line. Your code moves through stations. Each station does one job:

**Checkout** → **Init** → **Validate** → **Plan** → **Apply**

If any station fails, the pipeline stops. This prevents broken code from being deployed.

---

## What is Jenkins?

Jenkins is a free automation tool that runs pipelines.

**How it works:**

1. Jenkins watches your Git repository
2. When you push code, Jenkins detects the change
3. Jenkins runs your pipeline automatically
4. You see the results in the Jenkins web interface

In the labs, your instructor provides a Jenkins server. You don't need to install anything.

---

## What is GitOps?

GitOps is a simple idea: **your Git repository is the source of truth**.

**Four principles:**

1. **All infrastructure is defined in Git** - No manual changes
2. **Git history = change history** - Full audit trail
3. **Changes happen through Pull Requests** - Review before deploy
4. **Automation enforces the state** - Pipeline applies what's in Git

**Benefit:** To see what's deployed, just look at Git. To rollback, just revert a commit.

---

# Pipeline Architecture

## How the Pieces Fit Together

**Developer** → **GitHub** → **Jenkins** → **AWS**

1. **Developer** writes Terraform code and pushes to Git
2. **GitHub** stores your code and Pull Requests
3. **Jenkins** detects changes and runs the pipeline (init, validate, plan, apply)
4. **AWS** receives the infrastructure changes

---

# The Jenkinsfile

## What is a Jenkinsfile?

A Jenkinsfile is a text file that defines your pipeline. It lives in the root of your Git repository.

Think of it as a recipe. It tells Jenkins exactly what to do.

**Basic structure:**

```groovy
pipeline {
    agent any                    // Run on any available server

    stages {
        stage('Stage Name') {    // Each station in the assembly line
            steps {
                sh 'command'     // Commands to run
            }
        }
    }
}
```

---

## Pipeline Stages Explained

Each stage does one job:

| Stage | What it does | Terraform command |
|-------|--------------|-------------------|
| Checkout | Gets code from Git | (automatic) |
| Init | Downloads providers | `terraform init` |
| Validate | Checks syntax | `terraform validate` |
| Plan | Shows what will change | `terraform plan` |
| Approval | Waits for human OK | `input` step |
| Apply | Makes the changes | `terraform apply` |

---

## Simple Jenkinsfile Example

This is similar to what you'll use in Lab 7:

```groovy
pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm    // Get code from Git
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }
    }
}
```

This pipeline will run automatically when you push code. It checks your Terraform but does not apply changes yet.

---

## Adding Approval and Apply

In Lab 8, you'll add these stages:

```groovy
        stage('Approval') {
            when {
                branch 'develop'    // Only on develop branch
            }
            steps {
                input message: 'Apply changes?', ok: 'Apply'
            }
        }

        stage('Terraform Apply') {
            when {
                branch 'develop'    // Only on develop branch
            }
            steps {
                sh 'terraform apply -auto-approve'
            }
        }
```

**Key points:**

- `when { branch 'develop' }` - Stage only runs on develop branch
- `input` - Pauses and waits for human approval
- `-auto-approve` - Safe here because human already approved

---

# Branch Workflow

## How Branches Control Deployments

Different branches trigger different behavior:

- **feature/*** → Plan only (testing)
- **develop** → Plan + Apply (to staging)
- **main** → Plan + Apply (to production)

---

## What Happens on Each Branch

| Branch | What runs | Result |
|--------|-----------|--------|
| `feature/*` | Plan only | See what would change, no deployment |
| `develop` | Plan → Approval → Apply | Deploy to development/staging |
| `main` | Plan → Approval → Apply | Deploy to production |

**Pull Requests:** Always run plan only. Never apply on a PR.

---

## The `when` Directive

The `when` block controls when a stage runs:

```groovy
stage('Terraform Apply') {
    when {
        branch 'develop'    // Only run on develop branch
    }
    steps {
        sh 'terraform apply -auto-approve'
    }
}
```

**Common patterns:**

```groovy
when { branch 'main' }              // Only on main
when { branch 'develop' }           // Only on develop
when { anyOf {                      // On main OR develop
    branch 'main'
    branch 'develop'
}}
```

---

# What You'll Do in the Labs

## Lab 7: Automated Planning

You will:

1. Create a GitHub personal access token
2. Create a Jenkins Multibranch Pipeline job
3. Add a simple Jenkinsfile to your repository
4. Push code and watch Jenkins run automatically
5. View the Terraform plan output in Jenkins

**Result:** Every push triggers automatic validation and planning.

```
Push code → Jenkins detects → Runs init, validate, plan → See results
```

---

## Lab 8: Controlled Apply

You will:

1. Add an approval stage to your Jenkinsfile
2. Add a terraform apply stage
3. Use `when` blocks for branch-specific behavior
4. Test the approval workflow
5. Verify infrastructure is created in AWS

**Result:** Infrastructure deploys only after human approval.

```
Push to develop → Plan runs → Wait for approval → Apply → Infrastructure created
```

---

# Key Takeaways

1. **CI/CD automates your Terraform workflow** - No more manual runs
2. **Jenkinsfile is your pipeline recipe** - Lives in Git with your code
3. **Pipelines have stages** - Each stage does one job
4. **Branches control behavior** - Different branches, different actions
5. **Approval gates add safety** - Human review before production
6. **GitOps means Git is truth** - What's in Git is what's deployed

---

# Knowledge Check

## Question 1

**What is the main benefit of using CI/CD for Terraform?**

A) It makes Terraform run faster
B) It ensures consistent, automated validation and deployment
C) It removes the need for state files
D) It allows you to skip the plan step

<!--
Answer: B
Explanation: CI/CD ensures every change goes through the same automated process - validation, planning, and controlled deployment. This provides consistency and catches errors early.
-->

---

## Question 2

**Which Jenkinsfile directive controls when a stage runs?**

A) `if { branch 'main' }`
B) `when { branch 'main' }`
C) `only { branch 'main' }`
D) `run { branch 'main' }`

<!--
Answer: B
Explanation: The `when` directive with `branch` condition controls stage execution based on the Git branch.
-->

---

## Question 3

**In a GitOps workflow, where should infrastructure changes be made?**

A) Directly in AWS console
B) On the Jenkins server
C) Through Git commits and Pull Requests
D) Using terraform apply on your laptop

<!--
Answer: C
Explanation: GitOps means all changes go through Git. You commit code, create a PR, get approval, merge, and the pipeline applies the changes. This ensures full audit trail and review.
-->

---

# Next Steps

Complete **Lab 7** and **Lab 8** to practice these concepts hands-on!

- Lab 7: Set up Jenkins pipeline with automated planning
- Lab 8: Add approval gates and controlled apply
