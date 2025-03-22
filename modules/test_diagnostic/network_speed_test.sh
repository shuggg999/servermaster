#!/bin/bash

# 网络线路测速
# 此脚本提供各种网络延迟、路由和速度测试功能

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

# 显示网络线路测速菜单
show_network_speed_test_menu() {
    local title="网络线路测速"
    local menu_items=(
        "1" "besttrace三网回程延迟路由测试 - 电信/联通/移动回程分析"
        "2" "mtr_trace三网回程线路测试 - 详细路由跟踪测试" 
        "3" "Superspeed三网测速 - 全国节点速度测试"
        "4" "nxtrace快速回程测试脚本 - 快速测试回程路由"
        "5" "nxtrace指定IP回程测试脚本 - 测试特定IP回程"
        "6" "ludashi2020三网线路测试 - 全方位网络测试"
        "7" "i-abc多功能测速脚本 - 综合测速和系统信息"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      网络线路测速菜单                               "
            echo "====================================================="
            echo ""
            echo "  1) besttrace三网回程延迟路由测试     5) nxtrace指定IP回程测试脚本"
            echo "  2) mtr_trace三网回程线路测试         6) ludashi2020三网线路测试"
            echo "  3) Superspeed三网测速                7) i-abc多功能测速脚本"
            echo "  4) nxtrace快速回程测试脚本"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-7]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 18 70 8 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) execute_module "test_diagnostic/tests/besttrace_test.sh" ;;
            2) execute_module "test_diagnostic/tests/mtr_trace_test.sh" ;;
            3) execute_module "test_diagnostic/tests/superspeed_test.sh" ;;
            4) execute_module "test_diagnostic/tests/nxtrace_quick_test.sh" ;;
            5) execute_module "test_diagnostic/tests/nxtrace_ip_test.sh" ;;
            6) execute_module "test_diagnostic/tests/ludashi_test.sh" ;;
            7) execute_module "test_diagnostic/tests/iabc_test.sh" ;;
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
show_network_speed_test_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR"