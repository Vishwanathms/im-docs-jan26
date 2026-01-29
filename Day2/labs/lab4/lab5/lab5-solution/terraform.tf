# Terraform and provider version requirements
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.20.0"
    }
  }

  backend "s3" {
    bucket       = "boa-terraform-state-userX" # Replace userX
    key          = "terraform.tfstate"     # Path within bucket
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # S3 native locking (requires versioning enabled)
  }
}

