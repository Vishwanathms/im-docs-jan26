variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Deployment environment"
  type = string
  validation {
    condition     = contains(["staging", "production"], var.environment)
    error_message = "Only staging or production environment is allowed"
  }
}

variable "execution_role_arn" {
  description =<<-DESC
  AWS Role ARN that terraform will assume to run deployment.
  ARN stands for Amazon Resource Name, a unique identifier for AWS resource,
  here AWS Role in the followimg format: arn:aws:iam::aws_account_id:role/role-name
  Example:
  arn:aws:iam::123456789999:role/StagingDeploymentRole
  Notice that each role has an AWS account_id e.g. 123456789999
  which means that each role will operate in a specific AWS account.
  The best practice is to separate staging and production environment into
  two separate accounts, so we would have to create two separate roles in two
  separate account in this environment. Terraform AWS provider can use (assume) 
  one of those roles to perform operations on one of staging or production AWS account.
  You can find a example usage inside terraform.tf in aws provider block.
  DESC
  type = string
}


variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  # No default - must be provided in terraform.tfvars or Terraform will prompt

  validation {
    condition     = contains(["t3.nano", "t3.micro"], var.instance_type)
    error_message = "Only t3.nano or t3.micro are allowed."
  }
}