#!/bin/bash

# IP及解锁状态检测
# 此脚本提供各种IP信息和流媒体解锁状态的检测功能

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

# 显示IP及解锁状态检测菜单
show_ip_unlock_test_menu() {
    local title="IP及解锁状态检测"
    local menu_items=(
        "1" "ChatGPT解锁状态检测 - 检测是否可访问"
        "2" "Region流媒体解锁测试 - 流媒体区域限制检测"
        "3" "yeahwu流媒体解锁检测 - 全面流媒体测试"
        "4" "xykt IP质量体检脚本 - IP地址质量综合检测"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      IP及解锁状态检测菜单                            "
            echo "====================================================="
            echo ""
            echo "  1) ChatGPT解锁状态检测"
            echo "  2) Region流媒体解锁测试"
            echo "  3) yeahwu流媒体解锁检测"
            echo "  4) xykt IP质量体检脚本"
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
            1) execute_module "test_diagnostic/tests/chatgpt_test.sh" ;;
            2) execute_module "test_diagnostic/tests/region_media_test.sh" ;;
            3) execute_module "test_diagnostic/tests/yeahwu_media_test.sh" ;;
            4) execute_module "test_diagnostic/tests/xykt_ip_test.sh" ;;
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
show_ip_unlock_test_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 