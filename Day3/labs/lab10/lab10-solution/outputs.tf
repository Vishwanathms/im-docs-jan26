output "web_security_group_id" {
  description = "ID of the web security group"
  value       = module.security_groups.web_sg_id
}

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = module.ec2.instance_id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = module.ec2.public_ip
}
