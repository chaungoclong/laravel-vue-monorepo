#!/bin/bash

# Dừng script ngay lập tức nếu có bất kỳ lỗi nào xảy ra
set -e

# ==========================================
# KIỂM TRA QUYỀN ROOT (SUDO)
# ==========================================
if [ "$EUID" -ne 0 ]; then
  echo "❌ LỖI: Vui lòng chạy script này với quyền quản trị cao nhất (root)!"
  echo "👉 Hãy sử dụng lệnh: sudo ./setup.sh"
  exit 1
fi

# ==========================================
# CẤU HÌNH BIẾN MÔI TRƯỜNG - BẠN HÃY THAY ĐỔI Ở ĐÂY
# ==========================================
MYSQL_ROOT_PASS="Root@StrongPass2026!"
DB_NAME="app"
DB_USER="app"
DB_PASS="MyDb@User2026!"
AWS_REGION="ap-southeast-1"
WEB_ROOT="/var/www/laravel-vue" # Thư mục gốc của dự án

echo "=========================================="
echo "🚀 BẮT ĐẦU THIẾT LẬP SERVER AMAZON LINUX 2023"
echo "=========================================="

# ------------------------------------------
echo "[Bước 1/12] Đang cập nhật hệ điều hành..."
dnf update -y
echo "✅ Cập nhật hệ điều hành thành công."

# ------------------------------------------
echo "[Bước 2/12] Đang cài đặt Nginx..."
dnf install -y nginx
systemctl enable nginx
systemctl start nginx
echo "✅ Cài đặt và khởi động Nginx thành công."

# ------------------------------------------
echo "[Bước 3/12] Đang cài đặt PHP 8.4 và các extension phổ biến..."
dnf install -y php8.4 php8.4-fpm php8.4-pdo php8.4-mysqlnd php8.4-mbstring \
    php8.4-xml php8.4-zip php8.4-gd php8.4-intl php8.4-bcmath php-pecl-redis
echo "✅ Cài đặt PHP 8.4 thành công."

# ------------------------------------------
echo "[Bước 4/12] Đang cấu hình và tối ưu hóa PHP-FPM..."
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf

# Tối ưu hóa RAM cho Server 1GB (t3.micro / t2.micro)
sed -i 's/pm.max_children = 50/pm.max_children = 10/g' /etc/php-fpm.d/www.conf
sed -i 's/pm.start_servers = 5/pm.start_servers = 2/g' /etc/php-fpm.d/www.conf
sed -i 's/pm.min_spare_servers = 5/pm.min_spare_servers = 2/g' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_spare_servers = 35/pm.max_spare_servers = 5/g' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 500/g' /etc/php-fpm.d/www.conf

systemctl enable php-fpm
systemctl start php-fpm
echo "✅ Cấu hình và khởi động PHP-FPM thành công."

# ------------------------------------------
echo "[Bước 5/12] Đang cài đặt MySQL 8..."
wget -q https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm
dnf install -y mysql80-community-release-el9-4.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf install -y mysql-community-server
systemctl enable mysqld
systemctl start mysqld
echo "✅ Cài đặt và khởi động MySQL 8 thành công."

# ------------------------------------------
echo "[Bước 6/12] Đang thiết lập Database và User MySQL..."
sleep 5 # Chờ MySQL khởi động hoàn toàn
TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}')
mysql -u root -p"$TEMP_PASS" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASS}';"
mysql -u root -p"${MYSQL_ROOT_PASS}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON \`${DB_NAME}\`.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF
echo "✅ Khởi tạo Database thành công."

# ------------------------------------------
echo "[Bước 7/12] Đang cài đặt Redis..."
dnf install -y redis6
systemctl enable redis6
systemctl start redis6
echo "✅ Cài đặt và khởi động Redis thành công."

# ------------------------------------------
echo "[Bước 8/12] Đang cài đặt Supervisor (Quản lý tiến trình nền)..."
dnf install -y python3 python3-pip
pip3 install supervisor --quiet

mkdir -p /etc/supervisor/conf.d /var/log/supervisor

cat <<EOF > /etc/supervisor/supervisord.conf
; supervisor config file

