#!/bin/bash

# ServerMaster Installation Script
# This script installs the ServerMaster system

# 检查 Dialog 是否已安装
if ! command -v dialog &> /dev/null; then
    echo "错误: Dialog 未安装，请先安装 Dialog。"
    exit 1
fi

# 安装路径
INSTALL_DIR="/usr/local/servermaster"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"
LOGS_DIR="$INSTALL_DIR/logs"
TEMP_DIR="/tmp/servermaster"

# URLs
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 确保日志目录存在
    mkdir -p "$LOGS_DIR"
    
    # 写入日志文件
    echo "[$timestamp] [$level] $message" >> "$LOGS_DIR/install.log"
    
    # 在界面上显示
    case "$level" in
        "INFO")
            dialog --title "安装信息" --msgbox "$message" 6 60
            ;;
        "SUCCESS")
            dialog --title "安装成功" --msgbox "✅ $message" 6 60
            ;;
        "ERROR")
            dialog --title "安装错误" --msgbox "❌ $message" 6 60
            ;;
        *)
            dialog --title "安装信息" --msgbox "$message" 6 60
            ;;
    esac
}

# 执行命令并显示结果
execute_cmd() {
    local cmd="$1"
    local success_msg="$2"
    local error_msg="$3"
    
    # 执行命令并捕获输出
    local output
    if output=$(eval "$cmd" 2>&1); then
        dialog --title "执行结果" --msgbox "命令执行成功:\n$success_msg\n\n输出:\n$output" 12 70
        log "SUCCESS" "$success_msg"
        return 0
    else
        dialog --title "执行错误" --msgbox "命令执行失败:\n$error_msg\n\n错误:\n$output" 12 70
        log "ERROR" "$error_msg"
        return 1
    fi
}

# 确保 Dialog 已安装
ensure_dialog() {
    log "INFO" "检查 Dialog 安装状态"
    if ! command -v dialog &> /dev/null; then
        log "INFO" "正在安装 Dialog..."
        if command -v apt &> /dev/null; then
            apt update && apt install -y dialog
        elif command -v yum &> /dev/null; then
            yum install -y dialog
        elif command -v apk &> /dev/null; then
            apk add dialog
        else
            log "ERROR" "无法安装 Dialog，请手动安装。"
            dialog --title "错误" --msgbox "无法安装 Dialog，请手动安装。" 8 40
            exit 1
        fi
        log "SUCCESS" "Dialog 安装完成"
    else
        log "INFO" "Dialog 已安装"
    fi
}

# 检查系统要求
check_system() {
    log "INFO" "检查系统要求"
    
    # 检查必要的工具
    local required_tools="curl wget tar gzip"
    local missing_tools=""
    
    for tool in $required_tools; do
        if ! command -v $tool &> /dev/null; then
            missing_tools="$missing_tools $tool"
        fi
    done
    
    if [ ! -z "$missing_tools" ]; then
        log "INFO" "需要安装的工具: $missing_tools"
        
        if command -v apt &> /dev/null; then
            execute_cmd "apt update && apt install -y $missing_tools" \
                       "已安装工具: $missing_tools" \
                       "无法安装工具: $missing_tools"
        elif command -v yum &> /dev/null; then
            execute_cmd "yum install -y $missing_tools" \
                       "已安装工具: $missing_tools" \
                       "无法安装工具: $missing_tools"
        elif command -v apk &> /dev/null; then
            execute_cmd "apk add $missing_tools" \
                       "已安装工具: $missing_tools" \
                       "无法安装工具: $missing_tools"
        else
            log "ERROR" "无法安装必要的工具，请手动安装"
            exit 1
        fi
    else
        log "SUCCESS" "所有必要工具已安装"
    fi
}

