# ==========================================
# 1. Cấu hình chung (General Config)
# ==========================================
variable "aws_region" {
  description = "AWS Region để triển khai hạ tầng (VD: ap-southeast-1)"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Tên dự án (dùng làm tiền tố cho các resources, VD: laravel-vue)"
  type        = string
}

variable "environment" {
  description = "Môi trường triển khai (VD: dev, stg, prod)"
  type        = string
}

# ==========================================
# 2. Cấu hình EC2 & Database
# ==========================================
variable "ec2_instance_type" {
  description = "Loại EC2 instance để chạy ứng dụng"
  type        = string
  default     = "t3.medium"
}

variable "db_name" {
  description = "Tên database MySQL sẽ được tạo trong EC2"
  type        = string
}

variable "db_username" {
  description = "Tên đăng nhập (user) cho database MySQL"
  type        = string
}

variable "db_password" {
  description = "Mật khẩu cho user database MySQL"
  type        = string
  sensitive   = true # Terraform sẽ ẩn giá trị này trong log/console
}

variable "db_root_password" {
  description = "Mật khẩu root của MySQL"
  type        = string
  sensitive   = true
}

# ==========================================
# 3. Cấu hình CI/CD (GitHub & Pipeline)
# ==========================================
variable "github_connection_arn" {
  description = "ARN của AWS CodeStar Connections để kết nối an toàn với GitHub"
  type        = string
}

variable "github_repository_name" {
  description = "Tên repository trên GitHub (Định dạng: <tên-tài-khoản>/<tên-repo>)"
  type        = string
}

variable "github_branch_name" {
  description = "Tên nhánh trên GitHub sẽ trigger pipeline (VD: main, master, develop)"
  type        = string
  default     = "main"
}