#!/bin/bash

# ServerMaster Installation Script
# This script installs the ServerMaster system with all its modules

# Color definitions
GREEN='\033[0;32m'
BRIGHT_GREEN='\033[1;32m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Script version and URLs
VERSION="1.0"
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
# 添加Cloudflare Workers代理URL
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# Installation paths
INSTALL_DIR="/usr/local/servermaster"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"
BIN_DIR="/usr/local/bin"

# Display banner
show_banner() {
    clear
    echo -e "${CYAN}"
    echo "███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗     ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ "
    echo "██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗"
    echo "███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝"
    echo "╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗"
    echo "███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║"
    echo "╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    echo -e "${NC}"
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo -e "                               ${CYAN}「 ServerMaster 安装程序 v$VERSION 」${NC}"
    echo -e "                               ${BLUE}===============================${NC}"
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo ""
}

# Check system requirements
check_system() {
    echo -e "\n${CYAN}[步骤 1/7] 检查系统环境...${NC}"
    
    # Check OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        echo -e "    ${GREEN}✓${NC} 操作系统: $OS_NAME $OS_VERSION"
    else
        echo -e "    ${RED}✗${NC} 无法确定操作系统类型!"
        exit 1
    fi
    
    # Check if root
    if [ "$EUID" -ne 0 ]; then
        echo -e "    ${RED}✗${NC} 请使用 root 用户运行此脚本!"
        exit 1
    else
        echo -e "    ${GREEN}✓${NC} 权限检查: Root 用户"
    fi
    
    # Check required tools
    local required_tools=("curl" "wget" "tar" "gzip")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v $tool &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        echo -e "    ${YELLOW}!${NC} 缺少必要工具: ${missing_tools[*]}"
        echo -e "    ${CYAN}[*] 正在安装必要工具...${NC}"
        
        if [ -f /etc/debian_version ]; then
            echo -e "    ${CYAN}   - 使用 apt 安装工具...${NC}"
            apt update -y > /dev/null 2>&1
            apt install -y curl wget tar gzip > /dev/null 2>&1
        elif [ -f /etc/redhat-release ]; then
            echo -e "    ${CYAN}   - 使用 yum 安装工具...${NC}"
            yum install -y curl wget tar gzip > /dev/null 2>&1
        elif [ -f /etc/alpine-release ]; then
            echo -e "    ${CYAN}   - 使用 apk 安装工具...${NC}"
            apk add curl wget tar gzip > /dev/null 2>&1
        else
            echo -e "    ${RED}✗${NC} 无法在当前系统上安装必要工具!"
            exit 1
        fi
        echo -e "    ${GREEN}✓${NC} 必要工具已安装"
    else
        echo -e "    ${GREEN}✓${NC} 所有必要工具已安装"
    fi
    echo -e "    ${GREEN}✓${NC} 系统环境检查完成"
}

# Create necessary directories
create_directories() {
    echo -e "\n${CYAN}[步骤 2/7] 创建必要目录...${NC}"
    
    echo -e "    ${CYAN}   - 创建主目录: $INSTALL_DIR${NC}"
    mkdir -p "$INSTALL_DIR"
    echo -e "    ${CYAN}   - 创建模块目录: $MODULES_DIR${NC}"
    mkdir -p "$MODULES_DIR"
    echo -e "    ${CYAN}   - 创建配置目录: $CONFIG_DIR${NC}"
    mkdir -p "$CONFIG_DIR"
    
    # Create module structure
    echo -e "    ${CYAN}   - 创建模块子目录结构...${NC}"
    mkdir -p "$MODULES_DIR/system"
    mkdir -p "$MODULES_DIR/network"
    mkdir -p "$MODULES_DIR/network/vpn"
    mkdir -p "$MODULES_DIR/network/proxy"
    mkdir -p "$MODULES_DIR/application"
    mkdir -p "$MODULES_DIR/advanced"
    mkdir -p "$MODULES_DIR/special"
    
    echo -e "    ${GREEN}✓${NC} 目录结构创建完成"
}

