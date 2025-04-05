#!/bin/bash

# 赋予执行权限
chmod +x "$0"

# 订阅管理和转换
# 此脚本提供多种节点订阅的聚合、管理和格式转换功能
# 支持Python轻量级实现

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

# Python订阅合并器配置
SUBMERGER_DIR="/opt/sub_merger"
SUBMERGER_SERVICE="/etc/systemd/system/sub_merger.service"
SUBMERGER_SCRIPT="${MODULES_DIR}/network_security/scripts/simple_sub_merger.py"
SUBMERGER_INSTALL="${SUBMERGER_DIR}/simple_sub_merger.py"
SUBMERGER_CONFIG="${SUBMERGER_DIR}/subscriptions.json"
SUBMERGER_ACCESS_TOKEN="${SUBMERGER_DIR}/access_token.txt"
SUBMERGER_PORT_FILE="${SUBMERGER_DIR}/port.txt"
SUBMERGER_LOG="/var/log/sub_merger.log"
SUBMERGER_CRON="/etc/cron.d/sub_merger_refresh"

# 默认设置
DEFAULT_PORT="25500"
DEFAULT_PASSWORD="554365"
DEFAULT_MERGER_PORT="25502"

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        show_error_dialog "权限错误" "请使用root用户运行此脚本"
        exit 1
    fi
}

# 获取外部IP
get_external_ip() {
    curl -s https://api.ipify.org || curl -s https://ifconfig.me
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
        apt install -y curl wget python3 python3-pip nginx cron
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL系统
        yum install -y curl wget python3 python3-pip nginx cronie
    else
        show_error_dialog "系统错误" "不支持的操作系统类型"
        exit 1
    fi
}

# 安装Sub-Converter向导
install_subconverter_wizard() {
    local title="安装订阅管理工具"
    
    # 检查是否已安装
    local already_installed=false
    if [ -d "${SUBMERGER_DIR}" ] && [ -f "${SUBMERGER_INSTALL}" ]; then
        already_installed=true
    fi
    
    if [ "$already_installed" = true ]; then
        local confirm_message="检测到已安装订阅管理工具，是否重新安装？"
        
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
    
    # 选择安装方式 - 直接使用Python方式
    select_installation_method
    
    # 获取配置参数
    get_installation_params
    
    # 安装流程
    check_root
    install_dependencies
    
    # 安装Python订阅合并器
    install_python_merger
    configure_python_merger "$port" "$password" "${subscriptions[@]}"
    
    # 显示安装信息
    show_installation_info
}

# 选择安装方式
select_installation_method() {
    # 直接设置为Python方式
    install_method="python"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "将使用Python轻量级实现安装订阅管理工具"
        sleep 1
    else
        dialog --title "安装方式" --msgbox "将使用Python轻量级实现安装订阅管理工具\n- 更好支持Reality格式\n- 轻量级实现\n- 简洁界面" 10 50
    fi
}

# 获取安装参数
get_installation_params() {
    # 端口设置
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "请设置订阅管理工具监听端口 (默认: ${DEFAULT_MERGER_PORT}):"
        read -p "端口: " input_port
        port=${input_port:-$DEFAULT_MERGER_PORT}
        
        echo "请设置访问密码 (默认: ${DEFAULT_PASSWORD}):"
        read -p "密码: " input_password
        password=${input_password:-$DEFAULT_PASSWORD}
        
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
        port=$(dialog --title "端口设置" --inputbox "请设置订阅管理工具监听端口:" 8 50 "${DEFAULT_MERGER_PORT}" 2>&1 >/dev/tty)
        if [ -z "$port" ]; then
            port="${DEFAULT_MERGER_PORT}"
        fi
        
        # 密码设置
        password=$(dialog --title "密码设置" --inputbox "请设置访问密码:" 8 50 "${DEFAULT_PASSWORD}" 2>&1 >/dev/tty)
        if [ -z "$password" ]; then
            password="${DEFAULT_PASSWORD}"
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
}

