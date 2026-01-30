# Module 9: Terraform Modules and Reusability

## Learning Objectives

By the end of this module you will understand:
- What Terraform modules are and why they matter
- How to create local modules for your infrastructure
- Best practices for module design
- How to use modules from the Terraform Registry
- Module versioning and dependency management

---

# What Are Terraform Modules?

> A **module** is a container for multiple resources that are used together to accomplish a specific infrastructure goal.

**Think of modules as functions in programming:**
- Input: Variables
- Processing: Resource definitions
- Output: Exported values

**Real-world analogy**: Like a blueprint for a room in a house - you define it once, then reuse it multiple times with different configurations.

---

# Why Use Modules?

Without modules:
```hcl
# main.tf - 500 lines of mixed networking, compute, database resources
# Hard to read, hard to maintain, hard to reuse
```

With modules:
```hcl
# main.tf
module "networking" { ... }
module "compute" { ... }
module "database" { ... }
# Clean, organized, reusable
```

---

# Benefits of Modules

**Reusability**: Write once, use many times across projects

**Maintainability**: Changes in one place affect all uses

**Encapsulation**: Hide complexity, expose only what's needed

**Standardization**: Enforce organizational best practices

**Team Collaboration**: Different teams can own different modules

---

# Discussion: Your Infrastructure Components

**Think about your current infrastructure:**

- What components are repeated across environments?
- Examples: VPC setup, standard EC2 configurations, S3 buckets with policies
- How much code duplication exists?
- What would you want to package as a reusable component?

---

# Module Structure Basics

Every module contains standard Terraform files:

```
my-module/
├── main.tf          # Primary resource definitions
├── variables.tf     # Input variables
├── outputs.tf       # Output values
└── README.md        # Documentation (optional but recommended)
```

**Best Practice**: Keep modules focused on a single purpose

---

# Module Types

**1. Root Module**
- The directory where you run `terraform apply`
- Your main configuration that calls other modules

**2. Child Modules**
- Modules called by the root module or other modules

**3. Local Modules**
- Stored in your project filesystem
- Path: `./modules/vpc` or `../shared/modules/compute`

**4. Remote Modules**
- From Terraform Registry, Git repos, S3, etc.
- Example: `terraform-aws-modules/vpc/aws`

---

## Understanding Module Structure

Before diving into the refactoring, let's understand how Terraform modules work. This foundation will make the rest of the lab much clearer.

### What is a Module?

A Terraform module is simply **a folder containing `.tf` files**. That's it!

Think of a module like a **function in programming**:
- It takes **inputs** (variables)
- It **does something** (creates resources)
- It returns **outputs** (values other code can use)

Here's the key insight: **Every Terraform project is already a module** - it's called the "root module". When you run `terraform apply` in a directory, you're running the root module.

### Module Files

A well-structured module typically has three files:

```
my_module/
├── variables.tf    # Inputs  - what the module needs
├── main.tf         # Logic   - what the module creates (REQUIRED)
└── outputs.tf      # Returns - what the module exposes
```

| File | Required? | Purpose | Programming Analogy |
|------|-----------|---------|---------------------|
| `main.tf` | **Yes** | Defines resources to create | Function body |
| `variables.tf` | No | Declares input parameters | Function arguments |
| `outputs.tf` | No | Exposes values for other code to use | Return values |

> **Note**: Technically, only `main.tf` is required. A module could just be a folder with hardcoded resources. However, this limits reusability.

**Why use variables and outputs? (Best Practice)**

- **Variables** make your module **reusable**. Instead of hardcoding `name = "web-sg-user1"`, you use `name = "web-sg-${var.project}"`. Now anyone can use your module with their own project name.

- **Outputs** let other code **use values** from your module. If your security group module doesn't output the security group ID, your EC2 module has no way to reference it.

### How Root Module Calls Child Modules

The root module acts as an **orchestrator** - it doesn't create resources directly, but instead calls child modules and wires them together.

**How it works:**

1. **Root module** (your main project folder) contains `module` blocks that call child modules
2. Each `module` block specifies:
   - `source` - path to the child module folder
   - Input values that map to the child module's variables
3. **Child modules** receive inputs via variables, create resources, and expose outputs
4. The root module can pass one module's output as another module's input

**Example flow:**

```hcl
# In root main.tf - the orchestrator
module "security_groups" {
  source  = "./modules/security_groups"
  vpc_id  = data.aws_vpc.default.id    # Input: passing data TO the module
  project = var.project
}

module "ec2" {
  source             = "./modules/ec2"
  security_group_ids = [module.security_groups.web_sg_id]  # Using OUTPUT from another module
  project            = var.project
}
```

**The data flow:**
- `data.aws_vpc.default.id` → passed as input to `security_groups` module
- `security_groups` module creates resources and outputs `web_sg_id`
- `module.security_groups.web_sg_id` → passed as input to `ec2` module
- `ec2` module uses that security group ID to configure the instance

### Simple Before/After Example

**Before (monolithic)** - resources defined directly in root:

