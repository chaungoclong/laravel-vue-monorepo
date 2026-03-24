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
