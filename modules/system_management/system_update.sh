#!/bin/bash

# 系统更新
# 此脚本提供系统及软件包更新功能

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

# 定义颜色
GREEN="\033[1;32m"
BLUE="\033[1;34m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"
SEPARATOR="------------------------------------------------------"

# 修复 dpkg 可能的中断问题（更安全）
fix_dpkg_safe() {
    local log_msg="检查并修复 dpkg 相关问题...\n"
    
    # 查找是否有 apt/dpkg 进程占用锁文件
    if sudo lsof /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock &>/dev/null; then
        log_msg+="检测到 dpkg 被占用，尝试优雅终止相关进程...\n"
        
        # 获取占用进程的 PID
        PIDS=$(sudo lsof -t /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock)
        for PID in $PIDS; do
            log_msg+="终止进程: $PID\n"
            sudo kill -TERM $PID  # 先尝试优雅终止
            sleep 2  # 等待进程退出
            if ps -p $PID &>/dev/null; then
                log_msg+="进程 $PID 未能终止，执行强制终止...\n"
                sudo kill -9 $PID  # 若进程仍未退出，则强制终止
            fi
        done
    else
        log_msg+="未检测到 dpkg 进程占用锁文件。\n"
    fi

    # 停止系统自动更新服务（适用于 Ubuntu/Debian）
    log_msg+="停止 apt 相关的自动更新服务...\n"
    sudo systemctl stop apt-daily.service apt-daily-upgrade.service 2>/dev/null
    sudo systemctl disable apt-daily.service apt-daily-upgrade.service 2>/dev/null

    # 确保锁文件被删除
    log_msg+="删除 dpkg 锁文件...\n"
    sudo rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock

    # 修复 dpkg 未完成的安装
    log_msg+="修复 dpkg 配置...\n"
    sudo dpkg --configure -a

    # 再次启用自动更新服务
    log_msg+="重新启用 apt 自动更新服务...\n"
    sudo systemctl enable apt-daily.service apt-daily-upgrade.service 2>/dev/null
    
    echo -e "$log_msg"
}

# 统一系统更新方法，兼容多种 Linux 发行版
system_update() {
    local log=""
    local update_log=""
    local update_status="成功"
    
    log+="开始进行系统更新...\n"

    if command -v dnf &>/dev/null; then
        log+="检测到 DNF，使用 DNF 进行更新...\n"
        update_log=$(sudo dnf -y update 2>&1) || update_status="失败"

    elif command -v yum &>/dev/null; then
        log+="检测到 YUM，使用 YUM 进行更新...\n"
        update_log=$(sudo yum -y update 2>&1) || update_status="失败"

    elif command -v apt &>/dev/null; then
        log+="检测到 APT，使用 APT 进行更新...\n"
        fix_dpkg_safe  # 修复 dpkg 可能的中断问题
        update_log+=$(sudo DEBIAN_FRONTEND=noninteractive apt update -y 2>&1)
        update_log+="\n\n"
        update_log+=$(sudo DEBIAN_FRONTEND=noninteractive apt full-upgrade -y 2>&1) || update_status="失败"

    elif command -v apk &>/dev/null; then
        log+="检测到 APK，使用 Alpine 的 apk 进行更新...\n"
        update_log=$(sudo apk update && sudo apk upgrade 2>&1) || update_status="失败"

    elif command -v pacman &>/dev/null; then
        log+="检测到 Pacman，使用 Arch Linux 的 pacman 进行更新...\n"
        update_log=$(sudo pacman -Syu --noconfirm 2>&1) || update_status="失败"

    elif command -v zypper &>/dev/null; then
        log+="检测到 Zypper，使用 OpenSUSE 的 zypper 进行更新...\n"
        update_log+=$(sudo zypper refresh 2>&1)
        update_log+="\n\n"
        update_log+=$(sudo zypper update -y 2>&1) || update_status="失败"

    elif command -v opkg &>/dev/null; then
        log+="检测到 OPKG，使用 OpenWRT 的 opkg 进行更新...\n"
        update_log=$(sudo opkg update && sudo opkg upgrade 2>&1) || update_status="失败"

    else
        log+="未知的包管理器，无法更新系统！\n"
        update_status="失败"
    fi

    log+="系统更新$update_status！\n"
    
    # 打印并返回日志和状态
    echo -e "$log"
    
    # 返回更新日志和状态
    return_data=("$update_log" "$update_status")
    echo "${return_data[@]}"
}

# 显示系统更新执行界面
show_system_update() {
    # 确保我们在正确的目录
    cd "$INSTALL_DIR"
    
    clear
    
    # 文本模式下的显示
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "====================================================="
        echo -e "${GREEN}      系统更新                                        ${RESET}"
        echo "====================================================="
        echo ""
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        echo -e "${YELLOW}正在执行系统更新，请稍候...${RESET}"
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        echo ""
        
        # 执行系统更新并获取结果
        update_result=($(system_update))
        update_log="${update_result[0]}"
        update_status="${update_result[1]}"
        
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        if [ "$update_status" = "成功" ]; then
            echo -e "${GREEN}系统更新完成！${RESET}"
        else
            echo -e "${RED}系统更新失败！${RESET}"
        fi
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        
        # 显示更新日志
        echo ""
        echo -e "${YELLOW}更新日志:${RESET}"
        echo -e "$update_log"
        echo ""
        
        echo "按Enter键继续..."
        read
    else
        # 使用Dialog显示进度
        dialog --title "系统更新" --infobox "正在执行系统更新，请稍候..." 5 40
        
        # 执行系统更新并获取结果
        temp_file=$(mktemp)
        system_update > "$temp_file"
        update_result=($(cat "$temp_file"))
        update_log="${update_result[0]}"
        update_status="${update_result[1]}"
        rm -f "$temp_file"
        
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 显示结果
        if [ "$update_status" = "成功" ]; then
            dialog --title "系统更新" --msgbox "系统更新完成！\n\n更新日志:\n$update_log" $dialog_height $dialog_width
        else
            dialog --title "系统更新" --msgbox "系统更新失败！\n\n更新日志:\n$update_log" $dialog_height $dialog_width
        fi
    fi
}

# 直接显示系统更新界面，不再显示菜单
show_system_update

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 