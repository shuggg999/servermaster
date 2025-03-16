#!/bin/bash

# ServerMaster - Main script
# Modular server management system

# Script version
VERSION="1.0.0"

# Base directories
BASE_DIR="/usr/local/servermaster"
MODULES_DIR="$BASE_DIR/modules"
CONFIG_DIR="$BASE_DIR/config"
LOGS_DIR="$BASE_DIR/logs"
TEMP_DIR="/tmp/servermaster"

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
BLACK_BG='\033[40m'
BOLD='\033[1m'
DIM='\033[2m'
BLINK='\033[5m'
NC='\033[0m'

# GitHub repository information
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
# 添加Cloudflare Workers代理URL
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# Current menu path for breadcrumb navigation
MENU_PATH=""

# Create necessary directories if they don't exist
mkdir -p "$LOGS_DIR"
mkdir -p "$TEMP_DIR"

# Function to log messages
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] [$level] $message" >> "$LOGS_DIR/servermaster.log"
}

# Function to check if module exists
check_module() {
    local module_path="$1"
    if [ ! -f "$MODULES_DIR/$module_path" ]; then
        echo -e "${RED}错误: 模块 $module_path 不存在或无法访问!${NC}"
        log "ERROR" "模块 $module_path 不存在或无法访问"
        return 1
    fi
    return 0
}

# Function to execute module
execute_module() {
    local module_path="$1"
    shift
    
    if check_module "$module_path"; then
        # Export color variables and other necessary variables to module
        export GREEN BRIGHT_GREEN CYAN BLUE MAGENTA YELLOW RED WHITE GRAY BLACK_BG BOLD NC
        export BASE_DIR MODULES_DIR CONFIG_DIR LOGS_DIR TEMP_DIR
        
        # Execute the module
        bash "$MODULES_DIR/$module_path" "$@"
        return $?
    else
        # Module not found, ask if user wants to download it
        echo -e "${YELLOW}是否尝试下载此模块? (y/n)${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            download_module "$module_path"
            if [ $? -eq 0 ]; then
                # Module downloaded successfully, now execute it
                bash "$MODULES_DIR/$module_path" "$@"
                return $?
            fi
        fi
        return 1
    fi
}

# Function to download a module
download_module() {
    local module_path="$1"
    local module_dir=$(dirname "$MODULES_DIR/$module_path")
    
    echo -e "${CYAN}尝试下载模块: $module_path${NC}"
    
    # Create directory if it doesn't exist
    mkdir -p "$module_dir"
    
    # 首先尝试Cloudflare Workers代理
    if curl -s -o "$MODULES_DIR/$module_path" "$CF_PROXY_URL/modules/$module_path"; then
        chmod +x "$MODULES_DIR/$module_path"
        echo -e "${GREEN}模块从Cloudflare Workers代理下载成功!${NC}"
        return 0
    else
        # 尝试直接GitHub下载
        echo -e "${YELLOW}Cloudflare Workers代理下载失败，尝试直连GitHub...${NC}"
        if curl -s -o "$MODULES_DIR/$module_path" "$GITHUB_RAW/modules/$module_path"; then
            chmod +x "$MODULES_DIR/$module_path"
            echo -e "${GREEN}模块从GitHub下载成功!${NC}"
            return 0
        else
            # 最后尝试镜像站
            echo -e "${YELLOW}GitHub 下载失败，尝试使用镜像站...${NC}"
            if curl -s -o "$MODULES_DIR/$module_path" "${MIRROR_URL}${GITHUB_RAW}/modules/$module_path"; then
                chmod +x "$MODULES_DIR/$module_path"
                echo -e "${GREEN}模块从镜像站下载成功!${NC}"
                return 0
            else
                echo -e "${RED}无法下载模块!${NC}"
                log "ERROR" "无法下载模块: $module_path"
                return 1
            fi
        fi
    fi
}

