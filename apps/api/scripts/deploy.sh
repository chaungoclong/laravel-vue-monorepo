#!/bin/bash
# Thiết lập biến môi trường
APP_DIR="/var/www/laravel-vue/api"
SHARED_DIR="/var/www/laravel-vue/shared"
TIMESTAMP=$(date +"%Y%m%d%H%M%S")
RELEASE_DIR="$APP_DIR/releases/$TIMESTAMP"
DEPLOY_USER="ec2-user"
DEPLOY_GROUP="nginx"

# 1. Xác định môi trường từ CodeDeploy (Mặc định là development nếu trống)
# Chuyển tên Deployment Group về chữ thường (ví dụ: Production -> production)
ENV_NAME=$(echo "${DEPLOYMENT_GROUP_NAME:-development}" | tr '[:upper:]' '[:lower:]')

echo "Bắt đầu deploy API cho môi trường: $ENV_NAME"

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

# 3. Di chuyển code và cấu hình file .env
mv "$APP_DIR/temp_release" "$RELEASE_DIR"

if [ -f "$RELEASE_DIR/.env.${ENV_NAME}" ]; then
    cp "$RELEASE_DIR/.env.${ENV_NAME}" "$SHARED_DIR/.env"
    echo "Đã cập nhật .env từ file .env.${ENV_NAME}"
else
    echo "Cảnh báo: Không tìm thấy file .env.${ENV_NAME}, giữ nguyên .env cũ."
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

echo "Deploy Backend cho $ENV_NAME hoàn tất!"
