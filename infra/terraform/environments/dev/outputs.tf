output "dev_ec2_public_ip" { value = module.ec2.ec2_public_ip }
output "dev_artifacts_bucket" { value = module.s3.artifacts_bucket_id }
output "dev_app_data_bucket" { value = module.s3.app_data_bucket_id }
output "dev_pipeline_api_arn" { value = module.codepipeline.codepipeline_api_arn }
output "dev_pipeline_web_arn" { value = module.codepipeline.codepipeline_web_arn }
