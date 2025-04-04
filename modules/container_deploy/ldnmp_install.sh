#!/bin/bash

# LDNMP环境一键安装脚本
# 此脚本用于安装LDNMP (Linux, Docker, Nginx, MySQL, PHP) 环境

# 只在变量未定义时才设置安装目录
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
    MODULES_DIR="$INSTALL_DIR/modules"
    CONFIG_DIR="$INSTALL_DIR/config"
    
    # 导入共享函数
    source "$INSTALL_DIR/main.sh"
    
    # 导入对话框规则
    source "$CONFIG_DIR/dialog_rules.sh"
fi

# 保存当前目录
CURRENT_DIR="$(pwd)"

# LDNMP目录
LDNMP_DIR="/opt/ldnmp"
LDNMP_COMPOSE_FILE="$LDNMP_DIR/docker-compose.yml"
LDNMP_ENV_FILE="$LDNMP_DIR/.env"

# LDNMP环境一键安装
install_ldnmp_environment() {
    # 确认安装
    local title="LDNMP环境安装"
    local content="即将安装LDNMP (Linux, Docker, Nginx, MySQL, PHP) 环境。\n\n"
    content+="此安装将包括：\n"
    content+="· Docker (如果尚未安装)\n"
    content+="· Nginx Web服务器\n"
    content+="· MySQL/MariaDB数据库\n"
    content+="· PHP (多版本支持)\n"
    content+="· Redis缓存服务器\n"
    content+="· phpMyAdmin数据库管理工具\n\n"
    content+="是否继续？"
    
    local confirm
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        read -p "是否继续? (y/n): " confirm
    else
        dialog --title "$title" --yesno "$content" 15 60
        local status=$?
        if [ $status -eq 0 ]; then
            confirm="y"
        else
            confirm="n"
        fi
    fi
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return
    fi
    
    # 安装Docker（如果尚未安装）
    if ! command -v docker &> /dev/null; then
        local docker_msg="未检测到Docker。需要先安装Docker环境。\n正在安装Docker..."
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$docker_msg"
        else
            dialog --infobox "$docker_msg" 4 50
        fi
        
        # 调用Docker安装脚本
        "$MODULES_DIR/container_deploy/docker_install.sh"
        
        # 检查Docker安装是否成功
        if ! command -v docker &> /dev/null; then
            local error_msg="Docker安装失败。无法继续LDNMP环境安装。"
            
            if [ "$USE_TEXT_MODE" = true ]; then
                echo -e "$error_msg"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "安装失败" --msgbox "$error_msg" 6 50
            fi
            return 1
        fi
    fi
    
    # 配置安装参数
    configure_ldnmp_parameters
    
    # 开始安装LDNMP环境
    local setup_msg="正在设置LDNMP环境，请稍候..."
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$setup_msg"
    else
        dialog --infobox "$setup_msg" 3 50
    fi
    
    # 创建LDNMP目录
    mkdir -p "$LDNMP_DIR"
    mkdir -p "$LDNMP_DIR/nginx/conf.d"
    mkdir -p "$LDNMP_DIR/nginx/ssl"
    mkdir -p "$LDNMP_DIR/nginx/html"
    mkdir -p "$LDNMP_DIR/mysql/data"
    mkdir -p "$LDNMP_DIR/mysql/conf.d"
    mkdir -p "$LDNMP_DIR/redis/data"
    mkdir -p "$LDNMP_DIR/logs/nginx"
    mkdir -p "$LDNMP_DIR/logs/php"
    mkdir -p "$LDNMP_DIR/logs/mysql"
    mkdir -p "$LDNMP_DIR/www"
    
    # 创建默认站点
    echo "<!DOCTYPE html>
<html>
<head>
    <title>欢迎使用LDNMP环境</title>
    <meta charset=\"utf-8\">
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
    <style>
        body {
            font-family: 'Helvetica Neue', Arial, sans-serif;
            color: #333;
            max-width: 800px;
            margin: 0 auto;
            padding: 30px;
            line-height: 1.5;
        }
        h1 {
            color: #0088cc;
            border-bottom: 1px solid #eee;
            padding-bottom: 10px;
        }
        .info {
            background-color: #f9f9f9;
            border-left: 4px solid #0088cc;
            padding: 15px;
            margin-bottom: 20px;
        }
        code {
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 3px;
            font-family: monospace;
        }
        .footer {
            margin-top: 30px;
            font-size: 14px;
            color: #777;
            border-top: 1px solid #eee;
            padding-top: 15px;
        }
    </style>
</head>
<body>
    <h1>🚀 LDNMP环境已成功安装！</h1>
    
    <div class=\"info\">
        <p>如果您看到此页面，表示LDNMP (Linux, Docker, Nginx, MySQL, PHP) 环境已经成功安装并运行。</p>
        <p>此为默认的欢迎页面，您可以将其替换为自己的网站内容。</p>
    </div>
    
    <h2>环境信息</h2>
    <ul>
        <li><strong>Web服务器:</strong> Nginx</li>
        <li><strong>数据库:</strong> MySQL/MariaDB</li>
        <li><strong>PHP版本:</strong> 多版本可用</li>
        <li><strong>缓存:</strong> Redis</li>
    </ul>
    
    <h2>管理工具</h2>
    <p>phpMyAdmin数据库管理工具: <code>http://您的服务器IP:8080</code></p>
    
    <h2>基本目录结构</h2>
    <ul>
        <li><code>$LDNMP_DIR/www</code> - 网站根目录</li>
        <li><code>$LDNMP_DIR/nginx/conf.d</code> - Nginx配置文件</li>
        <li><code>$LDNMP_DIR/mysql/data</code> - MySQL数据文件</li>
        <li><code>$LDNMP_DIR/logs</code> - 各服务日志</li>
    </ul>
    
    <div class=\"footer\">
        <p>LDNMP环境 - 高效，稳定，可靠的Web应用部署环境</p>
    </div>
    <?php phpinfo(); ?>
</body>
</html>" > "$LDNMP_DIR/www/index.php"
    
    # 创建默认Nginx配置
    echo "server {
    listen 80;
    server_name localhost;
    root /var/www/html;
    index index.php index.html index.htm;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass php-fpm:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.ht {
        deny all;
    }
}" > "$LDNMP_DIR/nginx/conf.d/default.conf"
    
    # 创建环境变量文件
    echo "# LDNMP环境变量配置
