#!/bin/bash

# test_diagnostic模块菜单
# 此脚本提供测试与诊断相关功能的菜单界面

# 获取安装目录
INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
MODULES_DIR="$INSTALL_DIR/modules"

# 导入共享函数
source "$INSTALL_DIR/main.sh"

# 显示菜单
show_test_diagnostic_menu() {
    local title="测试与诊断"
    local menu_items=(
        "1" "IP及解锁状态检测 - 检测流媒体解锁状态"
        "2" "网络线路测速 - 带宽与回程路由测试"
        "3" "硬件性能测试 - CPU、内存、硬盘性能测试"
        "4" "综合性测试 - 多功能测评脚本"
        "5" "甲骨文云脚本合集 - OCI服务器工具"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      测试与诊断菜单                                  "
            echo "====================================================="
            echo ""
            echo "  1) IP及解锁状态检测        4) 综合性测试"
            echo "  2) 网络线路测速            5) 甲骨文云脚本合集"
            echo "  3) 硬件性能测试            "
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
            1) execute_module "test_diagnostic/unlock_test.sh" ;;
            2) execute_module "test_diagnostic/network_speed.sh" ;;
            3) execute_module "test_diagnostic/hardware_test.sh" ;;
            4) execute_module "test_diagnostic/comprehensive_test.sh" ;;
            5) execute_module "test_diagnostic/oracle_tools.sh" ;;
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
show_test_diagnostic_menu 