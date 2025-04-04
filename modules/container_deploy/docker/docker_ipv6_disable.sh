#!/bin/bash

# Docker IPv6支持关闭脚本
# 此脚本用于关闭Docker容器的IPv6支持

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

# 关闭Docker IPv6支持
disable_docker_ipv6() {
    local title="关闭Docker IPv6支持"
    local content="此操作将为Docker容器禁用IPv6网络支持。\n\n是否继续？"
    
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
    
    # 检查Docker daemon.json是否存在
    if [ ! -f /etc/docker/daemon.json ]; then
        # 文件不存在，表示Docker可能使用默认配置
        local empty_msg="未找到Docker配置文件。\nDocker可能正在使用默认配置，无需禁用IPv6。"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$empty_msg"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "未找到配置" --msgbox "$empty_msg" 8 60
        fi
        return
    fi
    
    # 获取当前配置
    local config=$(cat /etc/docker/daemon.json)
    
    # 创建临时文件
    local tmp_file=$(mktemp)
    
    # 检查是否有jq工具
    if command -v jq &> /dev/null; then
        # 使用jq删除IPv6相关配置
        echo "$config" | jq 'del(.ipv6) | del(.["fixed-cidr-v6"]) | del(.ip6tables)' > "$tmp_file"
    else
        # 没有jq，使用简单的替换方法
        # 删除ipv6相关配置行
        echo "$config" | grep -v '"ipv6":' | grep -v '"fixed-cidr-v6":' | grep -v '"ip6tables":' > "$tmp_file"
        
        # 修复格式问题
        sed -i 's/,\s*}/}/g' "$tmp_file"   # 删除最后一个逗号
        sed -i 's/,\s*,/,/g' "$tmp_file"   # 删除多余的逗号
    fi
    
    # 应用配置
    cat "$tmp_file" > /etc/docker/daemon.json
    rm -f "$tmp_file"
    
    # 重启Docker服务
    systemctl restart docker
    
    # 显示设置成功信息
    local result_content="Docker IPv6支持已成功禁用！\n\n"
    result_content+="Docker配置已更新，IPv6相关设置已移除。\n"
    result_content+="Docker服务已重启，新的配置已生效。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$result_content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "Docker IPv6已禁用" --msgbox "$result_content" $dialog_height $dialog_width
    fi
}

# 运行主函数
disable_docker_ipv6

# 恢复原始目录
cd "$CURRENT_DIR"