# 显示安装信息
show_installation_info() {
    local ip=$(curl -s https://api.ipify.org || curl -s https://ifconfig.me)
    
    # 创建配置文件保存路径
    local config_file="${SUBMERGER_DIR}/subscription_info.txt"
    
    # Python方式的信息文本
    local python_info=$(python3 "${SUBMERGER_INSTALL}" --info)
    
    info_text="
==================================================
    Python订阅合并器 安装完成
==================================================

服务信息:
  - 状态: $(systemctl is-active sub_merger)
  - 端口: ${port}
  - 访问密码: ${password}

访问信息:
  - IP地址: http://${ip}:${port}

订阅信息:
${python_info}

主要特点:
  - 更好地支持Reality格式订阅
  - 自动合并多个订阅源
  - 无需复杂配置，开箱即用

管理:
  - 启动: systemctl start sub_merger
  - 停止: systemctl stop sub_merger
  - 重启: systemctl restart sub_merger
  - 状态: systemctl status sub_merger
  - 日志: ${SUBMERGER_LOG}

配置文件:
  - 订阅配置: ${SUBMERGER_CONFIG}
  - 访问令牌: ${SUBMERGER_ACCESS_TOKEN}
  - 端口配置: ${SUBMERGER_PORT_FILE}

订阅信息已保存到文件: ${config_file}
您可以使用文本编辑器打开此文件复制订阅链接

==================================================
"
    
    # 保存配置信息到文件，方便用户复制
    python3 "${SUBMERGER_INSTALL}" --info > "${config_file}"

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

# 主菜单
show_subconverter_menu() {
    local title="订阅管理与转换"
    local menu_options=(
        "1" "安装/配置 - 初始安装或重新配置"
        "2" "查看服务状态 - 检查运行情况和订阅列表"
        "3" "添加订阅源 - 新增订阅源"
        "4" "移除订阅源 - 删除已添加的订阅源"
        "5" "修改访问密码 - 更改访问令牌"
        "6" "修改服务端口 - 更改服务监听端口"
        "7" "服务访问诊断 - 检查并修复访问问题"
        "11" "卸载 - 删除所有组件"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 检查服务状态
        local installed=false
        if [ -d "${SUBMERGER_DIR}" ] && [ -f "${SUBMERGER_INSTALL}" ]; then
            installed=true
        fi
        
        # 文本模式菜单
        if [ "$USE_TEXT_MODE" = true ]; then
            echo ""
            echo "===== $title ====="
            echo ""
            
            echo "  1) 安装/配置                 5) 修改访问密码"
            echo "  2) 查看服务状态             6) 修改服务端口"
            echo "  3) 添加订阅源               7) 服务访问诊断"
            echo "  4) 移除订阅源               11) 卸载"
            echo ""
            echo "  0) 返回上级菜单"
            
            echo ""
            if [ "$installed" = true ]; then
                echo "当前状态: 已安装 (Python订阅合并器)"
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
                status_text="当前状态: 已安装 (Python订阅合并器)"
            else
                status_text="当前状态: 未安装"
            fi
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --extra-button --extra-label "刷新" \
                --menu "$status_text\n\n请选择一个选项:" $dialog_height $dialog_width 9 \
                "${menu_options[@]}" 2>&1 >/dev/tty)
            
            # 处理Dialog的返回值
            local dialog_ret=$?
            if [ $dialog_ret -eq 3 ]; then
                continue
            elif [ $dialog_ret -ne 0 ]; then
                return
            fi
        fi
        
        # 如果用户选择返回，则退出函数
        if [ "$choice" = "0" ]; then
            return
        fi
        
        # 处理未安装情况下的限制
        if [ "$installed" = false ] && [ "$choice" != "1" ] && [ "$choice" != "0" ]; then
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "请先安装订阅管理工具"
                sleep 2
            else
                dialog --title "提示" --msgbox "请先安装订阅管理工具" 6 40
            fi
            continue
        fi
        
        # 根据用户选择执行相应操作
        case $choice in
            1) install_subconverter_wizard ;;
            2) python_check_status ;;
            3) python_add_subscription ;;
            4) python_remove_subscription ;;
            5) python_change_password ;;
            6) python_change_port ;;
            7) check_service_access ;;
            11) uninstall_subconverter ;;
            *) 
               echo "无效选择: $choice"
               show_error_dialog "无效选择" "请输入有效的选项!" 
               ;;
        esac
    done
}

