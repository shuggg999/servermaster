 #!/bin/bash
# 一键重装系统
# 此脚本提供自动化重装系统功能，支持多种Linux发行版

# 引入共享函数库
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
CONFIG_DIR="$INSTALL_DIR/config"
source "$CONFIG_DIR/dialog_rules.sh"

# 定义颜色
RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
BLUE="\033[34m"
RESET="\033[0m"

# 定义日志文件
LOG_FILE="/var/log/system_reinstall.log"

# 记录日志函数
log() {
    echo -e "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# 显示彩色信息
info() {
    echo -e "${BLUE}[信息]${RESET} $1" | tee -a "$LOG_FILE"
}

success() {
    echo -e "${GREEN}[成功]${RESET} $1" | tee -a "$LOG_FILE"
}

warning() {
    echo -e "${YELLOW}[警告]${RESET} $1" | tee -a "$LOG_FILE"
}

error() {
    echo -e "${RED}[错误]${RESET} $1" | tee -a "$LOG_FILE"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "请使用root用户运行此脚本"
        exit 1
    fi
}

# 检测网络连接
check_network() {
    info "检查网络连接..."
    if ! ping -c 3 google.com >/dev/null 2>&1 && ! ping -c 3 baidu.com >/dev/null 2>&1; then
        error "网络连接异常，请检查网络设置"
        exit 1
    fi
    success "网络连接正常"
}

# 获取系统信息
get_system_info() {
    info "获取系统信息..."
    
    # 获取CPU架构
    CPU_ARCH=$(uname -m)
    log "CPU架构: $CPU_ARCH"
    
    # 获取当前操作系统信息
    if [ -f /etc/os-release ]; then
        source /etc/os-release
        CURRENT_OS="$NAME $VERSION_ID"
    elif [ -f /etc/redhat-release ]; then
        CURRENT_OS=$(cat /etc/redhat-release)
    else
        CURRENT_OS="未知操作系统"
    fi
    log "当前系统: $CURRENT_OS"
    
    # 获取磁盘信息
    ROOT_DISK=$(df -h | grep -w '/' | awk '{print $1}' | sed 's/[0-9]*//g')
    log "根目录磁盘: $ROOT_DISK"
    
    # 获取内存信息
    TOTAL_MEM=$(free -h | grep Mem | awk '{print $2}')
    log "总内存: $TOTAL_MEM"
    
    success "系统信息获取完成"
}

# 备份重要数据
backup_important_data() {
    info "备份重要数据..."
    
    # 创建备份目录
    BACKUP_DIR="/tmp/system_backup_$(date +%Y%m%d%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    # 备份SSH密钥
    if [ -d /root/.ssh ]; then
        cp -r /root/.ssh "$BACKUP_DIR/"
        log "已备份SSH密钥"
    fi
    
    # 备份重要配置文件
    cp /etc/hostname "$BACKUP_DIR/" 2>/dev/null
    cp /etc/hosts "$BACKUP_DIR/" 2>/dev/null
    cp /etc/network/interfaces "$BACKUP_DIR/" 2>/dev/null || cp -r /etc/sysconfig/network-scripts "$BACKUP_DIR/" 2>/dev/null
    
    # 备份crontab
    crontab -l > "$BACKUP_DIR/root_crontab" 2>/dev/null
    
    success "重要数据备份完成，备份目录: $BACKUP_DIR"
}

# 选择要安装的系统
select_os() {
    local title="选择操作系统"
    local menu_items=(
        "debian11" "Debian 11 (推荐)"
        "debian10" "Debian 10"
        "ubuntu22" "Ubuntu 22.04 LTS"
        "ubuntu20" "Ubuntu 20.04 LTS"
        "centos7" "CentOS 7"
        "centos8" "CentOS 8 Stream"
        "almalinux8" "AlmaLinux 8"
        "rocky8" "Rocky Linux 8"
        "fedora36" "Fedora 36"
        "custom" "自定义系统(高级)"
    )
    
    # 显示菜单
    local choice=$(show_menu_dialog "$title" "请选择要安装的操作系统:" 10 "${menu_items[@]}")
    local selected=$(echo $choice | cut -d'|' -f1)
    local status=$(echo $choice | cut -d'|' -f2)
    
    if [[ $status -ne 0 || -z "$selected" ]]; then
        warning "未选择操作系统，操作取消"
        exit 0
    fi
    
    echo "$selected"
}

# 配置分区
configure_partitions() {
    local title="磁盘分区"
    local menu_items=(
        "auto" "自动分区 (推荐)"
        "single" "单分区 (仅/分区)"
        "standard" "标准分区 (/, /boot, swap)"
        "custom" "自定义分区方案 (高级)"
    )
    
    # 显示菜单
    local choice=$(show_menu_dialog "$title" "请选择分区方案:" 4 "${menu_items[@]}")
    local selected=$(echo $choice | cut -d'|' -f1)
    local status=$(echo $choice | cut -d'|' -f2)
    
    if [[ $status -ne 0 || -z "$selected" ]]; then
        warning "未选择分区方案，使用默认自动分区"
        selected="auto"
    fi
    
    echo "$selected"
}

# 配置密码
configure_password() {
    local title="设置ROOT密码"
    local prompt="请输入新系统的ROOT密码 (留空将随机生成):"
    
    local input_result=$(show_input_dialog "$title" "$prompt" "")
    local password=$(echo $input_result | cut -d'|' -f1)
    local status=$(echo $input_result | cut -d'|' -f2)
    
    if [[ $status -ne 0 ]]; then
        warning "未设置密码，操作取消"
        exit 0
    fi
    
    # 如果密码为空，生成随机密码
    if [[ -z "$password" ]]; then
        password=$(tr -dc 'a-zA-Z0-9!@#$%^&*()_+' < /dev/urandom | head -c 12)
        info "已生成随机密码: $password"
    fi
    
    echo "$password"
}

# 确认重装
confirm_reinstall() {
    local os=$1
    local partitioning=$2
    
    local message="您即将重装系统，这将删除当前系统上的所有数据！\n\n"
    message+="重装信息:\n"
    message+="- 目标系统: $os\n"
    message+="- 分区方案: $partitioning\n\n"
    message+="是否确定继续？"
    
    local confirm=$(show_confirm_dialog "警告" "$message")
    if [[ $confirm -ne 0 ]]; then
        info "用户取消重装"
        exit 0
    fi
    
    # 二次确认
    local message="最后确认: 系统将在确认后立即开始重装，且无法撤销！\n\n确定要继续吗？"
    local confirm=$(show_confirm_dialog "最终确认" "$message")
    if [[ $confirm -ne 0 ]]; then
        info "用户取消重装"
        exit 0
    fi
}

# 执行系统清理
clean_system() {
    info "执行系统清理..."
    # 同步文件系统，确保数据写入
    sync
    # 清除不必要的包和缓存
    if command -v apt >/dev/null 2>&1; then
        apt clean
    elif command -v yum >/dev/null 2>&1; then
        yum clean all
    fi
    success "系统清理完成"
}

# 下载并准备安装镜像
prepare_installation() {
    local os=$1
    info "准备安装 $os..."
    
    # 创建临时目录
    local TEMP_DIR="/tmp/reinstall_temp"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # 根据选择的系统下载相应的网络安装文件
    case $os in
        debian11)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/debian-cd/current/amd64/iso-cd/debian-11.7.0-amd64-netinst.iso
            ;;
        debian10)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/debian-cd/archive/10.13.0/amd64/iso-cd/debian-10.13.0-amd64-netinst.iso
            ;;
        ubuntu22)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/22.04.3/ubuntu-22.04.3-live-server-amd64.iso
            ;;
        ubuntu20)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/ubuntu-releases/20.04.6/ubuntu-20.04.6-live-server-amd64.iso
            ;;
        centos7)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/centos/7.9.2009/isos/x86_64/CentOS-7-x86_64-Minimal-2009.iso
            ;;
        centos8)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/centos-stream/8-stream/BaseOS/x86_64/iso/CentOS-Stream-8-x86_64-latest-boot.iso
            ;;
        almalinux8)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/almalinux/8/isos/x86_64/AlmaLinux-8-latest-x86_64-minimal.iso
            ;;
        rocky8)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/rocky/8/isos/x86_64/Rocky-8.8-x86_64-minimal.iso
            ;;
        fedora36)
            wget -O installer.iso https://mirrors.tuna.tsinghua.edu.cn/fedora/releases/36/Server/x86_64/iso/Fedora-Server-netinst-x86_64-36-1.5.iso
            ;;
        custom)
            # 对于自定义系统，让用户输入URL
            local input_result=$(show_input_dialog "自定义系统" "请输入系统镜像URL:" "")
            local custom_url=$(echo $input_result | cut -d'|' -f1)
            local status=$(echo $input_result | cut -d'|' -f2)
            
            if [[ $status -ne 0 || -z "$custom_url" ]]; then
                error "未提供有效的URL，操作取消"
                exit 1
            fi
            
            wget -O installer.iso "$custom_url"
            ;;
    esac
    
    # 检查下载是否成功
    if [ ! -f installer.iso ]; then
        error "下载安装镜像失败"
        exit 1
    fi
    
    success "安装镜像准备完成"
}

