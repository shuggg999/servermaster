#!/bin/bash

# ServerMaster Main Script
# This script serves as the main entry point for the ServerMaster system

# 防止重复执行
if [ -n "$SERVERMASTER_LOADED" ]; then
    return 0
fi
export SERVERMASTER_LOADED=true

# 安装路径 - 把这些变量定义提前到脚本顶部
INSTALL_DIR="/usr/local/servermaster"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"

# 开启调试模式，帮助排查问题
DEBUG=true
# DEBUG=false

# 文本模式标志，当Dialog不可用时使用
USE_TEXT_MODE=false

# 系统名称和版本信息
SYSTEM_NAME="ServerMaster"
# 获取版本号
VERSION="1.0"

# 定义窗口大小 - 以百分比形式表示终端大小
DIALOG_MAX_HEIGHT=40
DIALOG_MAX_WIDTH=140

# 获取正确的dialog尺寸
get_dialog_size() {
    # 获取终端大小
    local term_lines=$(tput lines 2>/dev/null || echo 24)
    local term_cols=$(tput cols 2>/dev/null || echo 80)
    
    # 计算dialog窗口大小 (使用终端的85%)
    local dialog_height=$((term_lines * 85 / 100))
    local dialog_width=$((term_cols * 85 / 100))
    
    # 确保不超过最大值
    [ "$dialog_height" -gt "$DIALOG_MAX_HEIGHT" ] && dialog_height=$DIALOG_MAX_HEIGHT
    [ "$dialog_width" -gt "$DIALOG_MAX_WIDTH" ] && dialog_width=$DIALOG_MAX_WIDTH
    
    # 确保最小值
    [ "$dialog_height" -lt 20 ] && dialog_height=20
    [ "$dialog_width" -lt 70 ] && dialog_width=70
    
    echo "$dialog_height $dialog_width"
}

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

# 导入对话框规则
if [ "$USE_TEXT_MODE" = false ] && [ -f "$CONFIG_DIR/dialog_rules.sh" ]; then
    source "$CONFIG_DIR/dialog_rules.sh"
    log_debug "已导入对话框规则"
else
    # 如果对话框规则文件不存在，使用文本模式
    if [ ! -f "$CONFIG_DIR/dialog_rules.sh" ]; then
        log_debug "对话框规则文件不存在: $CONFIG_DIR/dialog_rules.sh，将使用基本对话框"
    fi
fi

# 检查脚本运行环境并记录信息
check_environment() {
    local log_file="$INSTALL_DIR/logs/environment.log"
    mkdir -p "$INSTALL_DIR/logs"
    
    echo "====== 环境检查 $(date) ======" > "$log_file"
    echo "SHELL: $SHELL" >> "$log_file"
    echo "TERM: $TERM" >> "$log_file"
    echo "LANG: $LANG" >> "$log_file"
    echo "LC_ALL: $LC_ALL" >> "$log_file"
    echo "PATH: $PATH" >> "$log_file"
    
    # 检查必要工具
    for tool in dialog tput curl grep sed awk; do
        if command -v $tool &> /dev/null; then
            echo "$tool: 已安装 ($(command -v $tool))" >> "$log_file"
            if [ "$tool" = "dialog" ]; then
                dialog --version 2>&1 | head -n 1 >> "$log_file"
            fi
        else
            echo "$tool: 未安装" >> "$log_file"
        fi
    done
    
    # 检查终端信息
    echo "LINES: $(tput lines 2>/dev/null || echo 'unknown')" >> "$log_file"
    echo "COLUMNS: $(tput cols 2>/dev/null || echo 'unknown')" >> "$log_file"
    echo "COLORS: $(tput colors 2>/dev/null || echo 'unknown')" >> "$log_file"
    
    # 检查用户和权限
    echo "USER: $(whoami)" >> "$log_file"
    echo "UID: $(id -u)" >> "$log_file"
    echo "SUDO: $(sudo -n true 2>/dev/null && echo 'available' || echo 'unavailable')" >> "$log_file"
    
    # 记录操作系统信息
    if [ -f /etc/os-release ]; then
        echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2 | tr -d '"')" >> "$log_file"
    else
        echo "OS: Unknown" >> "$log_file"
    fi
    
    echo "KERNEL: $(uname -r)" >> "$log_file"
    echo "ARCH: $(uname -m)" >> "$log_file"
    
    log_debug "环境检查完成，日志已写入: $log_file"
}