# 运行主函数
# 确保在脚本开始时调用主函数，但不在其他函数中调用main函数
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # 直接运行此脚本时
    show_subconverter_menu
fi

# 安装Python Merger
install_python_merger() {
    local title="安装Python订阅合并器"
    local message="正在安装Python订阅合并器..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 安装Python依赖
    if [ -f /etc/debian_version ]; then
        apt install -y python3 python3-pip
    elif [ -f /etc/redhat-release ]; then
        yum install -y python3 python3-pip
    fi
    
    # 创建安装目录
    mkdir -p "${SUBMERGER_DIR}"
    
    # 复制Python脚本
    cp "${SUBMERGER_SCRIPT}" "${SUBMERGER_INSTALL}"
    chmod +x "${SUBMERGER_INSTALL}"
    
    # 创建systemd服务
    cat > "${SUBMERGER_SERVICE}" << EOF
[Unit]
Description=Python Subscription Merger Service
After=network.target

[Service]
ExecStart=/usr/bin/python3 ${SUBMERGER_INSTALL} --server
Restart=on-failure
User=root
Group=root
WorkingDirectory=${SUBMERGER_DIR}
StandardOutput=append:${SUBMERGER_LOG}
StandardError=append:${SUBMERGER_LOG}

[Install]
WantedBy=multi-user.target
EOF
    
    # 设置systemd服务和权限
    chmod 644 "${SUBMERGER_SERVICE}"
    systemctl daemon-reload
    systemctl enable sub_merger
    
    # 创建初始配置文件
    echo "${DEFAULT_PASSWORD}" > "${SUBMERGER_ACCESS_TOKEN}"
    echo "${DEFAULT_MERGER_PORT}" > "${SUBMERGER_PORT_FILE}"
    
    # 重启服务
    systemctl restart sub_merger
    
    # 创建flag文件标记安装
    touch "${SUBMERGER_INSTALL}"
    
    # 等待服务启动
    sleep 2
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "Python订阅合并器安装完成"
    else
        dialog --title "安装完成" --msgbox "Python订阅合并器安装完成" 6 40
    fi
}

# 配置Python Merger
configure_python_merger() {
    local port="${1:-$DEFAULT_MERGER_PORT}"
    local password="${2:-$DEFAULT_PASSWORD}"
    local subscriptions=("${@:3}")
    
    # 修改密码
    echo "$password" > "${SUBMERGER_ACCESS_TOKEN}"
    
    # 修改端口
    echo "$port" > "${SUBMERGER_PORT_FILE}"
    
    # 重启服务
    systemctl restart sub_merger
    
    # 添加订阅源
    if [ "${#subscriptions[@]}" -gt 0 ]; then
        for sub in "${subscriptions[@]}"; do
            if [ -n "$sub" ]; then
                python3 "${SUBMERGER_INSTALL}" --add "subscription_$(date +%s)" "$sub"
            fi
        done
    fi
    
    # 设置定时刷新
    cat > "${SUBMERGER_CRON}" << EOF
# 每6小时自动刷新订阅
0 */6 * * * root python3 ${SUBMERGER_INSTALL} --update >/dev/null 2>&1
EOF
    
    chmod 644 "${SUBMERGER_CRON}"
    systemctl restart cron
}

