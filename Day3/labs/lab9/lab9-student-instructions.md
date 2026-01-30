# Lab 9: Refactoring to Modules

## From Monolithic to Modular Terraform

---

## Objective

Learn to create and use Terraform modules by refactoring the monolithic configuration from Lab 3 into a clean, modular structure. You'll extract resources into reusable modules step-by-step.

---

## Time Estimate

**40-50 minutes**

---

## What You'll Learn

- Why modules improve maintainability and reusability
- How to structure a Terraform module (main.tf, variables.tf, outputs.tf)
- How to extract resources from a monolithic configuration
- How to pass data between modules using variables and outputs
- How to call modules from a root configuration

---

## The Refactoring Journey

We'll transform this flat structure:

```
lab3-solution/
├── main.tf          # All resources in one file
└── terraform.tf     # Provider configuration
```

Into this modular structure:

```
lab9/
├── main.tf              # Module calls only
├── terraform.tf         # Provider configuration
├── variables.tf         # Root-level variables
├── outputs.tf           # Root-level outputs
└── modules/
    ├── security_groups/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── iam/
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── ec2/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

---

## Why Modules?

Before we start, let's understand why this refactoring is valuable:

| Benefit | Description |
|---------|-------------|
| **Reusability** | Use the same module in multiple projects or environments |
| **Organization** | Group related resources logically |
| **Encapsulation** | Hide complexity behind simple interfaces |
| **Maintainability** | Changes in one module don't affect others |
| **Testing** | Test modules independently |

> **Note:** You learned about module structure (main.tf, variables.tf, outputs.tf) in the lecture. This lab puts that knowledge into practice.

Now let's start refactoring!

---

## Step 1: Create Your Working Directory

First, create a fresh working directory and copy only the source files from lab3-solution (not state or cache files):

```bash
# Create a new directory for lab9
mkdir ~/lab9
cd ~/lab9

# Copy only the source files from lab3-solution
cp ~/day1/lab3-solution/main.tf .
cp ~/day1/lab3-solution/terraform.tf .
```

> **Important**: Do NOT copy `.terraform/`, `terraform.tfstate`, or `.terraform.lock.hcl`. We want a clean start.

Your directory should now contain:
```
lab9/
├── main.tf
└── terraform.tf
```

Initialize Terraform:
```bash
terraform init
```

---

## Step 2: Create Module Directory Structure

Create the directories for our three modules:

```bash
mkdir -p modules/security_groups
mkdir -p modules/iam
mkdir -p modules/ec2
```

Your structure now looks like:
```
lab9/
├── main.tf
├── terraform.tf
└── modules/
    ├── security_groups/
    ├── iam/
    └── ec2/
```

---

## Step 3: Create Root-Level Variables

Before extracting modules, let's parameterize our configuration. Create a new file `variables.tf` in the root directory:

**File: `variables.tf`**

```hcl
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Project name - use userX format where X is your student number"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}
```

Now update `terraform.tf` to use these variables:

**File: `terraform.tf`**

```hcl
terraform {
  required_version = "~> 1.13.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  # IMPORTANT: Change 'userX' to your assigned student ID (user1, user2, etc.)
  default_tags {
    tags = {
      owner = var.project
    }
  }
}
```

---

## Step 4: Extract the Security Groups Module

Now let's extract the security group resources into their own module.

### 4.1 Create Module Variables

**File: `modules/security_groups/variables.tf`**

```hcl
variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "project" {
  description = "Project name - use UserX format where X is your student number"
  type        = string
}
```

### 4.2 Create Module Main Configuration

Move the security group resources from root `main.tf` to the module. Update the naming from `lab3-*` to `lab9-*` and replace hardcoded values with variables:

**File: `modules/security_groups/main.tf`**

```hcl
# Security Group - base security group (rules defined separately)
resource "aws_security_group" "web_sg" {
  name        = "lab9-web-sg-${var.project}"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "lab9-web-sg-${var.project}"
  }
}

