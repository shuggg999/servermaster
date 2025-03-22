#!/bin/bash

# 用户管理
# 此脚本提供用户添加/删除/权限管理功能

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

# 显示用户管理菜单
show_user_management_menu() {
    local title="用户管理"
    local menu_items=(
        "1" "用户列表 - 查看系统用户列表"
        "2" "添加用户 - 创建新用户"
        "3" "删除用户 - 移除现有用户"
        "4" "修改用户权限 - 更改用户组和权限"
        "5" "用户/密码生成器 - 生成随机用户名和密码"
        "6" "ROOT私钥登录模式 - 配置SSH密钥登录"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      用户管理                                        "
            echo "====================================================="
            echo ""
            echo "  1) 用户列表"
            echo "  2) 添加用户"
            echo "  3) 删除用户"
            echo "  4) 修改用户权限"
            echo "  5) 用户/密码生成器"
            echo "  6) ROOT私钥登录模式"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-6]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 7 \
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
            1|2|3|4|5|6) 
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
show_user_management_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 