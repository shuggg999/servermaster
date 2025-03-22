#!/bin/bash

# container_deploy模块菜单
# 此脚本提供容器与应用部署相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_container_deploy_menu() {
    local title="容器与应用部署"
    local menu_items=(
        "1" "Docker管理 - 安装与管理Docker环境"
        "2" "LDNMP建站 - 网站环境与应用部署"
        "3" "应用市场 - 各类应用一键部署"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      容器与应用部署菜单                              "
            echo "====================================================="
            echo ""
            echo "  1) Docker管理              "
            echo "  2) LDNMP建站               "
            echo "  3) 应用市场                "
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-3]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 4 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            if [ $? -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "container_deploy/docker_management.sh" ;;
            2) execute_module "container_deploy/ldnmp_website.sh" ;;
            3) execute_module "container_deploy/app_market.sh" ;;
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
show_container_deploy_menu 