# 上次修改: $(date)

# MySQL/MariaDB配置
MYSQL_VERSION=${LDNMP_MYSQL_VERSION}
MYSQL_ROOT_PASSWORD=${LDNMP_MYSQL_ROOT_PASSWORD}
MYSQL_DATABASE=${LDNMP_MYSQL_DATABASE}
MYSQL_USER=${LDNMP_MYSQL_USER}
MYSQL_PASSWORD=${LDNMP_MYSQL_PASSWORD}

# PHP配置
PHP_VERSION=${LDNMP_PHP_VERSION}

# Nginx配置
NGINX_VERSION=${LDNMP_NGINX_VERSION}

# Redis配置
REDIS_VERSION=${LDNMP_REDIS_VERSION}
REDIS_PASSWORD=${LDNMP_REDIS_PASSWORD}

# 网络配置
NETWORK_SUBNET=${LDNMP_NETWORK_SUBNET}

# 时区设置
TZ=${LDNMP_TZ}
" > "$LDNMP_ENV_FILE"
    
    # 创建docker-compose.yml文件
    echo "version: '3'

services:
  nginx:
    image: nginx:\${NGINX_VERSION}
    container_name: ldnmp-nginx
    ports:
      - \"80:80\"
      - \"443:443\"
    volumes:
      - ./www:/var/www/html
      - ./nginx/conf.d:/etc/nginx/conf.d
      - ./nginx/ssl:/etc/nginx/ssl
      - ./nginx/html:/usr/share/nginx/html
      - ./logs/nginx:/var/log/nginx
    environment:
      - TZ=\${TZ}
    networks:
      - ldnmp-network
    depends_on:
      - php-fpm
    restart: always

  php-fpm:
    image: php:\${PHP_VERSION}-fpm
    container_name: ldnmp-php
    volumes:
      - ./www:/var/www/html
      - ./logs/php:/var/log/php
    environment:
      - TZ=\${TZ}
    networks:
      - ldnmp-network
    restart: always

  mysql:
    image: mysql:\${MYSQL_VERSION}
    container_name: ldnmp-mysql
    ports:
      - \"3306:3306\"
    volumes:
      - ./mysql/data:/var/lib/mysql
      - ./mysql/conf.d:/etc/mysql/conf.d
      - ./logs/mysql:/var/log/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=\${MYSQL_ROOT_PASSWORD}
      - MYSQL_DATABASE=\${MYSQL_DATABASE}
      - MYSQL_USER=\${MYSQL_USER}
      - MYSQL_PASSWORD=\${MYSQL_PASSWORD}
      - TZ=\${TZ}
    networks:
      - ldnmp-network
    restart: always

  redis:
    image: redis:\${REDIS_VERSION}
    container_name: ldnmp-redis
    ports:
      - \"6379:6379\"
    volumes:
      - ./redis/data:/data
    command: redis-server --requirepass \${REDIS_PASSWORD}
    environment:
      - TZ=\${TZ}
    networks:
      - ldnmp-network
    restart: always

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    container_name: ldnmp-phpmyadmin
    ports:
      - \"8080:80\"
    environment:
      - PMA_HOST=mysql
      - PMA_USER=root
      - PMA_PASSWORD=\${MYSQL_ROOT_PASSWORD}
      - TZ=\${TZ}
    networks:
      - ldnmp-network
    depends_on:
      - mysql
    restart: always

