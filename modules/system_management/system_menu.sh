#!/bin/bash

# system_management模块菜单
# 此脚本提供系统管理相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"
CONFIG_DIR="$INSTALL_DIR/config"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_system_management_menu() {
    local title="系统管理"
    local menu_items=(
        "1" "系统信息查询 - 显示系统基本信息"
        "2" "系统更新 - 更新系统及软件包"
        "3" "系统清理 - 清理系统垃圾文件"
        "4" "系统工具 - 环境配置与资源管理"
        "5" "用户管理 - 用户添加/删除/权限管理"
        "6" "性能优化 - 系统性能调优工具"
        "7" "用户体验 - 命令行美化与工具"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      系统管理菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) 系统信息查询          5) 用户管理"
            echo "  2) 系统更新              6) 性能优化"
            echo "  3) 系统清理              7) 用户体验"
            echo "  4) 系统工具              "
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-7]: " choice
        else
            # 使用Dialog规则来显示菜单
            local result=$(show_menu_dialog "$title" "请选择一个选项:" 8 "${menu_items[@]}")
            local choice=$(echo "$result" | cut -d'|' -f1)
            local status=$(echo "$result" | cut -d'|' -f2)
            
            # 检查是否按下ESC或Cancel
            if [ "$status" -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "system_management/system_info.sh" ;;
            2) execute_module "system_management/system_update.sh" ;;
            3) execute_module "system_management/system_clean.sh" ;;
            4) execute_module "system_management/system_tools.sh" ;;
            5) execute_module "system_management/user_management.sh" ;;
            6) execute_module "system_management/performance_optimization.sh" ;;
            7) execute_module "system_management/user_experience.sh" ;;
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
    done
}

# 运行菜单
show_system_management_menu 