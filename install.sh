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
GITHUB_REPO="https://github.com/servermaster/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/servermaster/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"

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
    echo -e "${CYAN}[*] 检查系统环境...${NC}"
    
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
            apt update -y > /dev/null 2>&1
            apt install -y curl wget tar gzip > /dev/null 2>&1
        elif [ -f /etc/redhat-release ]; then
            yum install -y curl wget tar gzip > /dev/null 2>&1
        elif [ -f /etc/alpine-release ]; then
            apk add curl wget tar gzip > /dev/null 2>&1
        else
            echo -e "    ${RED}✗${NC} 无法在当前系统上安装必要工具!"
            exit 1
        fi
        echo -e "    ${GREEN}✓${NC} 必要工具已安装"
    else
        echo -e "    ${GREEN}✓${NC} 所有必要工具已安装"
    fi
}

# Create necessary directories
create_directories() {
    echo -e "${CYAN}[*] 创建必要目录...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$MODULES_DIR"
    mkdir -p "$CONFIG_DIR"
    
    # Create module structure
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
    echo -e "${CYAN}[*] 检查网络连接...${NC}"
    
    # Test direct GitHub connection
    if curl -s --head --fail "$GITHUB_RAW/version.txt" > /dev/null; then
        echo -e "    ${GREEN}✓${NC} GitHub 连接正常"
        USE_MIRROR=false
    else
        echo -e "    ${YELLOW}!${NC} GitHub 连接受限，尝试使用镜像站..."
        
        # Test mirror connection
        if curl -s --head --fail "${MIRROR_URL}${GITHUB_RAW}/version.txt" > /dev/null; then
            echo -e "    ${GREEN}✓${NC} 镜像站连接正常"
            USE_MIRROR=true
        else
            echo -e "    ${RED}✗${NC} 无法连接到 GitHub 或镜像站!"
            exit 1
        fi
    fi
    
    # Set the base URL based on connectivity test
    if [ "$USE_MIRROR" = true ]; then
        BASE_URL="${MIRROR_URL}${GITHUB_RAW}"
    else
        BASE_URL="${GITHUB_RAW}"
    fi
    
    echo -e "    ${GREEN}✓${NC} 使用源: $BASE_URL"
}

# Download main script
download_main_script() {
    echo -e "${CYAN}[*] 下载主脚本...${NC}"
    
    if curl -s -o "$INSTALL_DIR/main.sh" "$BASE_URL/main.sh"; then
        chmod +x "$INSTALL_DIR/main.sh"
        echo -e "    ${GREEN}✓${NC} 主脚本下载完成"
    else
        echo -e "    ${RED}✗${NC} 主脚本下载失败!"
        exit 1
    fi
}

# Download modules
download_modules() {
    echo -e "${CYAN}[*] 下载功能模块...${NC}"
    
    local modules_url="$BASE_URL/modules.tar.gz"
    local modules_file="/tmp/servermaster_modules.tar.gz"
    
    if curl -s -o "$modules_file" "$modules_url"; then
        echo -e "    ${GREEN}✓${NC} 模块打包文件下载完成"
        
        echo -e "${CYAN}[*] 解压模块文件...${NC}"
        if tar -xzf "$modules_file" -C "$MODULES_DIR"; then
            echo -e "    ${GREEN}✓${NC} 模块解压完成"
            rm -f "$modules_file"
        else
            echo -e "    ${RED}✗${NC} 模块解压失败!"
            exit 1
        fi
    else
        echo -e "    ${RED}✗${NC} 模块打包文件下载失败!"
        
        # Fallback: download individual modules
        echo -e "    ${YELLOW}!${NC} 尝试逐个下载模块..."
        
        # List of core modules to download
        local core_modules=(
            "system/system_info.sh"
            "system/system_update.sh"
            "system/system_clean.sh"
            "network/bbr_manager.sh"
            "application/docker_manager.sh"
            "special/workspace.sh"
        )
        
        for module in "${core_modules[@]}"; do
            local module_dir=$(dirname "$MODULES_DIR/$module")
            mkdir -p "$module_dir"
            
            if curl -s -o "$MODULES_DIR/$module" "$BASE_URL/modules/$module"; then
                chmod +x "$MODULES_DIR/$module"
                echo -e "    ${GREEN}✓${NC} 已下载模块: $module"
            else
                echo -e "    ${RED}✗${NC} 下载失败: $module"
            fi
        done
    fi
}

# Create command link
create_command() {
    echo -e "${CYAN}[*] 创建命令链接...${NC}"
    
    # Create sm command
    echo '#!/bin/bash' > "$BIN_DIR/sm"
    echo "exec $INSTALL_DIR/main.sh \"\$@\"" >> "$BIN_DIR/sm"
    chmod +x "$BIN_DIR/sm"
    
    # Add autocompletion if possible
    if [ -d "/etc/bash_completion.d" ]; then
        curl -s -o "/etc/bash_completion.d/sm" "$BASE_URL/completion/sm"
        chmod +x "/etc/bash_completion.d/sm"
    fi
    
    echo -e "    ${GREEN}✓${NC} 命令链接创建完成，现在可以使用 'sm' 命令启动系统"
}

# Finalize installation
finalize() {
    echo -e "${CYAN}[*] 完成安装...${NC}"
    
    # Create version file
    echo "$VERSION" > "$INSTALL_DIR/version.txt"
    
    # Set proper permissions
    chmod -R 755 "$INSTALL_DIR"
    
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${GREEN}       ServerMaster 安装成功!      ${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${CYAN}版本:${NC} $VERSION"
    echo -e "${CYAN}安装目录:${NC} $INSTALL_DIR"
    echo -e "${CYAN}启动命令:${NC} sm"
    echo -e ""
    echo -e "${YELLOW}是否立即启动 ServerMaster? (y/n)${NC}"
    read -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        exec "$INSTALL_DIR/main.sh"
    else
        echo -e "${CYAN}您可以稍后使用 'sm' 命令启动系统。${NC}"
    fi
}

# Main installation process
main() {
    show_banner
    check_system
    create_directories
    check_connectivity
    download_main_script
    download_modules
    create_command
    finalize
}

# Start installation
main