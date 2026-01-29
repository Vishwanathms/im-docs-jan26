# AWS Provider configuration
provider "aws" {
  region = var.aws_region # Using a variable for region

  default_tags {
    tags = {
      owner = "userX" # Replace with your user number
    }
  }
}

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
    Name = "userX"
  }
}
