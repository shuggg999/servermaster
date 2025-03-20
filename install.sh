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
    echo "[$timestamp] [$level] $message" >> "$LOGS_DIR/install.log"
    dialog --title "安装日志" --infobox "$message" 5 60
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
    dialog --title "系统检查" --infobox "正在检查系统要求..." 5 40
    sleep 1
    
    # 检查必要的工具
    local required_tools="curl wget tar gzip"
    local missing_tools=""
    
    for tool in $required_tools; do
        if ! command -v $tool &> /dev/null; then
            missing_tools="$missing_tools $tool"
        fi
    done
    
    if [ ! -z "$missing_tools" ]; then
        log "INFO" "正在安装必要的工具: $missing_tools"
        dialog --title "安装依赖" --infobox "正在安装必要的工具..." 5 40
        sleep 1
        
        if command -v apt &> /dev/null; then
            apt update && apt install -y $missing_tools
        elif command -v yum &> /dev/null; then
            yum install -y $missing_tools
        elif command -v apk &> /dev/null; then
            apk add $missing_tools
        else
            dialog --title "错误" --msgbox "无法安装必要的工具，请手动安装。" 8 40
            exit 1
        fi
        log "SUCCESS" "必要工具安装完成"
    else
        log "INFO" "所有必要工具已安装"
    fi
}

# 创建必要的目录
create_directories() {
    log "INFO" "创建必要的目录"
    dialog --title "创建目录" --infobox "正在创建必要的目录..." 5 40
    sleep 1
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$MODULES_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOGS_DIR"
    mkdir -p "$TEMP_DIR"
    log "SUCCESS" "目录创建完成"
}

# 检查网络连接
check_connectivity() {
    log "INFO" "检查网络连接"
    dialog --title "网络检查" --infobox "正在检查网络连接..." 5 40
    sleep 1
    
    if ! curl -s "$CF_PROXY_URL" &> /dev/null && \
       ! curl -s "$GITHUB_RAW" &> /dev/null && \
       ! curl -s "${MIRROR_URL}${GITHUB_RAW}" &> /dev/null; then
        log "ERROR" "无法连接到服务器，请检查网络连接。"
        dialog --title "错误" --msgbox "无法连接到服务器，请检查网络连接。" 8 40
        exit 1
    fi
    log "SUCCESS" "网络连接正常"
}

# 下载主脚本
download_main_script() {
    log "INFO" "下载主脚本"
    dialog --title "下载主脚本" --infobox "正在下载主脚本..." 5 40
    sleep 1
    
    if curl -s -o "$INSTALL_DIR/main.sh" "$CF_PROXY_URL/main.sh" || \
       curl -s -o "$INSTALL_DIR/main.sh" "$GITHUB_RAW/main.sh" || \
       curl -s -o "$INSTALL_DIR/main.sh" "${MIRROR_URL}${GITHUB_RAW}/main.sh"; then
        chmod +x "$INSTALL_DIR/main.sh"
        log "SUCCESS" "主脚本下载完成"
    else
        log "ERROR" "无法下载主脚本"
        dialog --title "错误" --msgbox "无法下载主脚本。" 8 40
        exit 1
    fi
}

# 下载模块
download_modules() {
    log "INFO" "下载系统模块"
    dialog --title "下载模块" --infobox "正在下载系统模块..." 5 40
    sleep 1
    
    if curl -s -o "$TEMP_DIR/modules.tar.gz" "$CF_PROXY_URL/modules.tar.gz" || \
       curl -s -o "$TEMP_DIR/modules.tar.gz" "$GITHUB_RAW/modules.tar.gz" || \
       curl -s -o "$TEMP_DIR/modules.tar.gz" "${MIRROR_URL}${GITHUB_RAW}/modules.tar.gz"; then
        tar -xzf "$TEMP_DIR/modules.tar.gz" -C "$INSTALL_DIR"
        log "SUCCESS" "系统模块下载完成"
    else
        log "ERROR" "无法下载系统模块"
        dialog --title "错误" --msgbox "无法下载系统模块。" 8 40
        exit 1
    fi
}

# 创建命令链接
create_command() {
    log "INFO" "创建系统命令"
    dialog --title "创建命令" --infobox "正在创建系统命令..." 5 40
    sleep 1
    
    ln -sf "$INSTALL_DIR/main.sh" /usr/local/bin/sm
    chmod +x /usr/local/bin/sm
    log "SUCCESS" "系统命令创建完成"
}

# 完成安装
finalize() {
    log "SUCCESS" "ServerMaster 安装完成"
    dialog --title "安装完成" --msgbox "ServerMaster 安装完成！\n\n正在启动系统..." 8 40
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