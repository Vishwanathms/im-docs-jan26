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
