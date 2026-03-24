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

