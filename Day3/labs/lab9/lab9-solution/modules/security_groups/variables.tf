variable "vpc_id" {
  description = "VPC ID where security groups will be created"
  type        = string
}

variable "project" {
  description = "Project name - use UserX format where X is your student number"
  type        = string
}
