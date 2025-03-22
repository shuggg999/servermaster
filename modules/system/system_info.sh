#!/bin/bash

# 系统信息模块 - 使用dialog实现更友好的界面

# 定义颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
PLAIN='\033[0m'

# 定义窗口大小
DIALOG_HEIGHT=40
DIALOG_WIDTH=140

# 获取系统基本信息
get_system_info() {
    clear

    # 收集系统信息
    local hostname=$(hostname)
    local os_info=$(grep "PRETTY_NAME" /etc/os-release | cut -d '"' -f 2)
    local kernel=$(uname -r)
    local uptime=$(uptime -p)
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    local cpu_info=$(lscpu | grep "Model name" | sed 's/Model name:\s*//g')
    local cpu_cores=$(nproc)
    local memory_total=$(free -h | awk '/Mem:/ {print $2}')
    local memory_used=$(free -h | awk '/Mem:/ {print $3}')
    local memory_used_percent=$(free | awk '/Mem:/ {printf("%.1f", $3/$2*100)}')
    local disk_info=$(df -h / | awk 'NR==2 {print $2 " 总容量, " $3 " 已用 (" $5 " 使用率)"}')
    local ip_addr=$(ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d '/' -f 1 | head -n 1)
    
    # 创建信息文本
    local info_text
    info_text="系统信息:\n"
    info_text+="--------------------------------------\n"
    info_text+="主机名: $hostname\n"
    info_text+="操作系统: $os_info\n"
    info_text+="内核版本: $kernel\n"
    info_text+="运行时间: $uptime\n"
    info_text+="平均负载: $load_avg\n\n"
    
    info_text+="硬件信息:\n"
    info_text+="--------------------------------------\n"
    info_text+="CPU型号: $cpu_info\n"
    info_text+="CPU核心数: $cpu_cores\n"
    info_text+="内存: $memory_used / $memory_total ($memory_used_percent%)\n"
    info_text+="磁盘: $disk_info\n\n"
    
    info_text+="网络信息:\n"
    info_text+="--------------------------------------\n"
    info_text+="IP地址: $ip_addr\n"
    
    # 使用dialog显示信息
    dialog --title "系统信息" --msgbox "$info_text" $DIALOG_HEIGHT $DIALOG_WIDTH
}

# 获取CPU详细信息
get_cpu_info() {
    local cpu_info=$(lscpu)
    dialog --title "CPU详细信息" --msgbox "$cpu_info" $DIALOG_HEIGHT $DIALOG_WIDTH
}

# 获取内存详细信息
get_memory_info() {
    local memory_info=$(free -h)
    dialog --title "内存详细信息" --msgbox "$memory_info" $DIALOG_HEIGHT $DIALOG_WIDTH
}

# 获取磁盘详细信息
get_disk_info() {
    local disk_info=$(df -h)
    dialog --title "磁盘使用情况" --msgbox "$disk_info" $DIALOG_HEIGHT $DIALOG_WIDTH
}

# 获取网络连接信息
get_network_info() {
    local netstat_info=$(netstat -tuln)
    dialog --title "网络连接信息" --msgbox "$netstat_info" $DIALOG_HEIGHT $DIALOG_WIDTH
}

# 显示系统信息菜单
show_system_menu() {
    while true; do
        # 创建临时文件存储选择结果
        local temp_file=$(mktemp)
        
        # 显示菜单
        dialog --clear --title "系统信息" \
               --menu "请选择要查看的信息:" $DIALOG_HEIGHT $DIALOG_WIDTH 7 \
               "1" "系统概览" \
               "2" "CPU详细信息" \
               "3" "内存详细信息" \
               "4" "磁盘使用情况" \
               "5" "网络连接信息" \
               "0" "返回主菜单" 2> "$temp_file"
        
        # 获取退出状态和选择结果
        local status=$?
        local choice=$(<"$temp_file")
        rm -f "$temp_file"
        
        # 如果用户按了取消或ESC，则返回主菜单
        if [ $status -ne 0 ]; then
            break
        fi
        
        # 处理用户选择
        case $choice in
            1) get_system_info ;;
            2) get_cpu_info ;;
            3) get_memory_info ;;
            4) get_disk_info ;;
            5) get_network_info ;;
            0) break ;;
            *) dialog --title "错误" --msgbox "无效选项，请重新选择" 10 30 ;;
        esac
    done
}

# 主函数
main() {
    # 如果没有安装dialog，提示错误并退出
    if ! command -v dialog &> /dev/null; then
        echo "错误: 请先安装dialog"
        echo "Debian/Ubuntu: sudo apt install dialog"
        echo "CentOS/RHEL: sudo yum install dialog"
        exit 1
    fi
    
    # 显示系统信息菜单
    show_system_menu
}

# 执行主函数
main