# Check connectivity and determine the best URL to use
check_connectivity() {
    echo -e "\n${CYAN}[步骤 3/7] 检查网络连接...${NC}"
    
    # 首先尝试Cloudflare Workers代理
    echo -e "    ${CYAN}   - 测试 Cloudflare Workers 代理...${NC}"
    if curl -s --head --fail "$CF_PROXY_URL/version.txt" > /dev/null; then
        echo -e "    ${GREEN}✓${NC} Cloudflare Workers 代理连接正常"
        USE_CF_PROXY=true
        USE_MIRROR=false
    else
        # 如果CF代理失败，尝试直接GitHub连接
        echo -e "    ${YELLOW}!${NC} Cloudflare Workers 代理连接受限，尝试直连GitHub..."
        
        echo -e "    ${CYAN}   - 测试 GitHub 直连...${NC}"
        if curl -s --head --fail "$GITHUB_RAW/version.txt" > /dev/null; then
            echo -e "    ${GREEN}✓${NC} GitHub 连接正常"
            USE_CF_PROXY=false
            USE_MIRROR=false
        else
            echo -e "    ${YELLOW}!${NC} GitHub 连接受限，尝试使用镜像站..."
            
            # 最后尝试镜像站
            echo -e "    ${CYAN}   - 测试镜像站连接...${NC}"
            if curl -s --head --fail "${MIRROR_URL}${GITHUB_RAW}/version.txt" > /dev/null; then
                echo -e "    ${GREEN}✓${NC} 镜像站连接正常"
                USE_CF_PROXY=false
                USE_MIRROR=true
            else
                echo -e "    ${RED}✗${NC} 无法连接到 GitHub、Cloudflare Workers 代理或镜像站!"
                exit 1
            fi
        fi
    fi
    
    # Set the base URL based on connectivity test
    if [ "$USE_CF_PROXY" = true ]; then
        BASE_URL="${CF_PROXY_URL}"
    elif [ "$USE_MIRROR" = true ]; then
        BASE_URL="${MIRROR_URL}${GITHUB_RAW}"
    else
        BASE_URL="${GITHUB_RAW}"
    fi
    
    echo -e "    ${GREEN}✓${NC} 网络连接检查完成，使用源: $BASE_URL"
}

# Download main script
download_main_script() {
    echo -e "\n${CYAN}[步骤 4/7] 下载主脚本...${NC}"
    
    echo -e "    ${CYAN}   - 从 $BASE_URL 下载 main.sh...${NC}"
    if curl -s -o "$INSTALL_DIR/main.sh" "$BASE_URL/main.sh"; then
        chmod +x "$INSTALL_DIR/main.sh"
        echo -e "    ${GREEN}✓${NC} 主脚本下载成功"
        echo -e "    ${CYAN}   - 已设置可执行权限${NC}"
    else
        echo -e "    ${RED}✗${NC} 主脚本下载失败!"
        exit 1
    fi
}

