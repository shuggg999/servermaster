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
    BOLD='\033[1m'
    DIM='\033[2m'
    UNDERLINE='\033[4m'
    BLINK='\033[5m'
    REVERSE='\033[7m'
    HIDDEN='\033[8m'
fi

# 打印单行信息的函数：label 和 value
print_info() {
    local label="$1"
    local value="$2"
    # 设置固定宽度，确保右侧边框对齐
    printf "${BLUE}║${NC} ${CYAN}%-15s${NC} ${WHITE}%-50s${NC} ${BLUE}║${NC}\n" "$label:" "$value"
}

# Function to get IP address information
get_ip_address() {
    # 尝试从多个服务获取公网IPv4地址
    local ipv4=""
    local ipv4_sources=(
        "https://api.ipify.org"
        "https://ipv4.icanhazip.com"
        "https://v4.ident.me"
    )
    
    for source in "${ipv4_sources[@]}"; do
        ipv4=$(curl -s --connect-timeout 3 "$source" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$ipv4" ]; then
            break
        fi
    done
    
    # 尝试从多个服务获取公网IPv6地址
    local ipv6=""
    local ipv6_sources=(
        "https://api6.ipify.org"
        "https://ipv6.icanhazip.com"
        "https://v6.ident.me"
    )
    
    for source in "${ipv6_sources[@]}"; do
        ipv6=$(curl -s --connect-timeout 3 "$source" 2>/dev/null)
        if [ $? -eq 0 ] && [ -n "$ipv6" ]; then
            break
        fi
    done
    
    # 获取本地IP地址
    local local_ip=$(ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v "127.0.0.1" | head -n 1)
    
    # 显示IP地址信息
    print_info "公网IPv4" "${ipv4:-未检测到}"
    print_info "公网IPv6" "${ipv6:-未检测到}"
    print_info "本地IPv4" "${local_ip:-未检测到}"
}

# 获取系统信息
get_system_info() {
    # 获取主机名
    local hostname=$(hostname)
    print_info "主机名" "$hostname"
    
    # 获取操作系统信息
    local os_info=$(cat /etc/os-release | grep "PRETTY_NAME" | cut -d "=" -f 2 | tr -d '"')
    print_info "操作系统" "$os_info"
    
    # 获取内核版本
    local kernel=$(uname -r)
    print_info "内核版本" "$kernel"
    
    # 获取运行时间
    local uptime=$(uptime -p | sed 's/up //')
    print_info "运行时间" "$uptime"
    
    # 获取负载
    local load=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
    print_info "系统负载" "$load"
    
    # 获取CPU信息
    local cpu_model=$(cat /proc/cpuinfo | grep "model name" | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//')
    local cpu_cores=$(cat /proc/cpuinfo | grep "processor" | wc -l)
    local cpu_freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -n 1 | cut -d ":" -f 2 | sed 's/^[ \t]*//' | awk '{printf "%.2f GHz", $1/1000}')
    
    print_info "CPU型号" "$cpu_model"
    print_info "CPU核心数" "$cpu_cores"
    print_info "CPU频率" "$cpu_freq"
    
    # 获取内存使用情况
    local mem_total=$(free -h | grep "Mem" | awk '{print $2}')
    local mem_used=$(free -h | grep "Mem" | awk '{print $3}')
    local mem_free=$(free -h | grep "Mem" | awk '{print $4}')
    local mem_usage=$(free | grep Mem | awk '{printf "%.2f%%", $3/$2 * 100}')
    
    print_info "内存总量" "$mem_total"
    print_info "已用内存" "$mem_used ($mem_usage)"
    print_info "可用内存" "$mem_free"
    
    # 获取交换分区信息
    local swap_total=$(free -h | grep "Swap" | awk '{print $2}')
    local swap_used=$(free -h | grep "Swap" | awk '{print $3}')
    local swap_free=$(free -h | grep "Swap" | awk '{print $4}')
    
    print_info "交换分区总量" "$swap_total"
    print_info "已用交换分区" "$swap_used"
    print_info "可用交换分区" "$swap_free"
    
    # 获取磁盘使用情况
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                      ${BOLD}${YELLOW}磁盘使用情况${NC}                                     ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # 表头
    printf "${BLUE}║${NC} ${CYAN}%-14s %-10s %-12s %-12s %-10s${NC} ${BLUE}║${NC}\n" "挂载点" "总容量" "已用空间" "可用空间" "使用率"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # 磁盘信息
    df -h | grep -v "tmpfs" | grep -v "udev" | grep -v "loop" | grep -v "Filesystem" | while read line; do
        local mount=$(echo $line | awk '{print $6}')
        local total=$(echo $line | awk '{print $2}')
        local used=$(echo $line | awk '{print $3}')
        local avail=$(echo $line | awk '{print $4}')
        local usage=$(echo $line | awk '{print $5}')
        
        printf "${BLUE}║${NC} ${WHITE}%-14s %-10s %-12s %-12s %-10s${NC} ${BLUE}║${NC}\n" "$mount" "$total" "$used" "$avail" "$usage"
    done
    
    # 获取DNS服务器
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}                      ${BOLD}${YELLOW}DNS服务器${NC}                                        ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    cat /etc/resolv.conf | grep "nameserver" | while read line; do
        local dns=$(echo $line | awk '{print $2}')
        printf "${BLUE}║${NC} ${WHITE}%-65s${NC} ${BLUE}║${NC}\n" "$dns"
    done
    
    # 获取网络接口信息
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}                      ${BOLD}${YELLOW}网络接口${NC}                                         ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # 表头
    printf "${BLUE}║${NC} ${CYAN}%-12s %-18s %-18s %-12s${NC} ${BLUE}║${NC}\n" "接口名" "IP地址" "MAC地址" "状态"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # 网络接口信息
    ip -o addr show | grep -v "lo" | grep -v "docker" | grep -v "br-" | grep -v "veth" | while read line; do
        local interface=$(echo $line | awk '{print $2}')
        local ip=$(echo $line | awk '{print $4}')
        local mac=$(ip link show $interface | grep "link/ether" | awk '{print $2}')
        local status=$(ip link show $interface | grep -oP '(?<=state )[^ ]*')
        
        printf "${BLUE}║${NC} ${WHITE}%-12s %-18s %-18s %-12s${NC} ${BLUE}║${NC}\n" "$interface" "$ip" "$mac" "$status"
    done
}

