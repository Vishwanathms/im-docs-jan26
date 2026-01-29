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
