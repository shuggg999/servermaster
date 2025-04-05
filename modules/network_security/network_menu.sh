#!/bin/bash

# 网络与安全
# 此脚本提供网络与安全相关功能的菜单界面

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

# 订阅转换器菜单函数
show_subscription_converter_menu() {
    # 执行订阅转换器脚本
    # 使用source命令加载脚本，这样可以保留函数定义并执行主菜单
    source "${MODULES_DIR}/network_security/subscription_converter.sh"
    
    # 调用其主菜单函数
    show_subconverter_menu
}

# 显示网络安全菜单
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
        "0" "返回主菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      网络与安全菜单                                   "
            echo "====================================================="
            echo ""
            echo "  1) 防火墙管理              5) SSH防御程序"
            echo "  2) BBR管理                6) 系统监控预警"
            echo "  3) WARP管理               7) 安全工具"
            echo "  4) VPN与代理服务          8) 本机host解析"
            echo ""
            echo "  0) 返回主菜单"
            echo ""
            read -p "请选择操作 [0-8]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 9 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) execute_module "network_security/firewall_management.sh" ;;
            2) execute_module "network_security/bbr_manager.sh" ;;
            3) execute_module "network_security/warp_manager.sh" ;;
            4) show_vpn_proxy_menu ;;
            5) execute_module "network_security/ssh_defense.sh" ;;
            6) execute_module "network_security/system_monitoring.sh" ;;
            7) execute_module "network_security/security_tools.sh" ;;
            8) execute_module "network_security/hosts_manager.sh" ;;
            0) 
                cd "$CURRENT_DIR"  # 恢复原始目录
                return 
                ;;
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

# VPN与代理服务子菜单
show_vpn_proxy_menu() {
    local title="VPN与代理服务"
    local menu_items=(
        "1" "Xray Reality VPN一键安装 - 自动配置订阅更新"
        "2" "Xray手动更新 - 更新现有Xray配置"
        "3" "其他代理工具 - 更多代理选项"
        "4" "订阅管理和转换 - 多协议订阅聚合与格式转换"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      VPN与代理服务菜单                              "
            echo "====================================================="
            echo ""
            echo "  1) Xray Reality VPN一键安装"
            echo "  2) Xray手动更新"
            echo "  3) 其他代理工具"
            echo "  4) 订阅管理和转换"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-4]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 5 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "network_security/xray_setup.sh" ;;
            2) execute_module "network_security/xray_update.sh" ;;
            3) execute_module "network_security/other_proxy_tools.sh" ;;
            4) show_subscription_converter_menu ;;
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

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 