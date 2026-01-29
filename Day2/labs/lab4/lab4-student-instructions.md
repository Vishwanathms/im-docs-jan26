# Lab 4
## Parameterize Infrastructure with Variables

---

## Objective

Learn how to use variables to make your Terraform code flexible and reusable.

---

## Time Estimate

**20-25 minutes**

---

## What You'll Learn

- How to declare and use variables in Terraform
- Basic variable types (string)
- How to validate variable values
- How to use `terraform.tfvars` files
- How to override variables via CLI
- How to create outputs

---

## Prerequisites

- Completed Lab 1 (understanding of basic Terraform workflow)
- Text editor for modifying `.tf` files

---

## High-Level Instructions

1. Create project directory
2. Write configuration files (`terraform.tf`, `variables.tf`, `terraform.tfvars`, `main.tf`, `outputs.tf`)
3. Initialize and validate
4. Plan and apply deployment
5. Test variable validation
6. Test CLI variable override
7. Destroy infrastructure

---

## Documentation Links

- [Input Variables](https://developer.hashicorp.com/terraform/language/values/variables)
- [Variable Types](https://developer.hashicorp.com/terraform/language/expressions/type-constraints)
- [Variable Validation](https://developer.hashicorp.com/terraform/language/values/variables#custom-validation-rules)
- [Output Values](https://developer.hashicorp.com/terraform/language/values/outputs)
- [Variable Definition Files](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files)

---

## Detailed Instructions

### Step 1: Set Up Your Working Directory

Create a new directory for this lab:

```bash
cd
mkdir lab4
cd lab4
```

**Note:** This lab focuses on making your Terraform configurations flexible and reusable using variables.

---

### Step 2: Create Terraform Configuration

Create `terraform.tf`:

```hcl
# Terraform and provider version requirements
terraform {
  required_version = ">= 1.3.15"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }
}

# AWS Provider configuration
provider "aws" {
  region = var.aws_region # Using a variable for region

  default_tags {
    tags = {
      owner = "userX" # Replace with your user number
    }
  }
}
```

---

### Step 3: Understanding Provider Configuration

**What's New in This Lab:**
- `region = var.aws_region` - Region is now a variable instead of hardcoded
- `owner = "userX"` - Consistent with Lab 1's tagging approach

**Why This Matters:**
- Easy to deploy to different regions by changing one variable
- Variables make configurations reusable across environments
- No hardcoded values to change manually throughout your code

---

### Step 4: Create Variables File

Create `variables.tf`:

```hcl
# AWS Region variable
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

# EC2 instance type
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  # No default - must be provided in terraform.tfvars or Terraform will prompt

  validation {
    condition     = contains(["t3.nano", "t3.micro"], var.instance_type)
    error_message = "Only t3.nano or t3.micro are allowed."
  }
}
```

**What this code does:**
- `variable "aws_region"` - Declares the region variable with a default
- `default = "ap-south-1"` - Makes this variable **optional** (uses default if not specified)
- `variable "instance_type"` - Declares the instance type variable **without a default**
- **No default** - Makes this variable **required** (Terraform will prompt if not set in terraform.tfvars)
- `validation` - Ensures only t3.nano or t3.micro can be used
- `contains()` - Checks if the value is in the allowed list

**Understanding Required vs Optional Variables:**
- Variables **with** `default` = optional (Terraform uses the default if not provided)
- Variables **without** `default` = required (must be set in terraform.tfvars or Terraform will prompt)
- Best practice: Use terraform.tfvars to avoid interactive prompts

---

### Step 5: Understanding Variables

**What's Different from Lab 1?**

In Lab 1, we hardcoded values in main.tf:
```hcl
region = "ap-south-1"
instance_type = "t3.micro"
```

With variables, we:
1. Declare variables in `variables.tf`
2. Reference them in code with `var.variable_name`

**Why This Matters:**
- Change one value in terraform.tfvars → affects entire configuration
- Reuse same code for different environments
- Prevent errors with validation rules

---

### Step 6: Create Variable Values File

Create `terraform.tfvars`:

```hcl
# terraform.tfvars - Your variable values

aws_region    = "ap-south-1"
instance_type = "t3.nano"
```

**What this file does:**
- Sets actual values for variables declared in variables.tf
- `aws_region` and `instance_type` - Can be changed without modifying main.tf
- These values override the defaults set in variables.tf

---

### Step 7: Create Main Infrastructure

Create `main.tf`:

```hcl
# Data source to get the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 instance using variables
resource "aws_instance" "my_instance" {
  ami           = data.aws_ami.amazon_linux_2023.id
  instance_type = var.instance_type

  tags = {
    Name = "userX"  # Replace with your user number (user1, user2, etc.)
  }
}
```

**What this code does:**
- `data "aws_ami"` - Automatically finds the latest Amazon Linux 2023 AMI
- `ami = data.aws_ami.amazon_linux_2023.id` - Uses the AMI from data source
- `instance_type = var.instance_type` - **Uses the variable instead of hardcoding!**
- `Name = "userX"` - **IMPORTANT: Replace with your student number** - Identifies your instance in the AWS Console

**Compare to Lab 1:**
- Lab 1: `instance_type = "t3.micro"` (hardcoded)
- Lab 4: `instance_type = var.instance_type` (flexible!)

---

### Step 8: Create Outputs File

Create `outputs.tf`:

```hcl
# Outputs to display after apply

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.my_instance.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.my_instance.public_ip
}

output "configuration" {
  description = "Instance configuration used"
  value = {
    instance_type = var.instance_type
    region        = var.aws_region
  }
}
```

**What this code does:**
- `output "instance_id"` - Shows the instance ID after creation
- `output "instance_public_ip"` - Shows the public IP address
- `output "configuration"` - Shows which variable values were used
- These appear automatically after `terraform apply`

---

### Step 9: Initialize Terraform

Download the AWS provider plugin:

```bash
terraform init
```

---

### Step 10: Validate Configuration

Check for syntax errors:

```bash
terraform validate
```

---

### Step 10a: Optional - Test Variable Prompting

Want to see what happens when a required variable isn't set? Try this:

```bash
# Temporarily rename terraform.tfvars
mv terraform.tfvars terraform.tfvars.backup

# Try to plan - Terraform will prompt for instance_type
terraform plan
```

**What happens:**
- Terraform will prompt: `var.instance_type`
- Type `t3.nano` and press Enter
- The plan will proceed normally

**Why this matters:**
- Variables without defaults are **required**
- Terraform prompts for missing values interactively
- Using terraform.tfvars avoids these prompts (better for automation)

**Restore your file:**
```bash
mv terraform.tfvars.backup terraform.tfvars
```

---

### Step 11: Preview Changes

See what Terraform will create:

```bash
terraform plan
```

**What to look for:**
- `Plan: 1 to add` (instance)
- Variable values being used (instance_type, aws_region)
- Check that your variables show the correct values from terraform.tfvars

---

### Step 12: Deploy Infrastructure

Create the EC2 instance:

```bash
terraform apply
```

Type `yes` when prompted.

**After apply completes, you'll see the outputs:**
- instance_id
- instance_public_ip
- configuration (showing your variable values)

---

### Step 13: View Outputs

```bash
# View all outputs
terraform output

# View specific output
terraform output instance_id
```

---

### Step 14: Test Variable Validation

Let's test that validation rules work. Edit `terraform.tfvars` and try an invalid value:

**Test: Invalid Instance Type**
```hcl
instance_type = "t3.small"  # Not in allowed list
```

Run the plan:
```bash
terraform plan
```

**You'll see an error:**
```
Error: Invalid value for variable
Only t3.nano or t3.micro are allowed.
```

**Fix it** by changing back to `t3.nano` in terraform.tfvars before continuing.

---

### Step 15: Test CLI Variable Override

You can override variables from the command line without editing files:

```bash
# This will show a plan using t3.micro instead of t3.nano
terraform plan -var="instance_type=t3.micro"
```

**What to notice:**
- The plan shows `instance_type = "t3.micro"`
- But terraform.tfvars still has `t3.nano`
- CLI flags override terraform.tfvars values

**Don't apply** - we're just testing how variable overrides work.

---

### Step 16: Clean Up Resources

Destroy the infrastructure:

```bash
terraform destroy
```

Type `yes` when prompted.

---

## Optional Challenge

Ready for more practice? Try deploying with a different configuration.

**Challenge: Create a Staging Configuration**

1. Create a new file called `staging.tfvars`:

```hcl
aws_region    = "ap-south-1"
instance_type = "t3.micro"  # Larger than dev
```

2. Test it (but don't apply to avoid extra costs):

```bash
terraform plan -var-file="staging.tfvars"
```

**What to notice:**
- The plan shows `t3.micro` instead of `t3.nano`
- Same code, different configuration!
- This is how you'd deploy to different environments

---

## Congratulations!

You've successfully learned:
- How to declare variables in Terraform
- How to use terraform.tfvars to set variable values
- How to validate variables with simple rules
- How to reference variables in your code with `var.`
- How to override variables from the command line
- How to create outputs to display information

**What makes variables useful:**
- Same code works for different environments
- Change values without modifying .tf files
- Validation prevents mistakes
- Outputs show important information
