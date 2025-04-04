#!/bin/bash

# Docker配置编辑脚本
# 此脚本用于编辑Docker的daemon.json配置文件

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

# 编辑Docker配置文件
edit_docker_config() {
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
    
    # 确保目录存在
    mkdir -p /etc/docker
    
    # 检查配置文件是否存在
    if [ ! -f /etc/docker/daemon.json ]; then
        echo "{}" > /etc/docker/daemon.json
    fi
    
    # 显示当前配置
    local current_config=$(cat /etc/docker/daemon.json)
    
    # 选择编辑器
    local editor="nano"
    if ! command -v nano &> /dev/null; then
        if command -v vim &> /dev/null; then
            editor="vim"
        elif command -v vi &> /dev/null; then
            editor="vi"
        else
            # 安装nano编辑器
            if command -v apt &> /dev/null; then
                apt update && apt install -y nano
                editor="nano"
            elif command -v yum &> /dev/null; then
                yum install -y nano
                editor="nano"
            elif command -v dnf &> /dev/null; then
                dnf install -y nano
                editor="nano"
            else
                local error_msg="错误：系统中未找到可用的文本编辑器。\n请手动安装nano、vim或vi后重试。"
                
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo -e "$error_msg"
                    read -p "按Enter键继续..." confirm
                else
                    dialog --title "错误" --msgbox "$error_msg" 7 60
                fi
                return 1
            fi
        fi
    fi
    
    # 在文本模式下显示编辑提示
    if [ "$USE_TEXT_MODE" = true ]; then
        echo "当前Docker配置文件内容:"
        echo "$current_config"
        echo ""
        echo "即将使用 $editor 编辑器打开配置文件。"
        echo "编辑完成后保存并退出编辑器以应用更改。"
        read -p "按Enter键继续..." confirm
    else
        # 在对话框模式下显示当前配置
        local info_msg="当前Docker配置文件内容:\n\n$current_config\n\n即将使用 $editor 编辑器打开配置文件。\n编辑完成后保存并退出编辑器以应用更改。"
        dialog --title "Docker配置" --msgbox "$info_msg" 15 60
    fi
    
    # 使用编辑器打开配置文件
    $editor /etc/docker/daemon.json
    
    # 验证JSON语法
    if ! python3 -c "import json; json.load(open('/etc/docker/daemon.json'))" 2>/dev/null && \
       ! python -c "import json; json.load(open('/etc/docker/daemon.json'))" 2>/dev/null && \
       ! jq '.' /etc/docker/daemon.json >/dev/null 2>&1; then
        
        local error_msg="警告：配置文件可能包含无效的JSON语法。\n这可能导致Docker无法正常启动。\n\n是否重新编辑配置文件？"
        
        local confirm
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$error_msg"
            read -p "是否重新编辑? (y/n): " confirm
            if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                edit_docker_config
                return
            fi
        else
            dialog --title "无效的JSON" --yesno "$error_msg" 10 60
            local status=$?
            if [ $status -eq 0 ]; then
                edit_docker_config
                return
            fi
        fi
    fi
    
    # 重启Docker服务
    local restart_msg="配置已保存。需要重启Docker服务以应用更改。\n\n是否立即重启Docker服务？"
    
    local confirm
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$restart_msg"
        read -p "是否重启Docker? (y/n): " confirm
    else
        dialog --title "重启Docker" --yesno "$restart_msg" 8 60
        local status=$?
        if [ $status -eq 0 ]; then
            confirm="y"
        else
            confirm="n"
        fi
    fi
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        systemctl restart docker
        
        # 检查Docker是否成功重启
        sleep 2
        if systemctl is-active docker >/dev/null; then
            local success_msg="Docker服务已成功重启，新配置已生效。"
            
            if [ "$USE_TEXT_MODE" = true ]; then
                echo -e "$success_msg"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "重启成功" --msgbox "$success_msg" 6 40
            fi
        else
            local error_msg="错误：Docker服务重启失败。\n\n这可能是由于配置文件中的错误导致的。\n请检查配置文件内容并修复错误。"
            
            if [ "$USE_TEXT_MODE" = true ]; then
                echo -e "$error_msg"
                read -p "按Enter键继续..." confirm
            else
                dialog --title "重启失败" --msgbox "$error_msg" 8 50
            fi
        fi
    else
        local notice_msg="配置已保存，但未重启Docker服务。\n新配置将在下次Docker服务重启后生效。"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$notice_msg"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "注意" --msgbox "$notice_msg" 6 60
        fi
    fi
}

# 运行主函数
edit_docker_config

# 恢复原始目录
cd "$CURRENT_DIR"