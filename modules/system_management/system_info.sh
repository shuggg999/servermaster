#!/bin/bash

# 系统信息查询
# 此脚本提供系统基本信息的查询功能

# 只在变量未定义时才设置安装目录
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
    MODULES_DIR="$INSTALL_DIR/modules"
    CONFIG_DIR="$INSTALL_DIR/config"
    
    # 导入共享函数
    source "$INSTALL_DIR/main.sh"
    
    # 导入对话框规则
    source "$CONFIG_DIR/dialog_rules.sh"
fi

# 保存当前目录
CURRENT_DIR="$(pwd)"

# 显示系统信息
show_system_info() {
    # 确保我们在正确的目录
    cd "$INSTALL_DIR"
    
    clear
    
    # 获取IP地址信息
    ip_address_info() {
        ipv4_address=$(curl -s4 --max-time 5 ip.sb)
        ipv6_address=$(curl -s6 --max-time 5 ip.sb)
    }
    
    ip_address_info
    
    # 获取CPU信息
    local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')
    
    # 获取CPU使用率
    local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
        <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))
    
    # 获取CPU核心数
    local cpu_cores=$(nproc)
    
    # 获取CPU频率
    local cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')
    
    # 获取内存信息
    local mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2fM (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')
    
    # 获取磁盘信息
    local disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')
    
    # 获取IP地理位置信息
    local ipinfo=$(curl -s ipinfo.io)
    local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
    local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
    local isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')
    
    # 获取系统负载
    local load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
    
    # 获取DNS地址
    local dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)
    
    # 获取CPU架构
    local cpu_arch=$(uname -m)
    
    # 获取主机名
    local hostname=$(uname -n)
    
    # 获取内核版本
    local kernel_version=$(uname -r)
    
    # 获取网络算法
    local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    local queue_algorithm=$(sysctl -n net.core.default_qdisc)
    
    # 获取操作系统信息
    local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')
    
    # 获取虚拟内存信息
    local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')
    
    # 获取运行时长
    local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')
    
    # 获取时区和当前时间
    local current_time=$(date "+%Y-%m-%d %I:%M %p")
    local timezone=$(date +%Z)
    
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "====================================================="
        echo "      系统信息查询                                    "
        echo "====================================================="
        echo ""
        echo "-------------"
        echo "主机名:       $hostname"
        echo "系统版本:     $os_info"
        echo "Linux版本:    $kernel_version"
        echo "-------------"
        echo "CPU架构:      $cpu_arch"
        echo "CPU型号:      $cpu_info"
        echo "CPU核心数:    $cpu_cores"
        echo "CPU频率:      $cpu_freq"
        echo "-------------"
        echo "CPU占用:      $cpu_usage_percent%"
        echo "系统负载:     $load"
        echo "物理内存:     $mem_info"
        echo "虚拟内存:     $swap_info"
        echo "硬盘占用:     $disk_info"
        echo "-------------"
        echo "网络算法:     $congestion_algorithm $queue_algorithm"
        echo "-------------"
        echo "运营商:       $isp_info"
        if [ -n "$ipv4_address" ]; then
            echo "IPv4地址:     $ipv4_address"
        fi
        if [ -n "$ipv6_address" ]; then
            echo "IPv6地址:     $ipv6_address"
        fi
        echo "DNS地址:      $dns_addresses"
        echo "地理位置:     $country $city"
        echo "系统时间:     $timezone $current_time"
        echo "-------------"
        echo "运行时长:     $runtime"
        echo ""
        echo "按Enter键继续..."
        read
    else
        # 使用Dialog显示系统信息
        # 构建对话框显示信息
        local info_text="主机名:       $hostname\n"
        info_text+="系统版本:     $os_info\n"
        info_text+="Linux版本:    $kernel_version\n"
        info_text+="-------------\n"
        info_text+="CPU架构:      $cpu_arch\n"
        info_text+="CPU型号:      $cpu_info\n"
        info_text+="CPU核心数:    $cpu_cores\n"
        info_text+="CPU频率:      $cpu_freq\n"
        info_text+="-------------\n"
        info_text+="CPU占用:      $cpu_usage_percent%\n"
        info_text+="系统负载:     $load\n"
        info_text+="物理内存:     $mem_info\n"
        info_text+="虚拟内存:     $swap_info\n"
        info_text+="硬盘占用:     $disk_info\n"
        info_text+="-------------\n"
        info_text+="网络算法:     $congestion_algorithm $queue_algorithm\n"
        info_text+="-------------\n"
        info_text+="运营商:       $isp_info\n"
        
        if [ -n "$ipv4_address" ]; then
            info_text+="IPv4地址:     $ipv4_address\n"
        fi
        
        if [ -n "$ipv6_address" ]; then
            info_text+="IPv6地址:     $ipv6_address\n"
        fi
        
        info_text+="DNS地址:      $dns_addresses\n"
        info_text+="地理位置:     $country $city\n"
        info_text+="系统时间:     $timezone $current_time\n"
        info_text+="-------------\n"
        info_text+="运行时长:     $runtime\n"
        
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 使用Dialog显示信息
        dialog --title "系统信息查询" --msgbox "$info_text" $dialog_height $dialog_width
    fi
}

# 直接显示系统信息，不再显示菜单
show_system_info

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 