# 显示模块标题栏函数
show_module_header() {
    local title="$1"
    clear
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    
    # 使用printf居中显示标题
    local title_text="${BOLD}${CYAN}ServerMaster${NC} - ${YELLOW}$title${NC}"
    local title_length=${#title_text}
    local padding=$(( (65 - title_length) / 2 ))
    
    printf "${BLUE}║${NC}%${padding}s%s%${padding}s${BLUE}║${NC}\n" "" "$title_text" ""
    
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# 显示模块底部函数
show_module_footer() {
    echo ""
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    
    # 使用printf居中显示提示信息
    local footer_text="${YELLOW}按回车键返回上一级菜单...${NC}"
    local footer_length=${#footer_text}
    local padding=$(( (65 - footer_length) / 2 ))
    
    printf "${BLUE}║${NC}%${padding}s%s%${padding}s${BLUE}║${NC}\n" "" "$footer_text" ""
    
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    read
}

# 主函数
main() {
    # 显示模块标题
    show_module_header "系统信息"
    
    # 显示系统信息部分
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                      ${BOLD}${CYAN}基本系统信息${NC}                                     ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # 获取系统信息
    get_system_info
    
    # 显示IP地址信息部分
    echo -e "\n${BLUE}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}                      ${BOLD}${GREEN}网络连接信息${NC}                                     ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    # 获取IP地址信息
    get_ip_address
    
    # 尝试获取地理位置信息
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BLUE}║${NC}                      ${BOLD}${GREEN}地理位置信息${NC}                                     ${BLUE}║${NC}"
    echo -e "${BLUE}╠═══════════════════════════════════════════════════════════════════════════╣${NC}"
    
    ip_info=$(curl -s --connect-timeout 5 ipinfo.io 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$ip_info" ]; then
        country=$(echo "$ip_info" | grep -oP '"country": "\K[^"]+' 2>/dev/null)
        region=$(echo "$ip_info" | grep -oP '"region": "\K[^"]+' 2>/dev/null)
        city=$(echo "$ip_info" | grep -oP '"city": "\K[^"]+' 2>/dev/null)
        isp=$(echo "$ip_info" | grep -oP '"org": "\K[^"]+' 2>/dev/null)
        
        print_info "国家/地区" "${country:-未知}"
        print_info "省份/城市" "${region:-未知}/${city:-未知}"
        print_info "运营商" "${isp:-未知}"
    else
        printf "${BLUE}║${NC} ${RED}%-65s${NC} ${BLUE}║${NC}\n" "无法获取地理位置信息，请检查网络连接"
    fi
    
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    
    # 显示模块底部
    show_module_footer
}

# 执行主函数
main "$@"