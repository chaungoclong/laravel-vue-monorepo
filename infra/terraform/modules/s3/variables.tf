variable "project_name" {
  description = "Tên dự án"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai (dev, stg, prod...)"
  type        = string
}

variable "aws_region" {
  description = "AWS Region để triển khai hạ tầng (VD: ap-southeast-1)"
  type        = string
}

variable "aws_account_id" {
  description = "ID của AWS Account"
  type        = string
}