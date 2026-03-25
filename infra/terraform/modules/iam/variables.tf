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

variable "aws_account_id" {
  description = "ID của AWS Account"
  type        = string
}

variable "s3_bucket_artifacts_arn" {
  description = "ARN của S3 Bucket chứa artifacts để cấp quyền cho IAM Role"
  type        = string
}

variable "github_connection_arn" {
  description = "ARN của AWS CodeStar Connection để cấp quyền cho Pipeline Role"
  type        = string
}