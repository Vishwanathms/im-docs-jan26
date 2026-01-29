# AWS Provider configuration
provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      owner = "userX"
    }
  }
}

# S3 bucket for storing Terraform state
# IMPORTANT: Replace userX with your assigned user number (e.g., user1, user2)
resource "aws_s3_bucket" "terraform_state" {
  bucket = "boa-terraform-state-userx" # Replace x with your user number

  tags = {
    Name = "userX"
  }
}

# Enable versioning to keep history of state files
# REQUIRED for S3 native state locking (use_lockfile)
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption for security
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs for reference
output "s3_bucket_name" {
  description = "Name of the S3 bucket for state storage"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}
