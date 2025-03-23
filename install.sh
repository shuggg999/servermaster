#!/bin/bash

# ServerMaster Installation Script
# This script installs the ServerMaster system

# 安装路径
INSTALL_DIR="/usr/local/servermaster"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"
LOGS_DIR="$INSTALL_DIR/logs"
TEMP_DIR="/tmp/servermaster"

# 模块子目录
MODULE_SUBDIRS=(
    "system_management"
    "network_security"
    "backup_sync"
    "container_deploy"
    "test_diagnostic"
    "cluster_management"
    "workspace_management"
    "intranet_penetration"
    "system_maintenance"
)

# URLs
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# 文本模式 - 无需Dialog
USE_TEXT_MODE=true

# 重试设置
MAX_RETRIES=3
CONNECTION_TIMEOUT=10

# 智能执行命令函数（替代sudo）
safe_exec() {
    # 如果用户是root，直接执行命令
    if [ "$(id -u)" -eq 0 ]; then
        eval "$@"
    # 如果系统有sudo命令，使用sudo执行
    elif command -v sudo &> /dev/null; then
        sudo "$@"
    # 如果都不满足，提示错误
    else
        echo -e "[\033[31mERROR\033[0m] 需要root权限执行该命令，但系统中没有sudo命令"
        echo -e "请使用root用户执行此脚本，或安装sudo软件包"
        return 1
    fi
}

# 日志函数
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    
    # 确保日志目录存在
    mkdir -p "$LOGS_DIR"
    
    # 写入日志文件
    echo -e "[$timestamp] [$level] $message" >> "$LOGS_DIR/install.log"
    
    # 文本模式下直接输出到控制台
    if [ "$USE_TEXT_MODE" = true ]; then
        case "$level" in
            "INFO")     echo -e "[\033[34mINFO\033[0m] $message" ;;
            "SUCCESS")  echo -e "[\033[32mSUCCESS\033[0m] $message" ;;
            "ERROR")    echo -e "[\033[31mERROR\033[0m] $message" ;;
            *)          echo -e "[$level] $message" ;;
        esac
    fi
}

