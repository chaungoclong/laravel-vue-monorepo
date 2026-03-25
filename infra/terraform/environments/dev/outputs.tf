# ==========================================
# Thông tin CI/CD & Storage
# ==========================================
output "s3_bucket_artifacts_name" {
  description = "Tên S3 bucket được tạo để lưu trữ artifacts của CI/CD"
  value       = module.s3.bucket_artifacts_id
}

output "codebuild_api_project" {
  description = "Tên project CodeBuild dùng để build API"
  value       = module.codebuild.project_api_name
}

output "codebuild_web_project" {
  description = "Tên project CodeBuild dùng để build Web"
  value       = module.codebuild.project_web_name
}

output "codepipeline_api_id" {
  description = "ID của CodePipeline API vừa được tạo"
  value       = module.codepipeline.pipeline_api_arn
}

output "codepipeline_web_id" {
  description = "ID của CodePipeline Web vừa được tạo"
  value       = module.codepipeline.pipeline_web_arn
}

# ==========================================
# Thông tin EC2 (Server)
# ==========================================
output "ec2_instance_id" {
  description = "ID của EC2 instance chạy ứng dụng"
  value       = module.ec2.instance_id
}

output "ec2_public_ip" {
  description = "Địa chỉ Public IP của máy chủ EC2 để truy cập ứng dụng"
  value       = module.ec2.public_ip
}

# ==========================================
# Thông tin IAM Roles
# ==========================================
output "iam_role_pipeline_arn" {
  description = "ARN của IAM Role cấp cho CodePipeline"
  value       = module.iam.iam_role_codepipeline_arn
}

output "iam_role_codebuild_arn" {
  description = "ARN của IAM Role cấp cho CodeBuild"
  value       = module.iam.iam_role_codebuild_arn
}

output "iam_role_codedeploy_arn" {
  description = "ARN của IAM Role cấp cho CodeDeploy"
  value       = module.iam.iam_role_codedeploy_arn
}
