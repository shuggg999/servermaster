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
    sleep 1
    
    # 获取当前版本和最新版本
    if [ -f "$INSTALL_DIR/version.txt" ]; then
        VERSION=$(cat "$INSTALL_DIR/version.txt")
    fi
    
    local latest_version=""
    
    # 尝试从不同源获取最新版本
    if latest_version=$(curl -s --connect-timeout 5 "$CF_PROXY_URL/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        dialog --title "版本信息" --msgbox "从 Cloudflare Workers 获取到最新版本: $latest_version\n当前版本: $VERSION" 8 60
    elif latest_version=$(curl -s --connect-timeout 5 "$GITHUB_RAW/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        dialog --title "版本信息" --msgbox "从 GitHub 直连获取到最新版本: $latest_version\n当前版本: $VERSION" 8 60
    elif latest_version=$(curl -s --connect-timeout 5 "${MIRROR_URL}${GITHUB_RAW}/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        dialog --title "版本信息" --msgbox "从镜像站获取到最新版本: $latest_version\n当前版本: $VERSION" 8 60
    else
        dialog --title "检查更新" --msgbox "无法获取最新版本信息，请检查网络连接" 6 50
        return
    fi
    
    # 清理版本号，确保只包含有效字符
    latest_version=$(echo "$latest_version" | tr -cd '0-9\.\n')
    
    if [ "$VERSION" != "$latest_version" ]; then
        dialog --title "发现新版本" --yesno "发现新版本 $latest_version，当前版本 $VERSION，是否更新？" 8 60
        
        if [ $? -eq 0 ]; then
            dialog --title "更新中" --infobox "正在准备更新..." 5 40
            sleep 1
            
            # 备份配置
            if [ -d "$CONFIG_DIR" ]; then
                cp -r "$CONFIG_DIR" "/tmp/servermaster_config_backup"
            fi
            
            # 更新版本号到临时文件，以便安装脚本可以读取
            echo -n "$latest_version" > "/tmp/servermaster_new_version"
            
            # 执行更新安装脚本
            local update_cmd=""
            if curl -s --connect-timeout 5 "$CF_PROXY_URL/install.sh" > "/tmp/servermaster_install.sh" 2>/dev/null; then
                update_cmd="/tmp/servermaster_install.sh"
            elif curl -s --connect-timeout 5 "$GITHUB_RAW/install.sh" > "/tmp/servermaster_install.sh" 2>/dev/null; then
                update_cmd="/tmp/servermaster_install.sh"
            elif curl -s --connect-timeout 5 "${MIRROR_URL}${GITHUB_RAW}/install.sh" > "/tmp/servermaster_install.sh" 2>/dev/null; then
                update_cmd="/tmp/servermaster_install.sh"
            else
                dialog --title "更新失败" --msgbox "无法下载安装脚本，更新失败" 6 40
                return
            fi
            
            # 设置可执行权限
            chmod +x "$update_cmd"
            
            # 显示更新日志
            dialog --title "更新信息" --msgbox "即将开始更新\n\n从版本: $VERSION\n更新到: $latest_version\n\n请确保网络通畅" 10 50
            
            # 恢复配置（如果更新成功）
            echo '
            # 在安装完成后恢复配置和更新版本号
            if [ -d "/tmp/servermaster_config_backup" ] && [ -d "$INSTALL_DIR/config" ]; then
                cp -r /tmp/servermaster_config_backup/* $INSTALL_DIR/config/
                rm -rf /tmp/servermaster_config_backup
            fi
            
            # 确保设置正确的版本号
            if [ -f "/tmp/servermaster_new_version" ]; then
                cat /tmp/servermaster_new_version > $INSTALL_DIR/version.txt
                rm -f /tmp/servermaster_new_version
            fi
            ' >> "$update_cmd"
            
            # 执行更新
            exec bash "$update_cmd"
            exit 0
        fi
    else
        dialog --title "检查更新" --msgbox "当前已是最新版本 $VERSION" 6 40
    fi
}

# 卸载系统
uninstall_system() {
    dialog --title "卸载确认" --yesno "确定要卸载 ServerMaster 系统吗？\n\n此操作将删除：\n- 所有脚本和模块\n- 配置文件\n- 系统命令\n\n此操作不可恢复！" 12 60
    
    if [ $? -eq 0 ]; then
        dialog --title "二次确认" --yesno "最后确认：真的要卸载 ServerMaster 吗？" 8 50
        
        if [ $? -eq 0 ]; then
            dialog --title "卸载中" --infobox "正在卸载 ServerMaster..." 5 40
            sleep 1
            
            # 删除命令链接
            rm -f /usr/local/bin/sm
            
            # 删除主目录
            rm -rf "$INSTALL_DIR"
            
            # 删除临时文件
            rm -rf "/tmp/servermaster"
            rm -rf "/tmp/servermaster_*"
            
            dialog --title "卸载完成" --msgbox "ServerMaster 已成功卸载！" 6 40
            clear
            exit 0
        fi
    fi
    
    # 用户取消卸载，返回主菜单
    return
}

# 显示主菜单
show_main_menu() {
    while true; do
        choice=$(dialog --title "ServerMaster 主菜单" \
                       --backtitle "ServerMaster v$VERSION" \
                       --menu "请选择要执行的操作：" 15 60 9 \
                       "1" "系统信息" \
                       "2" "系统更新" \
                       "3" "系统清理" \
                       "4" "BBR管理" \
                       "5" "Docker管理" \
                       "6" "工作区管理" \
                       "7" "脚本更新" \
                       "8" "卸载系统" \
                       "9" "退出系统" \
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
                uninstall_system
                ;;
            9) 
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