log_debug "脚本开始执行"

# 检查 Dialog 是否已安装
if ! command -v dialog &> /dev/null; then
    echo "警告: Dialog 未安装，使用文本模式。"
    export USE_TEXT_MODE=true
fi

log_debug "Dialog检查完成: USE_TEXT_MODE=$USE_TEXT_MODE"

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

# 检查模块目录是否存在
check_modules() {
    log_debug "检查模块目录"
    
    if [ ! -d "$MODULES_DIR" ]; then
        log_error "模块目录不存在: $MODULES_DIR"
        
        if [ "$USE_TEXT_MODE" = false ]; then
            dialog --title "错误" --msgbox "模块目录不存在，请重新安装系统！" 10 50
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
        # 获取窗口大小
        read dialog_height dialog_width <<< $(get_dialog_size)
        local small_height=5
        local small_width=40
        
        dialog --title "检查更新" --infobox "正在检查更新..." $small_height $small_width
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
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local info_height=10
            local info_width=50
            
            dialog --title "版本信息" --msgbox "从 Cloudflare Workers 获取到最新版本: $latest_version\n当前版本: $VERSION" $info_height $info_width
        else
            echo "从 Cloudflare Workers 获取到最新版本: $latest_version"
            echo "当前版本: $VERSION"
        fi
    elif latest_version=$(curl -s --connect-timeout 5 "$GITHUB_RAW/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        if [ "$USE_TEXT_MODE" = false ]; then
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local info_height=10
            local info_width=50
            
            dialog --title "版本信息" --msgbox "从 GitHub 直连获取到最新版本: $latest_version\n当前版本: $VERSION" $info_height $info_width
        else
            echo "从 GitHub 直连获取到最新版本: $latest_version"
            echo "当前版本: $VERSION"
        fi
    elif latest_version=$(curl -s --connect-timeout 5 "${MIRROR_URL}${GITHUB_RAW}/version.txt" 2>/dev/null) && [ ! -z "$latest_version" ]; then
        if [ "$USE_TEXT_MODE" = false ]; then
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local info_height=10
            local info_width=50
            
            dialog --title "版本信息" --msgbox "从镜像站获取到最新版本: $latest_version\n当前版本: $VERSION" $info_height $info_width
        else
            echo "从镜像站获取到最新版本: $latest_version"
            echo "当前版本: $VERSION"
        fi
    else
        if [ "$USE_TEXT_MODE" = false ]; then
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local info_height=10
            local info_width=50
            
            dialog --title "检查更新" --msgbox "无法获取最新版本信息，请检查网络连接" $info_height $info_width
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
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local prompt_height=10
            local prompt_width=50
            
            dialog --title "发现新版本" --yesno "发现新版本 $latest_version，当前版本 $VERSION，是否更新？" $prompt_height $prompt_width
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
                # 获取窗口大小
                read dialog_height dialog_width <<< $(get_dialog_size)
                local small_height=5
                local small_width=40
                
                dialog --title "更新中" --infobox "正在准备更新..." $small_height $small_width
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
                    # 获取窗口大小
                    read dialog_height dialog_width <<< $(get_dialog_size)
                    local info_height=10
                    local info_width=50
                    
                    dialog --title "更新失败" --msgbox "无法下载安装脚本，更新失败" $info_height $info_width
                else
                    echo "无法下载安装脚本，更新失败"
                fi
                return 0
            fi
            
            # 设置可执行权限
            chmod +x "$update_cmd"
            
            # 显示更新日志
            if [ "$USE_TEXT_MODE" = false ]; then
                # 获取窗口大小
                read dialog_height dialog_width <<< $(get_dialog_size)
                local info_height=10
                local info_width=50
                
                dialog --title "更新信息" --msgbox "即将开始更新\n\n从版本: $VERSION\n更新到: $latest_version\n\n请确保网络通畅" $info_height $info_width
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
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local info_height=10
            local info_width=50
            
            dialog --title "检查更新" --msgbox "当前已是最新版本 $VERSION" $info_height $info_width
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
        # 获取窗口大小
        read dialog_height dialog_width <<< $(get_dialog_size)
        local prompt_height=10
        local prompt_width=50
        
        dialog --title "卸载确认" --yesno "确定要卸载 ServerMaster 系统吗？\n\n此操作将删除：\n- 所有脚本和模块\n- 配置文件\n- 系统命令\n\n此操作不可恢复！" $prompt_height $prompt_width
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
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local prompt_height=10
            local prompt_width=50
            
            dialog --title "二次确认" --yesno "最后确认：真的要卸载 ServerMaster 吗？" $prompt_height $prompt_width
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
                # 获取窗口大小
                read dialog_height dialog_width <<< $(get_dialog_size)
                local small_height=5
                local small_width=40
                
                dialog --title "卸载中" --infobox "正在卸载 ServerMaster..." $small_height $small_width
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
                # 获取窗口大小
                read dialog_height dialog_width <<< $(get_dialog_size)
                local info_height=10
                local info_width=50
                
                dialog --title "卸载完成" --msgbox "ServerMaster 已成功卸载！" $info_height $info_width
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

# 执行模块的函数
execute_module() {
    local module_path="$1"
    local full_path="$MODULES_DIR/$module_path"
    
    # 保存当前工作目录
    local current_dir=$(pwd)
    
    log_debug "尝试执行模块: $full_path (当前目录: $current_dir)"
    
    if [ -f "$full_path" ]; then
        log_debug "模块存在，执行中..."
        # 切换到安装目录再执行，确保相对路径正确
        cd "$INSTALL_DIR"
        # 使用绝对路径执行模块
        source "$full_path"
        
        # 立即恢复原来的工作目录
        cd "$current_dir"
        log_debug "模块执行完成，已恢复工作目录: $(pwd)"
        
        if [ "$USE_TEXT_MODE" = true ]; then
    echo ""
            echo "模块执行完成，按Enter键返回主菜单..."
            read
        fi
    else
        log_error "模块不存在: $full_path (当前目录: $current_dir)"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "错误: 模块不存在 ($module_path)"
            echo "请检查安装是否完整"
    echo ""
            echo "按Enter键继续..."
            read
        else
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            local error_height=10
            local error_width=50
            
            dialog --title "错误" --msgbox "模块不存在: $module_path\n请检查安装是否完整" $error_height $error_width
        fi
        
        # 确保在错误情况下也恢复工作目录
        cd "$current_dir"
    fi
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
        echo "  1) 系统管理              6) 集群管理"
        echo "  2) 网络与安全            7) 工作区管理"
        echo "  3) 备份与同步            8) 内网穿透"
        echo "  4) 容器与应用部署        9) 系统维护"
        echo "  5) 测试与诊断            0) 退出系统"
    echo ""
        read -p "请选择操作 [0-9]: " choice
        
        case $choice in
            1) execute_module "system_management/system_menu.sh" ;;
            2) execute_module "network_security/network_menu.sh" ;;
            3) execute_module "backup_sync/backup_menu.sh" ;;
            4) execute_module "container_deploy/container_menu.sh" ;;
            5) execute_module "test_diagnostic/test_menu.sh" ;;
            6) execute_module "cluster_management/cluster_menu.sh" ;;
            7) execute_module "workspace_management/workspace_menu.sh" ;;
            8) execute_module "intranet_penetration/intranet_menu.sh" ;;
            9) execute_module "system_maintenance/maintenance_menu.sh" ;;
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

