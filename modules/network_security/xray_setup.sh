#!/bin/bash
# Xray Reality 一键部署脚本
# 支持自动安装所需组件、配置服务、设置定时更新

# 引入共享函数库
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
CONFIG_DIR="$INSTALL_DIR/config"
source "$CONFIG_DIR/dialog_rules.sh"

# 定义颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# 定义路径
XRAY_CONF="/usr/local/etc/xray/config.json"
WEB_DIR="/var/www/html"
CRON_FILE="/etc/cron.d/xray-update"
LOG_FILE="/var/log/xray_setup.log"
UPDATE_SCRIPT="/usr/local/bin/xray_update.sh"
NGINX_CONF="/etc/nginx/conf.d/xray.conf"

# 订阅文件路径
V2RAY_SUB="${WEB_DIR}/subscribe_v2ray.txt"
CLASH_SUB="${WEB_DIR}/subscribe_clash.yaml"
CLASH_SUB_B64="${WEB_DIR}/subscribe_clash.yaml.b64"

# 创建日志文件
touch "$LOG_FILE"
chmod 644 "$LOG_FILE"

# 记录日志函数
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 显示彩色信息
info() {
    echo -e "${BLUE}[信息]${RESET} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[成功]${RESET} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[警告]${RESET} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[错误]${RESET} $1" | tee -a "$LOG_FILE"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用root用户运行此脚本"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    info "开始安装所需依赖..."
    
    # 检测操作系统
    if [[ -f /etc/debian_version ]]; then
        # Debian/Ubuntu
        apt update -q
        apt install -y curl wget unzip jq cron nginx qrencode xxd openssl
    elif [[ -f /etc/redhat-release ]]; then
        # CentOS/RHEL
        yum install -y epel-release
        yum install -y curl wget unzip jq cronie nginx qrencode openssl
        if ! command -v xxd &> /dev/null; then
            yum install -y vim-common # 包含xxd命令
        fi
    else
        error "不支持的操作系统！"
        exit 1
    fi
    
    success "依赖安装完成"
}

# 安装Xray
install_xray() {
    info "开始安装Xray..."
    
    # 下载官方安装脚本并执行
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
    
    # 检查是否安装成功
    if ! command -v xray &> /dev/null; then
        error "Xray安装失败！"
        exit 1
    fi
    
    success "Xray安装完成"
}

