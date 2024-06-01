#!/bin/bash

# 设置默认值
DB_NAME="wordpress"
DB_USER="wordpress"
DB_PASS=$(openssl rand -base64 12)

# 提示输入数据库名称
read -p "请输入数据库名称 (默认: wordpress): " input_db_name
DB_NAME=${input_db_name:-$DB_NAME}

# 提示输入数据库用户名
read -p "请输入数据库用户名 (默认: wordpress): " input_db_user
DB_USER=${input_db_user:-$DB_USER}

# 提示输入数据库密码
read -p "请输入数据库密码 (默认自动生成): " input_db_pass
DB_PASS=${input_db_pass:-$DB_PASS}

# 提示输入域名
read -p "请输入域名 (例如: example.com): " domain

# 显示将要使用的数据库信息
echo "将使用以下数据库信息:"
echo "数据库名称: ${DB_NAME}"
echo "数据库用户名: ${DB_USER}"
echo "数据库密码: ${DB_PASS}"
echo "域名: ${domain}"

# 更新系统和安装必要的软件包
apt update && apt upgrade -y
apt install -y nginx mariadb-server php-fpm php-mysql php-cli wget unzip socat dnsutils

# 启动并启用 Nginx 和 MariaDB 服务
systemctl start nginx
systemctl enable nginx
systemctl start mariadb
systemctl enable mariadb

# 安全安装 MariaDB
mysql_secure_installation <<EOF

y
${DB_PASS}
${DB_PASS}
y
y
y
y
EOF

# 创建 MariaDB 数据库和用户
mysql -u root -p${DB_PASS} <<MYSQL_SCRIPT
CREATE DATABASE ${DB_NAME};
CREATE USER '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';
GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost';
FLUSH PRIVILEGES;
MYSQL_SCRIPT

# 下载并解压 WordPress
wget https://wordpress.org/latest.zip -O /tmp/wordpress.zip
unzip /tmp/wordpress.zip -d /tmp/
mv /tmp/wordpress/* /var/www/html/

# 确保文件已复制
if [ ! -f /var/www/html/wp-config-sample.php ]; then
    echo "错误: WordPress 文件未正确复制到 /var/www/html"
    exit 1
fi

# 设置 WordPress 配置文件
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sed -i "s/database_name_here/${DB_NAME}/" /var/www/html/wp-config.php
sed -i "s/username_here/${DB_USER}/" /var/www/html/wp-config.php
sed -i "s/password_here/${DB_PASS}/" /var/www/html/wp-config.php

# 创建临时 Nginx 配置以支持 HTTP 验证
PHP_VERSION=$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')
PHP_FPM_SOCK="/run/php/php${PHP_VERSION}-fpm.sock"

cat <<EOF > /etc/nginx/sites-available/${domain}
server {
    listen 80;
    server_name ${domain} www.${domain};

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_FPM_SOCK};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -s /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/
systemctl reload nginx

# 安装 Certbot
apt install -y certbot python3-certbot-nginx

# 申请 SSL 证书
certbot --nginx -d ${domain} -m your-email@example.com --agree-tos --no-eff-email --redirect

# 检查证书是否成功生成
if [ ! -f /etc/letsencrypt/live/${domain}/fullchain.pem ]; then
    echo "错误: SSL 证书生成失败"
    exit 1
fi

# 设置 Nginx 配置以使用 SSL
cat <<EOF > /etc/nginx/sites-available/${domain}
server {
    listen 80;
    server_name ${domain} www.${domain};
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    server_name ${domain} www.${domain};

    ssl_certificate /etc/letsencrypt/live/${domain}/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/${domain}/privkey.pem;

    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$args;
    }

    location ~ \.php\$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:${PHP_FPM_SOCK};
    }

    location ~ /\.ht {
        deny all;
    }
}
EOF

ln -sf /etc/nginx/sites-available/${domain} /etc/nginx/sites-enabled/
systemctl reload nginx

# 调整权限和重启服务
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
systemctl restart nginx

# 重启 PHP-FPM 服务
systemctl restart php${PHP_VERSION}-fpm

# 显示数据库信息
echo "数据库名称: ${DB_NAME}"
echo "数据库用户名: ${DB_USER}"
echo "数据库密码: ${DB_PASS}"
echo "域名: ${domain}"

echo "WordPress 安装完成！请访问您的网站以完成安装。"