# 创建必要的目录
create_directories() {
    log "INFO" "创建必要的目录"
    
    if [ -d "$INSTALL_DIR" ]; then
        log "INFO" "安装目录已存在，检查子目录"
    else
        execute_cmd "mkdir -p $INSTALL_DIR" \
                   "创建安装目录: $INSTALL_DIR" \
                   "无法创建安装目录: $INSTALL_DIR"
    fi
    
    # 创建子目录
    local subdirs=("$MODULES_DIR" "$CONFIG_DIR" "$LOGS_DIR" "$TEMP_DIR")
    for dir in "${subdirs[@]}"; do
        if [ -d "$dir" ]; then
            log "INFO" "目录已存在: $dir"
        else
            execute_cmd "mkdir -p $dir" \
                       "创建目录: $dir" \
                       "无法创建目录: $dir"
        fi
    done
    
    log "SUCCESS" "目录结构创建完成"
}

# 检查网络连接
check_connectivity() {
    log "INFO" "检查网络连接"
    
    local connected=false
    local output=""
    
    # 尝试Cloudflare Workers代理
    if output=$(curl -s --connect-timeout 5 "$CF_PROXY_URL" 2>&1); then
        log "SUCCESS" "成功连接到 Cloudflare Workers 代理"
        connected=true
    # 尝试GitHub直连
    elif output=$(curl -s --connect-timeout 5 "$GITHUB_RAW" 2>&1); then
        log "SUCCESS" "成功连接到 GitHub 直连"
        connected=true
    # 尝试镜像站
    elif output=$(curl -s --connect-timeout 5 "${MIRROR_URL}${GITHUB_RAW}" 2>&1); then
        log "SUCCESS" "成功连接到镜像站"
        connected=true
    fi
    
    if [ "$connected" = false ]; then
        log "ERROR" "无法连接到任何服务器，请检查网络连接"
        dialog --title "网络错误" --msgbox "连接错误: $output" 8 60
        exit 1
    fi
}

# 下载主脚本
download_main_script() {
    log "INFO" "开始下载主脚本"
    
    if [ -f "$INSTALL_DIR/main.sh" ]; then
        log "INFO" "主脚本已存在，准备覆盖"
    fi
    
    local download_success=false
    local output=""
    
    # 尝试Cloudflare Workers代理
    if output=$(curl -s -o "$INSTALL_DIR/main.sh" "$CF_PROXY_URL/main.sh" 2>&1); then
        chmod +x "$INSTALL_DIR/main.sh"
        log "SUCCESS" "从Cloudflare Workers下载主脚本成功"
        download_success=true
    # 尝试GitHub直连
    elif output=$(curl -s -o "$INSTALL_DIR/main.sh" "$GITHUB_RAW/main.sh" 2>&1); then
        chmod +x "$INSTALL_DIR/main.sh"
        log "SUCCESS" "从GitHub直连下载主脚本成功"
        download_success=true
    # 尝试镜像站
    elif output=$(curl -s -o "$INSTALL_DIR/main.sh" "${MIRROR_URL}${GITHUB_RAW}/main.sh" 2>&1); then
        chmod +x "$INSTALL_DIR/main.sh"
        log "SUCCESS" "从镜像站下载主脚本成功"
        download_success=true
    fi
    
    if [ "$download_success" = false ]; then
        log "ERROR" "所有下载源均无法下载主脚本"
        dialog --title "下载错误" --msgbox "下载错误: $output" 8 60
        exit 1
    fi
}

