#!/bin/bash

# intranet_penetration模块菜单
# 此脚本提供内网穿透相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_intranet_penetration_menu() {
    local title="内网穿透"
    local menu_items=(
        "1" "FRP服务端 - 安装/管理FRP服务端"
        "2" "FRP客户端 - 安装/管理FRP客户端"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      内网穿透菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) FRP服务端                "
            echo "  2) FRP客户端                "
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-2]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 3 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            if [ $? -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "intranet_penetration/frp_server.sh" ;;
            2) execute_module "intranet_penetration/frp_client.sh" ;;
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
show_intranet_penetration_menu 