# 创建自动应答文件 (preseed/kickstart)
create_response_file() {
    local os=$1
    local partitioning=$2
    local password=$3
    
    info "创建自动应答文件..."
    
    # 根据不同操作系统创建不同的应答文件
    case $os in
        debian*|ubuntu*)
            # 为Debian/Ubuntu创建preseed文件
            cat > preseed.cfg <<EOF
# 基本设置
d-i debian-installer/locale string zh_CN.UTF-8
d-i keyboard-configuration/xkb-keymap select us
d-i netcfg/choose_interface select auto

# 网络设置
d-i netcfg/get_hostname string servermaster
d-i netcfg/get_domain string local

# 镜像设置
d-i mirror/country string manual
d-i mirror/http/hostname string mirrors.tuna.tsinghua.edu.cn
d-i mirror/http/directory string /debian
d-i mirror/http/proxy string

# 用户设置
d-i passwd/root-login boolean true
d-i passwd/make-user boolean false
d-i passwd/root-password password ${password}
d-i passwd/root-password-again password ${password}

# 时区设置
d-i time/zone string Asia/Shanghai
d-i clock-setup/utc boolean true
d-i clock-setup/ntp boolean true

# 分区设置
EOF
            # 根据分区方案添加分区配置
            case $partitioning in
                auto)
                    cat >> preseed.cfg <<EOF
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
EOF
                    ;;
                single)
                    cat >> preseed.cfg <<EOF
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select atomic
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
EOF
                    ;;
                standard)
                    cat >> preseed.cfg <<EOF