# 下载模块
download_modules() {
    log "INFO" "开始下载系统模块"
    
    local download_success=false
    local output=""
    
    # 尝试Cloudflare Workers代理
    if output=$(curl -s -o "$TEMP_DIR/modules.tar.gz" "$CF_PROXY_URL/modules.tar.gz" 2>&1); then
        execute_cmd "tar -xzf $TEMP_DIR/modules.tar.gz -C $INSTALL_DIR" \
                   "模块解压成功" \
                   "模块解压失败"
        log "SUCCESS" "从Cloudflare Workers下载并解压模块成功"
        download_success=true
    # 尝试GitHub直连
    elif output=$(curl -s -o "$TEMP_DIR/modules.tar.gz" "$GITHUB_RAW/modules.tar.gz" 2>&1); then
        execute_cmd "tar -xzf $TEMP_DIR/modules.tar.gz -C $INSTALL_DIR" \
                   "模块解压成功" \
                   "模块解压失败"
        log "SUCCESS" "从GitHub直连下载并解压模块成功"
        download_success=true
    # 尝试镜像站
    elif output=$(curl -s -o "$TEMP_DIR/modules.tar.gz" "${MIRROR_URL}${GITHUB_RAW}/modules.tar.gz" 2>&1); then
        execute_cmd "tar -xzf $TEMP_DIR/modules.tar.gz -C $INSTALL_DIR" \
                   "模块解压成功" \
                   "模块解压失败"
        log "SUCCESS" "从镜像站下载并解压模块成功"
        download_success=true
    fi
    
    if [ "$download_success" = false ]; then
        log "ERROR" "所有下载源均无法下载系统模块"
        dialog --title "下载错误" --msgbox "下载错误: $output" 8 60
        exit 1
    fi
}

# 创建命令链接
create_command() {
    log "INFO" "创建系统命令链接"
    
    if [ -L "/usr/local/bin/sm" ]; then
        log "INFO" "命令链接已存在，准备更新"
    fi
    
    execute_cmd "ln -sf $INSTALL_DIR/main.sh /usr/local/bin/sm && chmod +x /usr/local/bin/sm" \
               "系统命令链接创建成功" \
               "系统命令链接创建失败"
}

# 完成安装
finalize() {
    log "SUCCESS" "ServerMaster 安装完成"
    
    # 设置版本号
    if [ -f "/tmp/servermaster_new_version" ]; then
        cat "/tmp/servermaster_new_version" > "$INSTALL_DIR/version.txt"
        log "SUCCESS" "版本号已更新为 $(cat $INSTALL_DIR/version.txt)"
    else
        # 获取最新版本号
        local latest_version=$(curl -s "$CF_PROXY_URL/version.txt" || 
                            curl -s "$GITHUB_RAW/version.txt" || 
                            curl -s "${MIRROR_URL}${GITHUB_RAW}/version.txt" || 
                            echo "1.0")
        echo -n "$latest_version" > "$INSTALL_DIR/version.txt"
        log "SUCCESS" "版本号已设置为 $latest_version"
    fi
    
    # 恢复配置（如果是更新安装）
    if [ -d "/tmp/servermaster_config_backup" ] && [ -d "$INSTALL_DIR/config" ]; then
        cp -r /tmp/servermaster_config_backup/* "$INSTALL_DIR/config/"
        rm -rf /tmp/servermaster_config_backup
        log "SUCCESS" "配置文件已恢复"
    fi
    
    # 设置权限
    chmod -R 755 "$INSTALL_DIR"
    
    dialog --title "安装完成" --msgbox "ServerMaster 安装完成！\n\n当前版本: $(cat $INSTALL_DIR/version.txt)\n\n正在启动系统..." 10 50
    clear
    exec "$INSTALL_DIR/main.sh"
}

# 显示安装步骤
show_install_steps() {
    dialog --title "安装步骤" --msgbox "ServerMaster 安装向导\n\n1. 检查系统要求\n2. 创建必要目录\n3. 检查网络连接\n4. 下载主脚本\n5. 下载系统模块\n6. 创建系统命令\n7. 完成安装" 12 50
}

# 主函数
main() {
    # 显示欢迎信息
    dialog --title "欢迎" --msgbox "欢迎使用 ServerMaster 安装向导！\n\n本向导将帮助您安装 ServerMaster 系统。" 8 50
    
    # 显示安装步骤
    show_install_steps
    
    # 执行安装步骤
    ensure_dialog
    check_system
    create_directories
    check_connectivity
    download_main_script
    download_modules
    create_command
    finalize
}

# 启动安装
main