#!/bin/bash

# ServerMaster Installation Script
# This script installs the ServerMaster system

# 检测是否通过管道运行
# is_piped() {
#     [ -p /dev/stdin ]
# }

# # 如果是通过管道运行，先将脚本内容保存到临时文件再执行
# if is_piped; then
#     temp_script=$(mktemp /tmp/servermaster_install_XXXXXX.sh)
#     cat > "$temp_script"
#     chmod +x "$temp_script"
#     exec bash "$temp_script"
#     exit $?
# fi

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
    echo -e "[$timestamp] [$level] $message" >> "$LOGS_DIR/install.log"
}

# 在文件顶部添加一个新的函数用于显示实时日志
# 在一个对话框中显示安装日志
show_progress() {
    local log_file="$LOGS_DIR/install.log"
    local fifo_file="/tmp/servermaster_install_fifo"
    
    # 确保日志目录存在
    mkdir -p "$LOGS_DIR"
    
    # 清空日志文件
    : > "$log_file"
    
    # 创建FIFO
    rm -f "$fifo_file"
    mkfifo "$fifo_file"
    
    # 获取窗口尺寸
    local term_height=$(tput lines)
    local term_width=$(tput cols)
    local win_height=$((term_height * 80 / 100))
    local win_width=$((term_width * 80 / 100))
    [ $win_height -lt 20 ] && win_height=20
    [ $win_width -lt 70 ] && win_width=70
    
    # 启动dialog显示日志内容
    dialog --title "ServerMaster 安装进度" \
           --begin 2 2 \
           --tailboxbg "$fifo_file" $((win_height-5)) $((win_width-10)) \
           --and-widget \
           --begin $((win_height-3)) 2 \
           --infobox "安装中，请稍候..." 3 $((win_width-10)) &
    
    dialog_pid=$!
    
    # 添加初始内容到FIFO，防止file pointer错误
    echo "正在初始化安装程序..." > "$fifo_file" &
    
    # 启动后台进程，从日志文件更新到FIFO
    (
        while true; do
            if [ -f "$log_file" ]; then
                # 使用cat而不是直接重定向，避免文件指针错误
                cat "$log_file" > "$fifo_file" 2>/dev/null || true
                sleep 1
            fi
        done
    ) &
    
    tail_pid=$!
    
    # 返回FIFO路径，供日志函数使用
    echo "$fifo_file"
}

# 执行命令并记录日志
execute_cmd() {
    local cmd="$1"
    local success_msg="$2"
    local error_msg="$3"
    
    log "INFO" "执行: $cmd"
    
    # 执行命令并捕获输出
    local output
    if output=$(eval "$cmd" 2>&1); then
        log "SUCCESS" "$success_msg\n$output"
        return 0
    else
        log "ERROR" "$error_msg\n$output"
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
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    # 尝试Cloudflare Workers代理
    if output=$(curl -s -S -o "$TEMP_DIR/main.sh.tmp" "$CF_PROXY_URL/main.sh" 2>&1) && [ -s "$TEMP_DIR/main.sh.tmp" ]; then
        # 检查文件大小确保下载成功
        if [ -s "$TEMP_DIR/main.sh.tmp" ]; then
            mv "$TEMP_DIR/main.sh.tmp" "$INSTALL_DIR/main.sh"
            chmod +x "$INSTALL_DIR/main.sh"
            log "SUCCESS" "从Cloudflare Workers下载主脚本成功"
            download_success=true
        else
            log "ERROR" "从Cloudflare Workers下载的文件为空"
            rm -f "$TEMP_DIR/main.sh.tmp"
        fi
    # 尝试GitHub直连
    elif output=$(curl -s -S -o "$TEMP_DIR/main.sh.tmp" "$GITHUB_RAW/main.sh" 2>&1) && [ -s "$TEMP_DIR/main.sh.tmp" ]; then
        if [ -s "$TEMP_DIR/main.sh.tmp" ]; then
            mv "$TEMP_DIR/main.sh.tmp" "$INSTALL_DIR/main.sh"
            chmod +x "$INSTALL_DIR/main.sh"
            log "SUCCESS" "从GitHub直连下载主脚本成功"
            download_success=true
        else
            log "ERROR" "从GitHub直连下载的文件为空"
            rm -f "$TEMP_DIR/main.sh.tmp"
        fi
    # 尝试镜像站
    elif output=$(curl -s -S -o "$TEMP_DIR/main.sh.tmp" "${MIRROR_URL}${GITHUB_RAW}/main.sh" 2>&1) && [ -s "$TEMP_DIR/main.sh.tmp" ]; then
        if [ -s "$TEMP_DIR/main.sh.tmp" ]; then
            mv "$TEMP_DIR/main.sh.tmp" "$INSTALL_DIR/main.sh"
            chmod +x "$INSTALL_DIR/main.sh"
            log "SUCCESS" "从镜像站下载主脚本成功"
            download_success=true
        else
            log "ERROR" "从镜像站下载的文件为空"
            rm -f "$TEMP_DIR/main.sh.tmp"
        fi
    fi
    
    # 清理临时文件
    rm -f "$TEMP_DIR/main.sh.tmp"
    
    if [ "$download_success" = false ]; then
        log "ERROR" "所有下载源均无法下载主脚本: $output"
        dialog --title "下载错误" --msgbox "下载错误: $output" 8 60
        exit 1
    fi
}

