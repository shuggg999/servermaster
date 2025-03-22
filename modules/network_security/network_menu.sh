#!/bin/bash

# network_security模块菜单
# 此脚本提供网络与安全相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_network_security_menu() {
    local title="网络与安全"
    local menu_items=(
        "1" "防火墙管理 - 端口与IP管理"
        "2" "BBR管理 - 安装/配置Google BBR"
        "3" "WARP管理 - 配置WARP网络"
        "4" "VPN与代理服务 - Xray等代理工具"
        "5" "SSH防御程序 - SSH安全加固"
        "6" "系统监控预警 - TG-bot监控"
        "7" "安全工具 - 漏洞修复与病毒扫描"
        "8" "本机host解析 - 管理hosts文件"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      网络与安全菜单                                  "
            echo "====================================================="
            echo ""
            echo "  1) 防火墙管理              5) SSH防御程序"
            echo "  2) BBR管理                6) 系统监控预警"
            echo "  3) WARP管理               7) 安全工具"
            echo "  4) VPN与代理服务          8) 本机host解析"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-8]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 9 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            if [ $? -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "network_security/firewall_management.sh" ;;
            2) execute_module "network_security/bbr_manager.sh" ;;
            3) execute_module "network_security/warp_manager.sh" ;;
            4) execute_module "network_security/vpn_proxy_services.sh" ;;
            5) execute_module "network_security/ssh_defense.sh" ;;
            6) execute_module "network_security/system_monitoring.sh" ;;
            7) execute_module "network_security/security_tools.sh" ;;
            8) execute_module "network_security/hosts_manager.sh" ;;
            0) return ;;
            *) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "无效选择，请重试"
                    sleep 1
                else
                    dialog --title "错误" --msgbox "无效选项: $choice\n请重新选择" 8 40
                fi
                ;;
        esac
        
        # 文本模式下，显示按键提示
        if [ "$USE_TEXT_MODE" = true ]; then
            echo ""
            echo "按Enter键继续..."
            read
        fi
    done
}

# 运行菜单
show_network_security_menu 