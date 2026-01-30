# Security Group - base security group (rules defined separately)
resource "aws_security_group" "web_sg" {
  name        = "lab9-web-sg-${var.project}"
  description = "Security group for web server"
  vpc_id      = var.vpc_id

  tags = {
    Name = "lab9-web-sg-${var.project}"
  }
}

# Security Group Rule - HTTP ingress
resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.web_sg.id
  description       = "HTTP"
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab9-http-rule-${var.project}"
  }
}

# Security Group Rule - Allow all outbound
resource "aws_vpc_security_group_egress_rule" "all_outbound" {
  security_group_id = aws_security_group.web_sg.id
  description       = "Allow all outbound"
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"

  tags = {
    Name = "lab9-egress-rule-${var.project}"
  }
}
