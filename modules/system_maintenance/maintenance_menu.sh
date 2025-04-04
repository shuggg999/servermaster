#!/bin/bash

# 系统维护
# 此脚本提供系统维护相关功能的菜单界面

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

# 显示系统维护菜单
show_system_maintenance_menu() {
    local title="系统维护"
    local menu_items=(
        "1" "脚本更新 - 更新ServerMaster系统"
        "2" "K命令高级用法 - 高级功能使用说明"
        "3" "卸载脚本 - 卸载ServerMaster"
        "4" "重启服务器 - 重启系统"
        "5" "隐私与安全设置 - 配置安全选项"
        "0" "返回主菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      系统维护菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) 脚本更新                 4) 重启服务器"
            echo "  2) K命令高级用法            5) 隐私与安全设置"
            echo "  3) 卸载脚本                "
            echo ""
            echo "  0) 返回主菜单"
            echo ""
            read -p "请选择操作 [0-5]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 6 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) check_updates ;;
            2) execute_module "system_maintenance/advanced_usage.sh" ;;
            3) uninstall_system ;;
            4) execute_module "system_maintenance/reboot_system.sh" ;;
            5) execute_module "system_maintenance/privacy_settings.sh" ;;
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

# 运行菜单
show_system_maintenance_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 