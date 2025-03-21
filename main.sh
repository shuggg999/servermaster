#!/bin/bash

# ServerMaster Main Script
# This script serves as the main entry point for the ServerMaster system

# 开启调试模式，帮助排查问题
# DEBUG=true
DEBUG=false

# 文本模式标志，当Dialog不可用时使用
USE_TEXT_MODE=false

# 日志函数
log_debug() {
    if [ "$DEBUG" = true ]; then
        echo "[DEBUG] $1" >&2
    fi
}

# 打印错误信息
log_error() {
    echo -e "\033[31m[ERROR]\033[0m $1" >&2
}

# 打印成功信息
log_success() {
    echo -e "\033[32m[SUCCESS]\033[0m $1" >&2
}

log_debug "脚本开始执行"

# 检查 Dialog 是否已安装
if ! command -v dialog &> /dev/null; then
    echo "警告: Dialog 未安装，使用文本模式。"
    export USE_TEXT_MODE=true
fi

log_debug "Dialog检查完成: USE_TEXT_MODE=$USE_TEXT_MODE"

# 安装路径
INSTALL_DIR="/usr/local/servermaster"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"

log_debug "设置目录: INSTALL_DIR=$INSTALL_DIR"

# 获取版本号
if [ -f "$INSTALL_DIR/version.txt" ]; then
    VERSION=$(cat "$INSTALL_DIR/version.txt")
else
    VERSION="1.0"
fi

log_debug "当前版本: $VERSION"

# URLs
GITHUB_REPO="https://github.com/shuggg999/servermaster"
GITHUB_RAW="https://raw.githubusercontent.com/shuggg999/servermaster/main"
MIRROR_URL="https://mirror.ghproxy.com/"
CF_PROXY_URL="https://install.ideapusher.cn/shuggg999/servermaster/main"

# 获取适合的窗口大小
get_window_size() {
    # 获取终端大小
    local term_height=$(tput lines 2>/dev/null || echo 24)
    local term_width=$(tput cols 2>/dev/null || echo 80)
    
    log_debug "终端大小: $term_height x $term_width"
    
    # 默认使用80%的终端空间
    local win_height=$((term_height * 80 / 100))
    local win_width=$((term_width * 80 / 100))
    
    # 确保窗口尺寸在合理范围内
    [ $win_height -lt 20 ] && win_height=20
    [ $win_width -lt 70 ] && win_width=70
    
    log_debug "计算窗口大小: $win_height x $win_width"
    
    echo "${win_height} ${win_width}"
}

# 检查模块目录是否存在
check_modules() {
    log_debug "检查模块目录"
    
    if [ ! -d "$MODULES_DIR" ]; then
        log_error "模块目录不存在: $MODULES_DIR"
        
        if [ "$USE_TEXT_MODE" = false ]; then
            local window_size=($(get_window_size))
            dialog --title "错误" --msgbox "模块目录不存在，请重新安装系统！" ${window_size[0]} ${window_size[1]}
        else
            echo "错误: 模块目录不存在，请重新安装系统！"
        fi
        exit 1
    fi
    
    log_debug "模块目录检查通过"
}