# Function to check for updates
check_updates() {
    echo -e "${CYAN}正在检查更新...${NC}"
    
    # 读取本地版本号 - 处理可能的BOM和特殊字符
    if [ -f "$BASE_DIR/version.txt" ]; then
        # 使用tr命令移除不可见字符，并确保只保留有效的版本号字符
        VERSION=$(tr -cd '0-9\.\n' < "$BASE_DIR/version.txt")
    fi
    
    # Get the latest version number (尝试三个源) - 同样处理可能的特殊字符
    local latest_version_raw=$(curl -s "$CF_PROXY_URL/version.txt" || 
                          curl -s "$GITHUB_RAW/version.txt" || 
                          curl -s "${MIRROR_URL}${GITHUB_RAW}/version.txt" || 
                          echo "unknown")
    
    # 清理版本号，确保只包含有效字符
    local latest_version=$(echo "$latest_version_raw" | tr -cd '0-9\.\n')
    
    if [ "$latest_version" = "unknown" ]; then
        echo -e "${RED}无法获取最新版本信息!${NC}"
        return 1
    fi
    
    echo -e "当前版本: ${YELLOW}$VERSION${NC}"
    echo -e "最新版本: ${GREEN}$latest_version${NC}"
    
    # Compare versions
    if [ "$VERSION" != "$latest_version" ]; then
        echo -e "${YELLOW}发现新版本! 是否更新? (y/n)${NC}"
        read -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            update_system "$latest_version"
        fi
    else
        echo -e "${GREEN}系统已是最新版本!${NC}"
        sleep 1
    fi
}

