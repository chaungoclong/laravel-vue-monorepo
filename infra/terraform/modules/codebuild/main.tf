resource "aws_codebuild_project" "api" {
  name         = "${var.project_name}-${var.environment}-cb-${var.aws_region}-api"
  service_role = var.iam_role_arn

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

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_CUSTOM_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED" # Tắt log CloudWatch để tránh tốn phí
    }
    s3_logs {
      status   = "ENABLED"
      location = "${var.s3_bucket_artifacts_id}/logs/api" # Lưu log build của API vào S3 thay vì CloudWatch
    }
  }
}

resource "aws_codebuild_project" "web" {
  name         = "${var.project_name}-${var.environment}-cb-${var.aws_region}-web"
  service_role = var.iam_role_arn

  artifacts { type = "CODEPIPELINE" }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "aws/codebuild/amazonlinux2-x86_64-standard:5.0"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"

    environment_variable {
      name  = "DEPLOY_ENV" # Biến môi trường này sẽ được truyền vào buildspec để phân biệt giữa API và Web khi chạy build
      value = var.environment
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "apps/web/buildspec.yml" # Đường dẫn file buildspec của Web trong Monorepo
  }

  cache {
    type  = "LOCAL"
    modes = ["LOCAL_CUSTOM_CACHE"]
  }

  logs_config {
    cloudwatch_logs {
      status = "DISABLED" # Tắt log CloudWatch để tránh tốn phí
    }
    s3_logs {
      status   = "ENABLED"
      location = "${var.s3_bucket_artifacts_id}/logs/web" # Lưu log build của Web vào S3 thay vì CloudWatch
    }
  }
}