# 显示横幅
show_banner() {
    local system_name="$1"
    log_debug "显示横幅，系统名称: $system_name"
    
    if [ "$USE_TEXT_MODE" = false ]; then
        # 获取窗口大小
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 使用Dialog显示横幅
        dialog --title "欢迎" --msgbox "\n    欢迎使用 $system_name 系统\n    版本: $VERSION\n\n    一个简单而强大的服务器管理工具\n" 10 50
    else
        # 文本模式横幅
        clear
        echo -e "${GREEN}================================================${NC}"
        echo -e "${YELLOW}           欢迎使用 $system_name 系统           ${NC}"
        echo -e "${BLUE}              版本: $VERSION                     ${NC}"
        echo -e "${YELLOW}      一个简单而强大的服务器管理工具            ${NC}"
        echo -e "${GREEN}================================================${NC}"
    echo ""
    fi
}

# 显示主菜单
show_main_menu() {
    log_debug "显示主菜单"
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            # 文本模式菜单
            show_text_menu
            return
        else
            # 获取窗口大小
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            log_debug "创建Dialog菜单 (高度=${dialog_height}, 宽度=${dialog_width})"
            
            # Dialog需要一个临时文件存储结果
            local temp_file=$(mktemp)
            
            # 创建Dialog菜单
            dialog --clear --title "主菜单" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 9 \
                "1" "系统管理 - 系统信息、更新、清理和工具" \
                "2" "网络与安全 - 防火墙、BBR、VPN及安全工具" \
                "3" "备份与同步 - 系统备份、定时任务和远程同步" \
                "4" "容器与应用部署 - Docker管理和应用部署" \
                "5" "测试与诊断 - 网络测速、性能测试和解锁检测" \
                "6" "集群管理 - 多服务器批量操作" \
                "7" "工作区管理 - 工作区创建和管理" \
                "8" "内网穿透 - FRP服务端和客户端管理" \
                "9" "系统维护 - 脚本更新和系统卸载" \
                "0" "退出 - 退出系统" 2> "$temp_file"
            
            # 获取Dialog退出状态和用户选择
            local status=$?
            log_debug "Dialog退出状态: $status"
            
            # 如果用户按了取消或ESC，则退出
            if [ $status -ne 0 ]; then
                log_debug "用户取消或按ESC键，退出程序"
                rm -f "$temp_file"
                clear
                echo "感谢使用！"
                exit 0
            fi
            
            # 读取用户选择
            choice=$(<"$temp_file")
            log_debug "用户选择: $choice"
            rm -f "$temp_file"
        fi
        
        # 根据用户选择执行对应功能
        case $choice in
            1) execute_module "system_management/system_menu.sh" ;;
            2) execute_module "network_security/network_menu.sh" ;;
            3) execute_module "backup_sync/backup_menu.sh" ;;
            4) execute_module "container_deploy/container_menu.sh" ;;
            5) execute_module "test_diagnostic/test_menu.sh" ;;
            6) execute_module "cluster_management/cluster_menu.sh" ;;
            7) execute_module "workspace_management/workspace_menu.sh" ;;
            8) execute_module "intranet_penetration/intranet_menu.sh" ;;
            9) execute_module "system_maintenance/maintenance_menu.sh" ;;
            0) 
                if [ "$USE_TEXT_MODE" = false ]; then
                    # 获取窗口大小
                    read exit_height exit_width <<< $(get_dialog_size)
                    exit_height=10
                    exit_width=50
                    
                    dialog --title "退出确认" --yesno "确定要退出吗？" $exit_height $exit_width
                    if [ $? -eq 0 ]; then
                        clear
                        echo "感谢使用！"
                        exit 0
                    fi
                else
                    clear
                    echo "感谢使用！"
                    exit 0
                fi
                ;;
            *)
                if [ "$USE_TEXT_MODE" = false ]; then
                    # 获取窗口大小
                    read error_height error_width <<< $(get_dialog_size)
                    error_height=10
                    error_width=50
                    
                    dialog --title "错误" --msgbox "无效选项: $choice\n请重新选择" $error_height $error_width
                else
                    echo "无效选项: $choice"
                    echo "请按Enter键继续..."
                    read
                fi
            ;;
    esac
    done
}

