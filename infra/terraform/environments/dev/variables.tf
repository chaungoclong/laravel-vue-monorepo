variable "project" { default = "myapp" }
variable "env" { default = "dev" }
variable "location" { default = "apse1" } # ap-southeast-1 viết tắt
variable "region" { default = "ap-southeast-1" }
variable "github_connection_arn" { description = "AWS CodeStar Connection ARN cho GitHub" }
variable "github_repo" { description = "ID Repo. VD: my-org/my-monorepo" }
variable "github_branch" { default = "develop" }
variable "mysql_root_pass" {
  type = string
  sensitive = true
}
variable "db_name" {
  type = string
  default = "app"
}
variable "db_user" {
  type = string
  default = "app"
}
variable "db_pass" {
  type = string
  sensitive = true
}