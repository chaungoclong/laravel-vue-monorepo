output "codedeploy_api_arn" { value = aws_codedeploy_app.api.arn }
output "codedeploy_web_arn" { value = aws_codedeploy_app.web.arn }
output "codedeploy_api_name" { value = aws_codedeploy_app.api.name }
output "codedeploy_web_name" { value = aws_codedeploy_app.web.name }
output "codedeploy_api_deployment_group_name" { value = aws_codedeploy_deployment_group.api.deployment_group_name }
output "codedeploy_web_deployment_group_name" { value = aws_codedeploy_deployment_group.web.deployment_group_name }
