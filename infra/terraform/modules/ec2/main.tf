# Security Group cho EC2 Instance
resource "aws_security_group" "app_sg" {
  name        = "${var.project_name}-${var.environment}-sg-${var.aws_region}-app"
  description = "Allow HTTP, HTTPS and SSH"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Lấy AMI Amazon Linux 2023 mới nhất
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# 1. Tạo Private Key
resource "tls_private_key" "ec2_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# 2. Tạo AWS Key Pair từ Public Key
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.project_name}-${var.environment}-${var.aws_region}-key"
  public_key = tls_private_key.ec2_ssh_key.public_key_openssh
}

# 3. Tự động lưu Private Key ra file .pem tại máy local để bạn có thể SSH
resource "local_file" "private_key_pem" {
  content         = tls_private_key.ec2_ssh_key.private_key_pem
  filename        = "${path.root}/${var.project_name}-${var.environment}-${var.aws_region}-key.pem"
  file_permission = "0400" # Phân quyền chỉ đọc để bảo mật file pem
}

# Khởi tạo EC2 Instance chạy cả Web và API
resource "aws_instance" "this" {
  ami                    = data.aws_ami.amazon_linux_2023.id
  instance_type          = var.ec2_instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  iam_instance_profile   = var.iam_instance_profile_name
  key_name               = aws_key_pair.ec2_key_pair.key_name

  # Đọc file bash script và truyền các biến bảo mật vào (Inject Variables)
  user_data = templatefile("${path.module}/setup.sh.tftpl", {
    DB_ROOT_PASSWORD = var.db_root_password
    DB_NAME          = var.db_name
    DB_USERNAME      = var.db_username
    DB_PASSWORD      = var.db_password
    AWS_REGION       = var.aws_region
    PROJECT_NAME     = var.project_name
  })

  tags = {
    Name        = var.project_name
    Environment = var.environment
  }
}
