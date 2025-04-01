#!/bin/bash

# 资源管理
# 此脚本提供资源管理相关功能的菜单界面

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

# 显示资源管理菜单
show_resource_management_menu() {
    local title="资源管理"
    local menu_items=(
        "1" "查看端口占用状态 - 检查端口使用情况"
        "2" "修改虚拟内存大小 - 调整SWAP空间大小"
        "3" "系统时区调整 - 设置系统时区"
        "4" "硬盘分区管理工具 - 管理磁盘分区"
        "0" "返回上级菜单"
    )
    
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      资源管理菜单                                   "
            echo "====================================================="
            echo ""
            echo "  1) 查看端口占用状态"
            echo "  2) 修改虚拟内存大小"
            echo "  3) 系统时区调整"
            echo "  4) 硬盘分区管理工具"
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
            1) echo "查看端口占用状态功能未实现" ;;
            2) echo "修改虚拟内存大小功能未实现" ;;
            3) echo "系统时区调整功能未实现" ;;
            4) echo "硬盘分区管理工具功能未实现" ;;
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
show_resource_management_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 