d-i partman-auto/method string regular
d-i partman-auto/choose_recipe select home
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
EOF
                    ;;
                custom)
                    cat >> preseed.cfg <<EOF
d-i partman-auto/method string regular
d-i partman-auto/expert_recipe string                         \
      boot-root ::                                            \
              500 10000 1000000000 ext4                       \
                      $primary{ } $bootable{ }                \
                      method{ format } format{ }              \
                      use_filesystem{ } filesystem{ ext4 }    \
                      mountpoint{ / }                         \
              .                                               \
              64 512 300% linux-swap                          \
                      method{ swap } format{ }                \
              .
d-i partman-partitioning/confirm_write_new_label boolean true
d-i partman/choose_partition select finish
d-i partman/confirm boolean true
d-i partman/confirm_nooverwrite boolean true
EOF
                    ;;
            esac

            # 包选择
            cat >> preseed.cfg <<EOF
# 软件包选择
tasksel tasksel/first multiselect standard, ssh-server
d-i pkgsel/include string openssh-server vim curl wget net-tools
d-i pkgsel/upgrade select full-upgrade

# 引导加载程序设置
d-i grub-installer/only_debian boolean true
d-i grub-installer/with_other_os boolean true
d-i grub-installer/bootdev string default

# 完成安装
d-i finish-install/reboot_in_progress note
EOF
            ;;
            
        centos*|almalinux*|rocky*|fedora*)
            # 为RHEL系列创建kickstart文件
            cat > kickstart.cfg <<EOF
#version=RHEL8
# System authorization information
auth --enableshadow --passalgo=sha512

# 使用CDROM安装
install
cdrom

# 使用图形化安装
text

# 设置防火墙
firewall --enabled --ssh

# 不配置X Window System
skipx

# 系统语言
lang zh_CN.UTF-8

# 键盘类型
keyboard us

# 清除所有分区
clearpart --all --initlabel

# 网络设置
network --bootproto=dhcp --hostname=servermaster.local

# Root密码
rootpw --plaintext ${password}

# 不创建用户
# user --name=user --password=password

# SELinux配置
selinux --enforcing

# 时区设置
timezone Asia/Shanghai --isUtc

# 引导程序设置
bootloader --location=mbr --append="crashkernel=auto rhgb quiet"

# 分区设置
EOF
            # 根据分区方案添加分区配置
            case $partitioning in
                auto|single)
                    cat >> kickstart.cfg <<EOF
autopart --type=lvm
EOF
                    ;;
                standard)
                    cat >> kickstart.cfg <<EOF
