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
      configuration    = { ProjectName = var.codebuild_api_name }
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
        ApplicationName     = var.codedeploy_api_name
        DeploymentGroupName = var.codedeploy_api_deployment_group_name
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
      configuration    = { ProjectName = var.codebuild_web_name }
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
        ApplicationName     = var.codedeploy_web_name
        DeploymentGroupName = var.codedeploy_web_deployment_group_name
      }
    }
  }
}