# 检查更新
check_updates() {
    log_debug "开始检查更新"
    
    if [ "$USE_TEXT_MODE" = false ]; then
        local window_size=($(get_window_size))
        dialog --title "检查更新" --infobox "正在检查更新..." 5 40
        sleep 1
    else
        echo "正在检查更新..."
    fi
    
    # 获取当前版本和最新版本
    if [ -f "$INSTALL_DIR/version.txt" ]; then
        VERSION=$(cat "$INSTALL_DIR/version.txt")
    fi
    
    local latest_version=""
    
    # 尝试从不同源获取最新版本
    if latest_version=$(curl -s --connect-timeout 5 "$CF_PROXY_URL/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "版本信息" --msgbox "从 Cloudflare Workers 获取到最新版本: $latest_version\n当前版本: $VERSION" ${window_size[0]} ${window_size[1]}
        else
            echo "从 Cloudflare Workers 获取到最新版本: $latest_version"
            echo "当前版本: $VERSION"
        fi
    elif latest_version=$(curl -s --connect-timeout 5 "$GITHUB_RAW/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "版本信息" --msgbox "从 GitHub 直连获取到最新版本: $latest_version\n当前版本: $VERSION" ${window_size[0]} ${window_size[1]}
        else
            echo "从 GitHub 直连获取到最新版本: $latest_version"
            echo "当前版本: $VERSION"
        fi
    elif latest_version=$(curl -s --connect-timeout 5 "${MIRROR_URL}${GITHUB_RAW}/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "版本信息" --msgbox "从镜像站获取到最新版本: $latest_version\n当前版本: $VERSION" ${window_size[0]} ${window_size[1]}
        else
            echo "从镜像站获取到最新版本: $latest_version"
            echo "当前版本: $VERSION"
        fi
    else
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "检查更新" --msgbox "无法获取最新版本信息，请检查网络连接" ${window_size[0]} ${window_size[1]}
        else
            echo "无法获取最新版本信息，请检查网络连接"
        fi
        return 0
    fi
    
    # 清理版本号，确保只包含有效字符
    latest_version=$(echo "$latest_version" | tr -cd '0-9\.\n')
    
    if [ "$VERSION" != "$latest_version" ]; then
        local do_update=0
        
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "发现新版本" --yesno "发现新版本 $latest_version，当前版本 $VERSION，是否更新？" ${window_size[0]} ${window_size[1]}
            do_update=$?
        else
            echo "发现新版本 $latest_version，当前版本 $VERSION"
            read -p "是否更新？(y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                do_update=0
            else
                do_update=1
            fi
        fi
        
        if [ $do_update -eq 0 ]; then
            if [ "$USE_TEXT_MODE" = false ]; then
                dialog --title "更新中" --infobox "正在准备更新..." 5 40
            else
                echo "正在准备更新..."
            fi
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
                if [ "$USE_TEXT_MODE" = false ]; then
                    dialog --title "更新失败" --msgbox "无法下载安装脚本，更新失败" ${window_size[0]} ${window_size[1]}
                else
                    echo "无法下载安装脚本，更新失败"
                fi
                return 0
            fi
            
            # 设置可执行权限
            chmod +x "$update_cmd"
            
            # 显示更新日志
            if [ "$USE_TEXT_MODE" = false ]; then
                dialog --title "更新信息" --msgbox "即将开始更新\n\n从版本: $VERSION\n更新到: $latest_version\n\n请确保网络通畅" ${window_size[0]} ${window_size[1]}
            else
                echo "即将开始更新"
                echo "从版本: $VERSION"
                echo "更新到: $latest_version"
                echo "请确保网络通畅"
            fi
            
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
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "检查更新" --msgbox "当前已是最新版本 $VERSION" ${window_size[0]} ${window_size[1]}
        else
            echo "当前已是最新版本 $VERSION"
        fi
    fi
    
    log_debug "检查更新完成"
    return 0
}

# 卸载系统
uninstall_system() {
    log_debug "开始卸载流程"
    
    local confirm_uninstall=1
    
    if [ "$USE_TEXT_MODE" = false ]; then
        local window_size=($(get_window_size))
        dialog --title "卸载确认" --yesno "确定要卸载 ServerMaster 系统吗？\n\n此操作将删除：\n- 所有脚本和模块\n- 配置文件\n- 系统命令\n\n此操作不可恢复！" ${window_size[0]} ${window_size[1]}
        confirm_uninstall=$?
    else
        echo "确定要卸载 ServerMaster 系统吗？"
        echo "此操作将删除："
        echo "- 所有脚本和模块"
        echo "- 配置文件"
        echo "- 系统命令"
        echo "此操作不可恢复！"
        read -p "确认卸载？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            confirm_uninstall=0
        fi
    fi
    
    if [ $confirm_uninstall -eq 0 ]; then
        local second_confirm=1
        
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "二次确认" --yesno "最后确认：真的要卸载 ServerMaster 吗？" ${window_size[0]} ${window_size[1]}
            second_confirm=$?
        else
            read -p "最后确认：真的要卸载 ServerMaster 吗？(y/n) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                second_confirm=0
            fi
        fi
        
        if [ $second_confirm -eq 0 ]; then
            if [ "$USE_TEXT_MODE" = false ]; then
                dialog --title "卸载中" --infobox "正在卸载 ServerMaster..." 5 40
            else
                echo "正在卸载 ServerMaster..."
            fi
            sleep 1
            
            # 删除命令链接
            rm -f /usr/local/bin/sm
            
            # 删除主目录
            rm -rf "$INSTALL_DIR"
            
            # 删除临时文件
            rm -rf "/tmp/servermaster"
            rm -rf "/tmp/servermaster_*"
            
            if [ "$USE_TEXT_MODE" = false ]; then
                dialog --title "卸载完成" --msgbox "ServerMaster 已成功卸载！" ${window_size[0]} ${window_size[1]}
            else
                echo "ServerMaster 已成功卸载！"
            fi
            clear
            exit 0
        fi
    fi
    
    # 用户取消卸载，返回主菜单
    log_debug "用户取消卸载"
    return
}

# 文本模式的菜单
show_text_menu() {
    log_debug "显示文本模式菜单"
    
    while true; do
        clear
        echo "====================================================="
        echo "      ServerMaster 主菜单 (v$VERSION)                "
        echo "====================================================="
        echo ""
        echo "  系统管理:                  网络与应用:"
        echo "  1) 系统信息                5) Docker管理"
        echo "  2) 系统更新                6) 工作区管理"
        echo "  3) 系统清理                7) 检查更新"
        echo "  4) BBR管理                 8) 卸载系统"
        echo ""
        echo "  0) 退出"
        echo ""
        read -p "请选择操作 [0-8]: " choice
        
        case $choice in
            1) 
                source "$MODULES_DIR/system/system_info.sh"
                read -p "按Enter键继续..." 
                ;;
            2) 
                source "$MODULES_DIR/system/system_update.sh"
                read -p "按Enter键继续..." 
                ;;
            3) 
                source "$MODULES_DIR/system/system_clean.sh"
                read -p "按Enter键继续..." 
                ;;
            4) 
                source "$MODULES_DIR/network/bbr_manager.sh"
                read -p "按Enter键继续..." 
                ;;
            5) 
                source "$MODULES_DIR/application/docker_manager.sh"
                read -p "按Enter键继续..." 
                ;;
            6) 
                source "$MODULES_DIR/special/workspace.sh"
                read -p "按Enter键继续..." 
                ;;
            7) 
                check_updates
                read -p "按Enter键继续..." 
                ;;
            8) 
                uninstall_system
                read -p "按Enter键继续..." 
                ;;
            0)
                echo "确定要退出 ServerMaster 吗？"
                read -p "确认退出？(y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    break
                fi
                ;;
            *)
                echo "无效选择，请重试"
                sleep 1
                ;;
        esac
    done
    
    clear
    echo "感谢使用 ServerMaster，再见！"
    exit 0
}

