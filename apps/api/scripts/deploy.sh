#!/bin/bash
# Thiết lập biến môi trường
APP_DIR="/var/www/laravel-vue/api"
SHARED_DIR="/var/www/laravel-vue/shared"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
RELEASE_DIR="$APP_DIR/releases/$TIMESTAMP"
DEPLOY_USER="ec2-user"
DEPLOY_GROUP="nginx"

# 1. Bật chế độ debug và log toàn bộ output ra file
set -xeuo pipefail
LOG_FILE="/tmp/deploy_api.log"
exec > >(tee "$LOG_FILE") 2>&1

# Đợi cho đến khi một file "ready" xuất hiện (file này được tạo ở cuối user_data)
while [ ! -f /var/lib/cloud/instance/boot-finished ]; do
  echo "Waiting for user_data to finish..."
  sleep 10
done

# 1. Xác định môi trường từ CodeDeploy (Mặc định là development nếu trống)
# Chuyển tên Deployment Group về chữ thường (ví dụ: Production -> production)
DEPLOYMENT_GROUP_NAME_LOWER=$(echo "${DEPLOYMENT_GROUP_NAME}" | tr '[:upper:]' '[:lower:]')
echo "Deployment group: $DEPLOYMENT_GROUP_NAME_LOWER"

if [[ "$DEPLOYMENT_GROUP_NAME_LOWER" == *"-prod-"* ]]; then
    APP_ENV=production
    ENV_FILE=".env.production"
elif [[ "$DEPLOYMENT_GROUP_NAME_LOWER" == *"-dev-"* ]]; then
    APP_ENV=local
    ENV_FILE=".env.development"
else
    echo "Lỗi: Không xác định được môi trường!"
    exit 1
fi

echo "Deploying with APP_ENV=$APP_ENV"

mkdir -p "$APP_DIR/releases"

chown -R $DEPLOY_USER:$DEPLOY_GROUP "$APP_DIR"

# Đảm bảo appspec.yml đã copy code vào $APP_DIR/temp_release
if [ -d "$APP_DIR/temp_release" ]; then
    mv "$APP_DIR/temp_release" "$RELEASE_DIR"
else
    echo "Lỗi: Không tìm thấy thư mục temp_release!"
    exit 1
fi

# 2. Khởi tạo cấu trúc thư mục
mkdir -p "$APP_DIR/releases"
mkdir -p "$SHARED_DIR/storage/framework/"{cache,sessions,views,testing}
mkdir -p "$SHARED_DIR/storage/logs"

if [ -f "$RELEASE_DIR/${ENV_FILE}" ]; then
    cp "$RELEASE_DIR/${ENV_FILE}" "$SHARED_DIR/.env"
    echo "Đã cập nhật .env từ file ${ENV_FILE}"
else
    echo "Cảnh báo: Không tìm thấy file ${ENV_FILE}, giữ nguyên .env cũ."
fi

# 4. Tạo Symlink cho Storage và Env
rm -rf "$RELEASE_DIR/storage"
ln -nfs "$SHARED_DIR/storage" "$RELEASE_DIR/storage"
ln -nfs "$SHARED_DIR/.env" "$RELEASE_DIR/.env"

# 5. Phân quyền
chown -R $DEPLOY_USER:$DEPLOY_GROUP "$SHARED_DIR"
chown -R $DEPLOY_USER:$DEPLOY_GROUP "$RELEASE_DIR"
chmod -R 775 "$RELEASE_DIR/storage" "$RELEASE_DIR/bootstrap/cache"

# 6. Tối ưu hóa Laravel
cd "$RELEASE_DIR"
php artisan config:clear
php artisan migrate --force
php artisan optimize:clear
php artisan optimize
php artisan storage:link

# 7. Atomic Deploy: Cập nhật symlink 'current'
ln -nfs "$RELEASE_DIR" "$APP_DIR/current"

cd "$APP_DIR/current"

# 8. RESTART SERVICES (QUAN TRỌNG)
echo "Đang làm mới bộ nhớ cache và restart workers..."

# Khởi động lại PHP-FPM để xóa OPcache
sudo systemctl reload php-fpm.service

# Load lại NGINX
sudo systemctl reload nginx

# Khởi động lại Supervisor - Thêm kiểm tra trạng thái trước
sudo supervisorctl reread
sudo supervisorctl update

# Luôn chạy lệnh này để báo hiệu cho workers tự thoát khi xong job
php artisan queue:restart

# 9. Dọn dẹp: Chỉ giữ lại 3 bản deploy gần nhất
cd "$APP_DIR/releases"
ls -1dt $APP_DIR/releases/* | tail -n +4 | xargs -d '\n' rm -rf

echo "Deploy Backend cho $APP_ENV hoàn tất!"
