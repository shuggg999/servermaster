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

# 智能执行命令函数（替代sudo）
safe_exec() {
    # 如果用户是root，直接执行命令
    if [ "$(id -u)" -eq 0 ]; then
        eval "$@"
    # 如果系统有sudo命令，使用sudo执行
    elif command -v sudo &> /dev/null; then
        sudo "$@"
    # 如果都不满足，提示错误
    else
        echo -e "${RED}错误: 需要root权限执行该命令，但系统中没有sudo命令${RESET}"
        echo -e "${YELLOW}请使用root用户执行此脚本，或安装sudo软件包${RESET}"
        return 1
    fi
}

# 修复 dpkg 可能的中断问题（更安全）
fix_dpkg_safe() {
    echo -e "检查并修复 dpkg 相关问题..."

    # 查找是否有 apt/dpkg 进程占用锁文件
    if safe_exec lsof /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock &>/dev/null; then
        echo -e "检测到 dpkg 被占用，尝试优雅终止相关进程..."
        
        # 获取占用进程的 PID
        PIDS=$(safe_exec lsof -t /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock)
        for PID in $PIDS; do
            echo -e "终止进程: $PID"
            safe_exec kill -TERM $PID  # 先尝试优雅终止
            sleep 2  # 等待进程退出
            if ps -p $PID &>/dev/null; then
                echo -e "进程 $PID 未能终止，执行强制终止..."
                safe_exec kill -9 $PID  # 若进程仍未退出，则强制终止
            fi
        done
    else
        echo -e "未检测到 dpkg 进程占用锁文件。"
    fi

    # 停止系统自动更新服务（适用于 Ubuntu/Debian）
    echo -e "停止 apt 相关的自动更新服务..."
    safe_exec systemctl stop apt-daily.service apt-daily-upgrade.service 2>/dev/null
    safe_exec systemctl disable apt-daily.service apt-daily-upgrade.service 2>/dev/null

    # 确保锁文件被删除
    echo -e "删除 dpkg 锁文件..."
    safe_exec rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock

    # 修复 dpkg 未完成的安装
    echo -e "修复 dpkg 配置..."
    safe_exec dpkg --configure -a

    # 再次启用自动更新服务
    echo -e "重新启用 apt 自动更新服务..."
    safe_exec systemctl enable apt-daily.service apt-daily-upgrade.service 2>/dev/null
}

# 统一系统更新方法，兼容多种 Linux 发行版
system_update() {
    # 创建临时文件存储状态
    local status_file=$(mktemp)
    echo "成功" > "$status_file"
    
    echo -e "开始进行系统更新..."

    if command -v dnf &>/dev/null; then
        echo -e "检测到 DNF，使用 DNF 进行更新..."
        if ! safe_exec dnf -y update; then
            echo "失败" > "$status_file"
        fi

    elif command -v yum &>/dev/null; then
        echo -e "检测到 YUM，使用 YUM 进行更新..."
        if ! safe_exec yum -y update; then
            echo "失败" > "$status_file"
        fi

    elif command -v apt &>/dev/null; then
        echo -e "检测到 APT，使用 APT 进行更新..."
        fix_dpkg_safe  # 修复 dpkg 可能的中断问题
        safe_exec DEBIAN_FRONTEND=noninteractive apt update -y
        if ! safe_exec DEBIAN_FRONTEND=noninteractive apt full-upgrade -y; then
            echo "失败" > "$status_file"
        fi

    elif command -v apk &>/dev/null; then
        echo -e "检测到 APK，使用 Alpine 的 apk 进行更新..."
        if ! (safe_exec apk update && safe_exec apk upgrade); then
            echo "失败" > "$status_file"
        fi

    elif command -v pacman &>/dev/null; then
        echo -e "检测到 Pacman，使用 Arch Linux 的 pacman 进行更新..."
        if ! safe_exec pacman -Syu --noconfirm; then
            echo "失败" > "$status_file"
        fi

    elif command -v zypper &>/dev/null; then
        echo -e "检测到 Zypper，使用 OpenSUSE 的 zypper 进行更新..."
        safe_exec zypper refresh
        if ! safe_exec zypper update -y; then
            echo "失败" > "$status_file"
        fi

    elif command -v opkg &>/dev/null; then
        echo -e "检测到 OPKG，使用 OpenWRT 的 opkg 进行更新..."
        if ! (safe_exec opkg update && safe_exec opkg upgrade); then
            echo "失败" > "$status_file"
        fi

    else
        echo -e "未知的包管理器，无法更新系统！"
        echo "失败" > "$status_file"
    fi

    local update_status=$(cat "$status_file")
    rm -f "$status_file"
    
    echo -e "系统更新${update_status}！"
    return 0
}

