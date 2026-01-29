---
marp: true
header: 'Terraform level 1 - Day 2 - **Lab 5**'
paginate: true
---

# Lab 5
## Migrate Local to Remote State

---

## Objective

In this lab, you will migrate your Terraform state from local storage to a remote backend using AWS S3. This enables team collaboration, state locking, and enhanced security for managing infrastructure in a shared environment.

---

## Time Estimate

**25-35 minutes**

---

## What You'll Learn

- How to create an S3 bucket for remote state storage
- How to enable S3 versioning for state locking and recovery
- How to configure Terraform backend settings
- How to migrate existing local state to remote storage
- How S3 native locking prevents concurrent modifications
- Best practices for remote state management in team environments

## High-Level Instructions

1. Create S3 bucket for state storage with versioning enabled
2. Configure Terraform backend in `terraform.tf`
3. Initialize and migrate state to remote backend
4. Verify remote state is working
5. Understand S3 native state locking

---

## Documentation Links

- [Terraform S3 Backend](https://developer.hashicorp.com/terraform/language/settings/backends/s3)
- [AWS S3 Bucket Configuration](https://docs.aws.amazon.com/AmazonS3/latest/userguide/creating-bucket.html)
- [S3 State Locking](https://developer.hashicorp.com/terraform/language/settings/backends/s3#s3-state-locking)
- [Backend Configuration](https://developer.hashicorp.com/terraform/language/settings/backends/configuration)

---

## Detailed Instructions

### Step 1: Set Up Backend Infrastructure

First, we need to create the S3 bucket that will store our state. Copy the backend setup files:

```bash
cd
mkdir lab5-backend-setup
cp ~/day2/labs/lab5/lab5-backend-setup/* ~/lab5-backend-setup/
cd ~/lab5-backend-setup
```

**IMPORTANT:** Edit the files and replace `userX` with your assigned user number (e.g., user1, user2) in both `main.tf` and `terraform.tf`.

---

### Step 2: Initialize and Apply Backend Setup

```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted.

---

### Step 3: Set Up Environment Variable

To make the following commands easier, let's set an environment variable for your bucket name:

```bash
# Replace userX with your user number (e.g., user1, user2, etc.)
export BUCKET_NAME="boa-terraform-state-userX"
```

**Important:** Replace `userX` with your actual user number before running this command!

---

### Step 4: Verify Backend Resources Created

```bash
# Check S3 bucket exists
aws s3 ls | grep $BUCKET_NAME

# Get bucket details
aws s3api get-bucket-versioning --bucket $BUCKET_NAME
```

---

### Step 5: Set Up Your Working Directory

Now set up your main lab5 directory by copying the lab4 solution files:

```bash
cd
mkdir lab5
cp ~/day2/labs/lab4/lab4-solution/* ~/lab5/
cd ~/lab5
```

---

### Step 6: Initialize Your Main Infrastructure

```bash
cd ~/lab5

# Initialize Terraform (this will use local state initially)
terraform init

# Create a plan
terraform plan

# Apply the configuration
terraform apply
```

Type `yes` when prompted.

---

### Step 7: Configure Remote Backend

Now let's migrate to remote state. Edit `terraform.tf` and add the backend configuration **inside the existing `terraform {}` block**:

```hcl
  # Remote backend configuration - ADD THIS inside terraform {} block
  backend "s3" {
    bucket       = "boa-terraform-state-userX" # Replace userX
    key          = "terraform.tfstate"     # Path within bucket
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # S3 native locking (requires versioning enabled)
  }
```

**IMPORTANT:** Replace `userX` with your user number in the backend configuration!

---

### Step 8: Migrate State to Remote Backend

```bash
# Re-initialize Terraform with the new backend
terraform init -migrate-state
```

**You will be prompted:** `Do you want to copy existing state to the new backend?`

Type `yes` to migrate the state.

---

### Step 9: Verify Remote State Migration

```bash
# Check that local state is now just a pointer
cat terraform.tfstate

# Verify state is in S3
aws s3 ls s3://$BUCKET_NAME/

# Download and view the remote state (for verification only)
aws s3 cp s3://$BUCKET_NAME/terraform.tfstate remote-state.json
cat remote-state.json
```

---

### Step 10: Clean Up Resources

**Clean up the main infrastructure:**
```bash
cd ~/lab5
terraform destroy
```

**Clean up the backend infrastructure:**
```bash
cd ~/lab5-backend-setup

# First, empty the S3 bucket (required before deletion)
aws s3 rm s3://$BUCKET_NAME --recursive

# Now destroy the backend resources
terraform destroy
```

Type `yes` when prompted.

---