# Function to update the system
update_system() {
    local latest_version="$1"
    echo -e "${CYAN}正在更新系统...${NC}"
    
    # 备份配置
    echo -e "${CYAN}备份配置文件...${NC}"
    if [ -d "$CONFIG_DIR" ]; then
        cp -r "$CONFIG_DIR" "$TEMP_DIR/config_backup"
    fi
    
    # 下载新版本的主脚本
    echo -e "${CYAN}下载新版本主脚本...${NC}"
    if curl -s -o "$TEMP_DIR/main.sh.new" "$CF_PROXY_URL/main.sh" || 
       curl -s -o "$TEMP_DIR/main.sh.new" "$GITHUB_RAW/main.sh" || 
       curl -s -o "$TEMP_DIR/main.sh.new" "${MIRROR_URL}${GITHUB_RAW}/main.sh"; then
        
        # 下载新版本的模块包
        echo -e "${CYAN}下载新版本模块包...${NC}"
        local modules_url="$CF_PROXY_URL/modules.tar.gz"
        local modules_file="$TEMP_DIR/modules.tar.gz.new"
        
        if curl -s -o "$modules_file" "$modules_url" || 
           curl -s -o "$modules_file" "$GITHUB_RAW/modules.tar.gz" || 
           curl -s -o "$modules_file" "${MIRROR_URL}${GITHUB_RAW}/modules.tar.gz"; then
            
            # 备份当前主脚本
            cp "$BASE_DIR/main.sh" "$TEMP_DIR/main.sh.bak"
            
            # 替换主脚本
            cp "$TEMP_DIR/main.sh.new" "$BASE_DIR/main.sh"
            chmod +x "$BASE_DIR/main.sh"
            
            # 清空模块目录
            find "$MODULES_DIR" -type f -delete
            
            # 解压新模块
            tar -xzf "$modules_file" -C "$BASE_DIR"
            
            # 恢复配置
            if [ -d "$TEMP_DIR/config_backup" ]; then
                cp -r "$TEMP_DIR/config_backup"/* "$CONFIG_DIR/"
            fi
            
            # 更新版本号 - 确保使用UTF-8编码，不带BOM
            echo -n "$latest_version" > "$BASE_DIR/version.txt"
            
            echo -e "${GREEN}更新成功! 新版本: $latest_version${NC}"
            echo -e "${CYAN}正在重启系统...${NC}"
            sleep 2
            exec "$BASE_DIR/main.sh"
            exit 0
        else
            echo -e "${RED}下载模块包失败!${NC}"
            # 恢复备份
            if [ -f "$TEMP_DIR/main.sh.bak" ]; then
                cp "$TEMP_DIR/main.sh.bak" "$BASE_DIR/main.sh"
            fi
            return 1
        fi
    else
        echo -e "${RED}下载主脚本失败!${NC}"
        return 1
    fi
}

# Function to show animation
show_animation() {
    local animation=('-' '\\' '|' '/')
    local i=0
    local message="$1"
    local duration=${2:-3}  # Default to 3 seconds
    local end_time=$(($(date +%s) + duration))
    
    while [ $(date +%s) -lt $end_time ]; do
        echo -ne "\r$message ${animation[i]} "
        i=$(( (i+1) % 4 ))
        sleep 0.2
    done
    echo -ne "\r$message 完成!   \n"
}

# Function to show logo
show_logo() {
    echo -e "${CYAN}${BOLD}"
    echo "███████╗███████╗██████╗ ██╗   ██╗███████╗██████╗     ███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ "
    echo "██╔════╝██╔════╝██╔══██╗██║   ██║██╔════╝██╔══██╗    ████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗"
    echo "███████╗█████╗  ██████╔╝██║   ██║█████╗  ██████╔╝    ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝"
    echo "╚════██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝  ██╔══██╗    ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗"
    echo "███████║███████╗██║  ██║ ╚████╔╝ ███████╗██║  ██║    ██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║"
    echo "╚══════╝╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝"
    echo -e "${NC}"
}

# Function to show decorative line
show_decoration() {
    echo ""
    echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
}

# Function to show menu header
show_menu_header() {
    local title="$1"
    clear
    show_logo
    show_decoration
    
    # Show different title based on menu path
    if [ -z "$MENU_PATH" ]; then
        echo -e "                               ${CYAN}${BOLD}「 服务器控制台 」${NC}"
        echo -e "                               ${BLUE}===============================${NC}"
        echo -e "                               ${YELLOW}系统版本: ServerMaster $VERSION${NC}"
    else
        local display_title="${title:-$MENU_PATH}"
        echo -e "                               ${CYAN}${BOLD}「 $display_title 」${NC}"
        echo -e "                               ${BLUE}===============================${NC}"
    fi
    
    show_decoration
    echo ""
}

# Function to show menu footer
show_menu_footer() {
    echo ""
    
    # Display system information
    current_time=$(date "+%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "时间未知")
    uptime_info=$(uptime | awk '{print $3, $4}' | sed 's/,//g' 2>/dev/null || echo "运行时间未知")
    echo -e "                  ${GREEN}系统时间: ${WHITE}$current_time${NC}  |  ${GREEN}运行时间: ${WHITE}$uptime_info${NC}"
    echo ""
    
    # Show different prompt based on menu path
    if [ -z "$MENU_PATH" ]; then
        echo -ne "${CYAN}${BOLD}管理员${NC}${GREEN}@${NC}${CYAN}${BOLD}服务器${NC} ${GREEN}➤${NC} "
    else
        echo -ne "${CYAN}${BOLD}管理员${NC}${GREEN}@${NC}${CYAN}${BOLD}服务器/${MENU_PATH}${NC} ${GREEN}➤${NC} "
    fi
}

# Function to show the pause prompt
show_pause() {
    echo ""
    echo -e "${YELLOW}按任意键继续...${NC}"
    read -n 1 -s
}

# Main menu
show_main_menu() {
    MENU_PATH=""
    show_menu_header
    
    echo -e "                               ${BLUE}════════════════════════${NC}"
    echo -e "                               ${BLUE}    命 令 控 制 中 心    ${NC}"
    echo -e "                               ${BLUE}════════════════════════${NC}"
    echo ""
    echo ""
    
    # Main menu options
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}系统管理${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [2]${NC} ${WHITE}网络管理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [3]${NC} ${WHITE}应用与服务${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}高级功能${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}特别功能${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [U]${NC} ${WHITE}脚本更新${NC}"
    echo ""
    echo -e "                          ${RED}◆ [X]${NC} ${WHITE}卸载系统${NC}"
    echo ""
    echo -e "                          ${RED}◆ [0]${NC} ${WHITE}退出系统${NC}"
    
    show_menu_footer
    
    read choice
    process_main_menu "$choice"
}

# Process main menu selection
process_main_menu() {
    case "$1" in
        1) system_management ;;
        2) network_management ;;
        3) application_service ;;
        4) advanced_features ;;
        5) special_features ;;
        U|u) check_updates ;;
        X|x) uninstall_system ;;
        0) 
            echo -e "${RED}正在退出系统...${NC}"
            echo -e "${GREEN}感谢使用 ServerMaster!${NC}"
            sleep 1
            clear
            exit 0 
            ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            show_main_menu
            ;;
    esac
}

# System management menu
system_management() {
    MENU_PATH="系统管理"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}系统信息查询${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}系统更新${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}系统清理${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}重装系统(DD)${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}时区设置${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [6]${NC} ${WHITE}修改SSH端口${NC}"
    echo ""
    echo -e "                          ${RED}◆ [7]${NC} ${WHITE}设置虚拟内存${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [8]${NC} ${WHITE}用户账户管理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [9]${NC} ${WHITE}计划任务管理${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回主菜单${NC}"
    
    show_menu_footer
    
    read choice
    process_system_menu "$choice"
}

# Process system management menu selection
process_system_menu() {
    case "$1" in
        1) execute_module "system/system_info.sh" && show_pause && system_management ;;
        2) execute_module "system/system_update.sh" && show_pause && system_management ;;
        3) execute_module "system/system_clean.sh" && show_pause && system_management ;;
        4) execute_module "system/system_reinstall.sh" && show_pause && system_management ;;
        5) execute_module "system/timezone_setup.sh" && show_pause && system_management ;;
        6) execute_module "system/ssh_port.sh" && show_pause && system_management ;;
        7) execute_module "system/virtual_memory.sh" && show_pause && system_management ;;
        8) execute_module "system/user_management.sh" && show_pause && system_management ;;
        9) execute_module "system/cron_management.sh" && show_pause && system_management ;;
        0) show_main_menu ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            system_management
            ;;
    esac
}

# Network management menu
network_management() {
    MENU_PATH="网络管理"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}BBR管理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}防火墙管理${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}WARP管理${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}网络测试${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}VPN管理${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [6]${NC} ${WHITE}代理管理${NC}"
    echo ""
    echo -e "                          ${RED}◆ [7]${NC} ${WHITE}DNS管理${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回主菜单${NC}"
    
    show_menu_footer
    
    read choice
    process_network_menu "$choice"
}

# Process network management menu selection
process_network_menu() {
    case "$1" in
        1) execute_module "network/bbr_manager.sh" && show_pause && network_management ;;
        2) execute_module "network/firewall_manager.sh" && show_pause && network_management ;;
        3) execute_module "network/warp_manager.sh" && show_pause && network_management ;;
        4) execute_module "network/network_test.sh" && show_pause && network_management ;;
        5) vpn_menu ;;
        6) proxy_menu ;;
        7) execute_module "network/dns_manager.sh" && show_pause && network_management ;;
        0) show_main_menu ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            network_management
            ;;
    esac
}

# VPN management submenu
vpn_menu() {
    MENU_PATH="网络管理/VPN管理"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}OpenVPN管理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}WireGuard管理${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}L2TP管理${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}PPTP管理${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}IPsec管理${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回上一级${NC}"
    
    show_menu_footer
    
    read choice
    process_vpn_menu "$choice"
}

# Process VPN management menu selection
process_vpn_menu() {
    case "$1" in
        1) execute_module "network/vpn/openvpn_manager.sh" && show_pause && vpn_menu ;;
        2) execute_module "network/vpn/wireguard_manager.sh" && show_pause && vpn_menu ;;
        3) execute_module "network/vpn/l2tp_manager.sh" && show_pause && vpn_menu ;;
        4) execute_module "network/vpn/pptp_manager.sh" && show_pause && vpn_menu ;;
        5) execute_module "network/vpn/ipsec_manager.sh" && show_pause && vpn_menu ;;
        0) network_management ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            vpn_menu
            ;;
    esac
}

# Proxy management submenu
proxy_menu() {
    MENU_PATH="网络管理/代理管理"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}Nginx反向代理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}Squid代理${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}V2Ray管理${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}Trojan管理${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}Shadowsocks管理${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回上一级${NC}"
    
    show_menu_footer
    
    read choice
    process_proxy_menu "$choice"
}

# Process proxy management menu selection
process_proxy_menu() {
    case "$1" in
        1) execute_module "network/proxy/nginx_proxy.sh" && show_pause && proxy_menu ;;
        2) execute_module "network/proxy/squid_proxy.sh" && show_pause && proxy_menu ;;
        3) execute_module "network/proxy/v2ray_manager.sh" && show_pause && proxy_menu ;;
        4) execute_module "network/proxy/trojan_manager.sh" && show_pause && proxy_menu ;;
        5) execute_module "network/proxy/shadowsocks_manager.sh" && show_pause && proxy_menu ;;
        0) network_management ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            proxy_menu
            ;;
    esac
}

# Application and service menu
application_service() {
    MENU_PATH="应用与服务"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}Docker管理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}LDNMP建站${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}面板集合${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}数据库管理${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}安全防护${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [6]${NC} ${WHITE}监控与告警${NC}"
    echo ""
    echo -e "                          ${RED}◆ [7]${NC} ${WHITE}文件管理${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回主菜单${NC}"
    
    show_menu_footer
    
    read choice
    process_application_menu "$choice"
}

# Process application and service menu selection
process_application_menu() {
    case "$1" in
        1) execute_module "application/docker_manager.sh" && show_pause && application_service ;;
        2) execute_module "application/ldnmp_manager.sh" && show_pause && application_service ;;
        3) panels_menu ;;
        4) database_menu ;;
        5) security_menu ;;
        6) execute_module "application/monitoring.sh" && show_pause && application_service ;;
        7) execute_module "application/file_manager.sh" && show_pause && application_service ;;
        0) show_main_menu ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            application_service
            ;;
    esac
}

# Panels submenu
panels_menu() {
    MENU_PATH="应用与服务/面板集合"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}宝塔面板${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}aaPanel${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}1Panel${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}ServerStatus${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}管理面板集成${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回上一级${NC}"
    
    show_menu_footer
    
    read choice
    process_panels_menu "$choice"
}

# Process panels menu selection
process_panels_menu() {
    case "$1" in
        1) execute_module "application/panels/bt_panel.sh" && show_pause && panels_menu ;;
        2) execute_module "application/panels/aa_panel.sh" && show_pause && panels_menu ;;
        3) execute_module "application/panels/one_panel.sh" && show_pause && panels_menu ;;
        4) execute_module "application/panels/server_status.sh" && show_pause && panels_menu ;;
        5) execute_module "application/panels/integrated_panel.sh" && show_pause && panels_menu ;;
        0) application_service ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            panels_menu
            ;;
    esac
}

# Database menu
database_menu() {
    MENU_PATH="应用与服务/数据库管理"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}MySQL管理${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}Redis管理${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}MongoDB管理${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}PostgreSQL管理${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}数据库备份恢复${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回上一级${NC}"
    
    show_menu_footer
    
    read choice
    process_database_menu "$choice"
}

# Process database menu selection
process_database_menu() {
    case "$1" in
        1) execute_module "application/database/mysql_manager.sh" && show_pause && database_menu ;;
        2) execute_module "application/database/redis_manager.sh" && show_pause && database_menu ;;
        3) execute_module "application/database/mongodb_manager.sh" && show_pause && database_menu ;;
        4) execute_module "application/database/postgresql_manager.sh" && show_pause && database_menu ;;
        5) execute_module "application/database/backup_restore.sh" && show_pause && database_menu ;;
        0) application_service ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            database_menu
            ;;
    esac
}

# Security menu
security_menu() {
    MENU_PATH="应用与服务/安全防护"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}SSH安全配置${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}Fail2Ban配置${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}防病毒设置${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}系统加固${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}防火墙设置${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [6]${NC} ${WHITE}安全审计${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回上一级${NC}"
    
    show_menu_footer
    
    read choice
    process_security_menu "$choice"
}

# Process security menu selection
process_security_menu() {
    case "$1" in
        1) execute_module "application/security/ssh_security.sh" && show_pause && security_menu ;;
        2) execute_module "application/security/fail2ban.sh" && show_pause && security_menu ;;
        3) execute_module "application/security/antivirus.sh" && show_pause && security_menu ;;
        4) execute_module "application/security/harden.sh" && show_pause && security_menu ;;
        5) execute_module "application/security/firewall.sh" && show_pause && security_menu ;;
        6) execute_module "application/security/audit.sh" && show_pause && security_menu ;;
        0) application_service ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            security_menu
            ;;
    esac
}

# Advanced features menu
advanced_features() {
    MENU_PATH="高级功能"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}内核优化${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}自动备份${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}远程管理${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}集群控制${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}自动化脚本${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [6]${NC} ${WHITE}升级内核${NC}"
    echo ""
    echo -e "                          ${RED}◆ [7]${NC} ${WHITE}高级网络配置${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回主菜单${NC}"
    
    show_menu_footer
    
    read choice
    process_advanced_menu "$choice"
}

# Process advanced features menu selection
process_advanced_menu() {
    case "$1" in
        1) execute_module "advanced/kernel_optimize.sh" && show_pause && advanced_features ;;
        2) execute_module "advanced/auto_backup.sh" && show_pause && advanced_features ;;
        3) execute_module "advanced/remote_management.sh" && show_pause && advanced_features ;;
        4) execute_module "advanced/cluster_control.sh" && show_pause && advanced_features ;;
        5) execute_module "advanced/automation.sh" && show_pause && advanced_features ;;
        6) execute_module "advanced/kernel_upgrade.sh" && show_pause && advanced_features ;;
        7) execute_module "advanced/network_config.sh" && show_pause && advanced_features ;;
        0) show_main_menu ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            advanced_features
            ;;
    esac
}

# Special features menu
special_features() {
    MENU_PATH="特别功能"
    show_menu_header
    
    echo ""
    echo -e "                          ${BRIGHT_GREEN}◆ [1]${NC} ${WHITE}工作区${NC}"
    echo ""
    echo -e "                          ${GREEN}◆ [2]${NC} ${WHITE}甲骨文云工具${NC}"
    echo ""
    echo -e "                          ${BLUE}◆ [3]${NC} ${WHITE}游戏服务器${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [4]${NC} ${WHITE}AI模型部署${NC}"
    echo ""
    echo -e "                          ${MAGENTA}◆ [5]${NC} ${WHITE}流媒体服务${NC}"
    echo ""
    echo -e "                          ${CYAN}◆ [6]${NC} ${WHITE}开发者工具箱${NC}"
    echo ""
    
    # Divider
    echo -e "                          ${YELLOW}----------------------------------------${NC}"
    echo ""
    echo -e "                          ${YELLOW}◆ [0]${NC} ${WHITE}返回主菜单${NC}"
    
    show_menu_footer
    
    read choice
    process_special_menu "$choice"
}

# Process special features menu selection
process_special_menu() {
    case "$1" in
        1) execute_module "special/workspace.sh" && show_pause && special_features ;;
        2) execute_module "special/oracle_cloud.sh" && show_pause && special_features ;;
        3) execute_module "special/game_servers.sh" && show_pause && special_features ;;
        4) execute_module "special/ai_models.sh" && show_pause && special_features ;;
        5) execute_module "special/media_service.sh" && show_pause && special_features ;;
        6) execute_module "special/dev_toolkit.sh" && show_pause && special_features ;;
        0) show_main_menu ;;
        *) 
            echo -e "${RED}无效选项，请重新输入${NC}"
            sleep 1
            special_features
            ;;
    esac
}

# Function to uninstall the system
uninstall_system() {
    clear
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}                                                                       ${RED}║${NC}"
    echo -e "${RED}║${NC}                ${BOLD}${RED}警告: 即将卸载 ServerMaster 系统${NC}                      ${RED}║${NC}"
    echo -e "${RED}║${NC}                                                                       ${RED}║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}此操作将删除以下内容:${NC}"
    echo -e " ${CYAN}• 所有 ServerMaster 脚本和模块${NC}"
    echo -e " ${CYAN}• 配置文件和日志${NC}"
    echo -e " ${CYAN}• 临时文件和下载的压缩包${NC}"
    echo -e " ${CYAN}• 系统命令链接 (sm)${NC}"
    echo ""
    echo -e "${RED}注意: 此操作不可逆! 所有 ServerMaster 数据将被永久删除!${NC}"
    echo ""
    echo -e "${YELLOW}确认卸载 ServerMaster? (输入 '${RED}yes${YELLOW}' 确认卸载)${NC}"
    read -r confirmation
    
    if [ "$confirmation" = "yes" ]; then
        echo ""
        echo -e "${CYAN}开始卸载 ServerMaster...${NC}"
        
        # Remove command link
        echo -e "${CYAN}[1/4] 删除命令链接...${NC}"
        rm -f /usr/local/bin/sm
        if [ -f "/etc/bash_completion.d/sm" ]; then
            rm -f /etc/bash_completion.d/sm
        fi
        echo -e "${GREEN}✓${NC} 命令链接已删除"
        
        # Remove temporary files
        echo -e "${CYAN}[2/4] 删除临时文件...${NC}"
        rm -rf /tmp/servermaster
        rm -f /tmp/servermaster_modules.tar.gz
        echo -e "${GREEN}✓${NC} 临时文件已删除"
        
        # Remove main directory
        echo -e "${CYAN}[3/4] 删除主目录...${NC}"
        rm -rf "$BASE_DIR"
        echo -e "${GREEN}✓${NC} 主目录已删除"
        
        # Final cleanup
        echo -e "${CYAN}[4/4] 完成清理...${NC}"
        echo -e "${GREEN}✓${NC} ServerMaster 已完全卸载!"
        
        echo ""
        echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║${NC}                                                                       ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                ${BOLD}${GREEN}ServerMaster 已成功卸载!${NC}                           ${GREEN}║${NC}"
        echo -e "${GREEN}║${NC}                                                                       ${GREEN}║${NC}"
        echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        
        echo ""
        echo -e "${YELLOW}感谢您使用 ServerMaster! 再见!${NC}"
        sleep 2
        exit 0
    else
        echo ""
        echo -e "${YELLOW}卸载已取消，返回主菜单...${NC}"
        sleep 1
        show_main_menu
    fi
}

# Check command line arguments
if [ $# -eq 0 ]; then
    # No arguments, show main menu
    show_main_menu
else
    # Process command line arguments
    case "$1" in
        --version|-v)
            echo "ServerMaster v$VERSION"
            exit 0
            ;;
        --help|-h)
            echo "ServerMaster v$VERSION - 模块化服务器管理系统"
            echo ""
            echo "使用方法: sm [选项] [命令]"
            echo ""
            echo "选项:"
            echo "  -v, --version    显示版本信息"
            echo "  -h, --help       显示帮助信息"
            echo ""
            echo "命令:"
            echo "  update           检查并安装更新"
            echo "  system           系统管理"
            echo "  network          网络管理"
            echo "  app              应用与服务管理"
            echo "  module <模块路径> 直接执行指定模块"
            echo ""
            exit 0
            ;;
        update)
            check_updates
            exit 0
            ;;
        system)
            system_management
            ;;
        network)
            network_management
            ;;
        app)
            application_service
            ;;
        advanced)
            advanced_features
            ;;
        special)
            special_features
            ;;
        module)
            if [ -z "$2" ]; then
                echo -e "${RED}错误: 未指定模块路径!${NC}"
                echo "使用方法: sm module <模块路径>"
                exit 1
            fi
            shift
            execute_module "$@"
            exit $?
            ;;
        *)
            echo -e "${RED}错误: 未知命令 '$1'!${NC}"
            echo "使用 'sm --help' 查看帮助信息"
            exit 1
            ;;
    esac
fi