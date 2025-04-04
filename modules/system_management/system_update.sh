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

# 创建日志目录
mkdir -p "$INSTALL_DIR/logs"
# 固定日志文件位置
DETAILED_LOG="$INSTALL_DIR/logs/system_update.log"
# 清空之前的日志
echo "系统更新日志 - $(date '+%Y-%m-%d %H:%M:%S')" > "$DETAILED_LOG"
echo "$SEPARATOR" >> "$DETAILED_LOG"

# 日志函数
log_message() {
    local message="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $message" | tee -a "$DETAILED_LOG"
}

# 智能执行命令函数（替代sudo）
safe_exec() {
    # 如果用户是root，直接执行命令
    if [ "$(id -u)" -eq 0 ]; then
        log_message "以root身份执行: $*"
        eval "$@" 2>&1 | tee -a "$DETAILED_LOG"
        return ${PIPESTATUS[0]}
    # 如果系统有sudo命令，使用sudo执行
    elif command -v sudo &> /dev/null; then
        log_message "以sudo执行: $*"
        sudo "$@" 2>&1 | tee -a "$DETAILED_LOG"
        return ${PIPESTATUS[0]}
    # 如果都不满足，提示错误
    else
        log_message "${RED}错误: 需要root权限执行该命令，但系统中没有sudo命令${RESET}"
        echo -e "${RED}错误: 需要root权限执行该命令，但系统中没有sudo命令${RESET}" | tee -a "$DETAILED_LOG"
        echo -e "${YELLOW}请使用root用户执行此脚本，或安装sudo软件包${RESET}" | tee -a "$DETAILED_LOG"
        return 1
    fi
}

# 修复 dpkg 可能的中断问题（更安全）
fix_dpkg_safe() {
    log_message "检查并修复 dpkg 相关问题..."
    echo -e "检查并修复 dpkg 相关问题..."

    # 查找是否有 apt/dpkg 进程占用锁文件
    if safe_exec lsof /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock &>/dev/null; then
        log_message "检测到 dpkg 被占用，尝试优雅终止相关进程..."
        echo -e "检测到 dpkg 被占用，尝试优雅终止相关进程..."
        
        # 获取占用进程的 PID
        PIDS=$(safe_exec lsof -t /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock)
        for PID in $PIDS; do
            log_message "终止进程: $PID"
            echo -e "终止进程: $PID"
            safe_exec kill -TERM $PID  # 先尝试优雅终止
            sleep 2  # 等待进程退出
            if ps -p $PID &>/dev/null; then
                log_message "进程 $PID 未能终止，执行强制终止..."
                echo -e "进程 $PID 未能终止，执行强制终止..."
                safe_exec kill -9 $PID  # 若进程仍未退出，则强制终止
            fi
        done
    else
        log_message "未检测到 dpkg 进程占用锁文件。"
        echo -e "未检测到 dpkg 进程占用锁文件。"
    fi

    # 停止系统自动更新服务（适用于 Ubuntu/Debian）
    log_message "停止 apt 相关的自动更新服务..."
    echo -e "停止 apt 相关的自动更新服务..."
    safe_exec systemctl stop apt-daily.service apt-daily-upgrade.service 2>/dev/null
    safe_exec systemctl disable apt-daily.service apt-daily-upgrade.service 2>/dev/null

    # 确保锁文件被删除
    log_message "删除 dpkg 锁文件..."
    echo -e "删除 dpkg 锁文件..."
    safe_exec rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock

    # 修复 dpkg 未完成的安装
    log_message "修复 dpkg 配置..."
    echo -e "修复 dpkg 配置..."
    safe_exec dpkg --configure -a

    # 再次启用自动更新服务
    log_message "重新启用 apt 自动更新服务..."
    echo -e "重新启用 apt 自动更新服务..."
    safe_exec systemctl enable apt-daily.service apt-daily-upgrade.service 2>/dev/null
}

