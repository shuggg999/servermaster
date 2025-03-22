#!/bin/bash

# env_config 环境与配置管理子功能
# 此脚本提供环境与配置管理相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_env_config_menu() {
    local title="环境与配置管理"
    local menu_items=(
        "1" "设置脚本启动快捷键 - 自定义启动"
        "2" "修改登录密码 - 修改当前用户密码"
        "3" "ROOT密码登录模式 - 开启密码登录"
        "4" "安装Python指定版本 - 安装Python环境"
        "5" "修改SSH连接端口 - 修改SSH默认端口"
        "6" "优化DNS地址 - 优化DNS解析服务"
        "7" "一键重装系统 - 重装操作系统"
        "8" "切换优先ipv4/ipv6 - 设置网络优先级"
        "9" "切换系统更新源 - 设置软件源"
        "10" "修改主机名 - 修改系统主机名"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      环境与配置管理菜单                              "
            echo "====================================================="
            echo ""
            echo "  1) 设置脚本启动快捷键       6) 优化DNS地址"
            echo "  2) 修改登录密码             7) 一键重装系统"
            echo "  3) ROOT密码登录模式         8) 切换优先ipv4/ipv6"
            echo "  4) 安装Python指定版本       9) 切换系统更新源"
            echo "  5) 修改SSH连接端口          10) 修改主机名"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-10]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 20 70 11 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            if [ $? -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) 
                echo "设置脚本启动快捷键功能尚未实现"
                sleep 2
                ;;
            2) 
                echo "修改登录密码功能尚未实现"
                sleep 2
                ;;
            3) 
                echo "ROOT密码登录模式功能尚未实现"
                sleep 2
                ;;
            4) 
                echo "安装Python指定版本功能尚未实现"
                sleep 2
                ;;
            5) 
                echo "修改SSH连接端口功能尚未实现"
                sleep 2
                ;;
            6) 
                echo "优化DNS地址功能尚未实现"
                sleep 2
                ;;
            7) 
                echo "一键重装系统功能尚未实现"
                sleep 2
                ;;
            8) 
                echo "切换优先ipv4/ipv6功能尚未实现"
                sleep 2
                ;;
            9) 
                echo "切换系统更新源功能尚未实现"
                sleep 2
                ;;
            10) 
                echo "修改主机名功能尚未实现"
                sleep 2
                ;;
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
show_env_config_menu 