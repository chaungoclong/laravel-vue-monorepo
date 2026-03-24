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
  region  = var.region
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
  source     = "../../modules/s3"
  project    = var.project
  env        = var.env
  location   = var.location
  account_id = data.aws_caller_identity.current.account_id
}

module "iam" {
  source                  = "../../modules/iam"
  project                 = var.project
  env                     = var.env
  location                = var.location
  region                  = var.region
  account_id              = data.aws_caller_identity.current.account_id
  s3_artifacts_arn        = module.s3.artifacts_bucket_arn
  codestar_connection_arn = var.github_connection_arn
}

module "ec2" {
  source               = "../../modules/ec2"
  project              = var.project
  env                  = var.env
  location             = var.location
  region               = var.region
  instance_type        = "t3.micro"
  vpc_id               = data.aws_vpc.default.id
  subnet_id            = data.aws_subnets.default.ids[0]
  iam_instance_profile = module.iam.ec2_instance_profile_name

  # Truyền các tham số Database xuống cho Setup Script
  mysql_root_pass = var.mysql_root_pass
  db_name         = var.db_name
  db_user         = var.db_user
  db_pass         = var.db_pass
}


# module "pipeline" {
#   source                = "../../modules/pipeline"
#   project               = var.project
#   env                   = var.env
#   location              = var.location
#   artifacts_bucket      = module.s3.artifacts_bucket_id
#   codebuild_role_arn    = module.iam.codebuild_role_arn
#   codedeploy_role_arn   = module.iam.codedeploy_role_arn
#   codepipeline_role_arn = module.iam.codepipeline_role_arn
#   github_branch         = var.github_branch
#   github_connection_arn = var.github_connection_arn
#   github_repo           = var.github_repo
# }


module "codebuild" {
  source             = "../../modules/codebuild"
  project            = var.project
  env                = var.env
  location           = var.location
  artifacts_bucket   = module.s3.artifacts_bucket_id
  codebuild_role_arn = module.iam.codebuild_role_arn
}


module "codedeploy" {
  source              = "../../modules/codedeploy"
  project             = var.project
  env                 = var.env
  location            = var.location
  codedeploy_role_arn = module.iam.codedeploy_role_arn
}

module "codepipeline" {
  source                               = "../../modules/codepipeline"
  project                              = var.project
  env                                  = var.env
  location                             = var.location
  artifacts_bucket                     = module.s3.artifacts_bucket_id
  codepipeline_role_arn                = module.iam.codepipeline_role_arn
  github_connection_arn                = var.github_connection_arn
  github_repo                          = var.github_repo
  github_branch                        = var.github_branch
  codebuild_api_name                   = module.codebuild.codebuild_api_name
  codebuild_web_name                   = module.codebuild.codebuild_web_name
  codedeploy_api_name                  = module.codedeploy.codedeploy_api_name
  codedeploy_web_name                  = module.codedeploy.codedeploy_web_name
  codedeploy_api_deployment_group_name = module.codedeploy.codedeploy_api_deployment_group_name
  codedeploy_web_deployment_group_name = module.codedeploy.codedeploy_web_deployment_group_name
}
