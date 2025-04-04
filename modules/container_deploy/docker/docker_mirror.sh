#!/bin/bash

# Docker镜像源切换脚本
# 此脚本用于切换Docker默认镜像源

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

# 切换Docker镜像源
switch_docker_mirror() {
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        local error_msg="错误：未检测到Docker安装。\n请先安装Docker后再使用此功能。"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$error_msg"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "错误" --msgbox "$error_msg" 7 60
        fi
        return 1
    fi
    
    # 获取当前镜像源
    local current_mirror="Docker官方源"
    if [ -f /etc/docker/daemon.json ]; then
        if grep -q "registry-mirrors" /etc/docker/daemon.json; then
            local mirror_url=$(grep "registry-mirrors" -A 2 /etc/docker/daemon.json | grep -o 'https://[^"]*' | head -1)
            case "$mirror_url" in
                "https://registry.docker-cn.com")
                    current_mirror="Docker中国源 (已停用)"
                    ;;
                "https://hub-mirror.c.163.com")
                    current_mirror="网易云镜像源"
                    ;;
                "https://registry.aliyuncs.com")
                    current_mirror="阿里云镜像源"
                    ;;
                "https://mirror.ccs.tencentyun.com")
                    current_mirror="腾讯云镜像源"
                    ;;
                "https://docker.mirrors.ustc.edu.cn")
                    current_mirror="中科大镜像源"
                    ;;
                "https://mirror.baidubce.com")
                    current_mirror="百度云镜像源"
                    ;;
                "https://dockerhub.azk8s.cn")
                    current_mirror="Azure中国镜像源"
                    ;;
                "https://docker.nju.edu.cn")
                    current_mirror="南京大学镜像源"
                    ;;
                "https://docker.mirrors.sjtug.sjtu.edu.cn")
                    current_mirror="上海交大镜像源"
                    ;;
                *)
                    current_mirror="自定义镜像源: $mirror_url"
                    ;;
            esac
        fi
    fi
    
    # 定义菜单选项
    local title="Docker镜像源管理"
    local menu_text="选择要使用的Docker镜像源：\n当前使用: $current_mirror"
    
    local options=(
        "1" "Docker官方源 (默认)"
        "2" "阿里云镜像源"
        "3" "腾讯云镜像源"
        "4" "华为云镜像源"
        "5" "网易云镜像源"
        "6" "百度云镜像源"
        "7" "清华大学镜像源"
        "8" "中科大镜像源"
        "9" "自定义镜像源"
        "0" "返回上一级菜单"
    )
    
    local choice
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$menu_text"
        echo ""
        for ((i=0; i<${#options[@]}; i+=2)); do
            echo -e "${options[i]}) ${options[i+1]}"
        done
        echo ""
        read -p "请输入选项编号 [0-9]: " choice
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        choice=$(dialog --title "$title" --menu "$menu_text" $dialog_height $dialog_width 10 "${options[@]}" 3>&1 1>&2 2>&3)
    fi
    
    # 返回上级菜单
    if [ "$choice" = "0" ]; then
        return
    fi
    
    # 准备镜像源URL
    local mirror_url=""
    local mirror_name=""
    
    case "$choice" in
        1)
            mirror_name="Docker官方源"
            # 官方源不需要设置registry-mirrors
            ;;
        2)
            mirror_name="阿里云镜像源"
            mirror_url="https://kfj32x6r.mirror.aliyuncs.com"
            ;;
        3)
            mirror_name="腾讯云镜像源"
            mirror_url="https://mirror.ccs.tencentyun.com"
            ;;
        4)
            mirror_name="华为云镜像源"
            mirror_url="https://05f073ad3c0010ea0f4bc00b7105ec20.mirror.swr.myhuaweicloud.com"
            ;;
        5)
            mirror_name="网易云镜像源"
            mirror_url="https://hub-mirror.c.163.com"
            ;;
        6)
            mirror_name="百度云镜像源"
            mirror_url="https://mirror.baidubce.com"
            ;;
        7)
            mirror_name="清华大学镜像源"
            mirror_url="https://docker.mirrors.tuna.tsinghua.edu.cn"
            ;;
        8)
            mirror_name="中科大镜像源"
            mirror_url="https://docker.mirrors.ustc.edu.cn"
            ;;
        9)
            # 自定义镜像源
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "请输入自定义Docker镜像源URL (必须以https://开头):"
                read -p "> " mirror_url
            else
                mirror_url=$(dialog --title "自定义镜像源" --inputbox "请输入自定义Docker镜像源URL\n(必须以https://开头):" 8 60 3>&1 1>&2 2>&3)
            fi
            
            if [ -z "$mirror_url" ]; then
                local error_msg="错误：未提供有效的镜像源URL。操作已取消。"
                
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo -e "$error_msg"
                    read -p "按Enter键继续..." confirm
                else
                    dialog --title "错误" --msgbox "$error_msg" 7 60
                fi
                return 1
            fi
            
            # 验证URL格式
            if [[ ! "$mirror_url" =~ ^https:// ]]; then
                local error_msg="错误：镜像源URL必须以https://开头。操作已取消。"
                
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo -e "$error_msg"
                    read -p "按Enter键继续..." confirm
                else
                    dialog --title "错误" --msgbox "$error_msg" 7 60
                fi
                return 1
            fi
            
            mirror_name="自定义镜像源"
            ;;
        *)
            local error_msg="错误：无效的选择。请输入0-9之间的数字。"
            
            if [ "$USE_TEXT_MODE" = true ]; then
                echo -e "$error_msg"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "错误" --msgbox "$error_msg" 7 60
            fi
            return 1
            ;;
    esac
    
    # 更新daemon.json配置
    mkdir -p /etc/docker
    
    # 获取当前配置
    local config="{}"
    if [ -f /etc/docker/daemon.json ]; then
        config=$(cat /etc/docker/daemon.json)
    fi
    
    # 创建临时文件
    local tmp_file=$(mktemp)
    
    # 更新配置
    if [ -z "$mirror_url" ]; then
        # Docker官方源，删除registry-mirrors配置
        if command -v jq &> /dev/null; then
            # 使用jq删除registry-mirrors
            echo "$config" | jq 'del(.["registry-mirrors"])' > "$tmp_file"
        else
            # 没有jq，使用简单的替换方法
            echo "$config" | grep -v "registry-mirrors" > "$tmp_file"
            # 修复格式问题
            sed -i 's/,\s*}/}/g' "$tmp_file"  # 删除最后一个逗号
            sed -i 's/,\s*,/,/g' "$tmp_file"  # 删除多余的逗号
        fi
    else
        # 设置镜像源
        if command -v jq &> /dev/null; then
            # 使用jq添加registry-mirrors
            echo "$config" | jq --arg mirror "[$mirror_url]" '.["registry-mirrors"] = $mirror | fromjson' > "$tmp_file"
        else
            # 没有jq，使用简单的添加方法
            if [ "$config" = "{}" ]; then
                # 空配置，直接写入
                echo "{
  \"registry-mirrors\": [\"$mirror_url\"]
}" > "$tmp_file"
            else
                # 有现有配置，需要合并
                # 检查是否已有registry-mirrors
                if grep -q "registry-mirrors" "$config"; then
                    # 替换现有的registry-mirrors
                    sed "s|\"registry-mirrors\": \[[^]]*\]|\"registry-mirrors\": [\"$mirror_url\"]|g" "$config" > "$tmp_file"
                else
                    # 添加新的registry-mirrors
                    # 移除最后的 }
                    echo "$config" | sed 's/}$//' > "$tmp_file"
                    # 检查是否需要添加逗号
                    if ! grep -q ',$' "$tmp_file"; then
                        echo ',' >> "$tmp_file"
                    fi
                    # 添加registry-mirrors
                    echo "  \"registry-mirrors\": [\"$mirror_url\"]
}" >> "$tmp_file"
                fi
            fi
        fi
    fi
    
    # 应用配置
    cat "$tmp_file" > /etc/docker/daemon.json
    rm -f "$tmp_file"
    
    # 重启Docker服务
    systemctl restart docker
    
    # 显示设置成功信息
    local result_title="Docker镜像源已更新"
    local result_msg=""
    
    if [ -z "$mirror_url" ]; then
        result_msg="已切换到Docker官方源。\nDocker服务已重启，新配置已生效。"
    else
        result_msg="已切换到${mirror_name}：${mirror_url}\nDocker服务已重启，新配置已生效。"
    fi
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$result_msg"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        dialog --title "$result_title" --msgbox "$result_msg" 7 65
    fi
}

# 运行主函数
switch_docker_mirror

# 恢复原始目录
cd "$CURRENT_DIR"