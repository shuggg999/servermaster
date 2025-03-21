#!/bin/bash

# System Information Module
# This module displays system information using Dialog

# 定义漂亮的boxdraw字符
BOX_H="═"
BOX_V="║"
BOX_TL="╔"
BOX_TR="╗"
BOX_BL="╚"
BOX_BR="╝"
BOX_VR="╠"
BOX_VL="╣"
BOX_HU="╩"
BOX_HD="╦"
BOX_HV="╬"

# Get system information
get_system_info() {
    # 自定义颜色（使用标准ANSI转义序列）
    local TITLE="\Z1"    # 红色标题
    local LABEL="\Z2"    # 绿色标签
    local VALUE="\Z3"    # 黄色数值
    local RESET="\Zn"    # 重置颜色
    
    # Basic system info
    local hostname=$(hostname)
    local os_info=$(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)
    local kernel=$(uname -r)
    local uptime=$(uptime -p)
    local load_avg=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    
    # CPU info
    local cpu_model=$(lscpu | grep "Model name" | cut -f 2 -d ":" | sed 's/^[ \t]*//')
    local cpu_cores=$(nproc)
    local cpu_freq=$(lscpu | grep "CPU MHz" | cut -f 2 -d ":" | sed 's/^[ \t]*//')
    
    # Memory info
    local total_mem=$(free -h | grep Mem | awk '{print $2}')
    local used_mem=$(free -h | grep Mem | awk '{print $3}')
    local free_mem=$(free -h | grep Mem | awk '{print $4}')
    local swap_total=$(free -h | grep Swap | awk '{print $2}')
    local swap_used=$(free -h | grep Swap | awk '{print $3}')
    
    # Disk info
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}')
    local disk_total=$(df -h / | tail -1 | awk '{print $2}')
    local disk_used=$(df -h / | tail -1 | awk '{print $3}')
    
    # Network info
    local ipv4=$(curl -s ifconfig.me)
    local dns=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | tr '\n' ' ')
    
    # 格式化输出，使用美观的方框和颜色
    local info_text=""
    info_text+="${BOX_TL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_TR}\n"
    info_text+="${BOX_V}${TITLE}                       系统信息概览                         ${RESET}${BOX_V}\n"
    info_text+="${BOX_VR}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VL}\n"
    
    # 系统信息部分
    info_text+="${BOX_V} ${LABEL}主机名${RESET}    : ${VALUE}$hostname${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}操作系统${RESET}  : ${VALUE}$os_info${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}内核版本${RESET}  : ${VALUE}$kernel${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}运行时间${RESET}  : ${VALUE}$uptime${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}系统负载${RESET}  : ${VALUE}$load_avg${RESET}${BOX_V}\n"
    
    info_text+="${BOX_VR}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VL}\n"
    
    # CPU信息部分
    info_text+="${BOX_V} ${TITLE}CPU信息:${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}CPU型号${RESET}   : ${VALUE}$cpu_model${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}CPU核心数${RESET} : ${VALUE}$cpu_cores${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}CPU频率${RESET}   : ${VALUE}$cpu_freq MHz${RESET}${BOX_V}\n"
    
    info_text+="${BOX_VR}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VL}\n"
    
    # 内存信息部分
    info_text+="${BOX_V} ${TITLE}内存信息:${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}总内存${RESET}    : ${VALUE}$total_mem${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}已用内存${RESET}  : ${VALUE}$used_mem${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}空闲内存${RESET}  : ${VALUE}$free_mem${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}交换空间${RESET}  : ${VALUE}$swap_total (已用: $swap_used)${RESET}${BOX_V}\n"
    
    info_text+="${BOX_VR}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VL}\n"
    
    # 磁盘信息部分
    info_text+="${BOX_V} ${TITLE}磁盘信息:${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}总空间${RESET}    : ${VALUE}$disk_total${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}已用空间${RESET}  : ${VALUE}$disk_used${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}使用率${RESET}    : ${VALUE}$disk_usage${RESET}${BOX_V}\n"
    
    info_text+="${BOX_VR}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_VL}\n"
    
    # 网络信息部分
    info_text+="${BOX_V} ${TITLE}网络信息:${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}公网IPv4${RESET}  : ${VALUE}$ipv4${RESET}${BOX_V}\n"
    info_text+="${BOX_V} ${LABEL}DNS服务器${RESET} : ${VALUE}$dns${RESET}${BOX_V}\n"
    
    info_text+="${BOX_BL}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_H}${BOX_BR}\n"
    
    # Display info using dialog with colors enabled
    dialog --title "系统信息" \
           --colors \
           --msgbox "$info_text" 35 70
}

# 添加交互式菜单
show_menu() {
    local choice=$(dialog --clear \
                  --title "系统信息" \
                  --menu "请选择查看选项:" 15 60 6 \
                  "1" "系统信息概览" \
                  "2" "CPU使用情况" \
                  "3" "内存使用情况" \
                  "4" "磁盘使用情况" \
                  "5" "网络连接" \
                  "6" "返回主菜单" \
                  3>&1 1>&2 2>&3)
    
    case $choice in
        "1")
            get_system_info
            show_menu
            ;;
        "2")
            # 获取CPU使用信息并以图形方式显示
            local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}' | cut -d. -f1)
            local cpu_chart=""
            local i=0
            while [ $i -lt 50 ]; do
                if [ $i -lt $(($cpu_usage / 2)) ]; then
                    cpu_chart="${cpu_chart}#"
                else
                    cpu_chart="${cpu_chart}-"
                fi
                i=$((i+1))
            done
            
            dialog --title "CPU使用情况" \
                   --colors \
                   --msgbox "\n\n\Zb当前CPU使用率:\Zn \Z1$cpu_usage%\Zn\n\n[$cpu_chart]\n\n" 10 60
            show_menu
            ;;
        "3")
            # 获取内存使用情况并以图形方式显示
            local mem_info=$(free -m)
            local total_mem=$(echo "$mem_info" | grep Mem | awk '{print $2}')
            local used_mem=$(echo "$mem_info" | grep Mem | awk '{print $3}')
            local usage_percent=$((used_mem * 100 / total_mem))
            
            local mem_chart=""
            local i=0
            while [ $i -lt 50 ]; do
                if [ $i -lt $(($usage_percent / 2)) ]; then
                    mem_chart="${mem_chart}#"
                else
                    mem_chart="${mem_chart}-"
                fi
                i=$((i+1))
            done
            
            dialog --title "内存使用情况" \
                   --colors \
                   --msgbox "\n\n\Zb内存使用:\Zn \Z1$used_mem MB\Zn / \Z2$total_mem MB\Zn (\Z3$usage_percent%\Zn)\n\n[$mem_chart]\n\n" 10 60
            show_menu
            ;;
        "4")
            # 显示磁盘使用情况
            local disk_info=$(df -h | grep -v "tmpfs\|udev")
            dialog --title "磁盘使用情况" \
                   --colors \
                   --msgbox "$disk_info" 20 70
            show_menu
            ;;
        "5")
            # 显示网络连接
            local connections=$(netstat -tulpn | grep LISTEN | head -10)
            dialog --title "网络连接" \
                   --colors \
                   --msgbox "当前监听的网络连接:\n\n$connections" 20 70
            show_menu
            ;;
        "6"|"")
            return 0
            ;;
    esac
}

# Main function
main() {
    # 显示主菜单而不是直接显示系统信息
    show_menu
}

# Start the module
main