# Module 10: Multi-Environment Deployment with Workspaces

## Learning Objectives

By the end of this module you will understand:
- What Terraform workspaces are and when to use them
- How to create and manage multiple workspaces
- How to use workspace-specific variables
- Backend state segregation strategies
- Best practices for multi-environment deployments

---

# The Multi-Environment Challenge

**Common scenario**: You need the same infrastructure in multiple environments

**Environments typically include:**
- **Development** (dev) - Frequent changes, smaller resources
- **Staging** (stage/qa) - Production-like for testing
- **Production** (prod) - Live customer-facing infrastructure

**The problem**: How to manage the same code with different configurations?

---

# Solution Options

**Option 1: Copy/Paste Code** (Bad)
```
/dev
  ├── main.tf    # Duplicated code
/staging
  ├── main.tf    # Duplicated code
/production
  ├── main.tf    # Duplicated code
```
**Problem**: Code duplication, maintenance nightmare

---

# Solution Options (continued)

**Option 2: Separate Directories** (Good for larger orgs)
```
/environments
  ├── dev/
  │   ├── main.tf         # Calls shared modules
  │   └── terraform.tfvars
  ├── staging/
  │   ├── main.tf         # Calls shared modules
  │   └── terraform.tfvars
  └── production/
      ├── main.tf         # Calls shared modules
      └── terraform.tfvars
```
**Pros**: Complete isolation, different backends possible

---

# Solution Options (continued)

**Option 3: Terraform Workspaces** (Good for similar environments)
```
/infrastructure
  ├── main.tf
  ├── variables.tf
  └── terraform.tfvars
```
Same code, different state files per workspace

**Pros**: DRY principle, easy to switch, minimal duplication

**We'll focus on workspaces today!**

---

# What Are Terraform Workspaces?

> **Workspaces** are parallel, isolated instances of Terraform state for the same configuration.

**Think of it like Git branches** - same code, different state tracking

**Default workspace**: `default`

**Key concept**: Each workspace maintains its own state file

---

# How Workspaces Work

**Single configuration:**
```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type
  # ...
}
```

**Multiple state files:**
```
terraform.tfstate.d/
├── dev/
│   └── terraform.tfstate      # Dev infrastructure state
├── staging/
│   └── terraform.tfstate      # Staging infrastructure state
└── prod/
    └── terraform.tfstate      # Prod infrastructure state
```

---

# Workspace Commands

**List workspaces:**
```bash
terraform workspace list
```

**Create new workspace:**
```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
```

**Switch workspace:**
```bash
terraform workspace select dev
```

**Show current workspace:**
```bash
terraform workspace show
```

**Delete workspace:**
```bash
terraform workspace delete dev
```

---

# Using Workspace Name in Configuration

**Access current workspace:**
```hcl
terraform.workspace
```

**Example usage:**
```hcl
resource "aws_instance" "web" {
  instance_type = var.instance_type

  tags = {
    Name        = "web-server-${terraform.workspace}"
    Environment = terraform.workspace
  }
}
```

**Result**: Creates `web-server-dev`, `web-server-staging`, `web-server-prod`

---

# Workspace-Specific Variables

**Problem**: Different environments need different configurations
- Dev: `t3.micro` instances
- Staging: `t3.small` instances
- Prod: `t3.large` instances

**Solution**: Use conditional logic based on workspace

---

# Workspace-Specific Variable Files

**Directory structure:**
```
infrastructure/
├── main.tf
├── variables.tf
├── outputs.tf
├── terraform.tfvars          # Common variables
└── env-configs/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

---

# Advanced: Environment-Specific tfvars Files

**env-configs/dev.tfvars**
```hcl
instance_type     = "t3.micro"
instance_count    = 1
db_instance_class = "db.t3.micro"
enable_monitoring = false
```

**env-configs/staging.tfvars**
```hcl
instance_type     = "t3.small"
instance_count    = 2
db_instance_class = "db.t3.small"
enable_monitoring = true
```

**env-configs/prod.tfvars**
```hcl
instance_type     = "t3.large"
instance_count    = 3
db_instance_class = "db.r6g.large"
enable_monitoring = true
backup_retention  = 30
```

---

# Using Environment-Specific tfvars

**Apply with specific var file:**
```bash
# For dev workspace
terraform workspace select dev
terraform apply -var-file="env-configs/dev.tfvars"

# For staging workspace
terraform workspace select staging
terraform apply -var-file="env-configs/staging.tfvars"

# For production workspace
terraform workspace select prod
terraform apply -var-file="env-configs/prod.tfvars"
```

**Best practice**: Document which var file to use with which workspace

---

# Backend State Segregation with Workspaces

**With S3 backend and workspaces:**

**backend.tf**
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
```

**Terraform automatically creates:**
```
s3://my-terraform-state-bucket/
└── infrastructure/
    ├── terraform.tfstate (default workspace)
    └── env:/
        ├── dev/terraform.tfstate
        ├── staging/terraform.tfstate
        └── prod/terraform.tfstate
```

---

# Alternative: Separate Backends Per Environment

**For stricter isolation:**

**environments/dev/backend.tf**
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-dev"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

**environments/prod/backend.tf**
```hcl
terraform {
  backend "s3" {
    bucket = "my-terraform-state-prod"  # Different bucket!
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}
```

**Use when**: Environments need different AWS accounts or strict access control

---

# Discussion: Workspace Strategy