networks:
  ldnmp-network:
    driver: bridge
    ipam:
      config:
        - subnet: \${NETWORK_SUBNET}
" > "$LDNMP_COMPOSE_FILE"
    
    # 启动LDNMP环境
    cd "$LDNMP_DIR"
    docker-compose up -d
    
    # 等待服务启动
    sleep 5
    
    # 检查服务状态
    local nginx_status=$(docker ps -q --filter "name=ldnmp-nginx" --filter "status=running" | wc -l)
    local php_status=$(docker ps -q --filter "name=ldnmp-php" --filter "status=running" | wc -l)
    local mysql_status=$(docker ps -q --filter "name=ldnmp-mysql" --filter "status=running" | wc -l)
    local redis_status=$(docker ps -q --filter "name=ldnmp-redis" --filter "status=running" | wc -l)
    local phpmyadmin_status=$(docker ps -q --filter "name=ldnmp-phpmyadmin" --filter "status=running" | wc -l)
    
    # 显示安装完成信息
    local result_title="LDNMP环境安装完成"
    local server_ip=$(hostname -I | awk '{print $1}')
    local result_content="LDNMP环境已成功安装！\n\n"
    result_content+="组件状态:\n"
    result_content+="· Nginx: $([ $nginx_status -eq 1 ] && echo "运行中" || echo "未启动")\n"
    result_content+="· PHP-FPM (${LDNMP_PHP_VERSION}): $([ $php_status -eq 1 ] && echo "运行中" || echo "未启动")\n"
    result_content+="· MySQL/MariaDB (${LDNMP_MYSQL_VERSION}): $([ $mysql_status -eq 1 ] && echo "运行中" || echo "未启动")\n"
    result_content+="· Redis (${LDNMP_REDIS_VERSION}): $([ $redis_status -eq 1 ] && echo "运行中" || echo "未启动")\n"
    result_content+="· phpMyAdmin: $([ $phpmyadmin_status -eq 1 ] && echo "运行中" || echo "未启动")\n\n"
    
    result_content+="访问信息:\n"
    result_content+="· 网站: http://${server_ip}\n"
    result_content+="· phpMyAdmin: http://${server_ip}:8080\n\n"
    
    result_content+="数据库信息:\n"
    result_content+="· 数据库地址: ${server_ip}:3306\n"
    result_content+="· 用户名: ${LDNMP_MYSQL_USER}\n"
    result_content+="· 密码: ${LDNMP_MYSQL_PASSWORD}\n"
    result_content+="· 默认数据库: ${LDNMP_MYSQL_DATABASE}\n\n"
    
    result_content+="Redis信息:\n"
    result_content+="· Redis地址: ${server_ip}:6379\n"
    result_content+="· 密码: ${LDNMP_REDIS_PASSWORD}\n\n"
    
    result_content+="目录结构:\n"
    result_content+="· 网站根目录: ${LDNMP_DIR}/www\n"
    result_content+="· 配置文件: ${LDNMP_DIR}/nginx/conf.d\n"
    result_content+="· 数据库数据: ${LDNMP_DIR}/mysql/data\n\n"
    
    result_content+="可以使用LDNMP环境管理功能进行进一步配置和管理。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$result_content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "$result_title" --msgbox "$result_content" $dialog_height $dialog_width
    fi
}

