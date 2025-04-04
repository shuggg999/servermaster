#!/bin/bash

# 赋予执行权限
chmod +x "$0"

# Sub-Converter 订阅转换器
# 此脚本用于安装配置 Sub-Converter，实现多节点订阅统一管理

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

# 定义安装目录和配置文件
SUBCONVERTER_DIR="/opt/subconverter"
SUBCONVERTER_CONFIG="${SUBCONVERTER_DIR}/pref.toml"
SUBCONVERTER_SERVICE="/etc/systemd/system/subconverter.service"
SUBCONVERTER_ACCESS_FILE="${SUBCONVERTER_DIR}/access_token.list"
SUBCONVERTER_BACKUP_DIR="${SUBCONVERTER_DIR}/backup"
SUBCONVERTER_SCRIPTS_DIR="${SUBCONVERTER_DIR}/scripts"
SUBCONVERTER_REFRESH_SCRIPT="${SUBCONVERTER_SCRIPTS_DIR}/refresh_subscriptions.sh"
SUBCONVERTER_CRON="/etc/cron.d/subconverter_refresh"
SUBCONVERTER_LOG="/var/log/subconverter.log"
SUBCONVERTER_DOCKER_COMPOSE="${SUBCONVERTER_DIR}/docker-compose.yml"
SUBCONVERTER_MERGED_FILE="${SUBCONVERTER_DIR}/merged_subscriptions.txt"
SUBCONVERTER_PROXY_DIR="${SUBCONVERTER_DIR}/proxy"
SUBCONVERTER_PROXY_SCRIPT="${SUBCONVERTER_PROXY_DIR}/proxy_sub.sh"
SUBCONVERTER_PROXY_CONFIG="/etc/nginx/conf.d/proxy_sub.conf"
SUBCONVERTER_PROXY_CRON="/etc/cron.d/proxy_sub"
SUBCONVERTER_PROXY_SUB="${SUBCONVERTER_PROXY_DIR}/converted_sub.txt"
SUBCONVERTER_PROXY_LOG="${SUBCONVERTER_PROXY_DIR}/proxy_sub.log"
SUBCONVERTER_PROXY_PORT="25501"

# 默认设置
DEFAULT_PORT="25500"
DEFAULT_PASSWORD="554365"
DEFAULT_REFRESH_INTERVAL="12h" # 默认12小时刷新一次

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        show_error_dialog "权限错误" "请使用root用户运行此脚本"
        exit 1
    fi
}

# 安装依赖
install_dependencies() {
    local title="安装依赖"
    local message="正在安装必要的依赖..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 检测系统类型
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu系统
        apt update -y
        apt install -y curl wget tar unzip git nginx cron jq
        
        # 如果是Docker安装方式，安装Docker
        if [ "$install_method" = "docker" ]; then
            apt install -y docker.io docker-compose
            systemctl enable docker
            systemctl start docker
        fi
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y curl wget tar unzip git nginx cronie jq
        
        # 如果是Docker安装方式，安装Docker
        if [ "$install_method" = "docker" ]; then
            yum install -y docker-ce docker-compose-plugin
            systemctl enable docker
            systemctl start docker
        fi
    else
        show_error_dialog "系统错误" "不支持的操作系统类型"
        exit 1
    fi
}