# 查看订阅状态
python_check_status() {
    # 首先检查脚本是否存在
    if [ ! -f "${SUBMERGER_INSTALL}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未找到Python脚本，请确保安装完成"
            echo "路径: ${SUBMERGER_INSTALL}"
            echo "尝试重新安装以解决此问题"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未找到Python脚本，请确保安装完成\n路径: ${SUBMERGER_INSTALL}\n\n尝试重新安装以解决此问题" 10 60
        fi
        return
    fi

    # 获取服务状态
    local service_status=$(systemctl is-active sub_merger 2>/dev/null || echo "未知")
    local ip=$(get_external_ip 2>/dev/null || echo "获取失败")
    
    # 安全地读取端口和令牌
    local port=""
    if [ -f "${SUBMERGER_PORT_FILE}" ]; then
        port=$(cat "${SUBMERGER_PORT_FILE}" 2>/dev/null || echo "获取失败")
    else
        port="未配置 (默认: ${DEFAULT_MERGER_PORT})"
    fi
    
    local token=""
    if [ -f "${SUBMERGER_ACCESS_TOKEN}" ]; then
        token=$(cat "${SUBMERGER_ACCESS_TOKEN}" 2>/dev/null || echo "获取失败")
    else
        token="未配置 (默认: ${DEFAULT_PASSWORD})"
    fi
    
    # 安全地获取订阅列表和访问链接
    local subscription_list=""
    local access_links=""
    
    if [ -x "${SUBMERGER_INSTALL}" ]; then
        subscription_list=$(python3 "${SUBMERGER_INSTALL}" --list 2>&1 || echo "获取失败: $?")
        access_links=$(python3 "${SUBMERGER_INSTALL}" --info 2>&1 || echo "获取失败: $?")
    else
        subscription_list="无法执行Python脚本 (权限不足)"
        access_links="无法执行Python脚本 (权限不足)"
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: Python脚本权限不足"
            echo "正在尝试修复权限..."
            chmod +x "${SUBMERGER_INSTALL}" 2>/dev/null
            echo "完成"
        fi
    fi
    
    # 检查是否有订阅源
    local has_subscriptions=true
    if [ -z "$subscription_list" ] || [ "$subscription_list" = "没有配置订阅源" ] || [[ "$subscription_list" == *"获取失败"* ]]; then
        has_subscriptions=false
    fi
    
    local status_text="
===== 服务状态 =====
服务状态: ${service_status}
IP地址: ${ip}
端口: ${port}
访问令牌: ${token}

===== 订阅链接 =====
$access_links

===== 订阅源列表 =====
$subscription_list
"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$status_text"
        
        if [ "$has_subscriptions" = false ]; then
            echo "提示: 您尚未添加任何订阅源，请使用'添加订阅源'功能添加"
        fi
        
        read -p "按Enter继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        local buttons="--ok-label 返回"
        if [ "$has_subscriptions" = false ]; then
            buttons="$buttons --yes-label 添加订阅 --extra-button --extra-label 诊断"
            dialog --title "服务状态" $buttons --yesno "$status_text\n\n提示: 您尚未添加任何订阅源，请添加订阅源" $dialog_height $dialog_width
            
            local result=$?
            if [ $result -eq 0 ]; then
                return
            elif [ $result -eq 3 ]; then
                check_service_access
            else
                python_add_subscription
            fi
        else
            buttons="$buttons --extra-button --extra-label 诊断"
            dialog --title "服务状态" $buttons --msgbox "$status_text" $dialog_height $dialog_width
            
            local result=$?
            if [ $result -eq 3 ]; then
                check_service_access
            fi
        fi
    fi
}

# 添加订阅
python_add_subscription() {
    # 首先检查脚本是否存在
    if [ ! -f "${SUBMERGER_INSTALL}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未找到Python脚本，请确保安装完成"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未找到Python脚本，请确保安装完成" 6 40
        fi
        return
    fi

    if [ "$USE_TEXT_MODE" = true ]; then
        echo "添加订阅源"
        echo "----------"
        echo "请输入订阅名称 (如: vps1):"
        read -p "名称: " name
        echo "请输入订阅URL:"
        read -p "URL: " url
        
        if [ -z "$name" ] || [ -z "$url" ]; then
            echo "名称和URL不能为空!"
            sleep 2
            return
        fi
        
        echo "正在添加订阅..."
        result=$(python3 "${SUBMERGER_INSTALL}" --add "$name" "$url" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            echo "添加失败 (错误码: $status):"
            echo "$result"
        else
            echo "订阅已添加"
            echo "$result"
        fi
        read -p "按Enter继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 请求订阅名称
        name=$(dialog --title "添加订阅" --inputbox "请输入订阅名称 (如: vps1):" 8 50 "" 2>&1 >/dev/tty)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        # 请求订阅URL
        url=$(dialog --title "添加订阅" --inputbox "请输入订阅URL:" 8 60 "" 2>&1 >/dev/tty)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        if [ -z "$name" ] || [ -z "$url" ]; then
            dialog --title "错误" --msgbox "名称和URL不能为空!" 6 40
            return
        fi
        
        # 显示进度消息
        dialog --title "添加订阅" --infobox "正在添加订阅，请稍候..." 5 40
        
        result=$(python3 "${SUBMERGER_INSTALL}" --add "$name" "$url" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            dialog --title "错误" --msgbox "添加失败 (错误码: $status):\n\n$result" 12 60
        else
            dialog --title "订阅添加" --msgbox "订阅已添加\n\n$result" 12 50
        fi
    fi
}

# 删除订阅
python_remove_subscription() {
    # 首先检查脚本是否存在
    if [ ! -f "${SUBMERGER_INSTALL}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未找到Python脚本，请确保安装完成"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未找到Python脚本，请确保安装完成" 6 40
        fi
        return
    fi

    # 安全地获取当前订阅列表
    local subs=$(python3 "${SUBMERGER_INSTALL}" --list 2>&1)
    local status=$?
    
    if [ $status -ne 0 ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "获取订阅列表失败 (错误码: $status):"
            echo "$subs"
            read -p "按Enter继续..." confirm
        else
            dialog --title "错误" --msgbox "获取订阅列表失败 (错误码: $status):\n\n$subs" 12 60
        fi
        return
    fi
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "当前订阅列表:"
        echo "--------------"
        echo "$subs"
        echo ""
        read -p "请输入要删除的订阅ID: " id
        
        if [ -z "$id" ]; then
            echo "ID不能为空!"
            sleep 2
            return
        fi
        
        echo "正在删除订阅..."
        result=$(python3 "${SUBMERGER_INSTALL}" --remove "$id" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            echo "删除失败 (错误码: $status):"
            echo "$result"
        else
            echo "订阅已删除"
            echo "$result"
        fi
        read -p "按Enter继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "当前订阅列表" --msgbox "$subs" $dialog_height $dialog_width
        
        # 请求要删除的ID
        id=$(dialog --title "删除订阅" --inputbox "请输入要删除的订阅ID:" 8 50 "" 2>&1 >/dev/tty)
        
        if [ $? -ne 0 ] || [ -z "$id" ]; then
            return
        fi
        
        # 显示进度消息
        dialog --title "删除订阅" --infobox "正在删除订阅，请稍候..." 5 40
        
        result=$(python3 "${SUBMERGER_INSTALL}" --remove "$id" 2>&1)
        status=$?
        if [ $status -ne 0 ]; then
            dialog --title "错误" --msgbox "删除失败 (错误码: $status):\n\n$result" 12 60
        else
            dialog --title "订阅删除" --msgbox "订阅已删除\n\n$result" 10 50
        fi
    fi
}

# 修改访问密码
python_change_password() {
    # 首先检查目录是否存在
    if [ ! -d "${SUBMERGER_DIR}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未找到配置目录，请确保安装完成"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未找到配置目录，请确保安装完成" 6 40
        fi
        return
    fi

    # 安全地读取当前密码
    local current_password=""
    if [ -f "${SUBMERGER_ACCESS_TOKEN}" ]; then
        current_password=$(cat "${SUBMERGER_ACCESS_TOKEN}" 2>/dev/null || echo "读取失败")
    else
        # 创建密码文件
        current_password="${DEFAULT_PASSWORD}"
        echo "${DEFAULT_PASSWORD}" > "${SUBMERGER_ACCESS_TOKEN}" 2>/dev/null
        if [ $? -ne 0 ]; then
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "创建密码文件失败，请检查权限"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "错误" --msgbox "创建密码文件失败，请检查权限" 6 40
            fi
            return
        fi
    fi
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "修改访问密码"
        echo "当前密码: ${current_password}"
        echo "----------"
        read -p "新密码: " new_password
        
        if [ -z "$new_password" ]; then
            echo "密码不能为空!"
            sleep 2
            return
        fi
        
        # 尝试写入新密码
        echo "$new_password" > "${SUBMERGER_ACCESS_TOKEN}" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "密码更新失败，请检查权限"
            sleep 2
            return
        fi
        
        echo "密码已更新"
        sleep 2
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        new_password=$(dialog --title "修改密码" --inputbox "当前密码: ${current_password}\n\n请输入新的访问密码:" 10 50 "$current_password" 2>&1 >/dev/tty)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        if [ -z "$new_password" ]; then
            dialog --title "错误" --msgbox "密码不能为空!" 6 40
            return
        fi
        
        # 尝试写入新密码
        echo "$new_password" > "${SUBMERGER_ACCESS_TOKEN}" 2>/dev/null
        if [ $? -ne 0 ]; then
            dialog --title "错误" --msgbox "密码更新失败，请检查权限" 6 40
            return
        fi
        
        dialog --title "修改密码" --msgbox "密码已更新为: $new_password" 6 50
    fi
    
    # 重启服务以应用新密码
    systemctl restart sub_merger 2>/dev/null
}

# 修改服务端口
python_change_port() {
    # 首先检查目录是否存在
    if [ ! -d "${SUBMERGER_DIR}" ]; then
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 未找到配置目录，请确保安装完成"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "未找到配置目录，请确保安装完成" 6 40
        fi
        return
    fi

    # 安全地读取当前端口
    local current_port=""
    if [ -f "${SUBMERGER_PORT_FILE}" ]; then
        current_port=$(cat "${SUBMERGER_PORT_FILE}" 2>/dev/null || echo "读取失败")
    else
        # 创建端口文件
        current_port="${DEFAULT_MERGER_PORT}"
        echo "${DEFAULT_MERGER_PORT}" > "${SUBMERGER_PORT_FILE}" 2>/dev/null
        if [ $? -ne 0 ]; then
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "创建端口文件失败，请检查权限"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "错误" --msgbox "创建端口文件失败，请检查权限" 6 40
            fi
            return
        fi
    fi
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "修改服务端口"
        echo "当前端口: ${current_port}"
        echo "----------"
        read -p "新端口: " new_port
        
        if [ -z "$new_port" ]; then
            echo "端口不能为空!"
            sleep 2
            return
        fi
        
        # 检查端口是否为数字
        if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
            echo "端口必须是数字!"
            sleep 2
            return
        fi
        
        # 尝试写入新端口
        echo "$new_port" > "${SUBMERGER_PORT_FILE}" 2>/dev/null
        if [ $? -ne 0 ]; then
            echo "端口更新失败，请检查权限"
            sleep 2
            return
        fi
        
        # 重启服务
        systemctl restart sub_merger 2>/dev/null
        
        echo "端口已更新，服务已重启"
        sleep 2
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        new_port=$(dialog --title "修改端口" --inputbox "当前端口: ${current_port}\n\n请输入新的服务端口:" 10 50 "$current_port" 2>&1 >/dev/tty)
        
        if [ $? -ne 0 ]; then
            return
        fi
        
        if [ -z "$new_port" ]; then
            dialog --title "错误" --msgbox "端口不能为空!" 6 40
            return
        fi
        
        # 检查端口是否为数字
        if ! [[ "$new_port" =~ ^[0-9]+$ ]]; then
            dialog --title "错误" --msgbox "端口必须是数字!" 6 40
            return
        fi
        
        # 尝试写入新端口
        echo "$new_port" > "${SUBMERGER_PORT_FILE}" 2>/dev/null
        if [ $? -ne 0 ]; then
            dialog --title "错误" --msgbox "端口更新失败，请检查权限" 6 40
            return
        fi
        
        # 重启服务
        dialog --title "修改端口" --infobox "正在重启服务..." 5 30
        systemctl restart sub_merger 2>/dev/null
        
        # 如果存在Nginx配置，也需要更新
        if [ -f "/etc/nginx/conf.d/sub_merger.conf" ]; then
            dialog --title "Nginx配置" --yesno "检测到Nginx配置，是否更新Nginx反向代理配置?" 7 50
            if [ $? -eq 0 ]; then
                fix_service_access
            fi
        fi
        
        dialog --title "修改端口" --msgbox "端口已更新为: $new_port\n服务已重启" 7 50
    fi
}

# 卸载订阅管理工具
uninstall_subconverter() {
    local title="卸载确认"
    local message="确定要卸载Python订阅合并器吗？这将删除所有配置和数据。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
        read -p "是否继续? (y/n): " confirm
        if [[ ! $confirm =~ ^[Yy]$ ]]; then
            return
        fi
    else
        local result=$(show_confirm_dialog "$title" "$message")
        if [[ $result -ne 0 ]]; then
            return
        fi
    fi
    
    # 停止服务
    systemctl stop sub_merger
    systemctl disable sub_merger
    
    # 删除文件
    rm -f "${SUBMERGER_SERVICE}"
    rm -f "${SUBMERGER_CRON}"
    rm -rf "${SUBMERGER_DIR}"
    
    # 重新加载systemd配置
    systemctl daemon-reload
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "Python订阅合并器已成功卸载"
        sleep 2
    else
        dialog --title "卸载完成" --msgbox "Python订阅合并器已成功卸载" 6 40
    fi
}

# 检查服务访问
check_service_access() {
    local title="服务访问诊断"
    
    # 获取当前配置
    local current_port=""
    if [ -f "${SUBMERGER_PORT_FILE}" ]; then
        current_port=$(cat "${SUBMERGER_PORT_FILE}")
    else
        current_port="${DEFAULT_MERGER_PORT}"
    fi
    
    # 检查端口是否被占用
    local port_occupied=false
    local occupied_by=""
    local port_check=$(ss -tulpn | grep ":$current_port")
    if [ -n "$port_check" ]; then
        port_occupied=true
        occupied_by=$(echo "$port_check" | awk '{print $7}')
    fi
    
    # 检查服务状态
    local service_status=$(systemctl is-active sub_merger)
    local nginx_status=$(systemctl is-active nginx 2>/dev/null || echo "未安装")
    
    # 检查Nginx配置
    local nginx_conf_exists=false
    if [ -f "/etc/nginx/conf.d/sub_merger.conf" ]; then
        nginx_conf_exists=true
    fi
    
    # 检查防火墙
    local firewall_status="未知"
    if command -v ufw >/dev/null 2>&1; then
        firewall_status=$(ufw status | grep -q "active" && echo "启用" || echo "禁用")
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall_status=$(firewall-cmd --state 2>/dev/null || echo "禁用")
    fi
    
    # 生成诊断报告
    local report="
===== 服务访问诊断报告 =====

服务状态:
  - sub_merger 服务: ${service_status}
  - Nginx 服务: ${nginx_status}

端口监听:
  - 配置端口: ${current_port}
  - 端口占用: $([ "$port_occupied" = true ] && echo "是, 被 $occupied_by 占用" || echo "否")

Nginx配置:
  - 代理配置: $([ "$nginx_conf_exists" = true ] && echo "存在" || echo "不存在")
  
防火墙状态:
  - 状态: ${firewall_status}

问题分析:
"
    
    # 检查可能的问题
    local issues_found=false
    local issues=""
    
    if [ "$service_status" != "active" ]; then
        issues="${issues}- 服务未正常运行,需要启动服务\n"
        issues_found=true
    fi
    
    if [ "$port_occupied" = true ] && [[ "$occupied_by" != *"python"* ]]; then
        issues="${issues}- 端口 ${current_port} 被其他程序占用,可尝试修改端口\n"
        issues_found=true
    fi
    
    if [ "$nginx_status" = "active" ] && [ "$nginx_conf_exists" = false ]; then
        issues="${issues}- Nginx正在运行但没有为订阅合并器配置代理\n"
        issues_found=true
    fi
    
    if [ "$issues_found" = false ]; then
        issues="- 未发现明显问题,服务应该可以正常访问\n"
    fi
    
    report="${report}${issues}"
    
    # 解决方案
    local solutions=""
    if [ "$issues_found" = true ]; then
        solutions="
建议解决方案:
- 使用自动修复尝试解决问题
- 自动修复将执行以下操作:
  1. 创建Nginx代理配置
  2. 重启相关服务
  3. 配置防火墙规则
"
        report="${report}${solutions}"
    fi
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$report"
        
        if [ "$issues_found" = true ]; then
            read -p "是否尝试自动修复这些问题? (y/n): " fix_confirm
            if [[ $fix_confirm =~ ^[Yy]$ ]]; then
                fix_service_access
            fi
        else
            read -p "按Enter键继续..." confirm
        fi
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        if [ "$issues_found" = true ]; then
            dialog --title "$title" --yes-label "自动修复" --no-label "返回" --yesno "$report" $dialog_height $dialog_width
            
            if [ $? -eq 0 ]; then
                fix_service_access
            fi
        else
            dialog --title "$title" --msgbox "$report" $dialog_height $dialog_width
        fi
    fi
}

# 修复服务访问
fix_service_access() {
    local title="服务访问修复"
    local message="正在修复服务访问问题..."
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$message"
    else
        show_progress_dialog "$title" "$message"
    fi
    
    # 获取当前配置
    local current_port=""
    if [ -f "${SUBMERGER_PORT_FILE}" ]; then
        current_port=$(cat "${SUBMERGER_PORT_FILE}")
    else
        current_port="${DEFAULT_MERGER_PORT}"
    fi
    
    # 获取IP地址
    local ip=$(get_external_ip)
    
    # 创建Nginx配置
    cat > "/etc/nginx/conf.d/sub_merger.conf" << EOF
server {
    listen 80;
    server_name _;
    
    location /sub {
        proxy_pass http://127.0.0.1:${current_port}/sub;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /ping {
        proxy_pass http://127.0.0.1:${current_port}/ping;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF
    
    # 重启服务
    systemctl restart sub_merger
    systemctl enable sub_merger
    
    # 如果Nginx安装了，重启它
    if command -v nginx >/dev/null 2>&1; then
        systemctl restart nginx
        systemctl enable nginx
    fi
    
    # 配置防火墙
    if command -v ufw >/dev/null 2>&1; then
        ufw allow 80/tcp
        ufw allow ${current_port}/tcp
    elif command -v firewall-cmd >/dev/null 2>&1; then
        firewall-cmd --permanent --add-port=80/tcp
        firewall-cmd --permanent --add-port=${current_port}/tcp
        firewall-cmd --reload
    fi
    
    local success_message="
===== 服务访问修复完成 =====

已执行的操作:
1. 创建了Nginx配置,将访问重定向到订阅合并器
2. 重启了相关服务
3. 配置了防火墙规则

现在您可以通过以下地址访问订阅:
- 使用Nginx代理 (推荐): http://${ip}/sub?token=$(cat ${SUBMERGER_ACCESS_TOKEN})&target=v2ray
- 直接端口访问: http://${ip}:${current_port}/sub?token=$(cat ${SUBMERGER_ACCESS_TOKEN})&target=v2ray

可以通过访问以下地址测试服务是否正常响应:
- http://${ip}/ping
- http://${ip}:${current_port}/ping
"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "$success_message"
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "修复完成" --msgbox "$success_message" $dialog_height $dialog_width
    fi
}

# 显示错误对话框
show_error_dialog() {
    local title="$1"
    local message="$2"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "错误: $title"
        echo "$message"
        sleep 2
    else
        dialog --title "错误: $title" --msgbox "$message" 8 50
    fi
}