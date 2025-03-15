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
GITHUB_REPO="https://github.com/servermaster/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/servermaster/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"

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
    
    # Try direct GitHub download first
    if curl -s -o "$MODULES_DIR/$module_path" "$GITHUB_RAW/modules/$module_path"; then
        chmod +x "$MODULES_DIR/$module_path"
        echo -e "${GREEN}模块下载成功!${NC}"
        return 0
    else
        # Try mirror
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
}

# Function to check for updates
check_updates() {
    echo -e "${CYAN}正在检查更新...${NC}"
    
    # Get the latest version number
    local latest_version=$(curl -s "$GITHUB_RAW/version.txt" || 
                          curl -s "${MIRROR_URL}${GITHUB_RAW}/version.txt" || 
                          echo "unknown")
    
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
            update_system
        fi
    else
        echo -e "${GREEN}系统已是最新版本!${NC}"
        sleep 1
    fi
}

# Function to update the system
update_system() {
    echo -e "${CYAN}正在更新系统...${NC}"
    
    # Download the update script
    if curl -s -o "$TEMP_DIR/update.sh" "$GITHUB_RAW/update.sh" || 
       curl -s -o "$TEMP_DIR/update.sh" "${MIRROR_URL}${GITHUB_RAW}/update.sh"; then
        chmod +x "$TEMP_DIR/update.sh"
        
        # Execute the update script
        bash "$TEMP_DIR/update.sh"
        
        # Check if update was successful
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}更新成功! 请重新启动系统.${NC}"
            exit 0
        else
            echo -e "${RED}更新失败!${NC}"
            return 1
        fi
    else
        echo -e "${RED}无法下载更新脚本!${NC}"
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
        1) execute_module "system/system_info.sh" && system_management ;;
        2) execute_module "system/system_update.sh" && system_management ;;
        3) execute_module "system/system_clean.sh" && system_management ;;
        4) execute_module "system/system_reinstall.sh" && system_management ;;
        5) execute_module "system/timezone_setup.sh" && system_management ;;
        6) execute_module "system/ssh_port.sh" && system_management ;;
        7) execute_module "system/virtual_memory.sh"