# 主函数
main() {
    log_debug "主函数开始执行"
    
    # 检查运行环境
    check_environment
    
    # 检查模块
    check_modules
    
    # 获取版本号 - 从文件读取并覆盖默认值
    if [ -f "$INSTALL_DIR/version.txt" ]; then
        VERSION=$(cat "$INSTALL_DIR/version.txt")
        log_debug "从文件读取版本号: $VERSION"
    fi
    
    # 获取窗口尺寸 - 固定大小
    local window_size=(20 70)
    
    # 显示横幅
    show_banner "$SYSTEM_NAME"
    
    # 检查更新后直接显示主菜单，防止意外跳转
    log_debug "准备执行检查更新..."
    check_updates
    log_debug "检查更新完成，准备显示主菜单..."
    
    # 显示主菜单
    if [ "$USE_TEXT_MODE" = false ]; then
        # 创建调试日志目录和文件
        mkdir -p "$INSTALL_DIR/logs"
        debug_log="$INSTALL_DIR/logs/main_debug.log"
        echo "====== 主函数调试信息 $(date) ======" > "$debug_log"
        echo "准备显示主菜单..." >> "$debug_log"
        show_main_menu
    else
        show_text_menu
    fi
    
    # 理论上永远不会执行到这里，因为菜单函数中有无限循环
    # 除非用户选择退出，那么会直接执行exit
    log_debug "脚本执行完毕"
    clear
    echo "感谢使用 ServerMaster，再见！"
}

# 启动程序
main