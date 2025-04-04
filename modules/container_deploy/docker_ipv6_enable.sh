#!/bin/bash

# Docker IPv6支持开启脚本
# 此脚本用于为Docker容器开启IPv6支持

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

# 开启Docker IPv6支持
enable_docker_ipv6() {
    local title="开启Docker IPv6支持"
    local content="此操作将为Docker容器启用IPv6网络支持。\n\n是否继续？"
    
    local confirm
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        read -p "是否继续? (y/n): " confirm
    else
        dialog --title "$title" --yesno "$content" 8 60
        local status=$?
        if [ $status -eq 0 ]; then
            confirm="y"
        else
            confirm="n"
        fi
    fi
    
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        return
    fi
    
    # 检查系统IPv6支持
    local ipv6_supported=false
    if [ -f /proc/net/if_inet6 ]; then
        ipv6_supported=true
    fi
    
    if [ "$ipv6_supported" != true ]; then
        local error_msg="错误: 您的系统不支持IPv6或IPv6功能已被禁用。\n请先确保系统级IPv6支持已启用。"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$error_msg"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "IPv6未启用" --msgbox "$error_msg" 8 60
        fi
        return
    fi
    
    # 配置Docker daemon.json
    mkdir -p /etc/docker
    
    # 获取当前配置
    local config="{}"
    if [ -f /etc/docker/daemon.json ]; then
        config=$(cat /etc/docker/daemon.json)
    fi
    
    # 创建临时文件
    local tmp_file=$(mktemp)
    
    # 检查是否已有IPv6配置
    if command -v jq &> /dev/null; then
        # 使用jq修改配置
        echo "$config" | jq '. + {"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64", "ip6tables": true, "experimental": true}' > "$tmp_file"
    else
        # 如果没有jq，使用简单的替换
        if [ "$config" = "{}" ]; then
            # 空配置，直接写入
            echo '{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "ip6tables": true,
  "experimental": true
}' > "$tmp_file"
        else
            # 有现有配置，需要合并
            # 移除最后的 }
            echo "$config" | sed 's/}$//' > "$tmp_file"
            # 检查是否需要添加逗号
            if ! grep -q ',$' "$tmp_file"; then
                echo ',' >> "$tmp_file"
            fi
            # 添加IPv6配置
            echo '  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64",
  "ip6tables": true,
  "experimental": true
}' >> "$tmp_file"
        fi
    fi
    
    # 应用配置
    cat "$tmp_file" > /etc/docker/daemon.json
    rm -f "$tmp_file"
    
    # 配置内核参数
    local sysctl_conf="/etc/sysctl.conf"
    
    # 添加或修改IPv6转发设置
    if grep -q "net.ipv6.conf.all.forwarding" "$sysctl_conf"; then
        sed -i 's/^net.ipv6.conf.all.forwarding.*/net.ipv6.conf.all.forwarding=1/' "$sysctl_conf"
    else
        echo "net.ipv6.conf.all.forwarding=1" >> "$sysctl_conf"
    fi
    
    # 应用内核参数
    sysctl -p "$sysctl_conf"
    
    # 重启Docker服务
    systemctl restart docker
    
    # 显示设置成功信息
    local result_content="Docker IPv6支持已成功启用！\n\n"
    result_content+="配置信息:\n"
    result_content+="- IPv6: 已启用\n"
    result_content+="- IPv6 CIDR: 2001:db8:1::/64\n"
    result_content+="- ip6tables: 已启用\n\n"
    result_content+="Docker服务已重启，新的IPv6配置已生效。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$result_content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "Docker IPv6已启用" --msgbox "$result_content" $dialog_height $dialog_width
    fi
}

# 运行主函数
enable_docker_ipv6

# 恢复原始目录
cd "$CURRENT_DIR"