# Security Group Rule - HTTP ingress
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab9-http-rule-${var.project}"
  }
}

# Security Group Rule - Allow all outbound
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.web_sg.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab9-egress-rule-${var.project}"
  }
}
```

### 4.3 Create Module Outputs

Modules communicate with the outside world through outputs. Other modules will need the security group ID:

**File: `modules/security_groups/outputs.tf`**

```hcl
output "web_sg_id" {
  description = "ID of the web security group"
  value       = aws_security_group.web_sg.id
}
```

---

## Step 5: Extract the IAM Module

### 5.1 Create Module Variables

**File: `modules/iam/variables.tf`**

```hcl
variable "project" {
  description = "Project name - use UserX format where X is your student number"
  type        = string
}
```

### 5.2 Create Module Main Configuration

**File: `modules/iam/main.tf`**

```hcl
# IAM Role for EC2
resource "aws_iam_role" "ec2_role" {
  name = "lab9-ec2-role-${var.project}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "lab9-ec2-role-${var.project}"
  }
}

# IAM Instance Profile - connects the role to EC2
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "lab9-ec2-profile-${var.project}"
  role = aws_iam_role.ec2_role.name
}
```

### 5.3 Create Module Outputs

**File: `modules/iam/outputs.tf`**

```hcl
output "instance_profile_name" {
  description = "Name of the IAM instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}
```

---

## Step 6: Extract the EC2 Module

### 6.1 Create Module Variables

**File: `modules/ec2/variables.tf`**

```hcl
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "project" {
  description = "Project name - use UserX format where X is your student number"
  type        = string
}
```

### 6.2 Create Module Main Configuration

**File: `modules/ec2/main.tf`**

```hcl
# EC2 Instance - uses the security group and IAM profile
resource "aws_instance" "web_server" {
  ami                    = "ami-067ec7f9e54a67559"
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  tags = {
    Name = "lab9-web-server-${var.project}"
  }
}
```

### 6.3 Create Module Outputs

**File: `modules/ec2/outputs.tf`**

```hcl
output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.web_server.id
}

output "public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web_server.public_ip
}

output "private_ip" {
  description = "Private IP of the EC2 instance"
  value       = aws_instance.web_server.private_ip
}
```

---

## Step 7: Update Root main.tf to Use Modules

Now replace all the resources in your root `main.tf` with module calls. The root configuration becomes an orchestrator that wires modules together:

**File: `main.tf`** (complete replacement)

```hcl
# Get the default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

module "security_groups" {
  source = "./modules/security_groups"

  vpc_id  = data.aws_vpc.default_vpc.id
  project = var.project
}

module "iam" {
  source = "./modules/iam"

  project = var.project
}

module "ec2" {
  source = "./modules/ec2"

  instance_type        = var.instance_type
  security_group_ids   = [module.security_groups.web_sg_id]
  iam_instance_profile = module.iam.instance_profile_name
  project              = var.project
}
```

**Key observations:**
- We use a `data` source to look up the default VPC
- Each `module` block references a local module via `source`
- Module outputs become inputs to other modules (e.g., `module.security_groups.web_sg_id`)
- Terraform automatically determines the correct order based on these dependencies

---

## Step 8: Create Root-Level Outputs

Create `outputs.tf` in the root directory to expose useful information:

**File: `outputs.tf`**

```hcl
output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.security_groups.web_sg_id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}
```

---

## Step 9: Deploy and Verify

### 9.1 Re-initialize Terraform

After adding modules, you must re-initialize:

```bash
terraform init
```

You should see output indicating the modules are being initialized:
```
Initializing modules...
- ec2 in modules/ec2
- iam in modules/iam
- security_groups in modules/security_groups
```

### 9.2 Create a terraform.tfvars File

Create a `terraform.tfvars` file to set your project name:

```hcl
project = "userX"  # Replace X with your student number
```

### 9.3 Review the Plan

```bash
terraform plan
```

Review the plan carefully. You should see resources being created with `lab9-*` naming and your project identifier.

### 9.4 Apply the Configuration

```bash
terraform apply
```

Type `yes` when prompted.

### 9.5 Verify the Deployment

Check the outputs:
```bash
terraform output
```

Verify resources in AWS:
```bash
# Check EC2 instance
aws ec2 describe-instances \
  --filters "Name=tag:owner,Values=userX" \
  --query "Reservations[].Instances[].{ID:InstanceId,State:State.Name,IP:PublicIpAddress}" \
  --region ap-south-1

