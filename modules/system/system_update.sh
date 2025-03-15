#!/bin/bash

# System Update Module
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

# Function to fix dpkg interruption issues
fix_dpkg() {
    echo -e "${YELLOW}正在修复可能的 dpkg 问题...${NC}"
    pkill -9 -f 'apt|dpkg' 2>/dev/null
    rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock 2>/dev/null
    DEBIAN_FRONTEND=noninteractive dpkg --configure -a 2>/dev/null
    echo -e "${GREEN}修复完成.${NC}"
}

# Function to update system
update_system() {
    echo -e "${CYAN}检测系统类型...${NC}"
    
    # Detect package manager
    if command -v apt-get &>/dev/null; then
        echo -e "${GREEN}检测到 Debian/Ubuntu 系统，使用 apt 包管理器${NC}"
        fix_dpkg
        echo -e "\n${YELLOW}正在更新软件源信息...${NC}"
        apt-get update -y
        echo -e "\n${YELLOW}正在升级系统，这可能需要一些时间...${NC}"
        DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        echo -e "\n${YELLOW}正在进行完整升级...${NC}"
        DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
        echo -e "\n${GREEN}Debian/Ubuntu 系统更新完成！${NC}"
    elif command -v dnf &>/dev/null; then
        echo -e "${GREEN}检测到 Fedora/RHEL 8+ 系统，使用 dnf 包管理器${NC}"
        echo -e "\n${YELLOW}正在更新系统，这可能需要一些时间...${NC}"
        dnf update -y
        echo -e "\n${GREEN}Fedora/RHEL 系统更新完成！${NC}"
    elif command -v yum &>/dev/null; then
        echo -e "${GREEN}检测到 CentOS/RHEL 系统，使用 yum 包管理器${NC}"
        echo -e "\n${YELLOW}正在更新系统，这可能需要一些时间...${NC}"
        yum update -y
        echo -e "\n${GREEN}CentOS/RHEL 系统更新完成！${NC}"
    elif command -v pacman &>/dev/null; then
        echo -e "${GREEN}检测到 Arch Linux 系统，使用 pacman 包管理器${NC}"
        echo -e "\n${YELLOW}正在更新系统，这可能需要一些时间...${NC}"
        pacman -Syu --noconfirm
        echo -e "\n${GREEN}Arch Linux 系统更新完成！${NC}"
    elif command -v zypper &>/dev/null; then
        echo -e "${GREEN}检测到 openSUSE 系统，使用 zypper 包管理器${NC}"
        echo -e "\n${YELLOW}正在更新系统，这可能需要一些时间...${NC}"
        zypper update -y
        echo -e "\n${GREEN}openSUSE 系统更新完成！${NC}"
    elif command -v apk &>/dev/null; then
        echo -e "${GREEN}检测到 Alpine Linux 系统，使用 apk 包管理器${NC}"
        echo -e "\n${YELLOW}正在更新系统，这可能需要一些时间...${NC}"
        apk update && apk upgrade
        echo -e "\n${GREEN}Alpine Linux 系统更新完成！${NC}"
    else
        echo -e "${RED}无法识别的系统！不支持自动更新。${NC}"
        echo -e "${YELLOW}支持的系统包括: Debian, Ubuntu, CentOS, Fedora, RHEL, Arch Linux, openSUSE, Alpine${NC}"
        exit 1
    fi
}

# Function to check for reboot requirement
check_reboot_required() {
    echo -e "\n${CYAN}检查是否需要重启...${NC}"
    
    if [ -f /var/run/reboot-required ] || [ -f /var/run/reboot-required.pkgs ]; then
        echo -e "${YELLOW}系统更新完成后需要重启才能完全生效.${NC}"
        
        while true; do
            echo -e "${CYAN}是否现在重启系统? (y/n):${NC} "
            read -r reboot_choice
            
            case $reboot_choice in
                [Yy])
                    echo -e "${GREEN}系统将在5秒后重启...${NC}"
                    sleep 5
                    reboot
                    ;;
                [Nn])
                    echo -e "${YELLOW}请记得稍后手动重启系统.${NC}"
                    break
                    ;;
                *)
                    echo -e "${RED}无效的选择，请输入 'y' 或 'n'.${NC}"
                    ;;
            esac
        done
    else
        echo -e "${GREEN}系统无需重启.${NC}"
    fi
}

# Clear the screen
clear

# Show header
echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
echo -e "                               ${CYAN}${BOLD}「 系统更新 」${NC}"
echo -e "                               ${BLUE}===============================${NC}"
echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
echo ""

echo -e "${YELLOW}系统更新将执行以下操作：${NC}"
echo -e "  ${GREEN}•${NC} 更新软件源"
echo -e "  ${GREEN}•${NC} 升级已安装的软件包"
echo -e "  ${GREEN}•${NC} 安装可用的系统更新"
echo -e "  ${GREEN}•${NC} 检查是否需要重启"
echo ""

while true; do
    echo -e "${CYAN}确定要开始系统更新吗? (y/n):${NC} "
    read -r update_choice
    
    case $update_choice in
        [Yy])
            echo -e "${GREEN}开始系统更新...${NC}"
            update_system
            check_reboot_required
            break
            ;;
        [Nn])
            echo -e "${YELLOW}已取消系统更新.${NC}"
            break
            ;;
        *)
            echo -e "${RED}无效的选择，请输入 'y' 或 'n'.${NC}"
            ;;
    esac
done

# Wait for user input before returning
echo -e "\n${YELLOW}按回车键返回上一级菜单...${NC}"
read
exit 0