# 统一系统更新方法，兼容多种 Linux 发行版
system_update() {
    # 创建临时文件存储状态
    local status_file=$(mktemp)
    echo "成功" > "$status_file"
    
    log_message "开始进行系统更新..."
    echo -e "开始进行系统更新..."

    # 检测系统类型
    local os_type=""
    local os_version=""
    
    if [ -f /etc/os-release ]; then
        os_type=$(grep -oP '(?<=^ID=).+' /etc/os-release | tr -d '"')
        os_version=$(grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"')
        log_message "检测到操作系统: $os_type $os_version"
    else
        log_message "警告: 无法检测操作系统类型"
    fi

    if command -v dnf &>/dev/null; then
        log_message "检测到 DNF，使用 DNF 进行更新..."
        echo -e "检测到 DNF，使用 DNF 进行更新..."
        # 先更新源
        log_message "更新 DNF 仓库信息..."
        if ! safe_exec dnf check-update -y; then
            log_message "DNF 仓库更新遇到问题，但继续尝试更新软件包..."
        fi
        # 执行更新
        log_message "更新软件包..."
        if ! safe_exec dnf -y update; then
            log_message "DNF 更新失败"
            echo "失败" > "$status_file"
        else
            log_message "DNF 更新成功"
        fi

    elif command -v yum &>/dev/null; then
        log_message "检测到 YUM，使用 YUM 进行更新..."
        echo -e "检测到 YUM，使用 YUM 进行更新..."
        # 先更新源
        log_message "更新 YUM 仓库信息..."
        if ! safe_exec yum check-update -y; then
            log_message "YUM 仓库更新遇到问题，但继续尝试更新软件包..."
        fi
        # 执行更新
        log_message "更新软件包..."
        if ! safe_exec yum -y update; then
            log_message "YUM 更新失败"
            echo "失败" > "$status_file"
        else
            log_message "YUM 更新成功"
        fi

    elif command -v apt &>/dev/null; then
        log_message "检测到 APT，使用 APT 进行更新..."
        echo -e "检测到 APT，使用 APT 进行更新..."
        # 修复 dpkg 问题
        fix_dpkg_safe
        # 更新源
        log_message "更新 APT 仓库信息..."
        if ! safe_exec DEBIAN_FRONTEND=noninteractive apt update -y; then
            log_message "APT 仓库更新失败"
        else
            log_message "APT 仓库更新成功"
        fi
        # 执行更新
        log_message "更新软件包..."
        if ! safe_exec DEBIAN_FRONTEND=noninteractive apt full-upgrade -y; then
            log_message "APT 更新失败"
            echo "失败" > "$status_file"
        else
            log_message "APT 更新成功"
        fi

    elif command -v apk &>/dev/null; then
        log_message "检测到 APK，使用 Alpine 的 apk 进行更新..."
        echo -e "检测到 APK，使用 Alpine 的 apk 进行更新..."
        log_message "更新 APK 仓库信息..."
        if ! safe_exec apk update; then
            log_message "APK 仓库更新失败"
        else
            log_message "APK 仓库更新成功"
            log_message "更新软件包..."
            if ! safe_exec apk upgrade; then
                log_message "APK 更新失败"
                echo "失败" > "$status_file"
            else
                log_message "APK 更新成功"
            fi
        fi

    elif command -v pacman &>/dev/null; then
        log_message "检测到 Pacman，使用 Arch Linux 的 pacman 进行更新..."
        echo -e "检测到 Pacman，使用 Arch Linux 的 pacman 进行更新..."
        if ! safe_exec pacman -Syu --noconfirm; then
            log_message "Pacman 更新失败"
            echo "失败" > "$status_file"
        else
            log_message "Pacman 更新成功"
        fi

    elif command -v zypper &>/dev/null; then
        log_message "检测到 Zypper，使用 OpenSUSE 的 zypper 进行更新..."
        echo -e "检测到 Zypper，使用 OpenSUSE 的 zypper 进行更新..."
        log_message "更新 Zypper 仓库信息..."
        if ! safe_exec zypper refresh; then
            log_message "Zypper 仓库更新失败"
        else
            log_message "Zypper 仓库更新成功"
            log_message "更新软件包..."
            if ! safe_exec zypper update -y; then
                log_message "Zypper 更新失败"
                echo "失败" > "$status_file"
            else
                log_message "Zypper 更新成功"
            fi
        fi

    elif command -v opkg &>/dev/null; then
        log_message "检测到 OPKG，使用 OpenWRT 的 opkg 进行更新..."
        echo -e "检测到 OPKG，使用 OpenWRT 的 opkg 进行更新..."
        log_message "更新 OPKG 仓库信息..."
        if ! safe_exec opkg update; then
            log_message "OPKG 仓库更新失败"
        else
            log_message "OPKG 仓库更新成功"
            log_message "更新软件包..."
            if ! safe_exec opkg upgrade; then
                log_message "OPKG 更新失败"
                echo "失败" > "$status_file"
            else
                log_message "OPKG 更新成功"
            fi
        fi

    else
        log_message "未知的包管理器，无法更新系统！"
        echo -e "未知的包管理器，无法更新系统！"
        echo "失败" > "$status_file"
    fi

    local update_status=$(cat "$status_file")
    rm -f "$status_file"
    
    log_message "系统更新${update_status}！"
    echo -e "系统更新${update_status}！"
    
    # 在日志中添加完成标记
    if [ "$update_status" = "成功" ]; then
        log_message "系统更新成功！"
    else
        log_message "系统更新失败！"
    fi
    
    return 0
}

# 更新Dialog显示内容的函数（避免滚动）
update_dialog_content() {
    local source_file="$1"
    local target_file="$2"
    local lines=$3
    
    # 获取最新的行数
    tail -n "$lines" "$source_file" > "$target_file"
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
        if grep -q "更新成功" "$log_file" || grep -q "更新成功" "$DETAILED_LOG"; then
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
        echo -e "详细日志已保存至: ${YELLOW}$DETAILED_LOG${RESET}"
        echo "可以使用以下命令查看详细日志:"
        echo -e "${BLUE}cat $DETAILED_LOG${RESET}"
        echo ""
        echo "按Enter键继续..."
        read
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        # 首先显示一个infobox，告知用户更新已经开始
        dialog --title "系统更新" --infobox "准备执行系统更新，正在初始化...\n\n详细日志将保存到: $DETAILED_LOG" 8 60
        sleep 2
        
        # 确保临时目录存在
        mkdir -p /tmp/servermaster
        
        # 创建两个临时文件：一个存放完整日志，一个用于显示
        update_full_file="/tmp/servermaster/update_full.txt"
        update_display_file="/tmp/servermaster/update_display.txt"
        echo "正在初始化系统更新..." > "$update_full_file"
        echo "正在初始化系统更新..." > "$update_display_file"
        
        # 创建一个后台进程来定期更新显示内容
        {
            local display_lines=$((dialog_height-12))
            while [ -f "$update_full_file" ]; do
                update_dialog_content "$update_full_file" "$update_display_file" "$display_lines"
                sleep 0.5
            done
        } &
        updater_pid=$!
        
        # 启动dialog对话框以显示更新日志
        dialog --title "系统更新进度" --begin 3 3 --tailbox "$update_display_file" $((dialog_height-10)) $((dialog_width-6)) 2>&1 >/dev/tty &
        dialog_pid=$!
        
        # 执行系统更新并将输出重定向到文件
        {
            # 输出到完整日志文件
            echo "开始系统更新过程..." >> "$update_full_file"
            echo "$SEPARATOR" >> "$update_full_file"
            
            # 执行更新并写入日志
            system_update >> "$update_full_file" 2>&1
            update_result=$?
            
            echo "$SEPARATOR" >> "$update_full_file"
            
            # 根据日志内容判断是否成功
            if grep -q "更新成功" "$DETAILED_LOG"; then
                echo "系统更新完成！" >> "$update_full_file"
                update_status="成功"
            else
                echo "系统更新失败！请检查日志详情。" >> "$update_full_file"
                update_status="失败"
            fi
            
            echo "等待5秒后关闭此窗口..." >> "$update_full_file"
            echo "详细日志已保存至: $DETAILED_LOG" >> "$update_full_file"
            sleep 5
            
            # 结束更新进程
            kill $updater_pid 2>/dev/null
            
            # 结束dialog进程
            kill $dialog_pid 2>/dev/null
            
            # 删除标记文件以终止更新器
            rm -f "$update_full_file"
        } &
        
        # 等待dialog进程结束
        wait $dialog_pid 2>/dev/null
        
        # 确保更新器进程已终止
        kill $updater_pid 2>/dev/null
        
        # 读取日志并格式化显示
        if [ -s "$DETAILED_LOG" ]; then
            # 提取最多30行关键日志信息
            update_log=$(grep -E "(开始进行系统更新|检测到操作系统|更新成功|更新失败|系统更新成功|系统更新失败)" "$DETAILED_LOG" | tail -n 30)
            
            # 创建一个格式化的日志显示数组
            log_entries=()
            while IFS= read -r line; do
                log_entries+=("$line")
            done <<< "$update_log"
            
            # 组合显示内容
            display_text="系统更新${update_status}！\n\n系统更新日志:\n"
            for entry in "${log_entries[@]}"; do
                display_text="${display_text}${entry}\n"
            done
            display_text="${display_text}\n详细日志已保存至: $DETAILED_LOG"
        else
            display_text="警告：更新日志为空，这可能是因为系统更新过程中没有产生输出或发生了错误。"
        fi
        
        # 显示最终结果
        if [ "$update_status" = "成功" ]; then
            dialog --title "系统更新" --msgbox "$display_text" $dialog_height $dialog_width
        else
            dialog --title "系统更新" --msgbox "$display_text" $dialog_height $dialog_width
        fi
        
        # 清理临时文件
        rm -f "$update_display_file" "$update_full_file"
    fi
    
    # 清理临时文件
    rm -f "$log_file"
    
    # 提示用户日志文件位置
    log_message "系统更新执行结束。详细日志已保存至: $DETAILED_LOG"
}

# 检查是否有参数要求直接运行系统更新
if [ "$1" = "--direct" ]; then
    # 直接执行系统更新，不显示界面
    system_update
    exit 0
fi

# 直接显示系统更新界面，不再显示菜单
show_system_update

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 