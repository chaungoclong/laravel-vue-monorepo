output "pipeline_api_arn" {
  description = "ARN của CodePipeline API vừa được tạo"
  value       = aws_codepipeline.api.arn
}
output "pipeline_web_arn" {
  description = "ARN của CodePipeline Web vừa được tạo"
  value       = aws_codepipeline.web.arn
}
