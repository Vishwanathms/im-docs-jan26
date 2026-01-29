# Outputs to display after apply

output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.my_instance.id
}

output "instance_public_ip" {
  description = "Public IP of the instance"
  value       = aws_instance.my_instance.public_ip
}

output "configuration" {
  description = "Instance configuration used"
  value = {
    instance_type = var.instance_type
    region        = var.aws_region
  }
}
