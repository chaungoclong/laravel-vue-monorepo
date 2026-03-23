# ==========================================
# 1. CodeDeploy Application (Tách riêng cho API & Web)
# ==========================================
resource "aws_codedeploy_app" "api" {
  name             = "${var.project}-cdapp-${var.location}-api"
  compute_platform = "Server"
}

resource "aws_codedeploy_app" "web" {
  name             = "${var.project}-cdapp-${var.location}-web"
  compute_platform = "Server"
}

# ==========================================
# 2. CodeBuild Projects (API & Web)
# ==========================================
resource "aws_codebuild_project" "api" {
  name         = "${var.project}-${var.env}-cb-${var.location}-api"
  service_role = var.codebuild_role_arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "apps/api/buildspec.yml" # Đường dẫn file buildspec của API trong Monorepo
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED" # Tắt log CloudWatch để tránh tốn phí
    }
    s3_logs {
      status   = "ENABLED"
      location = "${var.artifacts_bucket}/logs/api" # Lưu log build của API vào S3 thay vì CloudWatch
    }
  }
}

resource "aws_codebuild_project" "web" {
  name         = "${var.project}-${var.env}-cb-${var.location}-web"
  service_role = var.codebuild_role_arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "DEPLOY_ENV" # Biến môi trường này sẽ được truyền vào buildspec để phân biệt giữa API và Web khi chạy build
      value = var.env
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "apps/web/buildspec.yml" # Đường dẫn file buildspec của Web trong Monorepo
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED" # Tắt log CloudWatch để tránh tốn phí
    }
    s3_logs {
      status   = "ENABLED"
      location = "${var.artifacts_bucket}/logs/web" # Lưu log build của Web vào S3 thay vì CloudWatch
    }
  }
}

# ==========================================
# 3. CodeDeploy Deployment Groups (API & Web)
# ==========================================
resource "aws_codedeploy_deployment_group" "api" {
  app_name              = aws_codedeploy_app.api.name
  deployment_group_name = "${var.project}-${var.env}-cdgroup-${var.location}-api"
  service_role_arn      = var.codedeploy_role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.env
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.project
    }
  }
}

resource "aws_codedeploy_deployment_group" "web" {
  app_name              = aws_codedeploy_app.web.name
  deployment_group_name = "${var.project}-${var.env}-cdgroup-${var.location}-web"
  service_role_arn      = var.codedeploy_role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.env
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.project
    }
  }
}

# ==========================================
# 4. CodePipeline (API & Web)
# ==========================================
resource "aws_codepipeline" "api" {
  name          = "${var.project}-${var.env}-cp-${var.location}-api"
  role_arn      = var.codepipeline_role_arn
  pipeline_type = "V2" # Bắt buộc phải là V2 để hỗ trợ  
  execution_mode = "QUEUED" # Chế độ thực thi mới, cho phép xếp hàng các lần chạy pipeline nếu có nhiều commit liên tiếp

  artifact_store {
    location = var.artifacts_bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.github_branch]
        }
        file_paths {
          includes = ["apps/api/**"] # Chỉ kích hoạt khi có thay đổi trong thư mục apps/api/
        }
      }
    }
  }

  stage {
    name = "Source"
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
        DetectChanges    = "false" # Tắt trigger mặc định, nhường quyền cho block `trigger` ở trên
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration    = { ProjectName = aws_codebuild_project.api.name }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ApplicationName     = aws_codedeploy_app.api.name
        DeploymentGroupName = aws_codedeploy_deployment_group.api.deployment_group_name
      }
    }
  }
}

resource "aws_codepipeline" "web" {
  name          = "${var.project}-${var.env}-cp-${var.location}-web"
  role_arn      = var.codepipeline_role_arn
  pipeline_type = "V2" # Bắt buộc phải là V2 để hỗ trợ Trigger
  execution_mode = "QUEUED" # Chế độ thực thi mới, cho phép xếp hàng các lần chạy pipeline nếu có nhiều commit liên tiếp

  artifact_store {
    location = var.artifacts_bucket
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.github_branch]
        }
        file_paths {
          includes = ["apps/web/**"] # Chỉ kích hoạt khi có thay đổi trong thư mục apps/web/
        }
      }
    }
  }

  stage {
    name = "Source" # Tương tự API, trỏ chung 1 repo
    action {
      name             = "Source"
      category         = "Source"
      owner            = "AWS"
      provider         = "CodeStarSourceConnection"
      version          = "1"
      output_artifacts = ["source_output"]
      configuration = {
        ConnectionArn    = var.github_connection_arn
        FullRepositoryId = var.github_repo
        BranchName       = var.github_branch
        DetectChanges    = "false" # Tắt trigger mặc định, nhường quyền cho block `trigger` ở trên
      }
    }
  }

  stage {
    name = "Build"
    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"
      configuration    = { ProjectName = aws_codebuild_project.web.name }
    }
  }

  stage {
    name = "Deploy"
    action {
      name            = "Deploy"
      category        = "Deploy"
      owner           = "AWS"
      provider        = "CodeDeploy"
      input_artifacts = ["build_output"]
      version         = "1"
      configuration = {
        ApplicationName     = aws_codedeploy_app.web.name
        DeploymentGroupName = aws_codedeploy_deployment_group.web.deployment_group_name
      }
    }
  }
}