# 显示系统更新执行界面
show_system_update() {
    # 确保我们在正确的目录
    cd "$INSTALL_DIR"
    
    clear
    
    # 创建临时文件存储日志
    local log_file=$(mktemp)
    
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
        
        # 执行系统更新并直接输出到终端和日志文件
        system_update | tee "$log_file"
        
        # 检查更新是否成功（根据日志内容）
        if grep -q "系统更新成功" "$log_file"; then
            update_status="成功"
        else
            update_status="失败"
        fi
        
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        if [ "$update_status" = "成功" ]; then
            echo -e "${GREEN}系统更新完成！${RESET}"
        else
            echo -e "${RED}系统更新失败！${RESET}"
        fi
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        
        echo ""
        echo "按Enter键继续..."
        read
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 首先显示一个infobox，告知用户更新已经开始
        dialog --title "系统更新" --infobox "准备执行系统更新，正在初始化..." 5 40
        sleep 1
        
        # 确保临时目录存在
        mkdir -p /tmp/servermaster
        
        # 创建一个文件而不是FIFO管道（更可靠）
        update_file="/tmp/servermaster/update_log.txt"
        echo "正在初始化系统更新..." > "$update_file"
        
        # 启动tailbox对话框以实时显示更新日志（使用tailbox而不是tailboxbg）
        dialog --title "系统更新进度" --begin 3 3 --tailbox "$update_file" $((dialog_height-6)) $((dialog_width-6)) 2>&1 >/dev/tty &
        dialog_pid=$!
        
        # 执行系统更新并将输出重定向到文件
        {
            echo "开始系统更新过程..."
            echo "$SEPARATOR"
            # 执行更新并同时写入日志文件
            system_update | tee -a "$update_file" "$log_file"
            update_result=$?
            echo "$SEPARATOR"
            
            # 根据日志内容判断是否成功
            if grep -q "系统更新成功" "$log_file"; then
                echo -e "系统更新完成！" | tee -a "$update_file"
                update_status="成功"
            else
                echo -e "系统更新失败！请检查日志详情。" | tee -a "$update_file"
                update_status="失败"
            fi
            
            echo "等待5秒后关闭此窗口..." | tee -a "$update_file"
            sleep 5
            
            # 结束dialog进程
            kill $dialog_pid 2>/dev/null
        } &
        
        # 等待dialog进程结束
        wait $dialog_pid 2>/dev/null
        
        # 显示更新结果
        if [ -s "$log_file" ]; then
            update_log=$(cat "$log_file")
        else
            update_log="警告：更新日志为空，这可能是因为系统更新过程中没有产生输出或发生了错误。"
        fi
        
        if [ "$update_status" = "成功" ]; then
            dialog --title "系统更新" --msgbox "系统更新完成！\n\n更新日志:\n$update_log" $dialog_height $dialog_width
        else
            dialog --title "系统更新" --msgbox "系统更新失败！\n\n更新日志:\n$update_log" $dialog_height $dialog_width
        fi
        
        # 清理临时文件
        rm -f "$update_file"
    fi
    
    # 清理临时文件
    rm -f "$log_file"
}

# 直接显示系统更新界面，不再显示菜单
show_system_update

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 