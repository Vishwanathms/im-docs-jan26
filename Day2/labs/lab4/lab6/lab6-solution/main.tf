# AWS Provider configuration
provider "aws" {
  region = var.aws_region # Using a variable for region

  default_tags {
    tags = {
      owner = "userX" # Replace with your user number
      environment = var.environment
    }
  }
/* 
  // An example of how AWS provider can work with different 
  // AWS accounts (e.g. staging and production)
  // by using different roles created in each of those accounts  
  assume_role {
    role_arn     = var.execution_role_arn
    session_name = "terraform-deployment-${var.environment}"
  }
*/
}

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
    Name = "user00"  # Replace with your user number (user1, user2, etc.)
    Lab = "lab6"
  }
}