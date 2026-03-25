# ==========================================
# 1. EC2 Instance Role & Profile
# ==========================================
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-${var.environment}-iam-${var.aws_region}-ec2role"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

# Policy bắt buộc cho EC2 chạy CodeDeploy Agent
resource "aws_iam_role_policy_attachment" "ec2_codedeploy" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforAWSCodeDeploy"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-${var.environment}-iam-${var.aws_region}-ec2profile"
  role = aws_iam_role.ec2.name
}

# ==========================================
# 2. CodeDeploy Role
# ==========================================
resource "aws_iam_role" "codedeploy" {
  name = "${var.project_name}-${var.environment}-iam-${var.aws_region}-deployrole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codedeploy.amazonaws.com" } }]
  })
}

# AWSCodeDeployRole Managed Policy
resource "aws_iam_role_policy_attachment" "codedeploy_managed" {
  role       = aws_iam_role.codedeploy.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

# ==========================================
# 3. CodeBuild Role
# ==========================================
resource "aws_iam_role" "codebuild" {
  name = "${var.project_name}-${var.environment}-iam-${var.aws_region}-buildrole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codebuild.amazonaws.com" } }]
  })
}

# CodeBuild Policies
resource "aws_iam_role_policy" "codebuild_policy" {
  name = "CodeBuildPolicy"
  role = aws_iam_role.codebuild.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = [
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/${var.project_name}-${var.environment}-cb-${var.aws_region}-api",
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/${var.project_name}-${var.environment}-cb-${var.aws_region}-api:*",
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/${var.project_name}-${var.environment}-cb-${var.aws_region}-web",
          "arn:aws:logs:${var.aws_region}:${var.aws_account_id}:log-group:/aws/codebuild/${var.project_name}-${var.environment}-cb-${var.aws_region}-web:*"
        ]
      },
      {
        Effect = "Allow",
        Action = ["s3:PutObject", "s3:GetObject", "s3:GetObjectVersion", "s3:GetBucketAcl", "s3:GetBucketLocation", "s3:ListBucket"],
        Resource = [
          var.s3_bucket_artifacts_arn,
          "${var.s3_bucket_artifacts_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codebuild:CreateReportGroup", "codebuild:CreateReport", "codebuild:UpdateReport",
          "codebuild:BatchPutTestCases", "codebuild:BatchPutCodeCoverages"
        ],
        Resource = [
          "arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:report-group/${var.project_name}-${var.environment}-cb-${var.aws_region}-api-*",
          "arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:report-group/${var.project_name}-${var.environment}-cb-${var.aws_region}-web-*"
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "codestar-connections:GetConnectionToken", "codestar-connections:GetConnection",
          "codeconnections:GetConnectionToken", "codeconnections:GetConnection", "codeconnections:UseConnection"
        ],
        Resource = [var.github_connection_arn]
      }
    ]
  })
}

# ==========================================
# 4. CodePipeline Role
# ==========================================
resource "aws_iam_role" "codepipeline" {
  name = "${var.project_name}-${var.environment}-iam-${var.aws_region}-pipelinerole"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "codepipeline.amazonaws.com" } }]
  })
}

# Codepipeline Policies
resource "aws_iam_role_policy" "codepipeline_policy" {
  name = "CodePipelinePolicy"
  role = aws_iam_role.codepipeline.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "s3:GetBucketVersioning", "s3:GetBucketAcl", "s3:GetBucketLocation",
          "s3:PutObject", "s3:PutObjectAcl", "s3:GetObject", "s3:GetObjectVersion"
        ],
        Resource = [
          var.s3_bucket_artifacts_arn,
          "${var.s3_bucket_artifacts_arn}/*"
        ]
      },
      {
        Effect = "Allow",
        Action = ["codebuild:BatchGetBuilds", "codebuild:StartBuild", "codebuild:BatchGetBuildBatches", "codebuild:StartBuildBatch"],
        Resource = [
          "arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:project/${var.project_name}-${var.environment}-cb-${var.aws_region}-api",
          "arn:aws:codebuild:${var.aws_region}:${var.aws_account_id}:project/${var.project_name}-${var.environment}-cb-${var.aws_region}-web"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["codeconnections:UseConnection", "codestar-connections:UseConnection"],
        Resource = [var.github_connection_arn]
      },
      {
        Effect = "Allow",
        Action = [
          "codedeploy:CreateDeployment", "codedeploy:GetApplication", "codedeploy:GetDeployment",
          "codedeploy:RegisterApplicationRevision", "codedeploy:ListDeployments",
          "codedeploy:ListDeploymentGroups", "codedeploy:GetDeploymentGroup", "codedeploy:GetApplicationRevision"
        ],
        Resource = [
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:application:${var.project_name}-${var.environment}-cdapp-${var.aws_region}-*",
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentgroup:${var.project_name}-${var.environment}-cdapp-${var.aws_region}-api/${var.project_name}-${var.environment}-cdgroup-${var.aws_region}-api",
          "arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentgroup:${var.project_name}-${var.environment}-cdapp-${var.aws_region}-web/${var.project_name}-${var.environment}-cdgroup-${var.aws_region}-web"
        ]
      },
      {
        Effect   = "Allow",
        Action   = ["codedeploy:GetDeploymentConfig"],
        Resource = ["arn:aws:codedeploy:${var.aws_region}:${var.aws_account_id}:deploymentconfig:CodeDeployDefault.OneAtATime"]
      },
      {
        Effect   = "Allow",
        Action   = ["codedeploy:ListDeploymentConfigs"],
        Resource = ["*"]
      }
    ]
  })
}
