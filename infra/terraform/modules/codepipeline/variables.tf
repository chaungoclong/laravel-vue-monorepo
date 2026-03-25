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
  description = "ID của S3 Bucket chứa artifacts"
  type        = string
}

variable "iam_role_arn" {
  description = "ARN của IAM Role cho CodePipeline"
  type        = string
}

variable "github_connection_arn" {
  description = "ARN của AWS CodeStar Connection"
  type        = string
}

variable "github_repository_name" {
  description = "Tên GitHub Repository (vd: user/repo)"
  type        = string
}

variable "github_branch_name" {
  description = "Tên nhánh GitHub"
  type        = string
}

variable "codebuild_project_api_name" {
  description = "Tên CodeBuild Project cho API"
  type        = string
}

variable "codebuild_project_web_name" {
  description = "Tên CodeBuild Project cho Web"
  type        = string
}

variable "codedeploy_app_api_name" {
  description = "Tên CodeDeploy App cho API"
  type        = string
}

variable "codedeploy_app_web_name" {
  description = "Tên CodeDeploy App cho Web"
  type        = string
}

variable "codedeploy_group_api_name" {
  description = "Tên Deployment Group của API"
  type        = string
}

variable "codedeploy_group_web_name" {
  description = "Tên Deployment Group của Web"
  type        = string
}