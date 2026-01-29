output "instance_ip" {

    value = aws_instance.var-instance.public_ip

}

output "db_user" {
    value = aws_db_instance.db-instance.username
    sensitive = true
}

output "db_password" {
    value     = aws_db_instance.db-instance.password
    sensitive = true
}