[unix_http_server]
file=/var/run/supervisor.sock
chmod=0700

[supervisord]
logfile=/var/log/supervisor/supervisord.log
logfile_maxbytes=50MB
logfile_backups=10
loglevel=info
pidfile=/var/run/supervisord.pid
nodaemon=false
minfds=1024
minprocs=200
childlogdir=/var/log/supervisor

[rpcinterface:supervisor]
supervisor.rpcinterface_factory = supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///var/run/supervisor.sock

[include]
files = /etc/supervisor/conf.d/*.conf
EOF

# Tạo Systemd Service cho Supervisor
cat <<EOF > /usr/lib/systemd/system/supervisord.service
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf
ExecStop=/usr/local/bin/supervisord  shutdown
ExecReload=/usr/local/bin/supervisord -c /etc/supervisor/supervisord.conf  reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable supervisord
systemctl start supervisord
echo "✅ Cài đặt và khởi động Supervisor thành công."

# ------------------------------------------
echo "[Bước 9/12] Đang thiết lập User và quyền thư mục dự án..."
usermod -a -G nginx ec2-user

mkdir -p $WEB_ROOT
chown -R ec2-user:nginx $WEB_ROOT
echo "✅ Thiết lập quyền thư mục thành công."

# ------------------------------------------
echo "[Bước 10/12] Đang cấu hình Nginx..."

# Ghi đè trực tiếp cấu hình nginx.conf chuẩn
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat <<EOF > /etc/nginx/nginx.conf
user nginx;
worker_processes auto; # Tự động tối ưu theo số nhân CPU
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

# Load dynamic modules
include /usr/share/nginx/modules/*.conf;

events {
    worker_connections 1024; # Số lượng kết nối tối đa trên mỗi worker
}

http {
    include             /etc/nginx/mime.types;
    default_type        application/octet-stream;

    # Định dạng log và đường dẫn lưu trữ
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /var/log/nginx/access.log  main;

    # Tối ưu hóa hiệu suất gửi file
    sendfile            on;
    tcp_nopush          on;
    keepalive_timeout   65;
    types_hash_max_size 4096;

    # Nạp các file cấu hình riêng lẻ từ thư mục conf.d
    include /etc/nginx/conf.d/*.conf;
}
EOF

# Cấu hình default.conf trỏ về trang mặc định của Nginx
cat <<EOF > /etc/nginx/conf.d/default.conf
server {
    listen       80;
    listen       [::]:80;
    server_name  _;
    root         /usr/share/nginx/html;

    include /etc/nginx/default.d/*.conf;

    error_page 404 /404.html;
    location = /404.html { }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html { }
}
EOF

# Khởi động lại Nginx để nhận cấu hình mới
systemctl restart nginx
echo "✅ Cấu hình Nginx thành công."

# ------------------------------------------
echo "[Bước 11/12] Đang cài đặt Composer..."
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
php -r "unlink('composer-setup.php');"
echo "✅ Cài đặt Composer thành công."

# ------------------------------------------
echo "[Bước 12/12] Đang cài đặt AWS CodeDeploy Agent..."
dnf install -y ruby wget
cd /home/ec2-user
wget -q https://aws-codedeploy-${AWS_REGION}.s3.${AWS_REGION}.amazonaws.com/latest/install
chmod +x ./install
./install auto

systemctl start codedeploy-agent
echo "✅ Cài đặt và khởi động AWS CodeDeploy Agent thành công."

# ------------------------------------------
echo "=========================================="
echo "🎉 HOÀN TẤT THIẾT LẬP SERVER!"
echo " Thư mục dự án đã tạo sẵn chờ deploy: $WEB_ROOT"
echo " "
echo " [THÔNG TIN DATABASE]"
echo " DB_CONNECTION=mysql"
echo " DB_HOST=127.0.0.1"
echo " DB_PORT=3306"
echo " DB_DATABASE=$DB_NAME"
echo " DB_USERNAME=$DB_USER"
echo " DB_PASSWORD=$DB_PASS"
echo " "
echo " (Mật khẩu root MySQL đã được đổi thành: $MYSQL_ROOT_PASS)"
echo "=========================================="