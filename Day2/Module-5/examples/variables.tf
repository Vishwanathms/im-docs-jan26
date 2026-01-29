variable "instance_type" {
    type = string
    default = "t3.micro"
}

variable "db_user" {
    type = string
    description = "Database user"
    sensitive = true
}

variable "db_password" {
    type = string
    description = "Database password"
    sensitive = true

    validation {
        condition = length(var.db_password) >= 8
        error_message = "The database password must be at least 8 characters long."
    }
}