# 执行命令并记录日志
execute_cmd() {
    local cmd="$1"
    local success_msg="$2"
    local error_msg="$3"
    local retry_count=0
    
    log "INFO" "执行: $cmd"
    
    while [ $retry_count -lt $MAX_RETRIES ]; do
        # 执行命令并捕获输出
        local output
        if output=$(eval "$cmd" 2>&1); then
            log "SUCCESS" "$success_msg"
            return 0
        else
            retry_count=$((retry_count+1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log "INFO" "命令执行失败，重试 ($retry_count/$MAX_RETRIES): $error_msg: $output"
                sleep 2
            else
                log "ERROR" "$error_msg: $output"
                return 1
            fi
        fi
    done
}

# 检查系统要求
check_system() {
    log "INFO" "检查系统要求"
    
    # 检查必要的工具
    local required_tools="curl wget tar gzip dialog"
    local missing_tools=""
    
    for tool in $required_tools; do
        if ! command -v $tool &> /dev/null; then
            missing_tools="$missing_tools $tool"
        fi
    done
    
    if [ ! -z "$missing_tools" ]; then
        log "INFO" "需要安装的工具: $missing_tools"
        
        local retry_count=0
        local install_success=false
        
        while [ $retry_count -lt $MAX_RETRIES ] && [ "$install_success" = false ]; do
            if command -v apt &> /dev/null; then
                if safe_exec apt update && safe_exec apt install -y $missing_tools; then
                    install_success=true
                    log "SUCCESS" "已安装工具: $missing_tools"
                else
                    retry_count=$((retry_count+1))
                    if [ $retry_count -lt $MAX_RETRIES ]; then
                        log "INFO" "工具安装失败，重试 ($retry_count/$MAX_RETRIES)"
                        sleep 2
                    else
                        log "ERROR" "无法安装工具: $missing_tools，已达最大重试次数"
                        exit 1
                    fi
                fi
            elif command -v yum &> /dev/null; then
                if safe_exec yum install -y $missing_tools; then
                    install_success=true
                    log "SUCCESS" "已安装工具: $missing_tools"
                else
                    retry_count=$((retry_count+1))
                    if [ $retry_count -lt $MAX_RETRIES ]; then
                        log "INFO" "工具安装失败，重试 ($retry_count/$MAX_RETRIES)"
                        sleep 2
                    else
                        log "ERROR" "无法安装工具: $missing_tools，已达最大重试次数"
                        exit 1
                    fi
                fi
            elif command -v apk &> /dev/null; then
                if safe_exec apk add $missing_tools; then
                    install_success=true
                    log "SUCCESS" "已安装工具: $missing_tools"
                else
                    retry_count=$((retry_count+1))
                    if [ $retry_count -lt $MAX_RETRIES ]; then
                        log "INFO" "工具安装失败，重试 ($retry_count/$MAX_RETRIES)"
                        sleep 2
                    else
                        log "ERROR" "无法安装工具: $missing_tools，已达最大重试次数"
                        exit 1
                    fi
                fi
            else
                log "ERROR" "无法确定您的包管理器。请手动安装"
                exit 1
            fi
        done
    else
        log "SUCCESS" "所有必要工具已安装"
    fi
    
    # 再次检查dialog是否成功安装，这对于脚本的交互功能非常重要
    if ! command -v dialog &> /dev/null; then
        log "ERROR" "无法安装dialog，将使用文本模式"
        export USE_TEXT_MODE=true
    else
        log "SUCCESS" "Dialog已安装: $(dialog --version 2>&1 | head -n 1)"
        export USE_TEXT_MODE=false
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
    
    # 创建基本子目录
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
    
    # 创建模块子目录
    for subdir in "${MODULE_SUBDIRS[@]}"; do
        local module_dir="$MODULES_DIR/$subdir"
        if [ -d "$module_dir" ]; then
            log "INFO" "模块目录已存在: $module_dir"
        else
            execute_cmd "mkdir -p $module_dir" \
                       "创建模块目录: $module_dir" \
                       "无法创建模块目录: $module_dir"
        fi
    done
    
    log "SUCCESS" "目录结构创建完成"
}

# 检查网络连接
check_connectivity() {
    log "INFO" "检查网络连接"
    
    local connected=false
    local output=""
    local retry_count=0
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$connected" = false ]; do
        # 尝试Cloudflare Workers代理
        if output=$(curl -s --connect-timeout $CONNECTION_TIMEOUT "$CF_PROXY_URL" 2>&1); then
            log "SUCCESS" "成功连接到 Cloudflare Workers 代理"
            connected=true
        # 尝试GitHub直连
        elif output=$(curl -s --connect-timeout $CONNECTION_TIMEOUT "$GITHUB_RAW" 2>&1); then
            log "SUCCESS" "成功连接到 GitHub 直连"
            connected=true
        # 尝试镜像站
        elif output=$(curl -s --connect-timeout $CONNECTION_TIMEOUT "${MIRROR_URL}${GITHUB_RAW}" 2>&1); then
            log "SUCCESS" "成功连接到镜像站"
            connected=true
        else
            retry_count=$((retry_count+1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log "INFO" "网络连接失败，重试 ($retry_count/$MAX_RETRIES)"
                sleep 3
            fi
        fi
    done
    
    if [ "$connected" = false ]; then
        log "ERROR" "无法连接到任何服务器，已达最大重试次数，请检查网络连接: $output"
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
    local retry_count=0
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success" = false ]; do
        # 尝试Cloudflare Workers代理
        if output=$(curl -s -S --connect-timeout $CONNECTION_TIMEOUT -o "$TEMP_DIR/main.sh.tmp" "$CF_PROXY_URL/main.sh" 2>&1) && [ -s "$TEMP_DIR/main.sh.tmp" ]; then
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
        elif output=$(curl -s -S --connect-timeout $CONNECTION_TIMEOUT -o "$TEMP_DIR/main.sh.tmp" "$GITHUB_RAW/main.sh" 2>&1) && [ -s "$TEMP_DIR/main.sh.tmp" ]; then
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
        elif output=$(curl -s -S --connect-timeout $CONNECTION_TIMEOUT -o "$TEMP_DIR/main.sh.tmp" "${MIRROR_URL}${GITHUB_RAW}/main.sh" 2>&1) && [ -s "$TEMP_DIR/main.sh.tmp" ]; then
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
        
        if [ "$download_success" = false ]; then
            retry_count=$((retry_count+1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log "INFO" "下载主脚本失败，重试 ($retry_count/$MAX_RETRIES)"
                sleep 3
            fi
        fi
    done
    
    # 清理临时文件
    rm -f "$TEMP_DIR/main.sh.tmp"
    
    if [ "$download_success" = false ]; then
        log "ERROR" "所有下载源均无法下载主脚本，已达最大重试次数: $output"
        exit 1
    fi
}

# 创建初始模块文件
create_initial_modules() {
    log "INFO" "创建初始模块文件"
    
    # 创建主菜单模块
    for module in "${MODULE_SUBDIRS[@]}"; do
        local menu_file="$MODULES_DIR/$module/${module}_menu.sh"
        
        # 跳过已存在的文件
        if [ -f "$menu_file" ]; then
            log "INFO" "菜单文件已存在: $menu_file"
            continue
        fi
        
        # 创建菜单文件
        cat > "$menu_file" << EOF
#!/bin/bash

# $module 模块菜单
# 此脚本提供 $module 相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="\$(dirname \$(dirname \$(dirname \$(readlink -f \$0))))"
MODULES_DIR="\$INSTALL_DIR/modules"

# 导入共享函数
source "\$INSTALL_DIR/main.sh"

# 显示菜单
show_${module}_menu() {
    local title="$module 管理"
    local menu_items=(
        "1" "功能1 - 描述"
        "2" "功能2 - 描述"
        "3" "功能3 - 描述"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "\$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      \$title 菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) 功能1                      "
            echo "  2) 功能2                      "
            echo "  3) 功能3                      "
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-3]: " choice
        else
            # 使用Dialog显示菜单
            choice=\$(dialog --clear --title "\$title" \\
                --menu "请选择一个选项:" 15 60 4 \\
                "\${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            if [ \$? -ne 0 ]; then
                return
            fi
        fi
        
        case \$choice in
            1) echo "功能1未实现" ;;
            2) echo "功能2未实现" ;;
            3) echo "功能3未实现" ;;
            0) return ;;
            *) 
                if [ "\$USE_TEXT_MODE" = true ]; then
                    echo "无效选择，请重试"
                    sleep 1
                else
                    dialog --title "错误" --msgbox "无效选项: \$choice\\n请重新选择" 8 40
                fi
                ;;
        esac
        
        # 文本模式下，显示按键提示
        if [ "\$USE_TEXT_MODE" = true ]; then
            echo ""
            echo "按Enter键继续..."
            read
        fi
    done
}

# 运行菜单
show_${module}_menu
EOF
        # 设置可执行权限
        chmod +x "$menu_file"
        log "SUCCESS" "创建菜单文件: $menu_file"
    done
    
    log "SUCCESS" "初始模块文件创建完成"
}

# 下载模块
download_modules() {
    log "INFO" "开始下载系统模块"
    
    local download_success=false
    local output=""
    local retry_count=0
    
    # 创建临时目录
    mkdir -p "$TEMP_DIR"
    
    while [ $retry_count -lt $MAX_RETRIES ] && [ "$download_success" = false ]; do
        # 尝试Cloudflare Workers代理
        if output=$(curl -s -S --connect-timeout $CONNECTION_TIMEOUT -o "$TEMP_DIR/modules.tar.gz.tmp" "$CF_PROXY_URL/modules.tar.gz" 2>&1) && [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
            if [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
                mv "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
                if tar -xzf "$TEMP_DIR/modules.tar.gz" -C "$INSTALL_DIR"; then
                    log "SUCCESS" "从Cloudflare Workers下载并解压模块成功"
                    download_success=true
                else
                    log "ERROR" "模块解压失败"
                    rm -f "$TEMP_DIR/modules.tar.gz"
                fi
            else
                log "ERROR" "从Cloudflare Workers下载的模块文件为空"
                rm -f "$TEMP_DIR/modules.tar.gz.tmp"
            fi
        # 尝试GitHub直连
        elif output=$(curl -s -S --connect-timeout $CONNECTION_TIMEOUT -o "$TEMP_DIR/modules.tar.gz.tmp" "$GITHUB_RAW/modules.tar.gz" 2>&1) && [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
            if [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
                mv "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
                if tar -xzf "$TEMP_DIR/modules.tar.gz" -C "$INSTALL_DIR"; then
                    log "SUCCESS" "从GitHub直连下载并解压模块成功"
                    download_success=true
                else
                    log "ERROR" "模块解压失败"
                    rm -f "$TEMP_DIR/modules.tar.gz"
                fi
            else
                log "ERROR" "从GitHub直连下载的模块文件为空"
                rm -f "$TEMP_DIR/modules.tar.gz.tmp"
            fi
        # 尝试镜像站
        elif output=$(curl -s -S --connect-timeout $CONNECTION_TIMEOUT -o "$TEMP_DIR/modules.tar.gz.tmp" "${MIRROR_URL}${GITHUB_RAW}/modules.tar.gz" 2>&1) && [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
            if [ -s "$TEMP_DIR/modules.tar.gz.tmp" ]; then
                mv "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
                if tar -xzf "$TEMP_DIR/modules.tar.gz" -C "$INSTALL_DIR"; then
                    log "SUCCESS" "从镜像站下载并解压模块成功"
                    download_success=true
                else
                    log "ERROR" "模块解压失败"
                    rm -f "$TEMP_DIR/modules.tar.gz"
                fi
            else
                log "ERROR" "从镜像站下载的模块文件为空"
                rm -f "$TEMP_DIR/modules.tar.gz.tmp"
            fi
        fi
        
        if [ "$download_success" = false ]; then
            retry_count=$((retry_count+1))
            if [ $retry_count -lt $MAX_RETRIES ]; then
                log "INFO" "下载系统模块失败，重试 ($retry_count/$MAX_RETRIES)"
                sleep 3
            fi
        fi
    done
    
    # 清理临时文件
    rm -f "$TEMP_DIR/modules.tar.gz.tmp" "$TEMP_DIR/modules.tar.gz"
    
    if [ "$download_success" = false ]; then
        log "INFO" "下载远程模块失败，创建本地初始模块"
        create_initial_modules
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
        local retry_count=0
        local version_success=false
        local latest_version="1.0"
        
        while [ $retry_count -lt $MAX_RETRIES ] && [ "$version_success" = false ]; do
            if latest_version_tmp=$(curl -s --connect-timeout $CONNECTION_TIMEOUT "$CF_PROXY_URL/version.txt" 2>/dev/null) && [ -n "$latest_version_tmp" ]; then
                latest_version="$latest_version_tmp"
                version_success=true
            elif latest_version_tmp=$(curl -s --connect-timeout $CONNECTION_TIMEOUT "$GITHUB_RAW/version.txt" 2>/dev/null) && [ -n "$latest_version_tmp" ]; then
                latest_version="$latest_version_tmp"
                version_success=true
            elif latest_version_tmp=$(curl -s --connect-timeout $CONNECTION_TIMEOUT "${MIRROR_URL}${GITHUB_RAW}/version.txt" 2>/dev/null) && [ -n "$latest_version_tmp" ]; then
                latest_version="$latest_version_tmp"
                version_success=true
            else
                retry_count=$((retry_count+1))
                if [ $retry_count -lt $MAX_RETRIES ]; then
                    log "INFO" "获取版本号失败，重试 ($retry_count/$MAX_RETRIES)"
                    sleep 2
                fi
            fi
        done
        
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
    
    log "SUCCESS" "ServerMaster 安装完成！当前版本: $(cat $INSTALL_DIR/version.txt)"
    log "SUCCESS" "您可以通过执行 'sm' 命令启动系统"
    
    echo ""
    echo "====================================================="
    echo "  ServerMaster 安装完成！"
    echo "  当前版本: $(cat $INSTALL_DIR/version.txt)"
    echo "  运行命令: sm"
    echo "====================================================="
    echo ""
    
    # 自动启动main.sh
    log "INFO" "正在启动 ServerMaster..."
    if [ -f "$INSTALL_DIR/main.sh" ] && [ -x "$INSTALL_DIR/main.sh" ]; then
        exec "$INSTALL_DIR/main.sh"
    else
        log "ERROR" "无法自动启动ServerMaster，请手动执行 'sm' 命令"
    fi
}

# 主函数
main() {
    clear
    echo "====================================================="
    echo "          ServerMaster 安装程序启动                  "
    echo "====================================================="
    echo ""
    
    # 记录欢迎消息
    log "INFO" "欢迎使用 ServerMaster 安装向导！"
    log "INFO" "正在准备安装..."
    
    # 显示安装步骤
    log "INFO" "安装将执行以下步骤:"
    log "INFO" "1. 检查系统要求"
    log "INFO" "2. 创建必要目录"
    log "INFO" "3. 检查网络连接"
    log "INFO" "4. 下载主脚本"
    log "INFO" "5. 创建模块结构"
    log "INFO" "6. 创建系统命令"
    log "INFO" "7. 完成安装"
    echo ""
    
    # 执行安装步骤
    check_system
    create_directories
    check_connectivity
    download_main_script
    
    # 如果下载模块失败，则创建本地初始模块
    if ! download_modules; then
        create_initial_modules
    fi
    
    create_command
    
    # 完成安装
    finalize
}

# 检查是否为root用户，无需root直接给出明确警告
if [ "$(id -u)" -ne 0 ]; then
    echo "[\033[31mERROR\033[0m] 此脚本需要root权限运行！"
    echo "请使用root用户直接运行此脚本，或使用sudo命令提升权限。"
    exit 1
fi

# 执行主函数
main