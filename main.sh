#!/bin/bash

# ServerMaster Main Script
# This script serves as the main entry point for the ServerMaster system

# 检查 Dialog 是否已安装
if ! command -v dialog &> /dev/null; then
    echo "错误: Dialog 未安装，请重新运行安装脚本。"
    exit 1
fi

# 安装路径
INSTALL_DIR="/usr/local/servermaster"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"

# 获取版本号
if [ -f "$INSTALL_DIR/version.txt" ]; then
    VERSION=$(cat "$INSTALL_DIR/version.txt")
else
    VERSION="1.0"
fi

# URLs
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# 检查模块目录是否存在
check_modules() {
    if [ ! -d "$MODULES_DIR" ]; then
        dialog --title "错误" --msgbox "模块目录不存在，请重新安装系统！" 8 40
        exit 1
    fi
}

# 检查更新
check_updates() {
    dialog --title "检查更新" --infobox "正在检查更新..." 5 40
    
    local latest_version=$(curl -s "$CF_PROXY_URL/version.txt" || 
                          curl -s "$GITHUB_RAW/version.txt" || 
                          curl -s "${MIRROR_URL}${GITHUB_RAW}/version.txt" || 
                          echo "$VERSION")
    
    if [ "$VERSION" != "$latest_version" ]; then
        dialog --title "发现新版本" --yesno "发现新版本 $latest_version，当前版本 $VERSION，是否更新？" 8 60
        
        if [ $? -eq 0 ]; then
            dialog --title "更新中" --infobox "正在准备更新..." 5 40
            sleep 1
            
            # 备份配置
            if [ -d "$CONFIG_DIR" ]; then
                cp -r "$CONFIG_DIR" "/tmp/servermaster_config_backup"
            fi
            
            # 执行更新
            bash <(curl -sL "$CF_PROXY_URL/install.sh" || 
                  curl -sL "$GITHUB_REPO/raw/main/install.sh" || 
                  curl -sL "${MIRROR_URL}${GITHUB_REPO}/raw/main/install.sh")
            
            # 恢复配置
            if [ -d "/tmp/servermaster_config_backup" ]; then
                cp -r "/tmp/servermaster_config_backup"/* "$CONFIG_DIR/"
            fi
            
            # 更新版本号
            echo -n "$latest_version" > "$INSTALL_DIR/version.txt"
            
            # 重启主程序
            exec "$INSTALL_DIR/main.sh"
            exit 0
        fi
    else
        dialog --title "检查更新" --msgbox "当前已是最新版本 $VERSION" 6 40
    fi
}

# 显示主菜单
show_main_menu() {
    while true; do
        choice=$(dialog --title "ServerMaster 主菜单" \
                       --backtitle "ServerMaster v$VERSION" \
                       --menu "请选择要执行的操作：" 15 60 8 \
                       "1" "系统信息" \
                       "2" "系统更新" \
                       "3" "系统清理" \
                       "4" "BBR管理" \
                       "5" "Docker管理" \
                       "6" "工作区管理" \
                       "7" "脚本更新" \
                       "8" "退出系统" \
                       3>&1 1>&2 2>&3)
        
        exit_status=$?
        
        # 检查是否按下了取消按钮
        if [ $exit_status -ne 0 ]; then
            dialog --title "确认退出" --yesno "确定要退出 ServerMaster 吗？" 7 40
            if [ $? -eq 0 ]; then
                break
            else
                continue
            fi
        fi
        
        case $choice in
            1) 
                source "$MODULES_DIR/system/system_info.sh" 
                ;;
            2) 
                source "$MODULES_DIR/system/system_update.sh" 
                ;;
            3) 
                source "$MODULES_DIR/system/system_clean.sh" 
                ;;
            4) 
                source "$MODULES_DIR/network/bbr_manager.sh" 
                ;;
            5) 
                source "$MODULES_DIR/application/docker_manager.sh" 
                ;;
            6) 
                source "$MODULES_DIR/special/workspace.sh" 
                ;;
            7) 
                check_updates 
                ;;
            8) 
                dialog --title "确认退出" --yesno "确定要退出 ServerMaster 吗？" 7 40
                if [ $? -eq 0 ]; then
                    break
                fi
                ;;
        esac
    done
}

# 主函数
main() {
    # 检查模块
    check_modules
    
    # 欢迎界面
    dialog --title "ServerMaster" \
           --msgbox "欢迎使用 ServerMaster 服务器管理系统\n\n当前版本: v$VERSION" 8 50
    
    # 检查更新
    check_updates
    
    # 显示主菜单
    show_main_menu
    
    # 退出时的消息
    dialog --title "再见" --msgbox "感谢使用 ServerMaster，再见！" 6 40
    clear
}

# 启动程序
main