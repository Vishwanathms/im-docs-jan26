# EC2 Instance - uses the security group and IAM profile
resource "aws_instance" "web_server" {
  ami                    = "ami-067ec7f9e54a67559"
  instance_type          = var.instance_type
  vpc_security_group_ids = var.security_group_ids
  iam_instance_profile   = var.iam_instance_profile

  tags = {
    Name = "lab9-web-server-${var.project}"
  }
}
