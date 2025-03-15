#!/bin/bash

# System Cleaning Module
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

# Function to get initial disk usage
get_disk_usage() {
    df -h | grep -E '^/dev/'
}

# Function to clean the system
clean_system() {
    echo -e "${CYAN}检测系统类型...${NC}"
    
    # Detect package manager
    if command -v apt-get &>/dev/null; then
        echo -e "${GREEN}检测到 Debian/Ubuntu 系统，使用 apt 包管理器${NC}"
        
        echo -e "\n${YELLOW}修复可能中断的包安装...${NC}"
        fix_dpkg
        
        echo -e "\n${YELLOW}清理不需要的包...${NC}"
        apt-get autoremove --purge -y
        
        echo -e "\n${YELLOW}清理APT缓存...${NC}"
        apt-get clean -y
        apt-get autoclean -y
        
        echo -e "\n${YELLOW}清理日志文件...${NC}"
        journalctl --rotate --vacuum-time=1d 2>/dev/null
        journalctl --vacuum-size=50M 2>/dev/null
        
        echo -e "\n${GREEN}Debian/Ubuntu 系统清理完成！${NC}"
    
    elif command -v dnf &>/dev/null; then
        echo -e "${GREEN}检测到 Fedora/RHEL 8+ 系统，使用 dnf 包管理器${NC}"
        
        echo -e "\n${YELLOW}清理不需要的包...${NC}"
        dnf autoremove -y
        
        echo -e "\n${YELLOW}清理DNF缓存...${NC}"
        dnf clean all
        
        echo -e "\n${YELLOW}清理日志文件...${NC}"
        journalctl --rotate --vacuum-time=1d 2>/dev/null
        journalctl --vacuum-size=50M 2>/dev/null
        
        echo -e "\n${GREEN}Fedora/RHEL 系统清理完成！${NC}"
    
    elif command -v yum &>/dev/null; then
        echo -e "${GREEN}检测到 CentOS/RHEL 系统，使用 yum 包管理器${NC}"
        
        echo -e "\n${YELLOW}清理不需要的包...${NC}"
        yum autoremove -y
        
        echo -e "\n${YELLOW}清理YUM缓存...${NC}"
        yum clean all
        
        echo -e "\n${YELLOW}清理日志文件...${NC}"
        journalctl --rotate --vacuum-time=1d 2>/dev/null
        journalctl --vacuum-size=50M 2>/dev/null
        
        echo -e "\n${GREEN}CentOS/RHEL 系统清理完成！${NC}"
    
    elif command -v pacman &>/dev/null; then
        echo -e "${GREEN}检测到 Arch Linux 系统，使用 pacman 包管理器${NC}"
        
        echo -e "\n${YELLOW}清理不需要的包...${NC}"
        pacman -Rns $(pacman -Qtdq) --noconfirm 2>/dev/null
        
        echo -e "\n${YELLOW}清理Pacman缓存...${NC}"
        pacman -Sc --noconfirm
        
        echo -e "\n${YELLOW}清理日志文件...${NC}"
        journalctl --rotate --vacuum-time=1d 2>/dev/null
        journalctl --vacuum-size=50M 2>/dev/null
        
        echo -e "\n${GREEN}Arch Linux 系统清理完成！${NC}"
    
    elif command -v zypper &>/dev/null; then
        echo -e "${GREEN}检测到 openSUSE 系统，使用 zypper 包管理器${NC}"
        
        echo -e "\n${YELLOW}清理不需要的包...${NC}"
        zypper packages --unneeded | grep -v "+" | awk '{print $3}' | xargs -r zypper remove -y
        
        echo -e "\n${YELLOW}清理Zypper缓存...${NC}"
        zypper clean --all
        
        echo -e "\n${YELLOW}清理日志文件...${NC}"
        journalctl --rotate --vacuum-time=1d 2>/dev/null
        journalctl --vacuum-size=50M 2>/dev/null
        
        echo -e "\n${GREEN}openSUSE 系统清理完成！${NC}"
    
    elif command -v apk &>/dev/null; then
        echo -e "${GREEN}检测到 Alpine Linux 系统，使用 apk 包管理器${NC}"
        
        echo -e "\n${YELLOW}清理包管理器缓存...${NC}"
        apk cache clean
        
        echo -e "\n${YELLOW}清理系统日志...${NC}"
        rm -rf /var/log/*
        
        echo -e "\n${YELLOW}清理APK缓存...${NC}"
        rm -rf /var/cache/apk/*
        
        echo -e "\n${YELLOW}清理临时文件...${NC}"
        rm -rf /tmp/*
        
        echo -e "\n${GREEN}Alpine Linux 系统清理完成！${NC}"
    
    else
        echo -e "${RED}无法识别的系统！不支持自动清理。${NC}"
        echo -e "${YELLOW}支持的系统包括: Debian, Ubuntu, CentOS, Fedora, RHEL, Arch Linux, openSUSE, Alpine${NC}"
        exit 1
    fi
    
    # Common cleaning operations for all systems
    echo -e "\n${YELLOW}清理通用缓存文件...${NC}"
    find /tmp -type f -atime +10 -delete 2>/dev/null
    find /var/tmp -type f -atime +10 -delete 2>/dev/null
    
    # Clean old cores if they exist
    echo -e "\n${YELLOW}清理旧的核心转储文件...${NC}"
    find /var/crash -type f -delete 2>/dev/null
    find /var/core -type f -delete 2>/dev/null
    
    # Clean thumbnail cache for all users
    echo -e "\n${YELLOW}清理缩略图缓存...${NC}"
    find /home -type d -name ".thumbnails" -exec rm -rf {} \; 2>/dev/null
    find /root -type d -name ".thumbnails" -exec rm -rf {} \; 2>/dev/null
}

# Function to compare disk usage before and after cleaning
compare_disk_usage() {
    local before="$1"
    local after=$(get_disk_usage)
    
    echo -e "\n${CYAN}磁盘使用情况对比:${NC}"
    echo -e "${YELLOW}清理前:${NC}"
    echo "$before"
    echo -e "${GREEN}清理后:${NC}"
    echo "$after"
}

# Clear the screen
clear

# Show header
echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
echo -e "                               ${CYAN}${BOLD}「 系统清理 」${NC}"
echo -e "                               ${BLUE}===============================${NC}"
echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
echo ""

echo -e "${YELLOW}系统清理将执行以下操作：${NC}"
echo -e "  ${GREEN}•${NC} 清理软件包缓存"
echo -e "  ${GREEN}•${NC} 移除不需要的依赖包"
echo -e "  ${GREEN}•${NC} 删除旧的日志文件"
echo -e "  ${GREEN}•${NC} 清理临时文件和缓存"
echo -e "  ${GREEN}•${NC} 优化系统存储空间"
echo ""

while true; do
    echo -e "${CYAN}确定要开始系统清理吗? (y/n):${NC} "
    read -r clean_choice
    
    case $clean_choice in
        [Yy])
            echo -e "${GREEN}开始系统清理...${NC}"
            # Get disk usage before cleaning
            before_usage=$(get_disk_usage)
            
            # Perform cleaning
            clean_system
            
            # Compare disk usage
            compare_disk_usage "$before_usage"
            break
            ;;
        [Nn])
            echo -e "${YELLOW}已取消系统清理.${NC}"
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