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

# 1. Xác định môi trường từ CodeDeploy (Mặc định là development nếu trống)
# Chuyển tên Deployment Group về chữ thường (ví dụ: Production -> production)
DEPLOYMENT_GROUP_NAME_LOWER=$(echo "${DEPLOYMENT_GROUP_NAME}" | tr '[:upper:]' '[:lower:]')
echo "Deployment group: $GROUP_NAME"

if [[ "$GROUP_NAME" == *"-prod-"* ]]; then
    APP_ENV=production
    ENV_FILE=".env.production"
elif [[ "$GROUP_NAME" == *"-dev-"* ]]; then
    APP_ENV=local
    ENV_FILE=".env.development"
else
    echo "Lỗi: Không xác định được môi trường!"
    exit 1
fi

echo "Deploying with APP_ENV=$APP_ENV"

mkdir -p "$APP_DIR/releases"

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
# Chỉ chạy migrate nếu là môi trường production hoặc tùy mục đích của bạn
php artisan migrate --force
php artisan optimize:clear
php artisan optimize
php artisan storage:link

# 7. Atomic Deploy: Cập nhật symlink 'current'
ln -nfs "$RELEASE_DIR" "$APP_DIR/current"

# 8. Dọn dẹp: Chỉ giữ lại 3 bản deploy gần nhất
cd "$APP_DIR/releases"
ls -dt */ | tail -n +4 | xargs -r rm -rf

echo "Deploy Backend cho $APP_ENV hoàn tất!"