**When to use workspaces:**
- Environments are very similar (dev/staging/prod)
- Same team manages all environments
- Same AWS account (or at least same state storage)

**When to use separate directories:**
- Environments differ significantly
- Different teams own different environments
- Different AWS accounts per environment
- Need different backend configurations

**Question**: Which approach fits your organization?

---

# Safety Practices for Production

**1. Always verify workspace before applying:**
```bash
$ terraform workspace show
prod

$ echo "Current workspace: $(terraform workspace show)"
Current workspace: prod

# Only proceed if correct!
$ terraform apply
```

**2. Use plan files for production:**
```bash
terraform plan -out=prod.tfplan
# Review carefully
terraform apply prod.tfplan
```

---

# Safety Practices (continued)

**3. Add confirmation in scripts:**
```bash
#!/bin/bash
CURRENT_WS=$(terraform workspace show)
echo "Current workspace: $CURRENT_WS"
read -p "Deploy to $CURRENT_WS? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
  echo "Deployment cancelled"
  exit 1
fi

terraform apply
```

**4. Use CI/CD with branch-to-workspace mapping**
- `develop` branch → `dev` workspace
- `staging` branch → `staging` workspace
- `main` branch → `prod` workspace

---

# Workspace Limitations

**Things workspaces DON'T provide:**
- Different provider configurations (e.g., different AWS accounts)
- Different backend configurations
- True isolation (all workspaces in same Terraform state bucket)
- Granular access control per environment

**For these needs**: Use separate directories/repos with separate backends

---

# Data Sources Across Workspaces

**Workspaces can reference each other's resources:**

```hcl
# In staging workspace, reference prod VPC
data "terraform_remote_state" "prod" {
  backend = "s3"

  config = {
    bucket = "myapp-terraform-state"
    key    = "env:/prod/infrastructure/terraform.tfstate"
    region = "us-east-1"
  }

  workspace = "prod"
}

# Use prod VPC ID in staging for VPC peering
resource "aws_vpc_peering_connection" "staging_to_prod" {
  vpc_id      = module.networking.vpc_id  # Staging VPC
  peer_vpc_id = data.terraform_remote_state.prod.outputs.vpc_id  # Prod VPC
  auto_accept = true
}
```

---

# Workspace Best Practices

**DO:**
- Use meaningful workspace names (dev, staging, prod)
- Always check current workspace before operations
- Use `terraform.workspace` for resource naming
- Document workspace-to-environment mapping
- Implement workspace validation in CI/CD

**DON'T:**
- Use workspaces for completely different infrastructure
- Use default workspace for production
- Mix workspace approaches with directory approaches
- Assume workspace name format (use `terraform.workspace`)

---

# Migrating Between Workspace Strategies

**From separate directories to workspaces:**
```bash
# 1. Import existing state
cd environments/dev
terraform state pull > /tmp/dev.tfstate

# 2. Create workspace in unified config
cd ../../unified-config
terraform workspace new dev

# 3. Push state to new workspace
terraform state push /tmp/dev.tfstate
```

**Note**: Complex migration - test thoroughly in non-prod first!

---

# Discussion: Your Multi-Environment Strategy

**Questions to consider:**

- How many environments do you need?
- Are your environments very similar or quite different?
- Do you need different AWS accounts per environment?
- Who manages each environment?
- What level of isolation is required?

---

# Hands-On Practice Time

**You'll now work on Lab 10: Multi-Environment Deployment**

**Lab objectives:**
1. Create workspaces for dev, staging, and production
2. Configure environment-specific variables using locals
3. Deploy infrastructure to each workspace
4. Verify state isolation
5. Test switching between workspaces
6. Clean up specific environment

**Time**: ~45 minutes

---

# Knowledge Check 1

**What does each Terraform workspace have?**

A) Its own set of configuration files
B) Its own provider plugins
C) Its own state file
D) Its own Terraform version

---

# Knowledge Check 2

**How do you access the current workspace name in Terraform configuration?**

A) `var.workspace`
B) `terraform.workspace`
C) `workspace.current`
D) `env.workspace`

---

# Knowledge Check 3

**When are separate directories/repos better than workspaces?**

A) When environments are identical
B) When you need different AWS accounts per environment
C) When you want to save disk space
D) When you have only two environments

---

# Knowledge Check 4

**What happens to the state file when you switch workspaces?**

A) The state file is deleted
B) The state file is merged with the new workspace
C) Terraform loads the state file for the selected workspace
D) All state files are loaded simultaneously

---

# Key Takeaways

**Workspaces** enable managing multiple environments with the same code

**Each workspace** maintains its own isolated state file

Use `terraform.workspace` to make configurations **environment-aware**

**Combine workspaces with locals** for environment-specific configurations

**Always verify** current workspace before running terraform apply

**Workspaces are great** for similar environments, **separate directories** for different ones

**State isolation** is automatic but shares the same backend

---

# Next Up: Module 3

**Advanced HCL and Dynamic Resources**

We'll learn:
- Using `locals` for computed values
- `count` and `for_each` for dynamic resources
- Advanced data source usage
- Dynamic blocks
- Conditional resource creation

---

# Resources and Further Reading

**Terraform Documentation:**
- Workspaces: terraform.io/docs/language/state/workspaces
- Backend configuration: terraform.io/docs/language/settings/backends

**Best Practices:**
- Managing multiple environments
- Workspace naming conventions
- State organization strategies

**Advanced Topics:**
- Terragrunt for environment management
- Terraform Cloud workspaces (different from OSS workspaces!)
