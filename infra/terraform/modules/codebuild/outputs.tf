output "project_api_name" {
  description = "Tên của CodeBuild Project dùng cho API"
  value       = aws_codebuild_project.api.name # Thay bằng resource thực tế
}

output "project_web_name" {
  description = "Tên của CodeBuild Project dùng cho Web (Vue/React)"
  value       = aws_codebuild_project.web.name
}