# 配置LDNMP参数
configure_ldnmp_parameters() {
    # 设置默认值
    LDNMP_MYSQL_VERSION="8.0"
    LDNMP_MYSQL_ROOT_PASSWORD="$(openssl rand -base64 12)"
    LDNMP_MYSQL_DATABASE="mydatabase"
    LDNMP_MYSQL_USER="dbuser"
    LDNMP_MYSQL_PASSWORD="$(openssl rand -base64 12)"
    LDNMP_PHP_VERSION="8.1"
    LDNMP_NGINX_VERSION="latest"
    LDNMP_REDIS_VERSION="latest"
    LDNMP_REDIS_PASSWORD="$(openssl rand -base64 12)"
    LDNMP_NETWORK_SUBNET="172.20.0.0/24"
    LDNMP_TZ="Asia/Shanghai"
    
    # 如果在文本模式下，直接接受默认设置或询问用户
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "LDNMP环境配置参数:"
        echo "默认值已生成。您是否要自定义这些参数?"
        read -p "自定义配置? (y/n): " customize
        
        if [ "$customize" = "y" ] || [ "$customize" = "Y" ]; then
            echo ""
            echo "MySQL/MariaDB配置:"
            read -p "MySQL版本 [${LDNMP_MYSQL_VERSION}]: " input
            LDNMP_MYSQL_VERSION=${input:-$LDNMP_MYSQL_VERSION}
            
            read -p "MySQL root密码 [${LDNMP_MYSQL_ROOT_PASSWORD}]: " input
            LDNMP_MYSQL_ROOT_PASSWORD=${input:-$LDNMP_MYSQL_ROOT_PASSWORD}
            
            read -p "默认数据库名 [${LDNMP_MYSQL_DATABASE}]: " input
            LDNMP_MYSQL_DATABASE=${input:-$LDNMP_MYSQL_DATABASE}
            
            read -p "数据库用户名 [${LDNMP_MYSQL_USER}]: " input
            LDNMP_MYSQL_USER=${input:-$LDNMP_MYSQL_USER}
            
            read -p "数据库用户密码 [${LDNMP_MYSQL_PASSWORD}]: " input
            LDNMP_MYSQL_PASSWORD=${input:-$LDNMP_MYSQL_PASSWORD}
            
            echo ""
            echo "PHP配置:"
            read -p "PHP版本 [${LDNMP_PHP_VERSION}]: " input
            LDNMP_PHP_VERSION=${input:-$LDNMP_PHP_VERSION}
            
            echo ""
            echo "Nginx配置:"
            read -p "Nginx版本 [${LDNMP_NGINX_VERSION}]: " input
            LDNMP_NGINX_VERSION=${input:-$LDNMP_NGINX_VERSION}
            
            echo ""
            echo "Redis配置:"
            read -p "Redis版本 [${LDNMP_REDIS_VERSION}]: " input
            LDNMP_REDIS_VERSION=${input:-$LDNMP_REDIS_VERSION}
            
            read -p "Redis密码 [${LDNMP_REDIS_PASSWORD}]: " input
            LDNMP_REDIS_PASSWORD=${input:-$LDNMP_REDIS_PASSWORD}
            
            echo ""
            echo "网络配置:"
            read -p "Docker网络子网 [${LDNMP_NETWORK_SUBNET}]: " input
            LDNMP_NETWORK_SUBNET=${input:-$LDNMP_NETWORK_SUBNET}
            
            echo ""
            echo "时区设置:"
            read -p "时区 [${LDNMP_TZ}]: " input
            LDNMP_TZ=${input:-$LDNMP_TZ}
        fi
    else
        # 在对话框模式下提供表单让用户设置参数
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 使用表单让用户输入参数
        local temp_file=$(mktemp)
        dialog --title "LDNMP环境配置" --form "请设置LDNMP环境参数：" $dialog_height $dialog_width 16 \
            "MySQL版本:" 1 1 "$LDNMP_MYSQL_VERSION" 1 20 20 0 \
            "MySQL root密码:" 2 1 "$LDNMP_MYSQL_ROOT_PASSWORD" 2 20 20 0 \
            "默认数据库名:" 3 1 "$LDNMP_MYSQL_DATABASE" 3 20 20 0 \
            "数据库用户名:" 4 1 "$LDNMP_MYSQL_USER" 4 20 20 0 \
            "数据库用户密码:" 5 1 "$LDNMP_MYSQL_PASSWORD" 5 20 20 0 \
            "PHP版本:" 6 1 "$LDNMP_PHP_VERSION" 6 20 20 0 \
            "Nginx版本:" 7 1 "$LDNMP_NGINX_VERSION" 7 20 20 0 \
            "Redis版本:" 8 1 "$LDNMP_REDIS_VERSION" 8 20 20 0 \
            "Redis密码:" 9 1 "$LDNMP_REDIS_PASSWORD" 9 20 20 0 \
            "Docker网络子网:" 10 1 "$LDNMP_NETWORK_SUBNET" 10 20 20 0 \
            "时区:" 11 1 "$LDNMP_TZ" 11 20 20 0 \
            2> $temp_file
        
        # 获取表单输入结果
        if [ -s "$temp_file" ]; then
            LDNMP_MYSQL_VERSION=$(sed -n 1p $temp_file)
            LDNMP_MYSQL_ROOT_PASSWORD=$(sed -n 2p $temp_file)
            LDNMP_MYSQL_DATABASE=$(sed -n 3p $temp_file)
            LDNMP_MYSQL_USER=$(sed -n 4p $temp_file)
            LDNMP_MYSQL_PASSWORD=$(sed -n 5p $temp_file)
            LDNMP_PHP_VERSION=$(sed -n 6p $temp_file)
            LDNMP_NGINX_VERSION=$(sed -n 7p $temp_file)
            LDNMP_REDIS_VERSION=$(sed -n 8p $temp_file)
            LDNMP_REDIS_PASSWORD=$(sed -n 9p $temp_file)
            LDNMP_NETWORK_SUBNET=$(sed -n 10p $temp_file)
            LDNMP_TZ=$(sed -n 11p $temp_file)
        fi
        rm -f $temp_file
        
        # 确认参数设置
        local confirm_msg="LDNMP环境配置参数:\n\n"
        confirm_msg+="MySQL版本: ${LDNMP_MYSQL_VERSION}\n"
        confirm_msg+="MySQL root密码: ${LDNMP_MYSQL_ROOT_PASSWORD}\n"
        confirm_msg+="默认数据库名: ${LDNMP_MYSQL_DATABASE}\n"
        confirm_msg+="数据库用户名: ${LDNMP_MYSQL_USER}\n"
        confirm_msg+="数据库用户密码: ${LDNMP_MYSQL_PASSWORD}\n"
        confirm_msg+="PHP版本: ${LDNMP_PHP_VERSION}\n"
        confirm_msg+="Nginx版本: ${LDNMP_NGINX_VERSION}\n"
        confirm_msg+="Redis版本: ${LDNMP_REDIS_VERSION}\n"
        confirm_msg+="Redis密码: ${LDNMP_REDIS_PASSWORD}\n"
        confirm_msg+="Docker网络子网: ${LDNMP_NETWORK_SUBNET}\n"
        confirm_msg+="时区: ${LDNMP_TZ}\n\n"
        confirm_msg+="确认以上设置并继续安装?"
        
        dialog --title "确认设置" --yesno "$confirm_msg" $dialog_height $dialog_width
        local status=$?
        if [ $status -ne 0 ]; then
            # 用户取消，重新配置
            configure_ldnmp_parameters
        fi
    fi
}

# 运行主函数
install_ldnmp_environment

# 恢复原始目录
cd "$CURRENT_DIR"