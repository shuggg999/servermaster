#!/bin/bash

# 系统工具
# 此脚本提供系统工具相关功能的菜单界面

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

# 显示系统工具菜单
show_system_tools_menu() {
    local title="系统工具"
    local menu_items=(
        "1" "系统信息查看 - 显示系统详细信息"
        "2" "系统服务管理 - 管理系统服务状态"
        "3" "系统日志查看 - 查看系统日志文件"
        "4" "系统备份还原 - 系统配置备份与恢复"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      系统工具菜单                                   "
            echo "====================================================="
            echo ""
            echo "  1) 系统信息查看"
            echo "  2) 系统服务管理"
            echo "  3) 系统日志查看"
            echo "  4) 系统备份还原"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-4]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 5 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) echo "系统信息查看功能未实现" ;;
            2) echo "系统服务管理功能未实现" ;;
            3) echo "系统日志查看功能未实现" ;;
            4) echo "系统备份还原功能未实现" ;;
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
show_system_tools_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 