# 显示主菜单（两列布局，使用方向键选择）
show_main_menu() {
    log_debug "显示Dialog模式菜单"

    # 获取窗口尺寸
    local window_size=($(get_window_size))
    local win_height=${window_size[0]}
    local win_width=${window_size[1]}
    
    # 确保足够的空间来显示所有菜单项
    [ $win_height -lt 25 ] && win_height=25
    [ $win_width -lt 75 ] && win_width=75
    
    while true; do
        # 创建单个菜单，使用美观的布局
        choice=$(dialog --clear \
                       --title "ServerMaster 主菜单 (v$VERSION)" \
                       --backtitle "ServerMaster v$VERSION" \
                       --size $win_height $win_width \
                       --menu "\n      ╔══════════ 系统管理 ══════════╗    ╔══════════ 网络与应用 ══════════╗\n      ║                            ║    ║                                ║\n      ╚════════════════════════════╝    ╚════════════════════════════════╝\n\n请使用↑↓方向键选择操作，按Enter键确认:" 18 80 9 \
                       "1" "│ 系统信息 │ 查看服务器详细信息" \
                       "2" "│ 系统更新 │ 更新系统软件包" \
                       "3" "│ 系统清理 │ 清理系统临时文件" \
                       "4" "│ BBR管理  │ TCP加速管理" \
                       "5" "│ Docker管理 │ 容器应用管理" \
                       "6" "│ 工作区管理 │ 管理工作区" \
                       "7" "│ 检查更新 │ 检查脚本更新" \
                       "8" "│ 卸载系统 │ 卸载ServerMaster" \
                       "0" "│ 退出 │ 退出系统" \
                       3>&1 1>&2 2>&3)
        
        # 获取返回状态
        exit_status=$?
        
        log_debug "菜单选择: $choice, 状态: $exit_status"
        
        # 如果按了ESC或取消
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
                log_debug "选择了: 系统信息"
                source "$MODULES_DIR/system/system_info.sh" 
                ;;
            2) 
                log_debug "选择了: 系统更新"
                source "$MODULES_DIR/system/system_update.sh" 
                ;;
            3) 
                log_debug "选择了: 系统清理"
                source "$MODULES_DIR/system/system_clean.sh" 
                ;;
            4) 
                log_debug "选择了: BBR管理"
                source "$MODULES_DIR/network/bbr_manager.sh" 
                ;;
            5) 
                log_debug "选择了: Docker管理"
                source "$MODULES_DIR/application/docker_manager.sh" 
                ;;
            6) 
                log_debug "选择了: 工作区管理"
                source "$MODULES_DIR/special/workspace.sh" 
                ;;
            7) 
                log_debug "选择了: 检查更新"
                check_updates 
                ;;
            8) 
                log_debug "选择了: 卸载系统"
                uninstall_system
                ;;
            0) 
                log_debug "选择了: 退出"
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
    log_debug "主函数开始执行"
    
    # 检查模块
    check_modules
    
    # 获取窗口尺寸
    local window_size=($(get_window_size))
    
    # 欢迎界面
    if [ "$USE_TEXT_MODE" = false ]; then
        dialog --title "ServerMaster" \
               --msgbox "欢迎使用 ServerMaster 服务器管理系统\n\n当前版本: v$VERSION" ${window_size[0]} ${window_size[1]}
    else
        clear
        echo "====================================================="
        echo "欢迎使用 ServerMaster 服务器管理系统"
        echo "当前版本: v$VERSION"
        echo "====================================================="
        echo ""
        read -p "按Enter键继续..." 
    fi
    
    # 检查更新
    check_updates
    
    # 显示主菜单
    if [ "$USE_TEXT_MODE" = false ]; then
        show_main_menu
    else
        show_text_menu
    fi
    
    # 退出时的消息
    if [ "$USE_TEXT_MODE" = false ]; then
        dialog --title "再见" --msgbox "感谢使用 ServerMaster，再见！" ${window_size[0]} ${window_size[1]}
    fi
    clear
    
    log_debug "脚本执行完毕"
}

# 启动程序
main