# Download modules
download_modules() {
    echo -e "\n${CYAN}[步骤 5/7] 下载功能模块...${NC}"
    
    local modules_url="$BASE_URL/modules.tar.gz"
    local modules_file="/tmp/servermaster_modules.tar.gz"
    
    echo -e "    ${CYAN}   - 尝试下载完整模块包: $modules_url${NC}"
    if curl -s -o "$modules_file" "$modules_url"; then
        echo -e "    ${GREEN}✓${NC} 模块打包文件下载完成"
        
        echo -e "    ${CYAN}   - 解压模块文件到 $MODULES_DIR...${NC}"
        if tar -xzf "$modules_file" -C "$MODULES_DIR"; then
            echo -e "    ${GREEN}✓${NC} 模块解压完成"
            echo -e "    ${CYAN}   - 清理临时文件...${NC}"
            rm -f "$modules_file"
        else
            echo -e "    ${RED}✗${NC} 模块解压失败!"
            exit 1
        fi
    else
        echo -e "    ${RED}✗${NC} 模块打包文件下载失败!"
        
        # Fallback: download individual modules
        echo -e "    ${YELLOW}!${NC} 尝试逐个下载核心模块..."
        
        # List of core modules to download
        local core_modules=(
            "system/system_info.sh"
            "system/system_update.sh"
            "system/system_clean.sh"
            "network/bbr_manager.sh"
            "application/docker_manager.sh"
            "special/workspace.sh"
        )
        
        local module_count=${#core_modules[@]}
        local current=0
        
        for module in "${core_modules[@]}"; do
            current=$((current + 1))
            local module_dir=$(dirname "$MODULES_DIR/$module")
            mkdir -p "$module_dir"
            
            echo -e "    ${CYAN}   - 下载模块 [$current/$module_count]: $module${NC}"
            if curl -s -o "$MODULES_DIR/$module" "$BASE_URL/modules/$module"; then
                chmod +x "$MODULES_DIR/$module"
                echo -e "    ${GREEN}✓${NC} 模块 $module 下载成功"
            else
                echo -e "    ${RED}✗${NC} 模块 $module 下载失败"
            fi
        done
        
        echo -e "    ${GREEN}✓${NC} 核心模块下载完成"
    fi
}

# Create command link
create_command() {
    echo -e "\n${CYAN}[步骤 6/7] 创建命令链接...${NC}"
    
    # Create sm command
    echo -e "    ${CYAN}   - 创建 sm 命令脚本...${NC}"
    echo '#!/bin/bash' > "$BIN_DIR/sm"
    echo "exec $INSTALL_DIR/main.sh \"\$@\"" >> "$BIN_DIR/sm"
    chmod +x "$BIN_DIR/sm"
    echo -e "    ${GREEN}✓${NC} sm 命令创建完成"
    
    # Add autocompletion if possible
    if [ -d "/etc/bash_completion.d" ]; then
        echo -e "    ${CYAN}   - 设置命令自动补全...${NC}"
        curl -s -o "/etc/bash_completion.d/sm" "$BASE_URL/completion/sm"
        chmod +x "/etc/bash_completion.d/sm"
        echo -e "    ${GREEN}✓${NC} 命令自动补全设置完成"
    else
        echo -e "    ${YELLOW}!${NC} 未找到bash自动补全目录，跳过自动补全设置"
    fi
    
    echo -e "    ${GREEN}✓${NC} 命令链接创建完成，现在可以使用 'sm' 命令启动系统"
}

# Finalize installation
finalize() {
    echo -e "\n${CYAN}[步骤 7/7] 完成安装...${NC}"
    
    # 获取最新版本号 - 同样处理可能的特殊字符
    local latest_version_raw=$(curl -s "$CF_PROXY_URL/version.txt" || 
                          curl -s "$GITHUB_RAW/version.txt" || 
                          curl -s "${MIRROR_URL}${GITHUB_RAW}/version.txt" || 
                          echo "$VERSION")
    
    # 清理版本号，确保只包含有效字符
    local latest_version=$(echo "$latest_version_raw" | tr -cd '0-9\.\n')
    
    # Create version file - 确保使用UTF-8编码，不带BOM
    echo -e "    ${CYAN}   - 创建版本信息文件...${NC}"
    echo -n "$latest_version" > "$INSTALL_DIR/version.txt"
    
    # Set proper permissions
    echo -e "    ${CYAN}   - 设置权限...${NC}"
    chmod -R 755 "$INSTALL_DIR"
    
    echo -e "    ${GREEN}✓${NC} 安装完成!"
    
    echo -e "\n${GREEN}=========================================${NC}"
    echo -e "${GREEN}       ServerMaster 安装成功!      ${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${CYAN}版本:${NC} $latest_version"
    echo -e "${CYAN}安装目录:${NC} $INSTALL_DIR"
    echo -e "${CYAN}启动命令:${NC} sm"
    echo -e ""
    
    # 自动启动ServerMaster，无需用户确认
    echo -e "${CYAN}正在启动 ServerMaster...${NC}"
    exec "$INSTALL_DIR/main.sh"
}

# 显示安装进度概览
show_installation_steps() {
    echo -e "\n${YELLOW}安装将执行以下步骤:${NC}"
    echo -e " ${CYAN}[1]${NC} 检查系统环境"
    echo -e " ${CYAN}[2]${NC} 创建必要目录"
    echo -e " ${CYAN}[3]${NC} 检查网络连接"
    echo -e " ${CYAN}[4]${NC} 下载主脚本"
    echo -e " ${CYAN}[5]${NC} 下载功能模块"
    echo -e " ${CYAN}[6]${NC} 创建命令链接"
    echo -e " ${CYAN}[7]${NC} 完成安装"
    echo -e "\n${YELLOW}安装即将开始...${NC}"
    sleep 1
}

# 检查是否已安装并比较版本
check_installed_version() {
    if [ -f "$INSTALL_DIR/version.txt" ]; then
        # 使用tr命令移除不可见字符，并确保只保留有效的版本号字符
        local installed_version=$(tr -cd '0-9\.\n' < "$INSTALL_DIR/version.txt")
        
        # 获取最新版本号 - 同样处理可能的特殊字符
        local latest_version_raw=$(curl -s "$CF_PROXY_URL/version.txt" || 
                              curl -s "$GITHUB_RAW/version.txt" || 
                              curl -s "${MIRROR_URL}${GITHUB_RAW}/version.txt" || 
                              echo "$VERSION")
        
        # 清理版本号，确保只包含有效字符
        local latest_version=$(echo "$latest_version_raw" | tr -cd '0-9\.\n')
        
        echo -e "    ${CYAN}   - 检查版本信息...${NC}"
        echo -e "    ${CYAN}   - 已安装版本: ${YELLOW}$installed_version${NC}"
        echo -e "    ${CYAN}   - 最新版本: ${GREEN}$latest_version${NC}"
        
        if [ "$installed_version" != "$latest_version" ]; then
            echo -e "    ${YELLOW}!${NC} 发现新版本! 是否更新? (y/n)"
            read -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                echo -e "    ${CYAN}   - 准备更新系统...${NC}"
                # 备份配置
                if [ -d "$CONFIG_DIR" ]; then
                    echo -e "    ${CYAN}   - 备份配置文件...${NC}"
                    cp -r "$CONFIG_DIR" "/tmp/servermaster_config_backup"
                fi
                
                # 删除旧文件
                echo -e "    ${CYAN}   - 删除旧文件...${NC}"
                rm -rf "$INSTALL_DIR"
                
                # 继续安装流程，会下载最新版本
                return 0
            else
                echo -e "    ${CYAN}   - 继续使用当前版本...${NC}"
                exec "$INSTALL_DIR/main.sh"
                exit 0
            fi
        else
            echo -e "    ${GREEN}✓${NC} 已是最新版本!"
            echo -e "    ${CYAN}   - 是否重新安装? (y/n)${NC}"
            read -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                # 删除旧文件
                echo -e "    ${CYAN}   - 删除旧文件...${NC}"
                rm -rf "$INSTALL_DIR"
                return 0
            else
                echo -e "    ${CYAN}   - 启动已安装的系统...${NC}"
                exec "$INSTALL_DIR/main.sh"
                exit 0
            fi
        fi
    fi
    
    # 未安装或用户选择重新安装
    return 0
}

# Main installation process
main() {
    show_banner
    show_installation_steps
    check_system
    check_installed_version
    create_directories
    check_connectivity
    download_main_script
    download_modules
    create_command
    finalize
}

# Start installation
main