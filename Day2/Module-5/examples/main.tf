provider "aws" {
    region = "us-east-1"
}

/*
resource "aws_instance" "var-instance" {
    instance_type = "t3.micro"
    ami = "ami-06dd5c911c0d8dcdc"
}
*/
resource "aws_instance" "var-instance" {
    instance_type = var.instance_type
    ami = "ami-06dd5c911c0d8dcdc"
}

resource "aws_db_instance" "db-instance" {
    allocated_storage = 10
    engine = "mysql"
    instance_class = "db.t3.micro"
    db_name = "testdb"
    username = var.db_user
    password = var.db_password
    skip_final_snapshot = true
}