output "bucket_artifacts_id" {
  description = "ID (tên) của S3 Bucket dùng để lưu artifacts"
  value       = aws_s3_bucket.artifacts.id # Thay aws_s3_bucket.artifacts bằng resource thực tế của bạn
}

output "bucket_artifacts_arn" {
  description = "ARN của S3 Bucket dùng để lưu artifacts"
  value       = aws_s3_bucket.artifacts.arn
}