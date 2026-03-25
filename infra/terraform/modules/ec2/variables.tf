variable "project_name" {
  description = "Tên dự án"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "aws_region" {
  description = "AWS Region"
  type        = string
}

variable "ec2_instance_type" {
  description = "Loại EC2 instance"
  type        = string
}

variable "vpc_id" {
  description = "ID của VPC"
  type        = string
}

variable "subnet_id" {
  description = "ID của Subnet triển khai EC2"
  type        = string
}

variable "iam_instance_profile_name" {
  description = "Tên của IAM Instance Profile để gắn vào EC2"
  type        = string
}

variable "db_name" {
  description = "Tên Database"
  type        = string
}

variable "db_username" {
  description = "User Database"
  type        = string
}

variable "db_password" {
  description = "Mật khẩu User Database"
  type        = string
  sensitive   = true
}

variable "db_root_password" {
  description = "Mật khẩu Root MySQL"
  type        = string
  sensitive   = true
}
