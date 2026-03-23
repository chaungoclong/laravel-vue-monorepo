# Bucket lưu trữ Artifacts cho CI/CD
resource "aws_s3_bucket" "artifacts" {
  bucket        = "${var.project}-${var.env}-s3-${var.location}-artifacts-${var.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "artifacts_block" {
  bucket                  = aws_s3_bucket.artifacts.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket lưu trữ Application Data
resource "aws_s3_bucket" "app_data" {
  bucket        = "${var.project}-${var.env}-s3-${var.location}-appdata-${var.account_id}"
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "app_data_block" {
  bucket                  = aws_s3_bucket.app_data.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}