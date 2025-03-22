#!/bin/bash

# system_tools 系统工具子模块
# 此脚本提供系统工具相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_system_tools_menu() {
    local title="系统工具"
    local menu_items=(
        "1" "环境与配置管理 - 系统环境配置"
        "2" "资源管理 - 端口与资源管理"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      系统工具菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) 环境与配置管理"
            echo "  2) 资源管理"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-2]: " choice
        else
            # 使用Dialog规则来显示菜单
            local result=$(show_menu_dialog "$title" "请选择一个选项:" 3 "${menu_items[@]}")
            local choice=$(echo "$result" | cut -d'|' -f1)
            local status=$(echo "$result" | cut -d'|' -f2)
            
            # 检查是否按下ESC或Cancel
            if [ "$status" -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "system_management/env_config.sh" ;;
            2) execute_module "system_management/resource_management.sh" ;;
            0) return ;;
            *) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "无效选择，请重试"
                    sleep 1
                else
                    show_error_dialog "错误" "无效选项: $choice\n请重新选择"
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
show_system_tools_menu 