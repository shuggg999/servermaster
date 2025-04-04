#!/bin/bash

# Docker环境安装/更新脚本
# 此脚本用于安装或更新Docker环境

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

# 安装或更新Docker
install_or_update_docker() {
    local action="安装"
    local is_update=false
    
    # 检查Docker是否已安装
    if command -v docker &> /dev/null; then
        action="更新"
        is_update=true
        show_docker_already_installed
    fi
    
    # 提示用户确认安装/更新
    local title="${action}Docker环境"
    local content="您即将${action}Docker环境。\n\n这将${action}以下组件：\n· Docker Engine\n· Docker Compose\n· Docker命令行工具\n\n是否继续？"
    
    local confirm
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        read -p "是否继续? (y/n): " confirm
    else
        dialog --title "$title" --yesno "$content" 10 60
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
    
    # 显示处理中信息
    local process_msg="正在${action}Docker环境，请稍候..."
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$process_msg"
    else
        # 使用infobox显示进度信息
        dialog --infobox "$process_msg" 3 50
    fi
    
    # 安装必要的依赖
    local pkg_manager=""
    if command -v apt &> /dev/null; then
        pkg_manager="apt"
        # 更新软件包索引并安装依赖
        apt update -y
        apt install -y ca-certificates curl gnupg lsb-release
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
        yum install -y yum-utils device-mapper-persistent-data lvm2
    elif command -v dnf &> /dev/null; then
        pkg_manager="dnf"
        dnf -y install dnf-plugins-core
    else
        local error_msg="错误：不支持的操作系统。\n请确保您使用的是基于Debian、RHEL或Fedora的发行版。"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$error_msg"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "安装失败" --msgbox "$error_msg" 7 60
        fi
        return 1
    fi
    
    # 根据包管理器安装Docker
    case $pkg_manager in
        apt)
            # 添加Docker的GPG密钥
            mkdir -p /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            
            # 设置Docker APT源
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
            
            # 安装Docker
            apt update -y
            apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        yum)
            # 添加Docker源
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
            
            # 安装Docker
            yum install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
        dnf)
            # 添加Docker源
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            
            # 安装Docker
            dnf -y install docker-ce docker-ce-cli containerd.io docker-compose-plugin
            ;;
    esac
    
    # 安装Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        local compose_version="v2.20.3"
        local compose_path="/usr/local/bin/docker-compose"
        curl -L "https://github.com/docker/compose/releases/download/${compose_version}/docker-compose-$(uname -s)-$(uname -m)" -o "${compose_path}"
        chmod +x "${compose_path}"
    fi
    
    # 启动Docker服务
    systemctl start docker
    systemctl enable docker
    
    # 添加当前用户到docker组以避免使用sudo
    if getent passwd "$USER" &> /dev/null; then
        usermod -aG docker "$USER"
        echo "用户 $USER 已添加到docker组，请注销并重新登录以使权限生效。"
    fi
    
    # 显示安装完成信息
    local docker_version=$(docker --version)
    local compose_version=$(docker-compose --version)
    
    local result_content="Docker环境${action}成功！\n\n"
    result_content+="已安装组件:\n"
    result_content+="- ${docker_version}\n"
    result_content+="- ${compose_version}\n\n"
    result_content+="Docker服务已启动并设置为开机自启。\n"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$result_content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "Docker${action}完成" --msgbox "$result_content" $dialog_height $dialog_width
    fi
}

# 显示Docker已安装信息
show_docker_already_installed() {
    local docker_version=$(docker --version)
    local compose_version=$(docker-compose --version 2>/dev/null || docker compose version 2>/dev/null)
    local running_containers=$(docker ps -q | wc -l)
    local total_containers=$(docker ps -a -q | wc -l)
    local images_count=$(docker images -q | wc -l)
    
    local content="检测到Docker已经安装在系统中。\n\n"
    content+="当前版本信息:\n"
    content+="· ${docker_version}\n"
    content+="· ${compose_version}\n\n"
    content+="容器状态:\n"
    content+="· 运行中的容器: ${running_containers}\n"
    content+="· 容器总数: ${total_containers}\n"
    content+="· 镜像总数: ${images_count}\n\n"
    content+="您可以选择更新现有安装，或者保持现状。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        echo ""
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "Docker已安装" --msgbox "$content" $dialog_height $dialog_width
    fi
}

# 运行主函数
install_or_update_docker

# 恢复原始目录
cd "$CURRENT_DIR"