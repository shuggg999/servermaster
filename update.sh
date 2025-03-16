#!/bin/bash

# ServerMaster - Update Script
# This script updates the ServerMaster system to the latest version

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

# Base directories
BASE_DIR="/usr/local/servermaster"
MODULES_DIR="$BASE_DIR/modules"
CONFIG_DIR="$BASE_DIR/config"
LOGS_DIR="$BASE_DIR/logs"
TEMP_DIR="/tmp/servermaster"

# GitHub repository information
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# Create temp directory if it doesn't exist
mkdir -p "$TEMP_DIR"

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
    echo -e "                               ${CYAN}「 ServerMaster 更新程序 」${NC}"
    echo -e "                               ${BLUE}===============================${NC}"
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
    echo ""
}

# Check connectivity and determine the best URL to use
check_connectivity() {
    echo -e "${CYAN}[1/5] 检查网络连接...${NC}"
    
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

# Check version
check_version() {
    echo -e "${CYAN}[2/5] 检查版本信息...${NC}"
    
    # 获取当前版本 - 处理可能的BOM和特殊字符
    if [ -f "$BASE_DIR/version.txt" ]; then
        # 使用tr命令移除不可见字符，并确保只保留有效的版本号字符
        CURRENT_VERSION=$(tr -cd '0-9\.\n' < "$BASE_DIR/version.txt")
    else
        CURRENT_VERSION="未知"
    fi
    
    # 获取最新版本 - 同样处理可能的特殊字符
    LATEST_VERSION_RAW=$(curl -s "$BASE_URL/version.txt")
    LATEST_VERSION=$(echo "$LATEST_VERSION_RAW" | tr -cd '0-9\.\n')
    
    echo -e "    ${CYAN}   - 当前版本: ${YELLOW}$CURRENT_VERSION${NC}"
    echo -e "    ${CYAN}   - 最新版本: ${GREEN}$LATEST_VERSION${NC}"
    
    if [ "$CURRENT_VERSION" = "$LATEST_VERSION" ]; then
        echo -e "    ${GREEN}✓${NC} 已经是最新版本，无需更新"
        exit 0
    fi
    
    echo -e "    ${GREEN}✓${NC} 发现新版本，准备更新"
}

# Backup configuration
backup_config() {
    echo -e "${CYAN}[3/5] 备份配置文件...${NC}"
    
    if [ -d "$CONFIG_DIR" ]; then
        echo -e "    ${CYAN}   - 备份配置目录...${NC}"
        cp -r "$CONFIG_DIR" "$TEMP_DIR/config_backup"
        echo -e "    ${GREEN}✓${NC} 配置备份完成"
    else
        echo -e "    ${YELLOW}!${NC} 未找到配置目录，跳过备份"
    fi
}

# Download and update files
update_files() {
    echo -e "${CYAN}[4/5] 下载并更新文件...${NC}"
    
    # 下载主脚本
    echo -e "    ${CYAN}   - 下载主脚本...${NC}"
    if curl -s -o "$TEMP_DIR/main.sh.new" "$BASE_URL/main.sh"; then
        echo -e "    ${GREEN}✓${NC} 主脚本下载成功"
    else
        echo -e "    ${RED}✗${NC} 主脚本下载失败!"
        exit 1
    fi
    
    # 下载模块包
    echo -e "    ${CYAN}   - 下载模块包...${NC}"
    if curl -s -o "$TEMP_DIR/modules.tar.gz" "$BASE_URL/modules.tar.gz"; then
        echo -e "    ${GREEN}✓${NC} 模块包下载成功"
    else
        echo -e "    ${RED}✗${NC} 模块包下载失败!"
        exit 1
    fi
    
    # 备份当前主脚本
    if [ -f "$BASE_DIR/main.sh" ]; then
        cp "$BASE_DIR/main.sh" "$TEMP_DIR/main.sh.bak"
    fi
    
    # 更新主脚本
    echo -e "    ${CYAN}   - 更新主脚本...${NC}"
    cp "$TEMP_DIR/main.sh.new" "$BASE_DIR/main.sh"
    chmod +x "$BASE_DIR/main.sh"
    
    # 清空模块目录
    echo -e "    ${CYAN}   - 清理旧模块...${NC}"
    find "$MODULES_DIR" -type f -delete
    
    # 解压新模块
    echo -e "    ${CYAN}   - 解压新模块...${NC}"
    tar -xzf "$TEMP_DIR/modules.tar.gz" -C "$BASE_DIR"
    
    # 恢复配置
    if [ -d "$TEMP_DIR/config_backup" ]; then
        echo -e "    ${CYAN}   - 恢复配置文件...${NC}"
        cp -r "$TEMP_DIR/config_backup"/* "$CONFIG_DIR/"
    fi
    
    # 更新版本文件 - 确保使用UTF-8编码，不带BOM
    echo -e "    ${CYAN}   - 更新版本信息...${NC}"
    echo -n "$LATEST_VERSION" > "$BASE_DIR/version.txt"
    
    echo -e "    ${GREEN}✓${NC} 文件更新完成"
}

# Finalize update
finalize() {
    echo -e "${CYAN}[5/5] 完成更新...${NC}"
    
    # 设置权限
    echo -e "    ${CYAN}   - 设置文件权限...${NC}"
    chmod -R 755 "$BASE_DIR"
    
    # 清理临时文件
    echo -e "    ${CYAN}   - 清理临时文件...${NC}"
    rm -f "$TEMP_DIR/main.sh.new"
    rm -f "$TEMP_DIR/modules.tar.gz"
    
    echo -e "\n${GREEN}=========================================${NC}"
    echo -e "${GREEN}       ServerMaster 更新成功!      ${NC}"
    echo -e "${GREEN}=========================================${NC}"
    echo -e "${CYAN}版本:${NC} $LATEST_VERSION"
    echo -e "${CYAN}安装目录:${NC} $BASE_DIR"
    echo -e "${CYAN}启动命令:${NC} sm"
    echo -e ""
    
    echo -e "${GREEN}✓${NC} 更新完成!"
}

# Main function
main() {
    show_banner
    check_connectivity
    check_version
    backup_config
    update_files
    finalize
}

# Start update process
main 