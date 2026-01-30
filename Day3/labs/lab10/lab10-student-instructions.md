# Lab 10: Multi-Environment Deployment

## Using Workspaces for Dev and Staging

---

## Objective

Learn to manage multiple environments (dev, staging) using Terraform workspaces with environment-specific configurations and resource sizing.

---

## Time Estimate

**45-55 minutes**

---

## What You'll Learn

- Understanding Terraform workspaces
- Creating and switching between workspaces
- Using workspace-specific variable values
- Implementing environment-based resource sizing
- Managing separate state files per environment
- Best practices for multi-environment deployments

---

## High-Level Instructions

1. Set up workspace-aware variable configuration
2. Create environment-specific variable files
3. Update modules to support different sizing per environment
4. Create workspaces for dev and staging
5. Deploy to each environment with appropriate sizing
6. Verify separate state files and resources

---

## Documentation Links

- [Terraform Workspaces](https://developer.hashicorp.com/terraform/language/state/workspaces)
- [Managing Workspaces](https://developer.hashicorp.com/terraform/cli/workspaces)
- [Workspace Interpolation](https://developer.hashicorp.com/terraform/language/state/workspaces#current-workspace-interpolation)

---

## Detailed Instructions

### Step 1: Understand Workspace Concept

Workspaces allow you to manage multiple instances of infrastructure with the same code but different state files.

**Key Points:**
- Each workspace has its own state file
- Same code, different variable values
- Useful for dev/staging environments
- Access workspace name via `terraform.workspace`

---

### Step 2: Create Your Working Directory

First, go to your home directory and create a fresh lab10 directory. We'll copy your Lab 9 work as the starting point.

```bash
# Go to home directory
cd ~

# Create lab10 directory
mkdir ~/lab10
cd ~/lab10

# Copy all source files from your Lab 9 work
cp -R ~/lab9/* .
```


Your directory should now contain your Lab 9 modules:
```
lab10/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tf
├── terraform.tfvars
└── modules/
    ├── security_groups/
    ├── iam/
    └── ec2/
```

---

### Step 3: Add Environment-Specific Variable Files

Create two variable files for different environments. Each environment uses different instance sizing:

**File: `dev.tfvars`**

```hcl
# Development Environment Configuration
aws_region    = "ap-south-1"
instance_type = "t3.nano"
```

**File: `staging.tfvars`**

```hcl
# Staging Environment Configuration
aws_region    = "ap-south-1"
instance_type = "t3.micro"
```

---

### Step 4: Initialize Terraform

```bash
# Initialize Terraform (only needed once)
terraform init
```

---

### Step 5: Deploy to Development Environment

```bash
# Create and switch to dev workspace
terraform workspace new dev

# Or switch if already exists
# terraform workspace select dev

# View the plan
terraform plan -var-file="dev.tfvars" -var="project=UserX"

# Apply the configuration
terraform apply -var-file="dev.tfvars" -var="project=UserX"
```

**IMPORTANT**: Replace `UserX` with your unique student identifier (e.g., User1, User2, etc.)

---

### Step 6: Deploy to Staging Environment

```bash
# Create and switch to staging workspace
terraform workspace new staging

# View the plan
terraform plan -var-file="staging.tfvars" -var="project=UserX"

# Apply the configuration
terraform apply -var-file="staging.tfvars" -var="project=UserX"
```

---

### Step 7: Explore Workspaces

```bash
# List all workspaces
terraform workspace list

# Show current workspace
terraform workspace show

# Switch between workspaces
terraform workspace select dev
terraform workspace select staging

# View outputs for each workspace
terraform workspace select dev
terraform output

terraform workspace select staging
terraform output
```

---

## Key Concepts Recap

### Workspaces Benefits
- **Isolation**: Separate state files per environment
- **Code Reuse**: Same Terraform code for all environments
- **Simplicity**: Easy to switch between environments
- **Organization**: Clear separation of concerns

### Workspaces vs. Other Approaches
- **Workspaces**: Same backend, different state files
- **Separate Directories**: Different code per environment
- **Terragrunt**: Advanced multi-environment management

### Best Practices
- Use variable files for environment-specific values
- Name resources with workspace/environment prefix
- Use different CIDR ranges per environment
- Size resources appropriately per environment

---

## Verification Checklist

### Verify Each Environment

```bash
# Check dev environment
terraform workspace select dev
terraform output

# Get instance type (should be t3.nano for dev)
aws ec2 describe-instances \
  --filters "Name=tag:owner,Values=userX" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceType,Tags[?Key==`Name`].Value|[0]]' \
  --output table --region ap-south-1

# Check staging environment
terraform workspace select staging
terraform output

# Get instance type (should be t3.micro for staging)
aws ec2 describe-instances \
  --filters "Name=tag:owner,Values=userX" "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceType,Tags[?Key==`Name`].Value|[0]]' \
  --output table --region ap-south-1
```

---

### Verify State File Separation

```bash
# Check state files (if using local backend)
ls -la terraform.tfstate.d/

# You should see:
# terraform.tfstate.d/dev/
# terraform.tfstate.d/staging/
```

---

## Common Issues and Solutions

### Issue 1: Wrong Workspace Active
**Error**: Resources created in wrong environment
**Solution**: Always verify current workspace before applying:
```bash
terraform workspace show
```

### Issue 2: Variable File Not Applied
**Error**: Default values used instead of tfvars
**Solution**: Always specify `-var-file` flag:
```bash
terraform apply -var-file="dev.tfvars"
```

### Issue 3: Resources Not Created in Expected Workspace
**Error**: Resources appear in wrong workspace state
**Solution**: Always verify workspace before running apply:
```bash
terraform workspace show
```

---

## Optional Challenge Exercises

### Challenge 1: Add Remote Backend
Configure S3 backend with workspace-specific state file prefixes:
```hcl
backend "s3" {
  bucket = "userX-terraform-state"
  key    = "env/${terraform.workspace}/terraform.tfstate"
  region = "ap-south-1"
}
```

### Challenge 2: Environment-Specific Tags
Add environment-specific tags with compliance requirements for production.

### Challenge 3: Conditional Resources
Create a NAT gateway only in staging, not in dev.

### Challenge 4: Automated Workspace Selection
Create a shell script that automatically selects workspace based on input parameter.

---

## Clean Up

Clean up each environment separately:

```bash
# Destroy dev
terraform workspace select dev
terraform destroy -var-file="dev.tfvars" -var="project=UserX"

# Destroy staging
terraform workspace select staging
terraform destroy -var-file="staging.tfvars" -var="project=UserX"

# Delete workspaces
terraform workspace select default
terraform workspace delete dev
terraform workspace delete staging
```

---

## Next Steps

In Lab 11, you'll add policy enforcement using Open Policy Agent (OPA) to ensure compliance across all environments.

---

# Questions?

Great job completing Lab 10! You now understand how to manage multiple environments using Terraform workspaces.
