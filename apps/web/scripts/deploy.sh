#!/bin/bash
# 1. Bật chế độ debug và log toàn bộ output ra file
set -xeuo pipefail
LOG_FILE="/tmp/deploy_web.log"
exec > >(tee "$LOG_FILE") 2>&1

# 2. Cấu hình biến môi trường
APP_DIR="/var/www/laravel-vue/web"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
RELEASE_DIR="$APP_DIR/releases/v$TIMESTAMP"

# Xác định môi trường (ví dụ: production hoặc development)
ENV_NAME=$(echo "${DEPLOYMENT_GROUP_NAME:-development}" | tr '[:upper:]' '[:lower:]')

echo "------------------------------------------"
echo "Bắt đầu deploy Web cho môi trường: $ENV_NAME"
echo "------------------------------------------"

# 3. Khởi tạo cấu trúc thư mục
mkdir -p "$APP_DIR/releases"

# 4. Atomic Deploy: Di chuyển code từ thư mục tạm sang release mới
# Đảm bảo appspec.yml đã copy code vào $APP_DIR/temp_release
if [ -d "$APP_DIR/temp_release" ]; then
    mv "$APP_DIR/temp_release" "$RELEASE_DIR"
else
    echo "Lỗi: Không tìm thấy thư mục temp_release!"
    exit 1
fi

# 5. Phân quyền cho Nginx đọc file
chown -R ec2-user:nginx "$RELEASE_DIR"
find "$RELEASE_DIR" -type d -exec chmod 755 {} +
find "$RELEASE_DIR" -type f -exec chmod 644 {} +

# 6. Cập nhật symlink 'current' để trỏ tới bản build mới nhất
ln -nfs "$RELEASE_DIR" "$APP_DIR/current"

# 7. Dọn dẹp: Chỉ giữ lại 3 bản deploy gần nhất
cd "$APP_DIR/releases"
# Liệt kê các thư mục, lấy từ dòng thứ 4 trở đi và xóa chúng
ls -dt v*/ | tail -n +4 | xargs -r rm -rf

echo "------------------------------------------"
echo "Deploy Web cho $ENV_NAME hoàn tất!"
echo "------------------------------------------"