# Check security group
aws ec2 describe-security-groups \
  --filters "Name=tag:owner,Values=userX" \
  --query "SecurityGroups[].{ID:GroupId,Name:GroupName}" \
  --region ap-south-1
```

---

## Final Directory Structure

Your completed project should look like this:

```
lab9/
├── main.tf              # Module calls
├── terraform.tf         # Provider configuration
├── variables.tf         # Root variables
├── outputs.tf           # Root outputs
├── terraform.tfvars     # Variable values
└── modules/
    ├── security_groups/
    │   ├── main.tf      # Security group resources
    │   ├── variables.tf # vpc_id, project
    │   └── outputs.tf   # web_sg_id
    ├── iam/
    │   ├── main.tf      # IAM role and profile
    │   ├── variables.tf # project
    │   └── outputs.tf   # instance_profile_name
    └── ec2/
        ├── main.tf      # EC2 instance
        ├── variables.tf # instance_type, security_group_ids, etc.
        └── outputs.tf   # instance_id, public_ip, private_ip
```

---

## Module Dependency Flow

Understanding how data flows between modules in this lab:

| Source | Output | Destination | Input Variable |
|--------|--------|-------------|----------------|
| Default VPC (data source) | `id` | security_groups module | `vpc_id` |
| security_groups module | `web_sg_id` | ec2 module | `security_group_ids` |
| iam module | `instance_profile_name` | ec2 module | `iam_instance_profile` |

**Key insight:** The `ec2` module depends on both `security_groups` and `iam` modules. Terraform automatically determines the correct creation order based on these references - it will create the security group and IAM resources first, then create the EC2 instance.

---

## Key Concepts Recap

### Module Structure
Every module has three key files:
- **variables.tf**: Input parameters (what the module needs)
- **main.tf**: Resources (what the module creates)
- **outputs.tf**: Return values (what the module exposes)

### Module Communication
- Modules receive data through **variables**
- Modules expose data through **outputs**
- Parent configurations wire outputs → variables

### Best Practices Applied
1. **Single Responsibility**: Each module handles one concern
2. **Clear Interfaces**: Variables and outputs are well-documented
3. **No Hardcoding**: Values come from variables, not hardcoded strings
4. **Explicit Dependencies**: Data flows through outputs, not implicit references

---

## Clean Up

When finished, destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted.

Verify resources are deleted:
```bash
aws ec2 describe-instances \
  --filters "Name=tag:owner,Values=userX" "Name=instance-state-name,Values=running" \
  --region ap-south-1
```

---

## Troubleshooting

### Error: "Module not found"
**Cause**: Running terraform from wrong directory or typo in source path
**Solution**: Ensure you're in the root directory (where main.tf is) and check the `source` path

### Error: "No value for required variable"
**Cause**: Missing variable value
**Solution**: Create `terraform.tfvars` with required values or pass via `-var` flag

### Error: "Reference to undeclared output"
**Cause**: Trying to use an output that doesn't exist in the module
**Solution**: Check `outputs.tf` in the module and ensure the output is declared

---

## Questions?

Great job completing Lab 9! You've learned how to transform a monolithic Terraform configuration into a clean, modular structure. These skills are essential for managing infrastructure at scale.
