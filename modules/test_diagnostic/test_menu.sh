#!/bin/bash

# 测试与诊断
# 此脚本提供测试与诊断相关功能的菜单界面

# 只在变量未定义时才设置安装目录
if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR="$(dirname $(dirname $(dirname $(readlink -f $0))))"
    MODULES_DIR="$INSTALL_DIR/modules"
    CONFIG_DIR="$INSTALL_DIR/config"
    
    # 导入共享函数
    source "$INSTALL_DIR/main.sh"
    
    # 导入对话框规则
    source "$CONFIG_DIR/dialog_rules.sh"
fi

# 保存当前目录
CURRENT_DIR="$(pwd)"

# 显示测试与诊断菜单
show_test_diagnostic_menu() {
    local title="测试与诊断"
    local menu_items=(
        "1" "IP及解锁状态检测 - 流媒体和服务解锁测试"
        "2" "网络线路测速 - 延迟、路由和速度测试"
        "3" "硬件性能测试 - CPU和系统基准测试"
        "4" "综合性测试 - 全面系统评估"
        "5" "甲骨文云脚本合集 - 专用工具和优化" 
        "0" "返回主菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      测试与诊断菜单                                  "
            echo "====================================================="
            echo ""
            echo "  1) IP及解锁状态检测         4) 综合性测试"
            echo "  2) 网络线路测速             5) 甲骨文云脚本合集"
            echo "  3) 硬件性能测试             "
            echo ""
            echo "  0) 返回主菜单"
            echo ""
            read -p "请选择操作 [0-5]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 6 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) execute_module "test_diagnostic/ip_unlock_test.sh" ;;
            2) execute_module "test_diagnostic/network_speed_test.sh" ;;
            3) execute_module "test_diagnostic/hardware_test.sh" ;;
            4) execute_module "test_diagnostic/comprehensive_test.sh" ;;
            5) execute_module "test_diagnostic/oracle_tools.sh" ;;
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
show_test_diagnostic_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 