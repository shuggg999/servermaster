#!/bin/bash

# System Information Module
# This module displays system information using Dialog

# Get system information
get_system_info() {
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
    
    # Create info text
    local info_text="系统信息概览：\n\n"
    info_text+="主机名：$hostname\n"
    info_text+="操作系统：$os_info\n"
    info_text+="内核版本：$kernel\n"
    info_text+="运行时间：$uptime\n"
    info_text+="系统负载：$load_avg\n\n"
    
    info_text+="CPU信息：\n"
    info_text+="CPU型号：$cpu_model\n"
    info_text+="CPU核心数：$cpu_cores\n"
    info_text+="CPU频率：$cpu_freq MHz\n\n"
    
    info_text+="内存信息：\n"
    info_text+="总内存：$total_mem\n"
    info_text+="已用内存：$used_mem\n"
    info_text+="空闲内存：$free_mem\n"
    info_text+="交换空间：$swap_total (已用: $swap_used)\n\n"
    
    info_text+="磁盘信息：\n"
    info_text+="总空间：$disk_total\n"
    info_text+="已用空间：$disk_used\n"
    info_text+="使用率：$disk_usage\n\n"
    
    info_text+="网络信息：\n"
    info_text+="公网IPv4：$ipv4\n"
    info_text+="DNS服务器：$dns"
    
    # Display info using dialog
    dialog --title "系统信息" \
           --msgbox "$info_text" 25 70
}

# Main function
main() {
    get_system_info
}

# Start the module
main