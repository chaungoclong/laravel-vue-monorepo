# ==========================================
# 1. CodeDeploy Application (Tách riêng cho API & Web)
# ==========================================
resource "aws_codedeploy_app" "api" {
  name             = "${var.project_name}-${var.environment}-cdapp-${var.aws_region}-api"
  compute_platform = "Server"
}

resource "aws_codedeploy_app" "web" {
  name             = "${var.project_name}-${var.environment}-cdapp-${var.aws_region}-web"
  compute_platform = "Server"
}


# ==========================================
# 3. CodeDeploy Deployment Groups (API & Web)
# ==========================================
resource "aws_codedeploy_deployment_group" "api" {
  app_name              = aws_codedeploy_app.api.name
  deployment_group_name = "${var.project_name}-${var.environment}-cdgroup-${var.aws_region}-api"
  service_role_arn      = var.iam_role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.environment
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.project_name
    }
  }
}

resource "aws_codedeploy_deployment_group" "web" {
  app_name              = aws_codedeploy_app.web.name
  deployment_group_name = "${var.project_name}-${var.environment}-cdgroup-${var.aws_region}-web"
  service_role_arn      = var.iam_role_arn

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Environment"
      type  = "KEY_AND_VALUE"
      value = var.environment
    }
  }

  ec2_tag_set {
    ec2_tag_filter {
      key   = "Name"
      type  = "KEY_AND_VALUE"
      value = var.project_name
    }
  }
}
