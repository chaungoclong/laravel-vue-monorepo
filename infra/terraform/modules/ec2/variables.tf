variable "project" { type = string }
variable "env" { type = string }
variable "location" { type = string }
variable "region" {
  type = string
  default = "ap-southeast-1"
}
variable "instance_type" { type = string }
variable "iam_instance_profile" { type = string }
variable "vpc_id" { type = string }
variable "subnet_id" { type = string }

# Thêm các biến bảo mật cho Database
variable "mysql_root_pass" {
  type = string
  sensitive = true
  description = "Mật khẩu root của MySQL"
}
variable "db_name" {
  type = string
  default = "app"
  description = "Tên Database ứng dụng"
}
variable "db_user" {
  type = string
  default = "app"
  description = "User truy cập Database"
}
variable "db_pass" {
  type = string
  sensitive = true
  description = "Mật khẩu truy cập Database của User"
}