# 配置Nginx
configure_nginx() {
    info "配置Nginx作为前端服务器..."
    
    # 确保Nginx目录存在
    mkdir -p ${WEB_DIR}
    
    # 创建简单的欢迎页面
    cat > "${WEB_DIR}/index.html" <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>Welcome</title>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        body { font-family: Arial, sans-serif; text-align: center; padding: 50px; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>Server is running</h1>
    <p>This server is operational.</p>
</body>
</html>
EOF
    
    # 配置Nginx
    cat > "$NGINX_CONF" <<EOF
server {
    listen 80;
    server_name _;
    root ${WEB_DIR};
    index index.html;
    
    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOF
    
    # 重新加载Nginx配置
    systemctl restart nginx
    systemctl enable nginx
    
    success "Nginx配置完成"
}

# 获取用户输入的域名
get_domain() {
    local input_result=$(show_input_dialog "域名配置" "请输入您的域名 (用于客户端连接):" "reality.example.com")
    local domain=$(echo $input_result | cut -d'|' -f1)
    local status=$(echo $input_result | cut -d'|' -f2)
    
    if [[ $status -ne 0 || -z "$domain" ]]; then
        warning "未提供域名，使用默认值: reality.example.com"
        echo "reality.example.com"
    else
        echo "$domain"
    fi
}

# 配置Xray
configure_xray() {
    local domain=$1
    info "配置Xray..."
    
    # 生成新的 UUID
    NEW_UUID=$(xray uuid)
    log "新 UUID: $NEW_UUID"
    
    # 生成 Reality 密钥对
    KEYS=$(xray x25519)
    PRIVATE_KEY=$(echo "$KEYS" | grep -oP '(?<=Private key: ).+')
    PUBLIC_KEY=$(echo "$KEYS" | grep -oP '(?<=Public key: ).+')
    
    # 确保密钥非空
    if [[ -z "$PRIVATE_KEY" || -z "$PUBLIC_KEY" ]]; then
        error "生成 Reality 密钥失败！请检查 xray x25519 命令是否正常。"
        exit 1
    fi
    
    log "新 Private Key: $PRIVATE_KEY"
    log "新 Public Key: $PUBLIC_KEY"
    
    # Reality 相关参数
    SITE_LIST=("www.cloudflare.com" "www.amazon.com" "www.microsoft.com" "www.google.com" "www.youtube.com")
    SERVER_NAME=${SITE_LIST[$RANDOM % ${#SITE_LIST[@]}]}
    DEST="${SERVER_NAME}:443"
    
    # 生成 Short ID
    if command -v xxd >/dev/null 2>&1; then
        SHORT_ID=$(head -c 4 /dev/urandom | xxd -ps)
    else
        SHORT_ID=$(openssl rand -hex 4)
    fi
    
    if [[ -z "$SHORT_ID" ]]; then
        error "Short ID 生成失败！"
        exit 1
    fi
    
    log "新 Short ID: $SHORT_ID"
    log "新伪装域名: $SERVER_NAME"
    
    # 创建 Xray 配置目录
    mkdir -p $(dirname "$XRAY_CONF")
    
    # 创建 Xray 配置文件
    cat > "$XRAY_CONF" <<EOF
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$NEW_UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none",
        "fallbacks": [
          { "dest": 80, "xver": 1 }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "dest": "$DEST",
          "serverNames": [ "$SERVER_NAME" ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [ "$SHORT_ID" ]
        }
      }
    }
  ],
  "outbounds": [{ "protocol": "freedom" }]
}
EOF
    
    # 验证 JSON 格式
    jq . "$XRAY_CONF" > /dev/null 2>&1
    if [[ $? -ne 0 ]]; then
        error "配置文件 JSON 解析失败！"
        exit 1
    fi
    
    # 生成 V2RayN 订阅文件
    mkdir -p ${WEB_DIR}
    VLESS_LINK="vless://${NEW_UUID}@${domain}:443?security=reality&encryption=none&flow=xtls-rprx-vision&fp=chrome&pbk=${PUBLIC_KEY}&sid=${SHORT_ID}&sni=${SERVER_NAME}&spx=%2F#Reality"
    echo -n "$VLESS_LINK" | base64 -w0 > "${V2RAY_SUB}"
    
    # 生成 Clash 订阅文件
    cat > "${CLASH_SUB}" <<EOF
proxies:
  - name: "Reality-Node"
    type: vless
    server: ${domain}
    port: 443
    uuid: ${NEW_UUID}
    tls: true
    flow: xtls-rprx-vision
    servername: ${SERVER_NAME}
    reality-opts:
      public-key: ${PUBLIC_KEY}
      short-id: "${SHORT_ID}"
EOF
    
    # Base64 编码 Clash 订阅
    base64 -w0 "${CLASH_SUB}" > "${CLASH_SUB_B64}"
    
    # 生成二维码
    command -v qrencode >/dev/null && qrencode -o "${WEB_DIR}/qrcode.png" "$VLESS_LINK"
    
    success "Xray配置完成"
}

# 创建更新脚本
create_update_script() {
    local domain=$1
    info "创建自动更新脚本..."
    
    # 将现有的更新脚本复制到系统位置
    cp "$(dirname $(readlink -f $0))/xray_update.sh" "$UPDATE_SCRIPT"
    
    # 更新脚本中的域名
    sed -i "s/reality\.cryptoalert\.baby/${domain}/g" "$UPDATE_SCRIPT"
    
    # 添加执行权限
    chmod +x "$UPDATE_SCRIPT"
    
    success "更新脚本创建完成"
}

# 设置定时任务
setup_cron() {
    local choice=$(show_menu_dialog "定时更新配置" "请选择更新配置的频率:" 5 \
        "1" "每天更新一次" \
        "2" "每周更新一次" \
        "3" "每月更新一次" \
        "4" "不设置自动更新" \
    )
    
    local selected=$(echo $choice | cut -d'|' -f1)
    local status=$(echo $choice | cut -d'|' -f2)
    
    if [[ $status -ne 0 || -z "$selected" ]]; then
        warning "未选择更新频率，默认为每周更新一次"
        selected="2"
    fi
    
    # 删除已有的定时任务
    rm -f "$CRON_FILE" 2>/dev/null
    
    case $selected in
        1)
            info "设置为每天更新一次"
            echo "0 4 * * * root $UPDATE_SCRIPT > /dev/null 2>&1" > "$CRON_FILE"
            ;;
        2)
            info "设置为每周更新一次"
            echo "0 4 * * 0 root $UPDATE_SCRIPT > /dev/null 2>&1" > "$CRON_FILE"
            ;;
        3)
            info "设置为每月更新一次"
            echo "0 4 1 * * root $UPDATE_SCRIPT > /dev/null 2>&1" > "$CRON_FILE"
            ;;
        4)
            info "不设置自动更新"
            ;;
        *)
            warning "无效选择，默认为每周更新一次"
            echo "0 4 * * 0 root $UPDATE_SCRIPT > /dev/null 2>&1" > "$CRON_FILE"
            ;;
    esac
    
    # 刷新定时任务
    if [[ -f "$CRON_FILE" ]]; then
        chmod 644 "$CRON_FILE"
        systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null
        success "定时任务设置完成"
    fi
}