```hcl
# main.tf - everything in one file
resource "aws_security_group" "web_sg" {
  name   = "web-sg-UserX"
  vpc_id = data.aws_vpc.default.id
}

resource "aws_instance" "web" {
  ami                    = "ami-12345"
  vpc_security_group_ids = [aws_security_group.web_sg.id]
}
```

**After (modular)** - resources moved to modules, root just orchestrates:

```hcl
# main.tf - just module calls
module "security_groups" {
  source  = "./modules/security_groups"
  vpc_id  = data.aws_vpc.default.id
  project = var.project
}

module "ec2" {
  source             = "./modules/ec2"
  security_group_ids = [module.security_groups.web_sg_id]  # output from another module
  project            = var.project
}
```

```hcl
# modules/security_groups/main.tf - the actual resource
resource "aws_security_group" "web_sg" {
  name   = "web-sg-${var.project}"    # uses variable
  vpc_id = var.vpc_id
}
```

```hcl
# modules/security_groups/outputs.tf - expose the ID
output "web_sg_id" {
  value = aws_security_group.web_sg.id    # other modules can use this
}
```

### Key Takeaway

> **The root module becomes an orchestrator that wires modules together, rather than defining resources directly.**

---

# Understanding Module Dependencies

Terraform automatically determines the order:

```hcl
module "networking" {
  # No dependencies - runs first
}

module "compute" {
  subnet_id = module.networking.public_subnet_id  # Depends on networking
  vpc_id    = module.networking.vpc_id            # Depends on networking
}
```

**Terraform knows**:
1. Create networking module resources first
2. Then create compute module resources
3. Dependencies are implicit through references

---

# Module Input Variables: Best Practices

**DO:**
```hcl
variable "instance_type" {
  description = "EC2 instance type"  # Always provide description
  type        = string                # Always specify type
  default     = "t3.micro"           # Provide sensible defaults

  validation {                        # Add validation where appropriate
    condition     = contains(["t3.micro", "t3.small", "t3.medium"], var.instance_type)
    error_message = "Instance type must be t3.micro, t3.small, or t3.medium."
  }
}
```

---

# Module Input Variables: Anti-Patterns

**DON'T:**
```hcl
variable "it" {                      # Bad: Unclear name
  # No description                   # Bad: Missing description
  # No type specified                # Bad: Missing type
}

variable "hardcoded_ami" {
  default = "ami-0c55b159cbfafe1f0"  # Bad: Region-specific hardcoding
}

variable "everything" {               # Bad: Too many responsibilities
  type = object({
    vpc = string
    subnet = string
    instance = string
    # ... 20 more fields
  })
}
```

---

# Module Outputs: Best Practices

**DO:**
```hcl
output "vpc_id" {
  description = "ID of the VPC"               # Always describe
  value       = aws_vpc.main.id
}

output "database_endpoint" {
  description = "Connection endpoint for database"
  value       = aws_db_instance.main.endpoint
  sensitive   = true                          # Mark sensitive data
}
```

**Export only what's needed** - Don't expose internal implementation details

---

# Using Terraform Registry Modules

The **Terraform Registry** (registry.terraform.io) contains thousands of pre-built modules.

**Popular AWS modules:**
- `terraform-aws-modules/vpc/aws` - Production-ready VPC
- `terraform-aws-modules/ec2-instance/aws` - EC2 instances
- `terraform-aws-modules/rds/aws` - RDS databases
- `terraform-aws-modules/s3-bucket/aws` - S3 buckets

**Benefits:**
- Battle-tested code
- Best practices built-in
- Regular updates
- Community support

---

# Module Versioning

**Why version?**
- Prevent breaking changes
- Ensure reproducibility
- Enable controlled updates

**For remote modules:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"  # Exact version
  # OR
  # version = "~> 5.1"  # Any 5.1.x version
  # OR
  # version = ">= 5.0, < 6.0"  # Version constraints
}
```

---

# Module Versioning: Best Practices

**DO:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"  # Yes: Pinned version
}
```

**DON'T:**
```hcl
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  # Bad: No version - uses latest (dangerous!)
}

module "local" {
  source  = "./modules/compute"
  version = "1.0.0"  # Bad: Local modules don't use version attribute
}
```

---

# Module Sources: Different Types

**Local path:**
```hcl
module "networking" {
  source = "./modules/networking"  # Relative path
}
```

**Terraform Registry:**
```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.2"
}
```

**Git repository:**
```hcl
module "shared" {
  source = "git::https://github.com/your-org/terraform-modules.git//networking?ref=v1.2.0"
}
```

---

# Module Sources: Git References

**Different Git reference types:**
```hcl
# Tag
module "networking" {
  source = "git::https://github.com/your-org/modules.git//networking?ref=v1.0.0"
}

# Branch
module "networking" {
  source = "git::https://github.com/your-org/modules.git//networking?ref=main"
}

# Commit SHA
module "networking" {
  source = "git::https://github.com/your-org/modules.git//networking?ref=abc123def"
}
```

**Best Practice**: Use tags for production, branches for development

---

# Module Design Principles

