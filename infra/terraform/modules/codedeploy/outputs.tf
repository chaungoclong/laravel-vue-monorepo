output "app_api_name" {
  description = "Tên của CodeDeploy Application cho API"
  value       = aws_codedeploy_app.api.name # Thay bằng resource thực tế
}

output "app_web_name" {
  description = "Tên của CodeDeploy Application cho Web"
  value       = aws_codedeploy_app.web.name
}

output "deployment_group_api_name" {
  description = "Tên của CodeDeploy Deployment Group cho API"
  value       = aws_codedeploy_deployment_group.api.deployment_group_name
}

output "deployment_group_web_name" {
  description = "Tên của CodeDeploy Deployment Group cho Web"
  value       = aws_codedeploy_deployment_group.web.deployment_group_name
}