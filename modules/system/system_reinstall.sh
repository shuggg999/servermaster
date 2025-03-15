#!/bin/bash

# System Reinstall (DD) Module
# For ServerMaster script

# Check if colors are passed from the main script
if [ -z "$GREEN" ]; then
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
fi

# 检查是否是 root 用户
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 此脚本必须以 root 用户身份运行!${NC}"
        exit 1
    fi
}

# 检查安装依赖
install_dependency() {
    echo -e "${YELLOW}正在安装必要的依赖...${NC}"
    if command -v apt-get &>/dev/null; then
        apt-get update -y
        apt-get install -y wget curl
    elif command -v yum &>/dev/null; then
        yum install -y wget curl
    elif command -v dnf &>/dev/null; then
        dnf install -y wget curl
    elif command -v zypper &>/dev/null; then
        zypper install -y wget curl
    elif command -v apk &>/dev/null; then
        apk add wget curl
    else
        echo -e "${RED}无法安装依赖，不支持的包管理器.${NC}"
        exit 1
    fi
    echo -e "${GREEN}依赖安装完成.${NC}"
}

# 使用 MollyLau 的 DD 脚本
dd_mollylau() {
    echo -e "${CYAN}准备使用 MollyLau 的 DD 脚本...${NC}"
    wget --no-check-certificate -qO InstallNET.sh "https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh
}

#