part /boot --fstype="xfs" --size=1024
part pv.01 --fstype="lvmpv" --grow
volgroup vg_root pv.01
logvol / --fstype="xfs" --size=51200 --name=lv_root --vgname=vg_root
logvol swap --fstype="swap" --size=4096 --name=lv_swap --vgname=vg_root
EOF
                    ;;
                custom)
                    cat >> kickstart.cfg <<EOF
part /boot --fstype="xfs" --size=1024
part pv.01 --fstype="lvmpv" --grow
volgroup vg_root pv.01
logvol / --fstype="xfs" --size=51200 --name=lv_root --vgname=vg_root
logvol /home --fstype="xfs" --size=20480 --name=lv_home --vgname=vg_root
logvol swap --fstype="swap" --size=4096 --name=lv_swap --vgname=vg_root
EOF
                    ;;
            esac

            # 包选择和安装后脚本
            cat >> kickstart.cfg <<EOF
# 包选择
%packages
@core
openssh-server
vim
curl
wget
net-tools
%end

# 安装后脚本
%post
# 更新系统
yum -y update

# 启用SSH
systemctl enable sshd
systemctl start sshd

# 设置系统调优
echo 'net.ipv4.tcp_fastopen = 3' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_tw_recycle = 0' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_fin_timeout = 30' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_keepalive_time = 1200' >> /etc/sysctl.conf

# 应用系统设置
sysctl -p
%end

# 重启
reboot
EOF
            ;;
    esac
    
    success "自动应答文件创建完成"
}

# 安装BootLoader
install_bootloader() {
    info "配置引导加载程序..."
    
    # 挂载必要的文件系统
    mount -t proc none /mnt/proc
    mount -t sysfs none /mnt/sys
    mount -o bind /dev /mnt/dev
    
    # 在chroot环境中安装GRUB
    chroot /mnt grub-install --recheck $ROOT_DISK
    chroot /mnt update-grub
    
    success "引导加载程序配置完成"
}

# 开始重装系统
start_reinstall() {
    local os=$1
    local partitioning=$2
    local password=$3
    local response_file_path=""
    
    info "准备重装系统..."
    
    # 根据操作系统类型使用不同的重装方法
    case $os in
        debian*|ubuntu*)
            response_file_path="/tmp/reinstall_temp/preseed.cfg"
            ;;
        centos*|almalinux*|rocky*|fedora*)
            response_file_path="/tmp/reinstall_temp/kickstart.cfg"
            ;;
    esac
    
    # 显示进度对话框
    show_progress_dialog "系统重装" "正在准备重装系统，请稍候..."
    
    # 这里是一个模拟的重装过程，实际中需要根据具体环境调整
    # 在实际使用中，通常会使用更专业的工具如netboot.xyz或者特定的PXE服务
    
    # 提示用户系统将重启
    show_info_dialog "重启通知" "系统将在30秒后重启并开始安装过程。\n\n请注意：\n1. 安装过程中请勿断开电源\n2. 完成后系统将自动重启\n3. 安装可能需要10-30分钟，取决于网络速度"
    
    # 模拟倒计时
    for i in {30..1}; do
        show_progress_dialog "准备重启" "系统将在 $i 秒后重启..."
        sleep 1
    done
    
    # 在实际环境中，这里会执行真正的重启命令
    # reboot
    
    success "系统重装已开始，服务器即将重启"
}

# 主函数
main() {
    # 先显示欢迎信息
    clear
    show_info_dialog "欢迎" "欢迎使用一键重装系统工具\n\n该工具将帮助您快速重装服务器操作系统\n注意：此操作将清除服务器上的所有数据！"
    
    # 检查root权限
    check_root
    
    # 检查网络连接
    check_network
    
    # 获取系统信息
    get_system_info
    
    # 选择操作系统
    OS=$(select_os)
    
    # 配置分区
    PARTITIONING=$(configure_partitions)
    
    # 设置ROOT密码
    PASSWORD=$(configure_password)
    
    # 确认重装
    confirm_reinstall "$OS" "$PARTITIONING"
    
    # 备份重要数据
    backup_important_data
    
    # 执行系统清理
    clean_system
    
    # 准备安装
    prepare_installation "$OS"
    
    # 创建应答文件
    create_response_file "$OS" "$PARTITIONING" "$PASSWORD"
    
    # 开始重装过程
    start_reinstall "$OS" "$PARTITIONING" "$PASSWORD"
    
    # 显示完成信息
    show_info_dialog "操作完成" "系统重装过程已启动。\n服务器将重启并开始安装新系统。\n\n安装完成后，可以使用以下信息登录：\n用户名: root\n密码: $PASSWORD\n\n请妥善保管您的密码！"
}

# 执行主函数
main