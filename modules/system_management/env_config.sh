#!/bin/bash

# 环境与配置管理
# 此脚本提供环境配置相关功能的菜单界面

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

# 显示环境配置菜单
show_env_config_menu() {
    local title="环境与配置管理"
    local menu_items=(
        "1" "系统环境变量配置 - 管理系统环境变量"
        "2" "应用配置文件管理 - 管理应用配置文件"
        "3" "SSH服务配置 - 配置SSH服务安全选项"
        "4" "系统编码设置 - 配置系统字符编码"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      环境与配置管理菜单                             "
            echo "====================================================="
            echo ""
            echo "  1) 系统环境变量配置"
            echo "  2) 应用配置文件管理"
            echo "  3) SSH服务配置"
            echo "  4) 系统编码设置"
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
            1) echo "系统环境变量配置功能未实现" ;;
            2) echo "应用配置文件管理功能未实现" ;;
            3) echo "SSH服务配置功能未实现" ;;
            4) echo "系统编码设置功能未实现" ;;
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
show_env_config_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 