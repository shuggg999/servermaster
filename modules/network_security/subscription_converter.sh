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
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y curl wget tar unzip git nginx cronie jq
    else
        show_error_dialog "系统错误" "不支持的操作系统类型"
        exit 1
    fi
}

# 安装 Sub-Converter
install_subconverter() {
    local title="安装Sub-Converter"
    local message="正在安装Sub-Converter..."
    
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
    
    wget -O subconverter.tar.gz "${LATEST_RELEASE_URL}"
    tar -xzf subconverter.tar.gz -C "${SUBCONVERTER_DIR}" --strip-components=1
    rm subconverter.tar.gz
    
    # 设置权限
    chmod +x "${SUBCONVERTER_DIR}/subconverter"
    
    # 备份原始配置
    cp "${SUBCONVERTER_CONFIG}" "${SUBCONVERTER_BACKUP_DIR}/pref.toml.original"
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
    
    # 更新端口配置
    sed -i "s/^port = .*/port = ${port}/" "${SUBCONVERTER_CONFIG}"
    
    # 配置访问令牌
    echo "${password}" > "${SUBCONVERTER_ACCESS_FILE}"
    
    # 启用访问令牌
    sed -i 's/^api_access_token = ""/api_access_token = "true"/' "${SUBCONVERTER_CONFIG}"
    
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

# 安装Sub-Converter向导
install_subconverter_wizard() {
    local title="安装Sub-Converter"
    
    # 检查是否已安装
    if [ -d "${SUBCONVERTER_DIR}" ] && [ -f "${SUBCONVERTER_DIR}/subconverter" ]; then
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
    
    # 获取配置参数
    get_installation_params
    
    # 安装流程
    check_root
    install_dependencies
    install_subconverter
    configure_subconverter "$port" "$password"
    
    # 配置域名 (如果提供)
    if [ -n "$domain" ]; then
        configure_nginx "$domain" "$port"
    fi
    
    # 配置订阅刷新
    configure_refresh "$refresh_interval" "$formatted_subscriptions"
    
    # 显示安装信息
    show_installation_info
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
        
        echo "请输入域名 (如果有):"
        read -p "域名 (留空则不配置): " domain
        
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
        echo "     https://example.com/subscription2"
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
        
        # 域名设置
        domain=$(dialog --title "域名设置" --inputbox "请输入域名 (如果有):\n留空则不配置" 10 50 "" 2>&1 >/dev/tty)
        
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
        subscriptions_text=$(dialog --title "订阅链接" --editbox /tmp/sub_links.tmp 20 70 2>&1 >/dev/tty)
        
        # 将文本转换为数组
        IFS=$'\n' read -d '' -ra subscriptions <<< "$subscriptions_text"
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
    
    local info_text="
==================================================
    Sub-Converter 安装完成
==================================================

服务信息:
  - 状态: $(systemctl is-active subconverter)
  - 端口: ${port}
  - 访问密码: ${password}

访问信息:
  - IP地址: http://${ip}:${port}
$([ -n "$domain" ] && echo "  - 域名: http://${domain}")

订阅地址:
  - Clash订阅: http://${ip}:${port}/sub?target=clash&url=请替换为原始订阅链接&token=${password}
  - V2ray订阅: http://${ip}:${port}/sub?target=v2ray&url=请替换为原始订阅链接&token=${password}
  - ShadowRocket订阅: http://${ip}:${port}/sub?target=shadowrocket&url=请替换为原始订阅链接&token=${password}
  - Surge订阅: http://${ip}:${port}/sub?target=surge&url=请替换为原始订阅链接&token=${password}

更新频率:
  - 刷新间隔: ${refresh_interval}

管理:
  - 启动: systemctl start subconverter
  - 停止: systemctl stop subconverter
  - 重启: systemctl restart subconverter
  - 状态: systemctl status subconverter
  - 日志: ${SUBCONVERTER_LOG}

配置文件:
  - 主配置: ${SUBCONVERTER_CONFIG}
  - 刷新脚本: ${SUBCONVERTER_REFRESH_SCRIPT}
  - 密码文件: ${SUBCONVERTER_ACCESS_FILE}
  
==================================================
"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "$info_text"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "安装完成" --msgbox "$info_text" $dialog_height $dialog_width
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
    local service_status=$(systemctl is-active subconverter)
    local service_enabled=$(systemctl is-enabled subconverter)
    local port=$(grep -oP '(?<=port = )\d+' "${SUBCONVERTER_CONFIG}")
    local password=$(cat "${SUBCONVERTER_ACCESS_FILE}")
    local cron_schedule=$(grep "${SUBCONVERTER_REFRESH_SCRIPT}" "${SUBCONVERTER_CRON}" | awk '{print $1, $2, $3, $4, $5}')
    local ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
    
    local subscription_count=$(grep -c "https://" "${SUBCONVERTER_REFRESH_SCRIPT}")
    
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
- V2ray: http://${ip}:${port}/sub?target=v2ray&url=YOUR_SUB_URL&token=${password}
- ShadowRocket: http://${ip}:${port}/sub?target=shadowrocket&url=YOUR_SUB_URL&token=${password}
"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "$info_text"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "服务状态" --msgbox "$info_text" $dialog_height $dialog_width
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
    
    # 停止服务
    systemctl stop subconverter
    systemctl disable subconverter
    
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
        "7" "查看服务状态 - 显示运行状态与配置"
        "8" "卸载 Sub-Converter - 删除所有组件"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 检查服务状态
        local installed=false
        if [ -f "${SUBCONVERTER_DIR}/subconverter" ]; then
            installed=true
        fi
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      Sub-Converter 订阅转换管理                     "
            echo "====================================================="
            echo ""
            echo "  1) 安装/配置 Sub-Converter     5) 修改刷新间隔"
            echo "  2) 添加订阅源                 6) 立即刷新订阅"
            echo "  3) 删除订阅源                 7) 查看服务状态"
            echo "  4) 修改访问密码               8) 卸载 Sub-Converter"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            if [ "$installed" = true ]; then
                echo "当前状态: 已安装"
            else
                echo "当前状态: 未安装"
            fi
            echo ""
            read -p "请选择操作 [0-8]: " choice
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
                --menu "$status_text\n\n请选择一个选项:" $dialog_height $dialog_width 9 \
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
            7) check_status ;;
            8) uninstall_subconverter ;;
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