# 配置防火墙
configure_firewall() {
    info "配置防火墙..."
    
    # 检测防火墙类型并开放端口
    if command -v ufw &> /dev/null; then
        # Ubuntu/Debian with UFW
        ufw allow 80/tcp
        ufw allow 443/tcp
        ufw --force enable
    elif command -v firewall-cmd &> /dev/null; then
        # CentOS/RHEL with firewalld
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=443/tcp
        firewall-cmd --reload
    elif command -v iptables &> /dev/null; then
        # 通用 iptables
        iptables -I INPUT -p tcp --dport 80 -j ACCEPT
        iptables -I INPUT -p tcp --dport 443 -j ACCEPT
        
        # 保存 iptables 规则
        if [[ -f /etc/debian_version ]]; then
            apt install -y iptables-persistent
            netfilter-persistent save
        elif [[ -f /etc/redhat-release ]]; then
            service iptables save
        fi
    fi
    
    success "防火墙配置完成"
}

# 显示安装信息
show_info() {
    local domain=$1
    
    # 获取公网IP
    local ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
    
    # 创建信息文本
    local info_text="
    ==================================================
        Xray Reality VPN安装成功
    ==================================================
    
    服务器信息:
      - IP: ${ip}
      - 域名: ${domain}
    
    客户端连接信息:
      - 协议: VLESS + Reality
      - 端口: 443
      - UUID: $(grep -o '"id": "[^"]*' ${XRAY_CONF} | sed 's/"id": "//')
      - 流控: xtls-rprx-vision
      - 伪装域名: $(grep -o '"serverNames": \[ "[^"]*' ${XRAY_CONF} | sed 's/"serverNames": \[ "//')
    
    订阅地址:
      - V2rayN: http://${domain}/subscribe_v2ray.txt
      - Clash: http://${domain}/subscribe_clash.yaml
      - 二维码: http://${domain}/qrcode.png
    
    更新频率:
      $(if [[ -f "$CRON_FILE" ]]; then
          cat "$CRON_FILE" | grep -v "^#" | awk '{print "- "$5" "$2":"$1}'
        else
          echo "- 未设置自动更新"
        fi)
    
    手动更新:
      - 运行命令: ${UPDATE_SCRIPT}
    
    说明:
    - 订阅地址将自动更新，客户端配置只需导入一次
    - 伪装域名会定期更换，无需手动调整
    - 日志文件位于 ${LOG_FILE}
    
    ==================================================
    "
    
    # 显示信息
    clear
    echo "$info_text"
    
    # 将信息保存到文件
    echo "$info_text" > "${WEB_DIR}/xray_info.txt"
    
    # 以Dialog方式显示
    show_info_dialog "安装完成" "$info_text"
}

# 主函数
main() {
    clear
    echo "======================================================"
    echo "        Xray Reality VPN 一键安装脚本"
    echo "======================================================"
    echo ""
    echo "本脚本将自动完成以下任务:"
    echo "  1. 安装必要的依赖软件"
    echo "  2. 安装配置Xray和Nginx"
    echo "  3. 配置Reality VPN服务"
    echo "  4. 设置定时自动更新"
    echo "  5. 生成客户端订阅地址"
    echo ""
    
    # 确认安装
    local confirm=$(show_confirm_dialog "安装确认" "是否开始安装Xray Reality VPN服务?")
    if [[ $confirm -ne 0 ]]; then
        info "用户取消安装"
        exit 0
    fi
    
    # 获取域名
    local domain=$(get_domain)
    
    # 开始安装
    check_root
    install_dependencies
    install_xray
    configure_nginx
    configure_xray "$domain"
    create_update_script "$domain"
    setup_cron
    configure_firewall
    
    # 启动服务
    systemctl enable xray
    systemctl restart xray
    systemctl restart nginx
    
    # 显示完成信息
    show_info "$domain"
    
    success "Xray Reality VPN 安装完成！"
}

# 执行主函数
main 