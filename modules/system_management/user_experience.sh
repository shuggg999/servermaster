#!/bin/bash

# 用户体验
# 此脚本提供命令行美化与工具

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

# 显示用户体验菜单
show_user_experience_menu() {
    local title="用户体验"
    local menu_items=(
        "1" "文件管理器 - 安装终端文件管理器"
        "2" "切换系统语言 - 更改系统显示语言"
        "3" "命令行美化工具 - 美化终端界面"
        "4" "设置系统回收站 - 配置文件删除恢复机制"
        "5" "命令行历史记录 - 增强命令历史功能"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      用户体验                                        "
            echo "====================================================="
            echo ""
            echo "  1) 文件管理器"
            echo "  2) 切换系统语言"
            echo "  3) 命令行美化工具"
            echo "  4) 设置系统回收站"
            echo "  5) 命令行历史记录"
            echo ""
            echo "  0) 返回上级菜单"
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
        
        # 这里只是占位，具体功能实现会在后续开发中添加
        case $choice in
            1|2|3|4|5) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "该功能尚未实现"
                    sleep 2
                else
                    dialog --title "提示" --msgbox "该功能尚未实现" 8 40
                fi
                ;;
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
show_user_experience_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 