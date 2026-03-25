resource "aws_codepipeline" "api" {
  name           = "${var.project_name}-${var.environment}-cp-${var.aws_region}-api"
  role_arn       = var.iam_role_arn
  pipeline_type  = "V2"     # Bắt buộc phải là V2 để hỗ trợ  
  execution_mode = "QUEUED" # Chế độ thực thi mới, cho phép xếp hàng các lần chạy pipeline nếu có nhiều commit liên tiếp

  artifact_store {
    location = var.s3_bucket_artifacts_id
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.github_branch_name]
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
        FullRepositoryId = var.github_repository_name
        BranchName       = var.github_branch_name
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
      configuration    = { ProjectName = var.codebuild_project_api_name }
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
        ApplicationName     = var.codedeploy_app_api_name
        DeploymentGroupName = var.codedeploy_group_api_name
      }
    }
  }
}

resource "aws_codepipeline" "web" {
  name           = "${var.project_name}-${var.environment}-cp-${var.aws_region}-web"
  role_arn       = var.iam_role_arn
  pipeline_type  = "V2"     # Bắt buộc phải là V2 để hỗ trợ Trigger
  execution_mode = "QUEUED" # Chế độ thực thi mới, cho phép xếp hàng các lần chạy pipeline nếu có nhiều commit liên tiếp

  artifact_store {
    location = var.s3_bucket_artifacts_id
    type     = "S3"
  }

  trigger {
    provider_type = "CodeStarSourceConnection"
    git_configuration {
      source_action_name = "Source"
      push {
        branches {
          includes = [var.github_branch_name]
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
        FullRepositoryId = var.github_repository_name
        BranchName       = var.github_branch_name
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
      configuration    = { ProjectName = var.codebuild_project_web_name }
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
        ApplicationName     = var.codedeploy_app_web_name
        DeploymentGroupName = var.codedeploy_group_web_name
      }
    }
  }
}
