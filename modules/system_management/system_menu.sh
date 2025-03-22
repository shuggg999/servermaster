#!/bin/bash

# system_management模块菜单
# 此脚本提供系统管理相关功能的菜单界面

# 只在变量未定义时才设置安装目录
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
    MODULES_DIR="$INSTALL_DIR/modules"
    CONFIG_DIR="$INSTALL_DIR/config"
    
    # 导入共享函数
    source "$INSTALL_DIR/main.sh"
fi

# 保存当前目录
CURRENT_DIR="$(pwd)"

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
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
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
            # 使用Dialog显示菜单 - 不使用dialog_rules.sh中的函数，直接使用dialog命令
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 8 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
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
show_system_management_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 