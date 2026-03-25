terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "terraform-225828829859-ap-southeast-1-an"
    key     = "laravel-vue/dev/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
    profile = "terraform"
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "terraform"
}

data "aws_caller_identity" "current" {}

# Lấy Default VPC tự động
data "aws_vpc" "default" {
  default = true
}

# Lấy các Subnet thuộc Default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

module "s3" {
  source         = "../../modules/s3"
  project_name   = var.project_name
  environment    = var.environment
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_region     = var.aws_region
}

module "iam" {
  source                  = "../../modules/iam"
  project_name            = var.project_name
  environment             = var.environment
  aws_region              = var.aws_region
  aws_account_id          = data.aws_caller_identity.current.account_id
  s3_bucket_artifacts_arn = module.s3.bucket_artifacts_arn
  github_connection_arn   = var.github_connection_arn
}

module "ec2" {
  source                    = "../../modules/ec2"
  project_name              = var.project_name
  environment               = var.environment
  aws_region                = var.aws_region
  ec2_instance_type         = var.ec2_instance_type
  vpc_id                    = data.aws_vpc.default.id
  subnet_id                 = data.aws_subnets.default.ids[0] # Chọn Subnet đầu tiên trong Default VPC
  iam_instance_profile_name = module.iam.instance_profile_ec2_name
  db_name                   = var.db_name
  db_username               = var.db_username
  db_password               = var.db_password
  db_root_password          = var.db_root_password
}

module "codebuild" {
  source                 = "../../modules/codebuild"
  project_name           = var.project_name
  environment            = var.environment
  s3_bucket_artifacts_id = module.s3.bucket_artifacts_id
  iam_role_arn           = module.iam.iam_role_codebuild_arn
  aws_region             = var.aws_region
}

module "codedeploy" {
  source       = "../../modules/codedeploy"
  project_name = var.project_name
  environment  = var.environment
  iam_role_arn = module.iam.iam_role_codedeploy_arn
  aws_region   = var.aws_region
}

module "codepipeline" {
  source                     = "../../modules/codepipeline"
  project_name               = var.project_name
  environment                = var.environment
  aws_region                 = var.aws_region
  s3_bucket_artifacts_id     = module.s3.bucket_artifacts_id
  iam_role_arn               = module.iam.iam_role_codepipeline_arn
  github_connection_arn      = var.github_connection_arn
  github_repository_name     = var.github_repository_name
  github_branch_name         = var.github_branch_name
  codebuild_project_api_name = module.codebuild.project_api_name
  codebuild_project_web_name = module.codebuild.project_web_name
  codedeploy_app_api_name    = module.codedeploy.app_api_name
  codedeploy_app_web_name    = module.codedeploy.app_web_name
  codedeploy_group_api_name  = module.codedeploy.deployment_group_api_name
  codedeploy_group_web_name  = module.codedeploy.deployment_group_web_name
}
