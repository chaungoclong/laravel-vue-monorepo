output "instance_profile_ec2_name" {
  description = "Tên của IAM Instance Profile gắn vào EC2"
  value       = aws_iam_instance_profile.ec2.name # Thay bằng resource thực tế
}

output "iam_role_codebuild_arn" {
  description = "ARN của IAM Role dành cho CodeBuild"
  value       = aws_iam_role.codebuild.arn
}

output "iam_role_codedeploy_arn" {
  description = "ARN của IAM Role dành cho CodeDeploy"
  value       = aws_iam_role.codedeploy.arn
}

output "iam_role_codepipeline_arn" {
  description = "ARN của IAM Role dành cho CodePipeline"
  value       = aws_iam_role.codepipeline.arn
}