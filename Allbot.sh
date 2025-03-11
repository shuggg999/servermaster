#!/bin/bash

# 颜色定义
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[36m"
BOLD="\033[1m"
RESET="\033[0m"

# 显示横幅
show_banner() {
    clear
    echo -e "${BLUE}${BOLD}"
    echo "======================================================"
    echo "              我的自定义安装脚本 v1.0                 "
    echo "======================================================"
    echo -e "${RESET}"
    echo -e "${YELLOW}作者: YourName${RESET}"
    echo -e "${YELLOW}GitHub: https://github.com/yourusername/my-install-script${RESET}"
    echo ""
}

# 检查是否为 root 用户
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误: 此脚本需要 root 权限运行${RESET}"
        echo -e "请使用 ${YELLOW}sudo bash install.sh${RESET} 重新运行"
        exit 1
    fi
}

# 显示进度条
show_progress() {
    local duration=$1
    local steps=20
    local sleep_time=$(echo "scale=2; $duration/$steps" | bc)
    
    echo -ne "${YELLOW}安装进度: ${RESET}["
    for ((i=0; i<steps; i++)); do
        echo -ne "${GREEN}#${RESET}"
        sleep $sleep_time
    done
    echo -e "] ${GREEN}完成!${RESET}"
}

# 检查系统信息
check_system() {
    echo -e "${BLUE}[信息] 检测系统环境...${RESET}"
    sleep 1
    
    # 检测操作系统类型
    if [ -f /etc/redhat-release ]; then
        OS="CentOS"
    elif [ -f /etc/debian_version ]; then
        OS="Debian"
    elif [ -f /etc/lsb-release ]; then
        OS="Ubuntu"
    else
        echo -e "${RED}[错误] 不支持的操作系统!${RESET}"
        exit 1
    fi
    
    echo -e "${GREEN}[成功] 检测到系统: $OS${RESET}"
    
    # 检测系统位数
    ARCH=$(uname -m)
    echo -e "${GREEN}[成功] 系统架构: $ARCH${RESET}"
    
    # 检测内核版本
    KERNEL=$(uname -r)
    echo -e "${GREEN}[成功] 内核版本: $KERNEL${RESET}"
    
    sleep 1
}

# 更新系统
update_system() {
    echo -e "\n${BLUE}[信息] 正在更新系统...${RESET}"
    
    if [ "$OS" == "CentOS" ]; then
        yum update -y > /dev/null 2>&1
    else
        apt-get update -y > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}[成功] 系统更新完成${RESET}"
    sleep 1
}

# 安装依赖
install_dependencies() {
    echo -e "\n${BLUE}[信息] 正在安装依赖...${RESET}"
    
    if [ "$OS" == "CentOS" ]; then
        yum install -y wget curl vim net-tools > /dev/null 2>&1
    else
        apt-get install -y wget curl vim net-tools > /dev/null 2>&1
    fi
    
    echo -e "${GREEN}[成功] 依赖安装完成${RESET}"
    sleep 1
}

# 显示菜单并获取用户选择
show_menu() {
    echo -e "\n${BLUE}${BOLD}请选择要安装的组件:${RESET}"
    echo -e "${YELLOW}1.${RESET} 安装组件 A"
    echo -e "${YELLOW}2.${RESET} 安装组件 B"
    echo -e "${YELLOW}3.${RESET} 安装组件 C"
    echo -e "${YELLOW}4.${RESET} 全部安装"
    echo -e "${YELLOW}0.${RESET} 退出"
    
    echo -e "\n${YELLOW}请输入选项 [0-4]:${RESET} \c"
    read choice
    
    case $choice in
        1)
            install_component_a
            ;;
        2)
            install_component_b
            ;;
        3)
            install_component_c
            ;;
        4)
            install_all_components
            ;;
        0)
            echo -e "${GREEN}感谢使用，再见!${RESET}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效的选择，请重新输入${RESET}"
            show_menu
            ;;
    esac
}

# 安装组件 A
install_component_a() {
    echo -e "\n${BLUE}[信息] 正在安装组件 A...${RESET}"
    # 这里添加组件 A 的安装命令
    sleep 2
    show_progress 3
    echo -e "\n${GREEN}[成功] 组件 A 安装完成!${RESET}"
    
    # 安装后返回主菜单
    sleep 1
    show_menu
}

# 安装组件 B
install_component_b() {
    echo -e "\n${BLUE}[信息] 正在安装组件 B...${RESET}"
    # 这里添加组件 B 的安装命令
    sleep 2
    show_progress 3
    echo -e "\n${GREEN}[成功] 组件 B 安装完成!${RESET}"
    
    # 安装后返回主菜单
    sleep 1
    show_menu
}

# 安装组件 C
install_component_c() {
    echo -e "\n${BLUE}[信息] 正在安装组件 C...${RESET}"
    # 这里添加组件 C 的安装命令
    sleep 2
    show_progress 3
    echo -e "\n${GREEN}[成功] 组件 C 安装完成!${RESET}"
    
    # 安装后返回主菜单
    sleep 1
    show_menu
}

# 安装所有组件
install_all_components() {
    echo -e "\n${BLUE}[信息] 正在安装所有组件...${RESET}"
    
    # 安装组件 A
    echo -e "\n${YELLOW}[步骤 1/3] 安装组件 A${RESET}"
    sleep 2
    show_progress 2
    
    # 安装组件 B
    echo -e "\n${YELLOW}[步骤 2/3] 安装组件 B${RESET}"
    sleep 2
    show_progress 2
    
    # 安装组件 C
    echo -e "\n${YELLOW}[步骤 3/3] 安装组件 C${RESET}"
    sleep 2
    show_progress 2
    
    echo -e "\n${GREEN}${BOLD}[成功] 所有组件安装完成!${RESET}"
    
    # 安装后返回主菜单
    sleep 1
    show_menu
}

# 主程序
main() {
    show_banner
    check_root
    check_system
    update_system
    install_dependencies
    show_menu
}

# 执行主程序
main