# 安装 Sub-Converter (直接安装方式)
install_subconverter_direct() {
    local title="安装Sub-Converter"
    local message="正在通过直接下载方式安装Sub-Converter..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 创建安装目录
    mkdir -p "${SUBCONVERTER_DIR}"
    mkdir -p "${SUBCONVERTER_BACKUP_DIR}"
    mkdir -p "${SUBCONVERTER_SCRIPTS_DIR}"
    
    # 下载最新版本
    cd /tmp
    LATEST_RELEASE_URL=$(curl -s https://api.github.com/repos/tindy2013/subconverter/releases/latest | grep "browser_download_url.*linux.*64.*.tar.gz" | cut -d '"' -f 4)
    
    if [ -z "$LATEST_RELEASE_URL" ]; then
        # 如果API失败，使用备用下载链接
        LATEST_RELEASE_URL="https://github.com/tindy2013/subconverter/releases/latest/download/subconverter_linux64.tar.gz"
    fi
    
    # 使用国内镜像下载（如果可用）
    MIRROR_URL="https://mirror.ghproxy.com/$LATEST_RELEASE_URL"
    if wget -T 10 -t 3 -q --spider "$MIRROR_URL"; then
        wget -O subconverter.tar.gz "$MIRROR_URL" || wget -O subconverter.tar.gz "${LATEST_RELEASE_URL}"
    else
        wget -O subconverter.tar.gz "${LATEST_RELEASE_URL}"
    fi
    
    tar -xzf subconverter.tar.gz -C "${SUBCONVERTER_DIR}" --strip-components=1
    rm subconverter.tar.gz
    
    # 设置权限
    chmod +x "${SUBCONVERTER_DIR}/subconverter"
    
    # 备份原始配置
    cp "${SUBCONVERTER_CONFIG}" "${SUBCONVERTER_BACKUP_DIR}/pref.toml.original"
}

# 安装 Sub-Converter (Docker方式)
install_subconverter_docker() {
    local title="安装Sub-Converter"
    local message="正在通过Docker方式安装Sub-Converter..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 创建安装目录
    mkdir -p "${SUBCONVERTER_DIR}"
    mkdir -p "${SUBCONVERTER_BACKUP_DIR}"
    mkdir -p "${SUBCONVERTER_SCRIPTS_DIR}"
    mkdir -p "${SUBCONVERTER_DIR}/config"
    
    # 创建Docker Compose配置
    cat > "${SUBCONVERTER_DOCKER_COMPOSE}" <<EOF
version: '3'
services:
  subconverter:
    image: tindy2013/subconverter:latest
    container_name: subconverter
    restart: always
    ports:
      - "${port}:25500"
    volumes:
      - ${SUBCONVERTER_DIR}/config:/base/config
    networks:
      - subconverter_net

networks:
  subconverter_net:
    driver: bridge
EOF
    
    # 启动Docker容器
    docker-compose -f "${SUBCONVERTER_DOCKER_COMPOSE}" up -d
    
    # 等待容器启动并获取配置文件
    sleep 5
    
    # 复制配置文件
    if [ ! -f "${SUBCONVERTER_DIR}/config/pref.toml" ]; then
        docker cp subconverter:/base/pref.toml "${SUBCONVERTER_DIR}/config/pref.toml"
    fi
    
    # 备份原始配置
    cp "${SUBCONVERTER_DIR}/config/pref.toml" "${SUBCONVERTER_BACKUP_DIR}/pref.toml.original"
    
    # 设置权限
    chmod -R 755 "${SUBCONVERTER_DIR}/config"
    
    # 更新配置文件路径
    SUBCONVERTER_CONFIG="${SUBCONVERTER_DIR}/config/pref.toml"
}

# 配置 Sub-Converter
configure_subconverter() {
    local port="$1"
    local password="$2"
    
    local title="配置Sub-Converter"
    local message="正在配置Sub-Converter..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 更新端口配置 (仅在直接安装时需要)
    if [ "$install_method" = "direct" ]; then
        sed -i "s/^port = .*/port = ${port}/" "${SUBCONVERTER_CONFIG}"
    fi
    
    # 配置访问令牌
    echo "${password}" > "${SUBCONVERTER_ACCESS_FILE}"
    
    # 配置访问令牌
    sed -i 's/^api_access_token = ""/api_access_token = "true"/' "${SUBCONVERTER_CONFIG}"
    
    if [ "$install_method" = "direct" ]; then
        # 配置服务
        cat > "${SUBCONVERTER_SERVICE}" <<EOF
[Unit]
Description=Subscription Converter Service
After=network.target

[Service]
Type=simple
ExecStart=${SUBCONVERTER_DIR}/subconverter
WorkingDirectory=${SUBCONVERTER_DIR}
Restart=always
RestartSec=10
User=root

[Install]
WantedBy=multi-user.target
EOF
        
        # 设置服务自启动
        systemctl daemon-reload
        systemctl enable subconverter
        systemctl restart subconverter
    else
        # Docker方式不需要systemd服务
        docker-compose -f "${SUBCONVERTER_DOCKER_COMPOSE}" restart
    fi
}

# 配置定时刷新
configure_refresh() {
    local interval="$1"
    local subscriptions="$2"
    
    local title="配置定时刷新"
    local message="正在配置定时刷新..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 创建刷新脚本
    cat > "${SUBCONVERTER_REFRESH_SCRIPT}" <<EOF
#!/bin/bash

# 日志文件
LOG_FILE="${SUBCONVERTER_LOG}"

# 记录日志
log() {
    echo "\$(date '+%Y-%m-%d %H:%M:%S') - \$1" >> "\$LOG_FILE"
}

log "开始刷新订阅..."

# 刷新订阅链接列表
SUBSCRIPTIONS=(
${subscriptions}
)

# 遍历并刷新每个订阅
for sub in "\${SUBSCRIPTIONS[@]}"; do
    log "刷新订阅: \$sub"
    curl -s "http://localhost:${port}/sub?target=clash&url=\$sub&token=${password}" > /dev/null
    curl -s "http://localhost:${port}/sub?target=v2ray&url=\$sub&token=${password}" > /dev/null
    curl -s "http://localhost:${port}/sub?target=surge&url=\$sub&token=${password}" > /dev/null
    curl -s "http://localhost:${port}/sub?target=shadowrocket&url=\$sub&token=${password}" > /dev/null
done

log "订阅刷新完成"
EOF
    
    # 设置执行权限
    chmod +x "${SUBCONVERTER_REFRESH_SCRIPT}"
    
    # 创建定时任务
    if [[ "${interval}" == "30m" ]]; then
        echo "*/30 * * * * root ${SUBCONVERTER_REFRESH_SCRIPT}" > "${SUBCONVERTER_CRON}"
    elif [[ "${interval}" == "1h" ]]; then
        echo "0 * * * * root ${SUBCONVERTER_REFRESH_SCRIPT}" > "${SUBCONVERTER_CRON}"
    elif [[ "${interval}" == "2h" ]]; then
        echo "0 */2 * * * root ${SUBCONVERTER_REFRESH_SCRIPT}" > "${SUBCONVERTER_CRON}"
    elif [[ "${interval}" == "6h" ]]; then
        echo "0 */6 * * * root ${SUBCONVERTER_REFRESH_SCRIPT}" > "${SUBCONVERTER_CRON}"
    elif [[ "${interval}" == "12h" ]]; then
        echo "0 */12 * * * root ${SUBCONVERTER_REFRESH_SCRIPT}" > "${SUBCONVERTER_CRON}"
    elif [[ "${interval}" == "1d" ]]; then
        echo "0 0 * * * root ${SUBCONVERTER_REFRESH_SCRIPT}" > "${SUBCONVERTER_CRON}"
    fi
    
    # 设置定时任务权限
    chmod 644 "${SUBCONVERTER_CRON}"
    
    # 重启cron服务
    systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null
    
    # 立即执行一次刷新
    ${SUBCONVERTER_REFRESH_SCRIPT}
}

# 配置Nginx反向代理
configure_nginx() {
    local domain="$1"
    local port="$2"
    
    local title="配置Nginx"
    local message="正在配置Nginx反向代理..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 创建Nginx配置
    cat > "/etc/nginx/conf.d/subconverter.conf" <<EOF
server {
    listen 80;
    server_name ${domain};

    location / {
        proxy_pass http://127.0.0.1:${port};
        proxy_set_header Host \$http_host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }
}
EOF
    
    # 重启Nginx
    systemctl restart nginx
}

# 配置订阅代理处理
configure_subscription_proxy() {
    local title="配置订阅代理"
    local message="正在配置订阅代理处理..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 创建代理目录
    mkdir -p "${SUBCONVERTER_PROXY_DIR}"
    
    # 创建代理处理脚本
    cat > "${SUBCONVERTER_PROXY_SCRIPT}" << 'EOF'
#!/bin/bash

# 配置变量将在安装时替换
ORIGINAL_SUB="__ORIGINAL_SUB__"
LOCAL_SUB="__LOCAL_SUB__"
LOG_FILE="__LOG_FILE__"

# 记录日志
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "开始处理订阅..."

# 下载原始订阅
content=$(curl -s "$ORIGINAL_SUB")
if [ -z "$content" ]; then
    log "错误: 无法获取原始订阅内容"
    exit 1
fi

# 检查是否需要做预处理（如base64解码）
if [[ "$content" =~ ^vless:// ]] || [[ "$content" =~ ^vmess:// ]] || [[ "$content" =~ ^trojan:// ]] || [[ "$content" =~ ^ss:// ]]; then
    # 已经是协议链接，直接保存
    echo "$content" > "$LOCAL_SUB"
    log "保存了$(echo "$content" | wc -l)个节点"
elif [[ "$content" =~ ^[A-Za-z0-9+/=]+$ ]]; then
    # 可能是base64编码，尝试解码
    decoded=$(echo "$content" | base64 -d 2>/dev/null)
    if [[ "$decoded" =~ ^vless:// ]] || [[ "$decoded" =~ ^vmess:// ]] || [[ "$decoded" =~ ^trojan:// ]] || [[ "$decoded" =~ ^ss:// ]]; then
        echo "$decoded" > "$LOCAL_SUB"
        log "解码并保存了$(echo "$decoded" | wc -l)个节点"
    else
        # 尝试解析其他格式
        echo "$content" | base64 -d > "$LOCAL_SUB" 2>/dev/null || echo "$content" > "$LOCAL_SUB"
        log "尝试解码并保存了订阅内容"
    fi
else
    # 未知格式，直接保存
    echo "$content" > "$LOCAL_SUB"
    log "保存了原始订阅内容"
fi

log "订阅处理完成"
EOF
    
    # 替换变量
    for sub in "${subscriptions[@]}"; do
        if [ -n "$sub" ]; then
            original_sub="$sub"
            break
        fi
    done
    
    # 替换脚本中的变量
    sed -i "s|__ORIGINAL_SUB__|${original_sub}|g" "${SUBCONVERTER_PROXY_SCRIPT}"
    sed -i "s|__LOCAL_SUB__|${SUBCONVERTER_PROXY_SUB}|g" "${SUBCONVERTER_PROXY_SCRIPT}"
    sed -i "s|__LOG_FILE__|${SUBCONVERTER_PROXY_LOG}|g" "${SUBCONVERTER_PROXY_SCRIPT}"
    
    # 设置执行权限
    chmod +x "${SUBCONVERTER_PROXY_SCRIPT}"
    
    # 创建nginx配置
    cat > "${SUBCONVERTER_PROXY_CONFIG}" << EOF
server {
    listen ${SUBCONVERTER_PROXY_PORT};
    
    location / {
        root ${SUBCONVERTER_PROXY_DIR};
        try_files \$uri \$uri/ =404;
    }
}
EOF
    
    # 重启nginx
    systemctl restart nginx
    
    # 创建定时刷新任务
    cat > "${SUBCONVERTER_PROXY_CRON}" << EOF
*/30 * * * * root ${SUBCONVERTER_PROXY_SCRIPT}
EOF
    
    # 设置权限
    chmod 644 "${SUBCONVERTER_PROXY_CRON}"
    
    # 立即执行一次
    ${SUBCONVERTER_PROXY_SCRIPT}
    
    # 更新原始订阅脚本
    local proxy_url="http://localhost:${SUBCONVERTER_PROXY_PORT}/$(basename ${SUBCONVERTER_PROXY_SUB})"
    
    # 替换订阅源中的第一个链接为代理URL
    sed -i "0,/\"http/s|\"http[^\"]*\"|\"${proxy_url}\"|" "${SUBCONVERTER_REFRESH_SCRIPT}"
    
    # 重启cron服务
    systemctl restart cron
}

# 安装Sub-Converter向导
install_subconverter_wizard() {
    local title="安装Sub-Converter"
    
    # 检查是否已安装
    if [ -d "${SUBCONVERTER_DIR}" ] && ([ -f "${SUBCONVERTER_DIR}/subconverter" ] || [ -f "${SUBCONVERTER_DOCKER_COMPOSE}" ]); then
        local confirm_message="检测到已安装Sub-Converter，是否重新安装？"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "$confirm_message"
            read -p "是否继续? (y/n): " confirm
            if [[ ! $confirm =~ ^[Yy]$ ]]; then
                return
            fi
        else
            local result=$(show_confirm_dialog "$title" "$confirm_message")
            if [[ $result -ne 0 ]]; then
                return
            fi
        fi
    fi
    
    # 选择安装方式
    select_installation_method
    
    # 获取配置参数
    get_installation_params
    
    # 安装流程
    check_root
    install_dependencies
    
    # 根据选择的安装方式执行不同的安装函数
    if [ "$install_method" = "direct" ]; then
        install_subconverter_direct
    else
        install_subconverter_docker
    fi
    
    # 配置 Sub-Converter
    configure_subconverter "$port" "$password"
    
    # 配置域名 (如果提供)
    if [ -n "$domain" ]; then
        configure_nginx "$domain" "$port"
    fi
    
    # 配置订阅刷新
    configure_refresh "$refresh_interval" "$formatted_subscriptions"
    
    # 配置订阅代理处理
    configure_subscription_proxy
    
    # 显示安装信息
    show_installation_info
}

# 选择安装方式
select_installation_method() {
    local title="选择安装方式"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "请选择Sub-Converter的安装方式:"
        echo "1) 直接安装 (传统方式)"
        echo "2) Docker安装 (推荐，避免网络问题)"
        read -p "请选择 [1-2]: " method_choice
        
        case $method_choice in
            1) install_method="direct" ;;
            2) install_method="docker" ;;
            *) install_method="docker" ;; # 默认选择Docker
        esac
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 显示选择对话框
        method_options=(
            "direct" "直接安装 (传统方式)"
            "docker" "Docker安装 (推荐，避免网络问题)"
        )
        
        install_method=$(dialog --title "$title" --menu "请选择Sub-Converter的安装方式:" $dialog_height $dialog_width 2 "${method_options[@]}" 2>&1 >/dev/tty)
        if [ -z "$install_method" ]; then
            install_method="docker"  # 默认选择Docker
        fi
    fi
}

# 获取安装参数
get_installation_params() {
    # 端口设置
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "请设置Sub-Converter监听端口 (默认: ${DEFAULT_PORT}):"
        read -p "端口: " input_port
        port=${input_port:-$DEFAULT_PORT}
        
        echo "请设置访问密码 (默认: ${DEFAULT_PASSWORD}):"
        read -p "密码: " input_password
        password=${input_password:-$DEFAULT_PASSWORD}
        
        echo "请输入主机域名 (用于访问Sub-Converter服务):"
        read -p "主机域名 (留空则使用IP地址): " domain
        
        echo "请设置订阅刷新间隔:"
        echo "1) 30分钟"
        echo "2) 1小时"
        echo "3) 2小时"
        echo "4) 6小时" 
        echo "5) 12小时 (默认)"
        echo "6) 1天"
        read -p "请选择 [1-6]: " refresh_choice
        
        case $refresh_choice in
            1) refresh_interval="30m" ;;
            2) refresh_interval="1h" ;;
            3) refresh_interval="2h" ;;
            4) refresh_interval="6h" ;;
            5) refresh_interval="12h" ;;
            6) refresh_interval="1d" ;;
            *) refresh_interval="${DEFAULT_REFRESH_INTERVAL}" ;;
        esac
        
        echo "请输入需要管理的订阅链接 (每行一个):"
        echo "示例: https://example.com/subscription1"
        echo "     vless://... (Base64编码的VPS节点链接)"
        echo "输入完成后，请输入空行并按Enter结束输入"
        
        subscriptions=()
        while true; do
            read -p "订阅链接: " sub_link
            if [ -z "$sub_link" ]; then
                break
            fi
            subscriptions+=("$sub_link")
        done
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 端口设置
        port=$(dialog --title "端口设置" --inputbox "请设置Sub-Converter监听端口:" 8 50 "${DEFAULT_PORT}" 2>&1 >/dev/tty)
        if [ -z "$port" ]; then
            port="${DEFAULT_PORT}"
        fi
        
        # 密码设置
        password=$(dialog --title "密码设置" --inputbox "请设置访问密码:" 8 50 "${DEFAULT_PASSWORD}" 2>&1 >/dev/tty)
        if [ -z "$password" ]; then
            password="${DEFAULT_PASSWORD}"
        fi
        
        # 主机域名设置
        domain=$(dialog --title "主机域名设置" --inputbox "请输入主机域名 (用于访问Sub-Converter服务):\n留空则使用IP地址" 10 70 "" 2>&1 >/dev/tty)
        
        # 刷新间隔设置
        refresh_options=(
            "30m" "每30分钟"
            "1h" "每1小时"
            "2h" "每2小时"
            "6h" "每6小时"
            "12h" "每12小时 (默认)"
            "1d" "每天"
        )
        
        refresh_interval=$(dialog --title "刷新间隔" --menu "请设置订阅刷新间隔:" $dialog_height $dialog_width 6 "${refresh_options[@]}" 2>&1 >/dev/tty)
        if [ -z "$refresh_interval" ]; then
            refresh_interval="${DEFAULT_REFRESH_INTERVAL}"
        fi
        
        # 订阅链接设置
        dialog --title "订阅链接" --msgbox "请输入需要管理的订阅链接 (每行一个):\n\n示例: https://example.com/subscription1\n      vless://... (Base64编码的VPS节点链接)\n\n在下一个编辑框中输入这些链接。" 12 70
        
        # 创建临时文件并设置默认内容
        cat > /tmp/sub_links.tmp << EOF
