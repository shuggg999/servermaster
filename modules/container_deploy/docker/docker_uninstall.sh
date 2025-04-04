#!/bin/bash

# Docker环境完全卸载脚本
# 此脚本用于完全卸载Docker及所有相关组件和配置

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

# 卸载Docker
uninstall_docker() {
    # 检查Docker是否已安装
    if ! command -v docker &> /dev/null; then
        local error_msg="Docker未安装。没有需要卸载的组件。"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo -e "$error_msg"
            read -p "按Enter键继续..." confirm
        else
            dialog --title "未安装" --msgbox "$error_msg" 6 40
        fi
        return
    fi
    
    # 提示用户确认卸载
    local title="卸载Docker"
    local content="此操作将完全卸载Docker环境，包括：\n\n"
    content+="· 停止并删除所有运行中的容器\n"
    content+="· 删除所有Docker镜像、网络和卷\n"
    content+="· 卸载Docker Engine和Docker Compose\n"
    content+="· 删除所有Docker配置文件和数据\n\n"
    content+="警告：此操作不可逆！所有Docker数据将永久丢失！\n\n"
    content+="是否确认继续？"
    
    local confirm
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        read -p "输入 'CONFIRM' 确认卸载Docker: " confirm
        if [ "$confirm" != "CONFIRM" ]; then
            echo "操作已取消。"
            return
        fi
    else
        dialog --title "$title" --yesno "$content" 16 65
        local status=$?
        if [ $status -ne 0 ]; then
            return
        fi
        
        # 二次确认
        dialog --title "再次确认" --inputbox "请输入 'CONFIRM' 确认卸载Docker:" 8 40 3>&1 1>&2 2>&3
        confirm=$?
        if [ "$confirm" != "CONFIRM" ]; then
            dialog --title "已取消" --msgbox "操作已取消。" 5 30
            return
        fi
    fi
    
    # 显示处理中信息
    local process_msg="正在卸载Docker环境，请稍候..."
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$process_msg"
    else
        # 使用infobox显示进度信息
        dialog --infobox "$process_msg" 3 50
    fi
    
    # 停止所有容器
    if docker ps -q &>/dev/null; then
        echo "停止所有运行中的容器..."
        docker stop $(docker ps -q) &>/dev/null
    fi
    
    # 删除所有容器
    if docker ps -a -q &>/dev/null; then
        echo "删除所有容器..."
        docker rm -f $(docker ps -a -q) &>/dev/null
    fi
    
    # 删除所有镜像
    if docker images -q &>/dev/null; then
        echo "删除所有镜像..."
        docker rmi -f $(docker images -q) &>/dev/null
    fi
    
    # 删除所有卷
    if docker volume ls -q &>/dev/null; then
        echo "删除所有数据卷..."
        docker volume rm $(docker volume ls -q) &>/dev/null
    fi
    
    # 删除所有网络
    if docker network ls -q &>/dev/null; then
        echo "删除所有自定义网络..."
        for network in $(docker network ls --filter type=custom -q); do
            docker network rm $network &>/dev/null
        done
    fi
    
    # 停止Docker服务
    echo "停止Docker服务..."
    systemctl stop docker
    systemctl disable docker
    
    # 卸载Docker包
    echo "卸载Docker包..."
    local pkg_manager=""
    if command -v apt &> /dev/null; then
        pkg_manager="apt"
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        apt-get autoremove -y
    elif command -v yum &> /dev/null; then
        pkg_manager="yum"
        yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    elif command -v dnf &> /dev/null; then
        pkg_manager="dnf"
        dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    fi
    
    # 删除Docker Compose
    if [ -f /usr/local/bin/docker-compose ]; then
        echo "删除Docker Compose..."
        rm -f /usr/local/bin/docker-compose
    fi
    
    # 删除Docker数据目录
    echo "删除Docker数据目录..."
    rm -rf /var/lib/docker
    rm -rf /var/lib/containerd
    
    # 删除Docker配置文件
    echo "删除Docker配置文件..."
    rm -rf /etc/docker
    
    # 清理系统中的Docker相关配置
    if [ "$pkg_manager" = "apt" ]; then
        rm -rf /etc/apt/sources.list.d/docker.list
        rm -f /etc/apt/keyrings/docker.gpg
    elif [ "$pkg_manager" = "yum" ] || [ "$pkg_manager" = "dnf" ]; then
        rm -f /etc/yum.repos.d/docker-ce.repo
    fi
    
    # 显示完成信息
    local result_content="Docker环境已完全卸载！\n\n"
    result_content+="以下组件已被移除:\n"
    result_content+="- Docker Engine\n"
    result_content+="- Docker Compose\n"
    result_content+="- 所有Docker容器\n"
    result_content+="- 所有Docker镜像\n"
    result_content+="- 所有Docker网络\n"
    result_content+="- 所有Docker卷\n"
    result_content+="- 所有Docker配置\n\n"
    result_content+="如果您想重新安装Docker，请使用Docker安装选项。"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$result_content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "卸载完成" --msgbox "$result_content" $dialog_height $dialog_width
    fi
}

# 运行主函数
uninstall_docker

# 恢复原始目录
cd "$CURRENT_DIR"