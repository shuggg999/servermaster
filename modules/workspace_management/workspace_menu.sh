#!/bin/bash

# workspace_management模块菜单
# 此脚本提供工作区管理相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_workspace_management_menu() {
    local title="工作区管理"
    local menu_items=(
        "1" "快速工作区 - 1号-10号工作区"
        "2" "SSH常驻模式 - 保持SSH连接"
        "3" "创建/进入工作区 - 创建新工作区"
        "4" "注入命令到后台工作区 - 发送命令"
        "5" "删除指定工作区 - 关闭工作区"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      工作区管理菜单                                  "
            echo "====================================================="
            echo ""
            echo "  1) 快速工作区               4) 注入命令到后台工作区"
            echo "  2) SSH常驻模式              5) 删除指定工作区"
            echo "  3) 创建/进入工作区          "
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-5]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 6 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            if [ $? -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "workspace_management/quick_workspace.sh" ;;
            2) execute_module "workspace_management/ssh_keep_alive.sh" ;;
            3) execute_module "workspace_management/create_workspace.sh" ;;
            4) execute_module "workspace_management/inject_command.sh" ;;
            5) execute_module "workspace_management/delete_workspace.sh" ;;
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
show_workspace_management_menu 