# 下载模块
download_modules() {
    log "INFO" "开始下载系统模块"
    
    local download_success=false
    local output=""
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    # 尝试Cloudflare Workers代理
    if output=$(curl -s -S -o "$TEMP_DIR/modules.tar.gz.tmp" "$CF_PROXY_URL/modules.tar.gz" 2>&1) && [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
        if [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
            mv "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
            execute_cmd "tar -xzf $TEMP_DIR/modules.tar.gz -C $INSTALL_DIR" \
                       "模块解压成功" \
                       "模块解压失败"
            log "SUCCESS" "从Cloudflare Workers下载并解压模块成功"
            download_success=true
        else
            log "ERROR" "从Cloudflare Workers下载的模块文件为空"
            rm -f "$TEMP_DIR/modules.tar.gz.tmp"
        fi
    # 尝试GitHub直连
    elif output=$(curl -s -S -o "$TEMP_DIR/modules.tar.gz.tmp" "$GITHUB_RAW/modules.tar.gz" 2>&1) && [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
        if [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
            mv "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
            execute_cmd "tar -xzf $TEMP_DIR/modules.tar.gz -C $INSTALL_DIR" \
                       "模块解压成功" \
                       "模块解压失败"
            log "SUCCESS" "从GitHub直连下载并解压模块成功"
            download_success=true
        else
            log "ERROR" "从GitHub直连下载的模块文件为空"
            rm -f "$TEMP_DIR/modules.tar.gz.tmp"
        fi
    # 尝试镜像站
    elif output=$(curl -s -S -o "$TEMP_DIR/modules.tar.gz.tmp" "${MIRROR_URL}${GITHUB_RAW}/modules.tar.gz" 2>&1) && [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
        if [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
            mv "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
            execute_cmd "tar -xzf $TEMP_DIR/modules.tar.gz -C $INSTALL_DIR" \
                       "模块解压成功" \
                       "模块解压失败"
            log "SUCCESS" "从镜像站下载并解压模块成功"
            download_success=true
        else
            log "ERROR" "从镜像站下载的模块文件为空"
            rm -f "$TEMP_DIR/modules.tar.gz.tmp"
        fi
    fi
    
    # 清理临时文件
    rm -f "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
    
    if [ "$download_success" = false ]; then
        log "ERROR" "所有下载源均无法下载系统模块: $output"
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

# 主函数
main() {
    # 启动进度显示
    FIFO_FILE=$(show_progress)
    
    # 记录欢迎消息
    log "INFO" "欢迎使用 ServerMaster 安装向导！"
    log "INFO" "正在准备安装..."
    sleep 1
    
    # 显示安装步骤
    log "INFO" "安装将执行以下步骤:"
    log "INFO" "1. 检查系统要求"
    log "INFO" "2. 创建必要目录"
    log "INFO" "3. 检查网络连接"
    log "INFO" "4. 下载主脚本"
    log "INFO" "5. 下载系统模块"
    log "INFO" "6. 创建系统命令"
    log "INFO" "7. 完成安装"
    sleep 1
    
    # 执行安装步骤
    ensure_dialog
    check_system
    create_directories
    check_connectivity
    download_main_script
    download_modules
    create_command
    
    # 完成安装
    log "SUCCESS" "ServerMaster 安装完成！"
    sleep 2
    
    # 关闭进度监控
    kill $tail_pid 2>/dev/null
    kill $dialog_pid 2>/dev/null
    rm -f "$FIFO_FILE"
    
    # 运行完成函数
    finalize
}

# 启动安装
main