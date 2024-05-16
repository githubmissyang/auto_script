#!/bin/bash

# 提示用户逐步输入数据库信息
read -p "Enter MariaDB root password: " MYSQL_ROOT_PASSWORD
read -p "Enter WordPress database user: " WP_DB_USER
read -p "Enter WordPress database password: " WP_DB_PASSWORD

# 使用 hostname -I 获取本地IP地址
SERVER_IP=$(hostname -I | awk '{print $1}')

# 提示用户输入WordPress数据库名，按 Enter 使用默认数据库名（wordpress）
read -p "Enter WordPress database name (Press Enter for default 'wordpress'): " WP_DB_NAME
WP_DB_NAME="${WP_DB_NAME:-wordpress}"

# 提示用户输入博客端口，如果用户按下 Enter，则使用默认端口（80）
read -p "Enter the blog port (Press Enter for default 80): " BLOG_PORT
BLOG_PORT="${BLOG_PORT:-80}"

# 更新系统
apt update && apt upgrade -y

# 安装Apache、MariaDB和PHP
apt install apache2 mariadb-server php php-mysql libapache2-mod-php php-cli php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip unzip -y

# 启动Apache和MariaDB服务
systemctl start apache2
systemctl start mariadb

# 设置MariaDB root密码
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_ROOT_PASSWORD';FLUSH PRIVILEGES;"

# 创建WordPress数据库和用户
mysql -e "CREATE DATABASE $WP_DB_NAME;"
mysql -e "CREATE USER '$WP_DB_USER'@'localhost' IDENTIFIED BY '$WP_DB_PASSWORD';"
mysql -e "GRANT ALL PRIVILEGES ON $WP_DB_NAME.* TO '$WP_DB_USER'@'localhost';FLUSH PRIVILEGES;"

# 下载并解压WordPress
wget -c https://wordpress.org/latest.tar.gz
tar -xzvf latest.tar.gz -C /var/www/html/
chown -R www-data:www-data /var/www/html/wordpress
chmod -R 755 /var/www/html/wordpress

# 配置WordPress
cp /var/www/html/wordpress/wp-config-sample.php /var/www/html/wordpress/wp-config.php
sed -i "s/database_name_here/$WP_DB_NAME/g" /var/www/html/wordpress/wp-config.php
sed -i "s/username_here/$WP_DB_USER/g" /var/www/html/wordpress/wp-config.php
sed -i "s/password_here/$WP_DB_PASSWORD/g" /var/www/html/wordpress/wp-config.php
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /var/www/html/wordpress/wp-config.php

# 配置Apache虚拟主机
echo "
<VirtualHost *:$BLOG_PORT>
    ServerAdmin webmaster@localhost
    DocumentRoot /var/www/html/wordpress
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
" > /etc/apache2/sites-available/wordpress.conf

a2ensite wordpress.conf
systemctl reload apache2

echo "WordPress已成功部署，请访问 http://$SERVER_IP:$BLOG_PORT 完成安装。"
