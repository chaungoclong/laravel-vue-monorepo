#!/bin/bash

# Dừng script ngay lập tức nếu có bất kỳ lỗi nào xảy ra
set -e

# ==========================================
# KIỂM TRA QUYỀN ROOT (SUDO)
# ==========================================
if [ "$EUID" -ne 0 ]; then
echo "❌ LỖI: Vui lòng chạy script này với quyền quản trị cao nhất (root)!"
exit 1
fi

echo "=========================================="
echo "🚀 BẮT ĐẦU THIẾT LẬP SERVER AMAZON LINUX 2023"
echo "=========================================="

echo "[Bước 1/12] Đang cập nhật hệ điều hành..."
dnf update -y
echo "✅ Cập nhật hệ điều hành thành công."

echo "[Bước 2/12] Đang cài đặt Nginx..."
dnf install -y nginx
systemctl enable nginx
systemctl start nginx
echo "✅ Cài đặt và khởi động Nginx thành công."

echo "[Bước 3/12] Đang cài đặt PHP 8.4 và các extension..."
dnf install -y php8.4 php8.4-fpm php8.4-pdo php8.4-mysqlnd php8.4-mbstring \
php8.4-xml php8.4-zip php8.4-gd php8.4-intl php8.4-bcmath php-pecl-redis
echo "✅ Cài đặt PHP 8.4 thành công."

echo "[Bước 4/12] Đang cấu hình và tối ưu hóa PHP-FPM..."
sed -i 's/user = apache/user = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/group = apache/group = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/listen.owner = nobody/listen.owner = nginx/g' /etc/php-fpm.d/www.conf
sed -i 's/listen.group = nobody/listen.group = nginx/g' /etc/php-fpm.d/www.conf

# Tối ưu hóa RAM cho Server t3.micro
sed -i 's/pm.max_children = 50/pm.max_children = 10/g' /etc/php-fpm.d/www.conf
sed -i 's/pm.start_servers = 5/pm.start_servers = 2/g' /etc/php-fpm.d/www.conf
sed -i 's/pm.min_spare_servers = 5/pm.min_spare_servers = 2/g' /etc/php-fpm.d/www.conf
sed -i 's/pm.max_spare_servers = 35/pm.max_spare_servers = 5/g' /etc/php-fpm.d/www.conf
sed -i 's/;pm.max_requests = 500/pm.max_requests = 500/g' /etc/php-fpm.d/www.conf

systemctl enable php-fpm
systemctl start php-fpm
echo "✅ Cấu hình và khởi động PHP-FPM thành công."

echo "[Bước 5/12] Đang cài đặt MySQL 8..."
wget -q https://dev.mysql.com/get/mysql80-community-release-el9-4.noarch.rpm
dnf install -y mysql80-community-release-el9-4.noarch.rpm
rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
dnf install -y mysql-community-server
systemctl enable mysqld
systemctl start mysqld
echo "✅ Cài đặt và khởi động MySQL 8 thành công."

echo "[Bước 6/12] Đang thiết lập Database và User MySQL..."
# Chờ MySQL khởi động và tạo mật khẩu tạm thời hoàn tất
while ! grep -q 'temporary password' /var/log/mysqld.log; do
sleep 1
done

TEMP_PASS=$(grep 'temporary password' /var/log/mysqld.log | tail -n 1 | awk '{print $NF}')
mysql -u root -p"$TEMP_PASS" --connect-expired-password -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${mysql_root_pass}';"
mysql -u root -p"${mysql_root_pass}" <<'MYSQL_EOF'
CREATE DATABASE IF NOT EXISTS `${db_name}` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${db_user}'@'localhost' IDENTIFIED BY '${db_pass}';
GRANT ALL PRIVILEGES ON `${db_name}`.* TO '${db_user}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_EOF
echo "✅ Khởi tạo Database thành công."

echo "[Bước 7/12] Đang cài đặt Redis..."
dnf install -y redis6
systemctl enable redis6
systemctl start redis6
echo "✅ Cài đặt và khởi động Redis thành công."

echo "[Bước 8/12] Đang cài đặt Supervisor..."
dnf install -y python3 python3-pip
pip3 install supervisor --quiet

mkdir -p /etc/supervisor/conf.d /var/log/supervisor

cat > /etc/supervisor/supervisord.conf <<'SUPERVISOR_EOF'
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
SUPERVISOR_EOF

cat > /usr/lib/systemd/system/supervisord.service <<'SYSTEMD_EOF'
[Unit]
Description=Supervisor process control system for UNIX
Documentation=http://supervisord.org
After=network.target

[Service]
ExecStart=/usr/local/bin/supervisord -n -c /etc/supervisor/supervisord.conf
ExecStop=/usr/local/bin/supervisord shutdown
ExecReload=/usr/local/bin/supervisord -c /etc/supervisor/supervisord.conf reload
KillMode=process
Restart=on-failure
RestartSec=50s

[Install]
WantedBy=multi-user.target
SYSTEMD_EOF

systemctl daemon-reload
systemctl enable supervisord
systemctl start supervisord
echo "✅ Cài đặt và khởi động Supervisor thành công."

echo "[Bước 9/12] Đang thiết lập User và quyền thư mục dự án..."
usermod -a -G nginx ec2-user
mkdir -p /var/www/${project}
chown -R ec2-user:nginx /var/www/${project}
echo "✅ Thiết lập quyền thư mục thành công."

echo "[Bước 10/12] Đang cấu hình Nginx..."
cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
cat > /etc/nginx/nginx.conf <<'NGINX_MAIN_EOF'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log notice;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
worker_connections 1024;
}

http {
include             /etc/nginx/mime.types;
default_type        application/octet-stream;
log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
'$status $body_bytes_sent "$http_referer" '
'"$http_user_agent" "$http_x_forwarded_for"';
access_log  /var/log/nginx/access.log  main;
sendfile            on;
tcp_nopush          on;
keepalive_timeout   65;
types_hash_max_size 4096;
include /etc/nginx/conf.d/*.conf;
}
NGINX_MAIN_EOF

cat > /etc/nginx/conf.d/default.conf <<'NGINX_CONF_EOF'
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
NGINX_CONF_EOF

systemctl restart nginx
echo "✅ Cấu hình Nginx thành công."

echo "[Bước 11/12] Đang cài đặt Composer..."
export HOME=/home/ec2-user
export COMPOSER_HOME=/home/ec2-user/.config/composer
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
php composer-setup.php --install-dir=/usr/local/bin --filename=composer --quiet
php -r "unlink('composer-setup.php');"
echo "✅ Cài đặt Composer thành công."

echo "[Bước 12/12] Đang cài đặt AWS CodeDeploy Agent..."
dnf install -y ruby wget
cd /home/ec2-user
wget -q https://aws-codedeploy-${aws_region}.s3.${aws_region}.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl start codedeploy-agent
echo "✅ Cài đặt AWS CodeDeploy Agent thành công."

echo "=========================================="
echo "🎉 HOÀN TẤT THIẾT LẬP SERVER!"
echo "=========================================="