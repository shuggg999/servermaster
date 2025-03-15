#!/bin/bash

# System Information Query Module
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

# Function to get IP address information
get_ip_address() {
    ipv4_address=$(curl -s ipinfo.io/ip || curl -s ifconfig.me || curl -s icanhazip.com)
    ipv6_address=$(curl -s --max-time 1 ipv6.icanhazip.com || echo "Not available")
    
    echo -e "${CYAN}IPv4 地址:${NC} ${WHITE}$ipv4_address${NC}"
    if [ "$ipv6_address" != "Not available" ]; then
        echo -e "${CYAN}IPv6 地址:${NC} ${WHITE}$ipv6_address${NC}"
    else
        echo -e "${CYAN}IPv6 地址:${NC} ${GRAY}不可用${NC}"
    fi
}


# Function to get system information
get_system_info() {
    # Get CPU information
    cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')
    cpu_cores=$(nproc)
    cpu_freq=$(lscpu | grep "CPU MHz" | awk '{printf "%.2f GHz", $3/1000}')
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')

    # Get memory information
    mem_info=$(free -m | awk 'NR==2{printf "%.2f/%.2fGB (%.2f%%)", $3/1024, $2/1024, $3*100/$2}')
    swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%.2fGB/%.2fGB (%.0f%%)", used/1024, total/1024, percentage}')

    # Get disk information
    disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

    # Get load average
    load_avg=$(uptime | awk -F'load average: ' '{print $2}')

    # Get uptime
    uptime_info=$(uptime -p)
    uptime_info=${uptime_info:3} # Remove "up " prefix

    # Get OS information
    os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')

    # Get kernel information
    kernel_version=$(uname -r)

    # Networking information
    dns_info=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | tr '\n' ' ')
    netstat_installed=$(command -v netstat > /dev/null && echo "yes" || echo "no")
    
    if [ "$netstat_installed" = "yes" ]; then
        connection_count=$(netstat -an | wc -l)
        established_connections=$(netstat -an | grep ESTABLISHED | wc -l)
    else
        connection_count="未安装 netstat"
        established_connections="未安装 netstat"
    fi

    # Get hostname
    hostname=$(hostname)

    # Display system information
    echo ""
    echo -e "${BRIGHT_GREEN}┌──────────────────── 系统信息 ────────────────────┐${NC}"
    echo -e "${CYAN}主机名:${NC}         ${WHITE}$hostname${NC}"
    echo -e "${CYAN}操作系统:${NC}       ${WHITE}$os_info${NC}"
    echo -e "${CYAN}内核版本:${NC}       ${WHITE}$kernel_version${NC}"
    echo -e "${CYAN}运行时间:${NC}       ${WHITE}$uptime_info${NC}"
    echo -e "${CYAN}负载情况:${NC}       ${WHITE}$load_avg${NC}"
    echo -e "${BRIGHT_GREEN}├──────────────────── 硬件信息 ────────────────────┤${NC}"
    echo -e "${CYAN}CPU型号:${NC}        ${WHITE}$cpu_info${NC}"
    echo -e "${CYAN}CPU核心数:${NC}      ${WHITE}$cpu_cores${NC}"
    echo -e "${CYAN}CPU频率:${NC}        ${WHITE}$cpu_freq${NC}"
    echo -e "${CYAN}CPU占用:${NC}        ${WHITE}${cpu_usage}%${NC}"
    echo -e "${CYAN}内存使用:${NC}       ${WHITE}$mem_info${NC}"
    echo -e "${CYAN}交换分区:${NC}       ${WHITE}$swap_info${NC}"
    echo -e "${CYAN}磁盘使用:${NC}       ${WHITE}$disk_info${NC}"
    echo -e "${BRIGHT_GREEN}├──────────────────── 网络信息 ────────────────────┤${NC}"
    
    # Show IP information
    get_ip_address
    
    # Get network information about the country and ISP using ipinfo.io
    ip_info=$(curl -s ipinfo.io)
    country=$(echo "$ip_info" | grep -oP '"country": "\K[^"]+')
    region=$(echo "$ip_info" | grep -oP '"region": "\K[^"]+')
    city=$(echo "$ip_info" | grep -oP '"city": "\K[^"]+')
    isp=$(echo "$ip_info" | grep -oP '"org": "\K[^"]+')
    
    # Display network information
    echo -e "${CYAN}DNS 服务器:${NC}     ${WHITE}$dns_info${NC}"
    echo -e "${CYAN}连接数:${NC}         ${WHITE}$connection_count${NC} (已建立: ${WHITE}$established_connections${NC})"
    echo -e "${CYAN}网络位置:${NC}       ${WHITE}$country $region $city${NC}"
    echo -e "${CYAN}运营商:${NC}         ${WHITE}$isp${NC}"
    echo -e "${BRIGHT_GREEN}└────────────────────────────────────────────────┘${NC}"
    echo ""
}

# Clear the screen
clear

# Show header
echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
echo -e "                               ${CYAN}${BOLD}「 系统信息查询 」${NC}"
echo -e "                               ${BLUE}===============================${NC}"
echo -e "${YELLOW}★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★${NC}"
echo ""

# Show system information
get_system_info

# Wait for user input before returning
echo -e "${YELLOW}按回车键返回上一级菜单...${NC}"
read