**Single Responsibility**
- Each module should do ONE thing well
- Good: `vpc`, `compute`, `database`
- Bad: `everything`, `infrastructure`

**Loose Coupling**
- Modules should be independent
- Pass data through variables and outputs
- Avoid hidden dependencies

**High Cohesion**
- Related resources should be grouped together
- VPC + subnets + IGW = one module
- Don't split tightly coupled resources

---

# Module Design: Composition Pattern

**Build complex infrastructure from simple modules:**

```hcl
module "networking" {
  source = "./modules/networking"
  # ...
}

module "database" {
  source    = "./modules/rds"
  vpc_id    = module.networking.vpc_id
  subnet_ids = module.networking.private_subnet_ids
  # ...
}

module "application" {
  source     = "./modules/ec2-app"
  vpc_id     = module.networking.vpc_id
  subnet_ids = module.networking.public_subnet_ids
  db_endpoint = module.database.endpoint
  # ...
}
```

---

# Common Module Patterns

**1. Wrapper Module** - Simplifies complex registry modules
**2. Foundation Module** - Core infrastructure (networking, IAM)
**3. Application Module** - App-specific resources
**4. Environment Module** - Combines modules for specific environment

**Example hierarchy:**
```
Root
├── Foundation (VPC, IAM roles)
├── Data Layer (RDS, ElastiCache)
├── Compute Layer (EC2, ASG, ALB)
└── Monitoring (CloudWatch, SNS)
```

---

# Module Testing Considerations

**Basic testing:**
```bash
# Validate syntax
terraform validate

# Check formatting
terraform fmt -check -recursive

# Test plan generation
terraform plan
```

**Advanced testing** (covered in advanced courses):
- Terratest (Go-based testing)
- Kitchen-Terraform
- Checkov (policy testing)

---

# Troubleshooting Modules

**Common issues:**

**1. Module not found:**
```bash
terraform init  # Re-initialize to download modules
```

**2. Can't find module output:**
```bash
terraform state show module.networking.aws_vpc.main
```

**3. Module changes not applied:**
```bash
terraform get -update  # Update modules
```

**4. Circular dependencies:**
- Review module references
- Might need to restructure dependencies

---

# Module Documentation: README Template

**modules/networking/README.md**
```markdown
# Networking Module

## Description
Creates a VPC with public/private subnets, Internet Gateway, and NAT Gateway.

## Usage
```hcl
module "networking" {
  source = "./modules/networking"

  vpc_cidr     = "10.0.0.0/16"
  project_name = "my-app"
  environment  = "dev"
}
```

## Inputs
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_cidr | CIDR block for VPC | string | "10.0.0.0/16" | no |
| project_name | Project name | string | n/a | yes |

## Outputs
| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
```

---

# Discussion: Module Design

**For your infrastructure:**

- What would be your first module candidates?
- How would you organize: by layer (networking, compute) or by function (frontend, backend)?
- What inputs/outputs would each module need?
- Would you use registry modules or build your own?

---

# Hands-On Practice Time

**Your turn to practice!**

You'll now work on **Lab 9: Refactor to Modules**

**Lab objectives:**
1. Take an existing monolithic Terraform configuration
2. Identify logical components
3. Create separate modules for VPC, EC2, and Security Groups
4. Wire modules together in root configuration
5. Verify everything works with `terraform plan`

**Time**: ~45 minutes

---

# Knowledge Check 1

**What is the primary purpose of Terraform modules?**

A) To make configurations run faster
B) To organize and reuse infrastructure code
C) To reduce AWS costs
D) To avoid using variables

---

# Knowledge Check 2

**How do you reference an output from a module named 'networking'?**

A) `output.networking.vpc_id`
B) `networking.output.vpc_id`
C) `module.networking.vpc_id`
D) `var.networking.vpc_id`

---

# Knowledge Check 3

**What should you always specify when using remote modules from the Terraform Registry?**

A) The module name
B) A specific version
C) The AWS region
D) The provider version

---

# Knowledge Check 4

**Which file is NOT typically part of a module's structure?**

A) main.tf
B) variables.tf
C) outputs.tf
D) terraform.tfstate

---

# Key Takeaways

**Modules** enable code reuse and organization

**Every module** has inputs (variables), processing (resources), and outputs

**Local modules** use relative paths, **remote modules** use URLs/registry paths

**Always version** remote modules to ensure stability

**Module outputs** are accessed via `module.<name>.<output>`

**Start simple** - refactor into modules as patterns emerge

**Document** your modules for your future self and teammates

---

# Next Up: Module 2

**Multi-Environment Deployment Using Workspaces**

We'll learn how to:
- Use the same modules across dev/staging/prod
- Manage environment-specific configurations
- Isolate state files per environment
- Handle workspace-specific variables

---

# Resources and Further Reading

**Terraform Documentation:**
- Module documentation: terraform.io/docs/language/modules
- Module registry: registry.terraform.io

**Best Practices:**
- HashiCorp module standards
- AWS Well-Architected Framework

**Community Modules:**
- terraform-aws-modules organization on GitHub
- Module examples and templates