# 在此输入您的订阅链接，每行一个
# 示例:
# https://example.com/subscription1
# vless://XXXXXXX...
EOF
        
        # 订阅链接设置
        subscriptions_text=$(dialog --title "订阅链接" --editbox /tmp/sub_links.tmp 20 70 2>&1 >/dev/tty)
        
        # 将文本转换为数组，并过滤掉注释行
        subscriptions=()
        while IFS= read -r line; do
            # 跳过空行和注释行
            if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
                subscriptions+=("$line")
            fi
        done <<< "$subscriptions_text"
    fi
    
    # 格式化订阅链接
    formatted_subscriptions=""
    for sub in "${subscriptions[@]}"; do
        if [ -n "$sub" ]; then
            formatted_subscriptions+="    \"$sub\"\n"
        fi
    done
}

# 显示安装信息
show_installation_info() {
    local ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
    local installation_type="直接安装"
    local access_url=""
    
    if [ "$install_method" = "docker" ]; then
        installation_type="Docker安装"
    fi
    
    # 确定访问URL
    if [ -n "$domain" ]; then
        access_url="http://${domain}:${port}"
    else
        access_url="http://${ip}:${port}"
    fi
    
    # 创建配置文件保存路径
    local config_file="${SUBCONVERTER_DIR}/subscription_info.txt"
    
    # 构建合并的订阅链接（如果有多个订阅源）
    local merged_url=""
    local is_first=true
    for sub in "${subscriptions[@]}"; do
        if [ "$is_first" = true ]; then
            merged_url="${sub}"
            is_first=false
        else
            merged_url="${merged_url}|${sub}"
        fi
    done
    
    local info_text="
==================================================
    Sub-Converter 安装完成
==================================================

安装类型: ${installation_type}

服务信息:
  - 状态: $([ "$install_method" = "direct" ] && systemctl is-active subconverter || docker ps | grep -q subconverter && echo "running" || echo "stopped")
  - 端口: ${port}
  - 访问密码: ${password}

访问信息:
  - IP地址: http://${ip}:${port}
$([ -n "$domain" ] && echo "  - 域名: http://${domain}:${port}")

=============== 合并订阅链接(推荐) ===============
以下链接可直接使用，无需替换任何内容:

Clash订阅: 
${access_url}/sub?target=clash&url=${merged_url}&token=${password}

V2ray订阅: 
${access_url}/sub?target=v2ray&url=${merged_url}&token=${password}

ShadowRocket订阅: 
${access_url}/sub?target=shadowrocket&url=${merged_url}&token=${password}

=================================================

单个订阅地址(需替换URL):
  - Clash订阅: ${access_url}/sub?target=clash&url=请替换为原始订阅链接&token=${password}
  - V2ray订阅: ${access_url}/sub?target=v2ray&url=请替换为原始订阅链接&token=${password}
  - ShadowRocket订阅: ${access_url}/sub?target=shadowrocket&url=请替换为原始订阅链接&token=${password}
  - Surge订阅: ${access_url}/sub?target=surge&url=请替换为原始订阅链接&token=${password}

更新频率:
  - 刷新间隔: ${refresh_interval}

管理:
$([ "$install_method" = "direct" ] && echo "  - 启动: systemctl start subconverter
  - 停止: systemctl stop subconverter
  - 重启: systemctl restart subconverter
  - 状态: systemctl status subconverter" || echo "  - 启动: docker-compose -f ${SUBCONVERTER_DOCKER_COMPOSE} up -d
  - 停止: docker-compose -f ${SUBCONVERTER_DOCKER_COMPOSE} down
  - 重启: docker-compose -f ${SUBCONVERTER_DOCKER_COMPOSE} restart
  - 状态: docker ps | grep subconverter")
  - 日志: ${SUBCONVERTER_LOG}

配置文件:
$([ "$install_method" = "direct" ] && echo "  - 主配置: ${SUBCONVERTER_CONFIG}" || echo "  - 主配置: ${SUBCONVERTER_DIR}/config/pref.toml")
  - 刷新脚本: ${SUBCONVERTER_REFRESH_SCRIPT}
  - 密码文件: ${SUBCONVERTER_ACCESS_FILE}

订阅信息已保存到文件: ${config_file}
您可以使用文本编辑器打开此文件复制订阅链接

==================================================
"
    
    # 保存配置信息到文件，方便用户复制
    cat > "${config_file}" << EOF
# Sub-Converter 订阅信息
# 安装时间: $(date "+%Y-%m-%d %H:%M:%S")

# 服务器信息
服务器IP: ${ip}
$([ -n "$domain" ] && echo "服务器域名: ${domain}")
服务端口: ${port}
访问密码: ${password}

# 访问地址
管理地址: ${access_url}

# =========== 合并订阅链接(推荐) ===========
# 以下链接可直接使用，无需替换任何内容

Clash订阅: 
${access_url}/sub?target=clash&url=${merged_url}&token=${password}

V2ray订阅: 
${access_url}/sub?target=v2ray&url=${merged_url}&token=${password}

ShadowRocket订阅: 
${access_url}/sub?target=shadowrocket&url=${merged_url}&token=${password}

Surge订阅: 
${access_url}/sub?target=surge&url=${merged_url}&token=${password}

QuantumultX订阅: 
${access_url}/sub?target=quanx&url=${merged_url}&token=${password}

# ========================================

# 单个订阅链接 (请将YOUR_SUB_URL替换为实际订阅地址)
Clash订阅: ${access_url}/sub?target=clash&url=YOUR_SUB_URL&token=${password}
V2ray订阅: ${access_url}/sub?target=v2ray&url=YOUR_SUB_URL&token=${password}
ShadowRocket订阅: ${access_url}/sub?target=shadowrocket&url=YOUR_SUB_URL&token=${password}
Surge订阅: ${access_url}/sub?target=surge&url=YOUR_SUB_URL&token=${password}

# 已添加的订阅源
$(for sub in "${subscriptions[@]}"; do echo "- $sub"; done)

# 使用方法
# 1. 推荐使用"合并订阅链接"，无需替换任何内容
# 2. 如需指定单个订阅，将YOUR_SUB_URL替换为实际订阅地址
EOF

    # 设置文件权限
    chmod 644 "${config_file}"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "$info_text"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "安装完成" --yes-label "查看配置文件" --no-label "关闭" --yesno "$info_text" $dialog_height $dialog_width
        
        local choice=$?
        if [ $choice -eq 0 ]; then
            # 用户选择查看配置文件
            if command -v nano >/dev/null 2>&1; then
                nano "${config_file}"
            elif command -v vi >/dev/null 2>&1; then
                vi "${config_file}"
            else
                less "${config_file}"
            fi
        fi
    fi
}

# 添加订阅源
add_subscription() {
    local title="添加订阅源"
    local new_subscription=""
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "请输入新的订阅链接:"
        read -p "订阅链接: " new_subscription
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        new_subscription=$(dialog --title "$title" --inputbox "请输入新的订阅链接:" 8 70 "" 2>&1 >/dev/tty)
        local status=$?
        if [ $status -ne 0 ] || [ -z "$new_subscription" ]; then
            return
        fi
    fi
    
    # 检查订阅链接格式
    if [[ ! $new_subscription =~ ^https?:// ]]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 订阅链接必须以 http:// 或 https:// 开头"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "订阅链接必须以 http:// 或 https:// 开头" 8 50
        fi
        return
    fi
    
    # 添加到刷新脚本
    sed -i "/^SUBSCRIPTIONS=(/a \    \"$new_subscription\"," "${SUBCONVERTER_REFRESH_SCRIPT}"
    
    # 立即刷新
    ${SUBCONVERTER_REFRESH_SCRIPT}
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "订阅源添加成功并已刷新"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "成功" --msgbox "订阅源添加成功并已刷新" 6 40
    fi
}

# 删除订阅源
remove_subscription() {
    local title="删除订阅源"
    
    # 获取当前订阅列表
    local subscriptions=$(grep -oP '(?<=")https?://[^"]*(?=")' "${SUBCONVERTER_REFRESH_SCRIPT}")
    
    if [ -z "$subscriptions" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "没有找到订阅源"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "提示" --msgbox "没有找到订阅源" 6 40
        fi
        return
    fi
    
    # 生成选择列表
    local menu_items=()
    local i=1
    while IFS= read -r sub; do
        menu_items+=("$i" "$sub")
        ((i++))
    done <<< "$subscriptions"
    
    # 显示选择菜单
    local choice
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "当前订阅源列表:"
        for ((i=0; i<${#menu_items[@]}; i+=2)); do
            echo "${menu_items[i]}) ${menu_items[i+1]}"
        done
        read -p "请选择要删除的订阅源编号 [1-$((i/2))]: " choice
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        choice=$(dialog --title "$title" --menu "请选择要删除的订阅源:" $dialog_height $dialog_width $((i-1)) "${menu_items[@]}" 2>&1 >/dev/tty)
        local status=$?
        if [ $status -ne 0 ]; then
            return
        fi
    fi
    
    # 验证选择
    if [[ ! $choice =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt $((i-1)) ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "无效选择"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "无效选择" 6 40
        fi
        return
    fi
    
    # 获取要删除的订阅链接
    local to_remove=${menu_items[$(( (choice-1)*2 + 1 ))]}
    
    # 从刷新脚本中删除
    sed -i "/\"$to_remove\"/d" "${SUBCONVERTER_REFRESH_SCRIPT}"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "订阅源删除成功"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "成功" --msgbox "订阅源删除成功" 6 40
    fi
}

# 修改访问密码
change_password() {
    local title="修改访问密码"
    local new_password=""
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "请输入新的访问密码:"
        read -p "新密码: " new_password
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        new_password=$(dialog --title "$title" --inputbox "请输入新的访问密码:" 8 50 "" 2>&1 >/dev/tty)
        local status=$?
        if [ $status -ne 0 ]; then
            return
        fi
    fi
    
    if [ -z "$new_password" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "密码不能为空"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "密码不能为空" 6 40
        fi
        return
    fi
    
    # 更新密码文件
    echo "${new_password}" > "${SUBCONVERTER_ACCESS_FILE}"
    
    # 更新刷新脚本中的密码
    sed -i "s/token=[^&]*/token=${new_password}/g" "${SUBCONVERTER_REFRESH_SCRIPT}"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "访问密码修改成功"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "成功" --msgbox "访问密码修改成功" 6 40
    fi
}

# 修改刷新间隔
change_refresh_interval() {
    local title="修改刷新间隔"
    local refresh_options=(
        "1" "每30分钟"
        "2" "每1小时"
        "3" "每2小时"
        "4" "每6小时"
        "5" "每12小时"
        "6" "每天"
    )
    
    local choice
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "请选择新的刷新间隔:"
        echo "1) 每30分钟"
        echo "2) 每1小时"
        echo "3) 每2小时"
        echo "4) 每6小时"
        echo "5) 每12小时"
        echo "6) 每天"
        read -p "请选择 [1-6]: " choice
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        choice=$(dialog --title "$title" --menu "请选择新的刷新间隔:" $dialog_height $dialog_width 6 "${refresh_options[@]}" 2>&1 >/dev/tty)
        local status=$?
        if [ $status -ne 0 ]; then
            return
        fi
    fi
    
    local cron_expression=""
    case $choice in
        1) cron_expression="*/30 * * * *" ;;
        2) cron_expression="0 * * * *" ;;
        3) cron_expression="0 */2 * * *" ;;
        4) cron_expression="0 */6 * * *" ;;
        5) cron_expression="0 */12 * * *" ;;
        6) cron_expression="0 0 * * *" ;;
        *) 
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "无效选择"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "错误" --msgbox "无效选择" 6 40
            fi
            return
            ;;
    esac
    
    # 更新cron文件
    sed -i "s|^.* root ${SUBCONVERTER_REFRESH_SCRIPT}|${cron_expression} root ${SUBCONVERTER_REFRESH_SCRIPT}|" "${SUBCONVERTER_CRON}"
    
    # 重启cron服务
    systemctl restart cron 2>/dev/null || systemctl restart crond 2>/dev/null
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "刷新间隔修改成功"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "成功" --msgbox "刷新间隔修改成功" 6 40
    fi
}

# 立即刷新订阅
refresh_now() {
    local title="立即刷新订阅"
    local message="正在刷新所有订阅..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 执行刷新脚本
    ${SUBCONVERTER_REFRESH_SCRIPT}
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "订阅刷新完成"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "完成" --msgbox "订阅刷新完成" 6 40
    fi
}

# 查看服务状态
check_status() {
    local is_docker=false
    if [ -f "${SUBCONVERTER_DOCKER_COMPOSE}" ]; then
        is_docker=true
    fi
    
    if [ "$is_docker" = true ]; then
        local service_status=$(docker ps | grep -q subconverter && echo "running" || echo "stopped")
        local service_enabled="已启用"
    else
        local service_status=$(systemctl is-active subconverter)
        local service_enabled=$(systemctl is-enabled subconverter)
    fi
    
    local port=""
    if [ "$is_docker" = true ]; then
        port=$(grep -o "${port}:25500" "${SUBCONVERTER_DOCKER_COMPOSE}" | cut -d':' -f1)
    else
        port=$(grep -oP '(?<=port = )\d+' "${SUBCONVERTER_CONFIG}")
    fi
    
    local password=$(cat "${SUBCONVERTER_ACCESS_FILE}")
    local cron_schedule=$(grep "${SUBCONVERTER_REFRESH_SCRIPT}" "${SUBCONVERTER_CRON}" | awk '{print $1, $2, $3, $4, $5}')
    local ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
    
    local subscription_count=$(grep -c "https://" "${SUBCONVERTER_REFRESH_SCRIPT}")
    
    # 获取配置文件路径
    local config_file="${SUBCONVERTER_DIR}/subscription_info.txt"
    
    local info_text="
Sub-Converter 服务状态:

服务状态: ${service_status}
自启动: ${service_enabled}
监听端口: ${port}
访问密码: ${password}
订阅数量: ${subscription_count}
刷新计划: ${cron_schedule}

访问地址:
- 本地: http://127.0.0.1:${port}
- 远程: http://${ip}:${port}

示例订阅链接:
- Clash: http://${ip}:${port}/sub?target=clash&url=YOUR_SUB_URL&token=${password}
- V2ray: http://${ip}:${port}/sub?target=v2ray&url=请替换为原始订阅链接&token=${password}
- ShadowRocket订阅: http://${ip}:${port}/sub?target=shadowrocket&url=请替换为原始订阅链接&token=${password}
- Surge订阅: http://${ip}:${port}/sub?target=surge&url=请替换为原始订阅链接&token=${password}

更新频率:
  - 刷新间隔: ${refresh_interval}

管理:
$([ "$install_method" = "direct" ] && echo "  - 启动: systemctl start subconverter
  - 停止: systemctl stop subconverter
  - 重启: systemctl restart subconverter
  - 状态: systemctl status subconverter" || echo "  - 启动: docker-compose -f ${SUBCONVERTER_DOCKER_COMPOSE} up -d
  - 停止: docker-compose -f ${SUBCONVERTER_DOCKER_COMPOSE} down
  - 重启: docker-compose -f ${SUBCONVERTER_DOCKER_COMPOSE} restart
  - 状态: docker ps | grep subconverter")
  - 日志: ${SUBCONVERTER_LOG}

配置文件:
$([ "$install_method" = "direct" ] && echo "  - 主配置: ${SUBCONVERTER_CONFIG}" || echo "  - 主配置: ${SUBCONVERTER_DIR}/config/pref.toml")
  - 刷新脚本: ${SUBCONVERTER_REFRESH_SCRIPT}
  - 密码文件: ${SUBCONVERTER_ACCESS_FILE}

订阅信息已保存到文件: ${config_file}
"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "$info_text"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "服务状态" --yes-label "查看配置文件" --no-label "关闭" --yesno "$info_text" $dialog_height $dialog_width
        
        local choice=$?
        if [ $choice -eq 0 ] && [ -f "${config_file}" ]; then
            # 用户选择查看配置文件
            if command -v nano >/dev/null 2>&1; then
                nano "${config_file}"
            elif command -v vi >/dev/null 2>&1; then
                vi "${config_file}"
            else
                less "${config_file}"
            fi
        fi
    fi
}

# 卸载Sub-Converter
uninstall_subconverter() {
    local title="卸载Sub-Converter"
    local confirm_message="确定要卸载Sub-Converter吗？这将删除所有相关文件和配置。"
    local confirm
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$confirm_message"
        read -p "确认卸载? (y/n): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return
        fi
    else
        dialog --title "$title" --yesno "$confirm_message" 8 60
        local status=$?
        if [ $status -ne 0 ]; then
            return
        fi
    fi
    
    # 检查安装方式
    local is_docker=false
    if [ -f "${SUBCONVERTER_DOCKER_COMPOSE}" ]; then
        is_docker=true
    fi
    
    if [ "$is_docker" = true ]; then
        # Docker方式卸载
        docker-compose -f "${SUBCONVERTER_DOCKER_COMPOSE}" down
    else
        # 直接安装方式卸载
        systemctl stop subconverter
        systemctl disable subconverter
    fi
    
    # 删除文件
    rm -rf "${SUBCONVERTER_DIR}"
    rm -f "${SUBCONVERTER_SERVICE}"
    rm -f "${SUBCONVERTER_CRON}"
    rm -f "/etc/nginx/conf.d/subconverter.conf"
    
    # 重载服务
    systemctl daemon-reload
    systemctl restart nginx
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "Sub-Converter已成功卸载"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "卸载完成" --msgbox "Sub-Converter已成功卸载" 6 40
    fi
}

# 生成合并订阅链接
generate_merged_subscription() {
    local title="生成合并订阅"
    local message="正在生成合并订阅链接..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 检查是否已安装
    if [ ! -f "${SUBCONVERTER_REFRESH_SCRIPT}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 请先安装Sub-Converter"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "请先安装Sub-Converter" 6 40
        fi
        return
    fi
    
    # 提取已添加的订阅源
    local subscriptions=$(grep -oP '(?<=")https?://[^"]*(?=")' "${SUBCONVERTER_REFRESH_SCRIPT}")
    
    if [ -z "$subscriptions" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未找到订阅源，请先添加订阅源"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未找到订阅源，请先添加订阅源" 6 50
        fi
        return
    fi
    
    # 读取配置信息
    local ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
    local port=$(grep -oP '(?<=port = )\d+' "${SUBCONVERTER_CONFIG}" 2>/dev/null || grep -o '[0-9]\+:25500' "${SUBCONVERTER_DOCKER_COMPOSE}" 2>/dev/null | cut -d':' -f1)
    local password=$(cat "${SUBCONVERTER_ACCESS_FILE}")
    local domain=""
    
    # 检查是否设置了域名
    if [ -f "/etc/nginx/conf.d/subconverter.conf" ]; then
        domain=$(grep -oP '(?<=server_name )[^;]+' "/etc/nginx/conf.d/subconverter.conf" | tr -d '[:space:]')
    fi
    
    # 确定访问URL
    local access_url=""
    if [ -n "$domain" ]; then
        access_url="http://${domain}:${port}"
    else
        access_url="http://${ip}:${port}"
    fi
    
    # 构建合并的订阅链接（使用|分隔多个URL）
    local merged_url=""
    local is_first=true
    while IFS= read -r sub; do
        if [ "$is_first" = true ]; then
            merged_url="${sub}"
            is_first=false
        else
            merged_url="${merged_url}|${sub}"
        fi
    done <<< "$subscriptions"
    
    # 生成各客户端的最终订阅链接
    local clash_url="${access_url}/sub?target=clash&url=${merged_url}&token=${password}"
    local v2ray_url="${access_url}/sub?target=v2ray&url=${merged_url}&token=${password}"
    local shadowrocket_url="${access_url}/sub?target=shadowrocket&url=${merged_url}&token=${password}"
    local surge_url="${access_url}/sub?target=surge&url=${merged_url}&token=${password}"
    local quanx_url="${access_url}/sub?target=quanx&url=${merged_url}&token=${password}"
    
    # 保存到文件
    cat > "${SUBCONVERTER_MERGED_FILE}" << EOF
# Sub-Converter 合并订阅链接
# 生成时间: $(date "+%Y-%m-%d %H:%M:%S")
# 所有客户端只需使用以下链接，无需替换任何内容

# Clash订阅
${clash_url}

# V2ray客户端订阅
${v2ray_url}

# ShadowRocket订阅
${shadowrocket_url}

# Surge订阅
${surge_url}

# QuantumultX订阅
${quanx_url}

# 包含的原始订阅源:
$(while IFS= read -r sub; do echo "- $sub"; done <<< "$subscriptions")

# 使用方法:
# 1. 复制上述对应您设备的链接
# 2. 在客户端中直接添加，无需修改
EOF
    
    # 设置文件权限
    chmod 644 "${SUBCONVERTER_MERGED_FILE}"
    
    # 显示成功信息
    local success_message="合并订阅链接已生成并保存到文件:
${SUBCONVERTER_MERGED_FILE}

以下是您可以直接使用的订阅链接:

Clash订阅:
${clash_url}

V2ray订阅:
${v2ray_url}

ShadowRocket订阅:
${shadowrocket_url}

Surge订阅:
${surge_url}

QuantumultX订阅:
${quanx_url}

您可以在任何客户端中直接使用这些链接，无需替换任何内容。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "$success_message"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "合并订阅生成成功" --yes-label "查看完整链接" --no-label "关闭" --yesno "$success_message" $dialog_height $dialog_width
        
        local choice=$?
        if [ $choice -eq 0 ]; then
            # 用户选择查看文件
            if command -v nano >/dev/null 2>&1; then
                nano "${SUBCONVERTER_MERGED_FILE}"
            elif command -v vi >/dev/null 2>&1; then
                vi "${SUBCONVERTER_MERGED_FILE}"
            else
                less "${SUBCONVERTER_MERGED_FILE}"
            fi
        fi
    fi
}

# 更新或重新配置订阅代理
update_subscription_proxy() {
    local title="更新订阅代理"
    local message="是否要更新订阅代理配置？这将重新处理所有订阅。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
        read -p "是否继续? (y/n): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return
        fi
    else
        dialog --title "$title" --yesno "$message" 8 60
        local status=$?
        if [ $status -ne 0 ]; then
            return
        fi
    fi
    
    # 检查是否已安装
    if [ ! -d "${SUBCONVERTER_PROXY_DIR}" ]; then
        mkdir -p "${SUBCONVERTER_PROXY_DIR}"
    fi
    
    # 获取原始订阅
    local original_sub=""
    if [ -f "${SUBCONVERTER_PROXY_DIR}/original_sub_url.txt" ]; then
        original_sub=$(cat "${SUBCONVERTER_PROXY_DIR}/original_sub_url.txt")
    else
        # 如果没有保存原始订阅，提示用户输入
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "请输入原始订阅URL:"
            read -p "订阅URL: " original_sub
        else
            original_sub=$(dialog --title "输入订阅" --inputbox "请输入原始订阅URL:" 8 60 "" 2>&1 >/dev/tty)
        fi
    fi
    
    if [ -z "$original_sub" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未提供订阅URL"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未提供订阅URL" 6 40
        fi
        return
    fi
    
    # 保存原始订阅URL
    echo "$original_sub" > "${SUBCONVERTER_PROXY_DIR}/original_sub_url.txt"
    
    # 重新配置代理处理
    # 创建代理处理脚本
    cat > "${SUBCONVERTER_PROXY_SCRIPT}" << 'EOF'
#!/bin/bash

# 配置变量将在安装时替换
ORIGINAL_SUB="__ORIGINAL_SUB__"
LOCAL_SUB="__LOCAL_SUB__"
LOG_FILE="__LOG_FILE__"

# 记录日志
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

log "开始处理订阅..."

# 下载原始订阅
content=$(curl -s "$ORIGINAL_SUB")
if [ -z "$content" ]; then
    log "错误: 无法获取原始订阅内容"
    exit 1
fi

# 检查是否需要做预处理（如base64解码）
if [[ "$content" =~ ^vless:// ]] || [[ "$content" =~ ^vmess:// ]] || [[ "$content" =~ ^trojan:// ]] || [[ "$content" =~ ^ss:// ]]; then
    # 已经是协议链接，直接保存
    echo "$content" > "$LOCAL_SUB"
    log "保存了$(echo "$content" | wc -l)个节点"
elif [[ "$content" =~ ^[A-Za-z0-9+/=]+$ ]]; then
    # 可能是base64编码，尝试解码
    decoded=$(echo "$content" | base64 -d 2>/dev/null)
    if [[ "$decoded" =~ ^vless:// ]] || [[ "$decoded" =~ ^vmess:// ]] || [[ "$decoded" =~ ^trojan:// ]] || [[ "$decoded" =~ ^ss:// ]]; then
        echo "$decoded" > "$LOCAL_SUB"
        log "解码并保存了$(echo "$decoded" | wc -l)个节点"
    else
        # 尝试解析其他格式
        echo "$content" | base64 -d > "$LOCAL_SUB" 2>/dev/null || echo "$content" > "$LOCAL_SUB"
        log "尝试解码并保存了订阅内容"
    fi
else
    # 未知格式，直接保存
    echo "$content" > "$LOCAL_SUB"
    log "保存了原始订阅内容"
fi

log "订阅处理完成"
EOF
    
    # 替换脚本中的变量
    sed -i "s|__ORIGINAL_SUB__|${original_sub}|g" "${SUBCONVERTER_PROXY_SCRIPT}"
    sed -i "s|__LOCAL_SUB__|${SUBCONVERTER_PROXY_SUB}|g" "${SUBCONVERTER_PROXY_SCRIPT}"
    sed -i "s|__LOG_FILE__|${SUBCONVERTER_PROXY_LOG}|g" "${SUBCONVERTER_PROXY_SCRIPT}"
    
    # 设置执行权限
    chmod +x "${SUBCONVERTER_PROXY_SCRIPT}"
    
    # 创建nginx配置
    cat > "${SUBCONVERTER_PROXY_CONFIG}" << EOF
server {
    listen ${SUBCONVERTER_PROXY_PORT};
    
    location / {
        root ${SUBCONVERTER_PROXY_DIR};
        try_files \$uri \$uri/ =404;
    }
}
EOF
    
    # 重启nginx
    systemctl restart nginx
    
    # 创建定时刷新任务
    cat > "${SUBCONVERTER_PROXY_CRON}" << EOF
*/30 * * * * root ${SUBCONVERTER_PROXY_SCRIPT}
EOF
    
    # 设置权限
    chmod 644 "${SUBCONVERTER_PROXY_CRON}"
    
    # 立即执行一次
    ${SUBCONVERTER_PROXY_SCRIPT}
    
    # 更新原始订阅脚本
    local proxy_url="http://localhost:${SUBCONVERTER_PROXY_PORT}/$(basename ${SUBCONVERTER_PROXY_SUB})"
    
    # 替换订阅源中的第一个链接为代理URL
    sed -i "0,/\"http/s|\"http[^\"]*\"|\"${proxy_url}\"|" "${SUBCONVERTER_REFRESH_SCRIPT}"
    
    # 重启cron服务
    systemctl restart cron
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "订阅代理已更新并激活"
        read -p "按Enter键继续..." confirm
    else
        dialog --title "成功" --msgbox "订阅代理已更新并激活" 6 40
    fi
}

# 查看代理日志
view_proxy_logs() {
    if [ ! -f "${SUBCONVERTER_PROXY_LOG}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "代理日志不存在"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "代理日志不存在" 6 40
        fi
        return
    fi
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        cat "${SUBCONVERTER_PROXY_LOG}"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "订阅代理日志" --no-collapse --cr-wrap --tailbox "${SUBCONVERTER_PROXY_LOG}" $dialog_height $dialog_width
    fi
}

# 主菜单
show_subconverter_menu() {
    local title="Sub-Converter 订阅转换管理"
    local menu_items=(
        "1" "安装/配置 Sub-Converter - 初始安装或重新配置"
        "2" "添加订阅源 - 添加新的订阅链接"
        "3" "删除订阅源 - 移除已有订阅链接"
        "4" "修改访问密码 - 更改访问验证密码"
        "5" "修改刷新间隔 - 更改订阅更新频率"
        "6" "立即刷新订阅 - 手动更新所有订阅"
        "7" "生成合并订阅 - 创建便于使用的固定链接"
        "8" "查看服务状态 - 显示运行状态与配置"
        "9" "更新订阅代理 - 修复解析问题的代理工具"
        "10" "查看代理日志 - 显示订阅代理处理日志"
        "11" "卸载 Sub-Converter - 删除所有组件"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 检查服务状态
        local installed=false
        if [ -f "${SUBCONVERTER_DIR}/subconverter" ] || [ -f "${SUBCONVERTER_DOCKER_COMPOSE}" ]; then
            installed=true
        fi
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      Sub-Converter 订阅转换管理                     "
            echo "====================================================="
            echo ""
            echo "  1) 安装/配置 Sub-Converter     6) 立即刷新订阅"
            echo "  2) 添加订阅源                 7) 生成合并订阅 ★"
            echo "  3) 删除订阅源                 8) 查看服务状态"
            echo "  4) 修改访问密码               9) 更新订阅代理 ★"
            echo "  5) 修改刷新间隔               10) 查看代理日志"
            echo "                               11) 卸载 Sub-Converter"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            if [ "$installed" = true ]; then
                echo "当前状态: 已安装"
            else
                echo "当前状态: 未安装"
            fi
            echo ""
            read -p "请选择操作 [0-11]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            local status_text=""
            if [ "$installed" = true ]; then
                status_text="当前状态: 已安装"
            else
                status_text="当前状态: 未安装"
            fi
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --extra-button --extra-label "刷新" \
                --menu "$status_text\n\n请选择一个选项: (★ 表示推荐选项)" $dialog_height $dialog_width 12 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -eq 0 ]; then
                # 选择了菜单项
                :
            elif [ $status -eq 3 ]; then
                # 按下了"刷新"按钮
                continue
            else
                return
            fi
        fi
        
        # 处理未安装情况下的限制
        if [ "$installed" = false ] && [ "$choice" != "1" ] && [ "$choice" != "0" ]; then
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "请先安装 Sub-Converter"
                sleep 2
            else
                dialog --title "提示" --msgbox "请先安装 Sub-Converter" 6 40
            fi
            continue
        fi
        
        case $choice in
            1) install_subconverter_wizard ;;
            2) add_subscription ;;
            3) remove_subscription ;;
            4) change_password ;;
            5) change_refresh_interval ;;
            6) refresh_now ;;
            7) generate_merged_subscription ;;
            8) check_status ;;
            9) update_subscription_proxy ;;
            10) view_proxy_logs ;;
            11) uninstall_subconverter ;;
            0) return ;;
            *)
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "无效选择，请重试"
                    sleep 1
                else
                    dialog --title "错误" --msgbox "无效选项: $choice\n请重新选择" 8 40
                fi
                ;;
        esac
    done
}

# 运行主函数
show_subconverter_menu