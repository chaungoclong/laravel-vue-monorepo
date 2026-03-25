variable "project_name" {
  description = "Tên dự án"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai"
  type        = string
}

variable "aws_region" {
  description = "AWS Region để triển khai hạ tầng (VD: ap-southeast-1)"
  type        = string
}

variable "s3_bucket_artifacts_id" {
  description = "ID của S3 Bucket lưu artifacts"
  type        = string
}

variable "iam_role_arn" {
  description = "ARN của IAM Role cho CodeBuild"
  type        = string
}