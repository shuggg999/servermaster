#!/bin/bash

# 系统清理
# 此脚本提供系统垃圾文件清理功能

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
DETAILED_LOG="$INSTALL_DIR/logs/system_clean.log"
# 清空之前的日志
echo "系统清理日志 - $(date '+%Y-%m-%d %H:%M:%S')" > "$DETAILED_LOG"
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

    # 确保锁文件被删除
    log_message "删除 dpkg 锁文件..."
    echo -e "删除 dpkg 锁文件..."
    safe_exec rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock

    # 修复 dpkg 未完成的安装
    log_message "修复 dpkg 配置..."
    echo -e "修复 dpkg 配置..."
    safe_exec dpkg --configure -a
}

# 系统清理函数
system_clean() {
    # 创建临时文件存储状态
    local status_file=$(mktemp)
    echo "成功" > "$status_file"
    
    log_message "开始进行系统清理..."
    echo -e "开始进行系统清理..."

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

    # 通用清理
    log_message "清理临时目录..."
    echo -e "清理临时目录..."
    safe_exec find /tmp -type f -atime +10 -delete
    safe_exec rm -rf /var/tmp/\*

    # 根据不同发行版清理
    if command -v dnf &>/dev/null; then
        log_message "检测到 DNF，使用 DNF 进行清理..."
        echo -e "检测到 DNF，使用 DNF 进行清理..."
        
        log_message "重建RPM数据库..."
        if ! safe_exec rpm --rebuilddb; then
            log_message "RPM数据库重建失败"
        else
            log_message "RPM数据库重建成功"
        fi
        
        log_message "清理未使用的软件包..."
        if ! safe_exec dnf autoremove -y; then
            log_message "DNF清理未使用的软件包失败"
        else
            log_message "DNF清理未使用的软件包成功"
        fi
        
        log_message "清理DNF缓存..."
        if ! safe_exec dnf clean all; then
            log_message "DNF缓存清理失败"
        else
            log_message "DNF缓存清理成功"
        fi
        
        log_message "重建DNF缓存..."
        if ! safe_exec dnf makecache; then
            log_message "DNF缓存重建失败"
        else
            log_message "DNF缓存重建成功"
        fi
        
        log_message "清理系统日志..."
        if ! safe_exec journalctl --rotate; then
            log_message "日志轮转失败"
        else
            log_message "日志轮转成功"
            if ! safe_exec journalctl --vacuum-time=1s; then
                log_message "日志清理(时间)失败"
            else
                log_message "日志清理(时间)成功"
            fi
            if ! safe_exec journalctl --vacuum-size=500M; then
                log_message "日志清理(大小)失败"
            else
                log_message "日志清理(大小)成功"
            fi
        fi

    elif command -v yum &>/dev/null; then
        log_message "检测到 YUM，使用 YUM 进行清理..."
        echo -e "检测到 YUM，使用 YUM 进行清理..."
        
        log_message "重建RPM数据库..."
        if ! safe_exec rpm --rebuilddb; then
            log_message "RPM数据库重建失败"
        else
            log_message "RPM数据库重建成功"
        fi
        
        log_message "清理未使用的软件包..."
        if ! safe_exec yum autoremove -y; then
            log_message "YUM清理未使用的软件包失败"
        else
            log_message "YUM清理未使用的软件包成功"
        fi
        
        log_message "清理YUM缓存..."
        if ! safe_exec yum clean all; then
            log_message "YUM缓存清理失败"
        else
            log_message "YUM缓存清理成功"
        fi
        
        log_message "重建YUM缓存..."
        if ! safe_exec yum makecache; then
            log_message "YUM缓存重建失败"
        else
            log_message "YUM缓存重建成功"
        fi
        
        log_message "清理系统日志..."
        if ! safe_exec journalctl --rotate; then
            log_message "日志轮转失败"
        else
            log_message "日志轮转成功"
            if ! safe_exec journalctl --vacuum-time=1s; then
                log_message "日志清理(时间)失败"
            else
                log_message "日志清理(时间)成功"
            fi
            if ! safe_exec journalctl --vacuum-size=500M; then
                log_message "日志清理(大小)失败"
            else
                log_message "日志清理(大小)成功"
            fi
        fi

    elif command -v apt &>/dev/null; then
        log_message "检测到 APT，使用 APT 进行清理..."
        echo -e "检测到 APT，使用 APT 进行清理..."
        
        # 修复dpkg问题
        fix_dpkg_safe
        
        log_message "清理未使用的软件包..."
        if ! safe_exec apt autoremove --purge -y; then
            log_message "APT清理未使用的软件包失败"
        else
            log_message "APT清理未使用的软件包成功"
        fi
        
        log_message "清理APT缓存..."
        if ! safe_exec apt clean -y; then
            log_message "APT缓存清理失败"
        else
            log_message "APT缓存清理成功"
        fi
        
        log_message "自动清理APT..."
        if ! safe_exec apt autoclean -y; then
            log_message "APT自动清理失败"
        else
            log_message "APT自动清理成功"
        fi
        
        log_message "清理系统日志..."
        if ! safe_exec journalctl --rotate; then
            log_message "日志轮转失败"
        else
            log_message "日志轮转成功"
            if ! safe_exec journalctl --vacuum-time=1s; then
                log_message "日志清理(时间)失败"
            else
                log_message "日志清理(时间)成功"
            fi
            if ! safe_exec journalctl --vacuum-size=500M; then
                log_message "日志清理(大小)失败"
            else
                log_message "日志清理(大小)成功"
            fi
        fi

    elif command -v apk &>/dev/null; then
        log_message "检测到 APK，使用 Alpine 的 apk 进行清理..."
        echo -e "检测到 APK，使用 Alpine 的 apk 进行清理..."
        
        log_message "清理包管理器缓存..."
        if ! safe_exec apk cache clean; then
            log_message "APK缓存清理失败"
        else
            log_message "APK缓存清理成功"
        fi
        
        log_message "删除系统日志..."
        if ! safe_exec rm -rf /var/log/*; then
            log_message "系统日志删除失败"
        else
            log_message "系统日志删除成功"
        fi
        
        log_message "删除APK缓存..."
        if ! safe_exec rm -rf /var/cache/apk/*; then
            log_message "APK缓存删除失败"
        else
            log_message "APK缓存删除成功"
        fi
        
        log_message "删除临时文件..."
        if ! safe_exec rm -rf /tmp/*; then
            log_message "临时文件删除失败"
        else
            log_message "临时文件删除成功"
        fi

    elif command -v pacman &>/dev/null; then
        log_message "检测到 Pacman，使用 Arch Linux 的 pacman 进行清理..."
        echo -e "检测到 Pacman，使用 Arch Linux 的 pacman 进行清理..."
        
        log_message "清理孤立软件包..."
        orphans=$(safe_exec pacman -Qdtq)
        if [ -n "$orphans" ]; then
            if ! safe_exec pacman -Rns $(pacman -Qdtq) --noconfirm; then
                log_message "Pacman清理孤立软件包失败"
            else
                log_message "Pacman清理孤立软件包成功"
            fi
        else
            log_message "没有孤立软件包需要清理"
        fi
        
        log_message "清理Pacman缓存..."
        if ! safe_exec pacman -Scc --noconfirm; then
            log_message "Pacman缓存清理失败"
        else
            log_message "Pacman缓存清理成功"
        fi
        
        log_message "清理系统日志..."
        if ! safe_exec journalctl --rotate; then
            log_message "日志轮转失败"
        else
            log_message "日志轮转成功"
            if ! safe_exec journalctl --vacuum-time=1s; then
                log_message "日志清理(时间)失败"
            else
                log_message "日志清理(时间)成功"
            fi
            if ! safe_exec journalctl --vacuum-size=500M; then
                log_message "日志清理(大小)失败"
            else
                log_message "日志清理(大小)成功"
            fi
        fi

    elif command -v zypper &>/dev/null; then
        log_message "检测到 Zypper，使用 OpenSUSE 的 zypper 进行清理..."
        echo -e "检测到 Zypper，使用 OpenSUSE 的 zypper 进行清理..."
        
        log_message "清理Zypper缓存..."
        if ! safe_exec zypper clean --all; then
            log_message "Zypper缓存清理失败"
        else
            log_message "Zypper缓存清理成功"
        fi
        
        log_message "刷新Zypper..."
        if ! safe_exec zypper refresh; then
            log_message "Zypper刷新失败"
        else
            log_message "Zypper刷新成功"
        fi
        
        log_message "清理系统日志..."
        if ! safe_exec journalctl --rotate; then
            log_message "日志轮转失败"
        else
            log_message "日志轮转成功"
            if ! safe_exec journalctl --vacuum-time=1s; then
                log_message "日志清理(时间)失败"
            else
                log_message "日志清理(时间)成功"
            fi
            if ! safe_exec journalctl --vacuum-size=500M; then
                log_message "日志清理(大小)失败"
            else
                log_message "日志清理(大小)成功"
            fi
        fi

    elif command -v opkg &>/dev/null; then
        log_message "检测到 OPKG，使用 OpenWRT 的 opkg 进行清理..."
        echo -e "检测到 OPKG，使用 OpenWRT 的 opkg 进行清理..."
        
        log_message "删除系统日志..."
        if ! safe_exec rm -rf /var/log/*; then
            log_message "系统日志删除失败"
        else
            log_message "系统日志删除成功"
        fi
        
        log_message "删除临时文件..."
        if ! safe_exec rm -rf /tmp/*; then
            log_message "临时文件删除失败"
        else
            log_message "临时文件删除成功"
        fi
        
    elif command -v pkg &>/dev/null; then
        log_message "检测到 PKG，使用 BSD 的 pkg 进行清理..."
        echo -e "检测到 PKG，使用 BSD 的 pkg 进行清理..."
        
        log_message "清理未使用的依赖..."
        if ! safe_exec pkg autoremove -y; then
            log_message "PKG清理未使用的依赖失败"
        else
            log_message "PKG清理未使用的依赖成功"
        fi
        
        log_message "清理包管理器缓存..."
        if ! safe_exec pkg clean -y; then
            log_message "PKG缓存清理失败"
        else
            log_message "PKG缓存清理成功"
        fi
        
        log_message "删除系统日志..."
        if ! safe_exec rm -rf /var/log/*; then
            log_message "系统日志删除失败"
        else
            log_message "系统日志删除成功"
        fi
        
        log_message "删除临时文件..."
        if ! safe_exec rm -rf /tmp/*; then
            log_message "临时文件删除失败"
        else
            log_message "临时文件删除成功"
        fi

    else
        log_message "未知的包管理器，无法进行系统清理！"
        echo -e "未知的包管理器，无法进行系统清理！"
        echo "失败" > "$status_file"
    fi
    
    # 共通清理
    log_message "清理用户缓存目录..."
    if [ -d ~/.cache ]; then
        safe_exec find ~/.cache -type f -atime +30 -delete
        log_message "用户缓存目录清理完成"
    fi
    
    log_message "清理旧内核文件..."
    if command -v apt &>/dev/null; then
        # 保留当前和上一个内核版本
        current_kernel=$(uname -r)
        safe_exec apt-get purge $(dpkg -l 'linux-image-*' | grep -v "$current_kernel" | grep '^ii' | awk '{print $2}' | head -n -1) -y
        log_message "旧内核文件清理完成"
    fi
    
    log_message "清理回收站..."
    safe_exec rm -rf ~/.local/share/Trash/*
    log_message "回收站清理完成"

    local clean_status=$(cat "$status_file")
    rm -f "$status_file"
    
    log_message "系统清理${clean_status}！"
    echo -e "系统清理${clean_status}！"
    
    # 在日志中添加完成标记
    if [ "$clean_status" = "成功" ]; then
        log_message "系统清理成功！"
    else
        log_message "系统清理失败！"
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

# 显示系统清理执行界面
show_system_clean() {
    # 确保我们在正确的目录
    cd "$INSTALL_DIR"
    
    clear
    
    # 创建临时文件存储日志
    local log_file=$(mktemp)
    
    # 文本模式下的显示
    if [ "$USE_TEXT_MODE" = true ]; then
        clear
        echo "====================================================="
        echo -e "${GREEN}      系统清理                                        ${RESET}"
        echo "====================================================="
        echo ""
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        echo -e "${YELLOW}正在执行系统清理，请稍候...${RESET}"
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        echo ""
        
        # 执行系统清理并直接输出到终端和日志文件
        system_clean | tee "$log_file"
        
        # 检查清理是否成功
        if grep -q "清理成功" "$log_file" || grep -q "清理成功" "$DETAILED_LOG"; then
            clean_status="成功"
        else
            clean_status="失败"
        fi
        
        echo -e "${BLUE}${SEPARATOR}${RESET}"
        if [ "$clean_status" = "成功" ]; then
            echo -e "${GREEN}系统清理完成！${RESET}"
        else
            echo -e "${RED}系统清理失败！${RESET}"
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
        
        # 首先显示一个infobox，告知用户清理已经开始
        dialog --title "系统清理" --infobox "准备执行系统清理，正在初始化...\n\n详细日志将保存到: $DETAILED_LOG" 8 60
        sleep 2
        
        # 确保临时目录存在
        mkdir -p /tmp/servermaster
        
        # 创建两个临时文件：一个存放完整日志，一个用于显示
        clean_full_file="/tmp/servermaster/clean_full.txt"
        clean_display_file="/tmp/servermaster/clean_display.txt"
        echo "正在初始化系统清理..." > "$clean_full_file"
        echo "正在初始化系统清理..." > "$clean_display_file"
        
        # 创建一个后台进程来定期更新显示内容
        {
            local display_lines=$((dialog_height-12))
            while [ -f "$clean_full_file" ]; do
                update_dialog_content "$clean_full_file" "$clean_display_file" "$display_lines"
                sleep 0.5
            done
        } &
        updater_pid=$!
        
        # 启动dialog对话框以显示清理日志
        dialog --title "系统清理进度" --begin 3 3 --tailbox "$clean_display_file" $((dialog_height-10)) $((dialog_width-6)) 2>&1 >/dev/tty &
        dialog_pid=$!
        
        # 执行系统清理并将输出重定向到文件
        {
            # 输出到完整日志文件
            echo "开始系统清理过程..." >> "$clean_full_file"
            echo "$SEPARATOR" >> "$clean_full_file"
            
            # 执行清理并写入日志
            system_clean >> "$clean_full_file" 2>&1
            clean_result=$?
            
            echo "$SEPARATOR" >> "$clean_full_file"
            
            # 根据日志内容判断是否成功
            if grep -q "清理成功" "$DETAILED_LOG"; then
                echo "系统清理完成！" >> "$clean_full_file"
                clean_status="成功"
            else
                echo "系统清理失败！请检查日志详情。" >> "$clean_full_file"
                clean_status="失败"
            fi
            
            echo "等待5秒后关闭此窗口..." >> "$clean_full_file"
            echo "详细日志已保存至: $DETAILED_LOG" >> "$clean_full_file"
            sleep 5
            
            # 结束更新进程
            kill $updater_pid 2>/dev/null
            
            # 结束dialog进程
            kill $dialog_pid 2>/dev/null
            
            # 删除标记文件以终止更新器
            rm -f "$clean_full_file"
        } &
        
        # 等待dialog进程结束
        wait $dialog_pid 2>/dev/null
        
        # 确保更新器进程已终止
        kill $updater_pid 2>/dev/null
        
        # 读取日志并格式化显示
        if [ -s "$DETAILED_LOG" ]; then
            # 提取最多30行关键日志信息
            clean_log=$(grep -E "(开始进行系统清理|检测到操作系统|清理成功|清理失败|系统清理成功|系统清理失败)" "$DETAILED_LOG" | tail -n 30)
            
            # 创建一个格式化的日志显示数组
            log_entries=()
            while IFS= read -r line; do
                log_entries+=("$line")
            done <<< "$clean_log"
            
            # 组合显示内容
            display_text="系统清理${clean_status}！\n\n系统清理日志:\n"
            for entry in "${log_entries[@]}"; do
                display_text="${display_text}${entry}\n"
            done
            display_text="${display_text}\n详细日志已保存至: $DETAILED_LOG"
        else
            display_text="警告：清理日志为空，这可能是因为系统清理过程中没有产生输出或发生了错误。"
        fi
        
        # 显示最终结果
        if [ "$clean_status" = "成功" ]; then
            dialog --title "系统清理" --msgbox "$display_text" $dialog_height $dialog_width
        else
            dialog --title "系统清理" --msgbox "$display_text" $dialog_height $dialog_width
        fi
        
        # 清理临时文件
        rm -f "$clean_display_file" "$clean_full_file"
    fi
    
    # 清理临时文件
    rm -f "$log_file"
    
    # 提示用户日志文件位置
    log_message "系统清理执行结束。详细日志已保存至: $DETAILED_LOG"
}

# 检查是否有参数要求直接运行系统清理
if [ "$1" = "--direct" ]; then
    # 直接执行系统清理，不显示界面
    system_clean
    exit 0
fi

# 直接显示系统清理界面，不再显示菜单
show_system_clean

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 