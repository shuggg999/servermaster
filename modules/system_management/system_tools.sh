#!/bin/bash

# 系统工具
# 此脚本提供系统工具相关功能的菜单界面

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

# 显示系统工具菜单
show_system_tools_menu() {
    local title="系统工具"
    local menu_items=(
        "1" "环境与配置管理 - 系统环境及配置相关工具"
        "2" "资源管理 - 系统资源管理工具"
        "3" "用户管理 - 用户添加/删除/权限管理"
        "4" "性能优化 - 系统性能调优工具"
        "5" "用户体验 - 提升命令行使用体验"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      系统工具菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) 环境与配置管理"
            echo "  2) 资源管理"
            echo "  3) 用户管理"
            echo "  4) 性能优化"
            echo "  5) 用户体验"
            echo ""
            echo "  \033[31m0\033[0m) 返回上级菜单"
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
            1) show_env_config_menu ;;
            2) show_resource_management_menu ;;
            3) show_user_management_menu ;;
            4) show_performance_optimization_menu ;;
            5) show_user_experience_menu ;;
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

# 显示环境与配置管理菜单
show_env_config_menu() {
    local title="环境与配置管理"
    local menu_items=(
        "1" "设置脚本启动快捷键 - 配置快速启动方式"
        "2" "修改登录密码 - 更改当前用户密码"
        "3" "ROOT密码登录模式 - 启用ROOT密码登录"
        "4" "安装Python指定版本 - 安装特定Python版本"
        "5" "修改SSH连接端口 - 更改SSH服务端口"
        "6" "优化DNS地址 - 配置更快的DNS服务器"
        "7" "一键重装系统 - 系统重装工具"
        "8" "切换优先ipv4/ipv6 - 设置IP协议优先级"
        "9" "切换系统更新源 - 更改软件源"
        "10" "修改主机名 - 更改系统主机名"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      环境与配置管理                                 "
            echo "====================================================="
            echo ""
            echo "  1) 设置脚本启动快捷键      6) 优化DNS地址"
            echo "  2) 修改登录密码            7) 一键重装系统"
            echo "  3) ROOT密码登录模式        8) 切换优先ipv4/ipv6"
            echo "  4) 安装Python指定版本      9) 切换系统更新源"
            echo "  5) 修改SSH连接端口         10) 修改主机名"
            echo ""
            echo "  \033[31m0\033[0m) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-10]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 11 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        # 这里只是占位，具体功能实现会在后续开发中添加
        case $choice in
            1|2|3|4|5|6|7|8|9|10) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "该功能尚未实现"
                    sleep 2
                else
                    dialog --title "提示" --msgbox "该功能尚未实现" 8 40
                fi
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
    done
}

# 显示资源管理菜单
show_resource_management_menu() {
    local title="资源管理"
    local menu_items=(
        "1" "查看端口占用状态 - 显示端口使用情况"
        "2" "修改虚拟内存大小 - 调整SWAP空间"
        "3" "系统时区调整 - 设置系统时区"
        "4" "硬盘分区管理工具 - 磁盘分区操作"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      资源管理                                        "
            echo "====================================================="
            echo ""
            echo "  1) 查看端口占用状态"
            echo "  2) 修改虚拟内存大小"
            echo "  3) 系统时区调整"
            echo "  4) 硬盘分区管理工具"
            echo ""
            echo "  \033[31m0\033[0m) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-4]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 5 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        # 这里只是占位，具体功能实现会在后续开发中添加
        case $choice in
            1|2|3|4) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "该功能尚未实现"
                    sleep 2
                else
                    dialog --title "提示" --msgbox "该功能尚未实现" 8 40
                fi
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
    done
}

# 显示用户管理菜单
show_user_management_menu() {
    local title="用户管理"
    local menu_items=(
        "1" "用户添加/删除/权限管理 - 系统用户管理"
        "2" "用户/密码生成器 - 创建安全的用户名和密码"
        "3" "ROOT私钥登录模式 - 配置SSH密钥认证"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      用户管理                                       "
            echo "====================================================="
            echo ""
            echo "  1) 用户添加/删除/权限管理"
            echo "  2) 用户/密码生成器"
            echo "  3) ROOT私钥登录模式"
            echo ""
            echo "  \033[31m0\033[0m) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-3]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 4 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        # 这里只是占位，具体功能实现会在后续开发中添加
        case $choice in
            1|2|3) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "该功能尚未实现"
                    sleep 2
                else
                    dialog --title "提示" --msgbox "该功能尚未实现" 8 40
                fi
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
    done
}

# 显示性能优化菜单
show_performance_optimization_menu() {
    local title="性能优化"
    local menu_items=(
        "1" "设置BBR3加速 - 启用TCP加速"
        "2" "红帽系Linux内核升级 - 升级系统内核"
        "3" "Linux系统内核参数优化 - 调整内核参数"
        "4" "一条龙系统调优 - 全面系统性能优化"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      性能优化                                       "
            echo "====================================================="
            echo ""
            echo "  1) 设置BBR3加速"
            echo "  2) 红帽系Linux内核升级"
            echo "  3) Linux系统内核参数优化"
            echo "  4) 一条龙系统调优"
            echo ""
            echo "  \033[31m0\033[0m) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-4]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 5 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        # 这里只是占位，具体功能实现会在后续开发中添加
        case $choice in
            1|2|3|4) 
                if [ "$USE_TEXT_MODE" = true ]; then
                    echo "该功能尚未实现"
                    sleep 2
                else
                    dialog --title "提示" --msgbox "该功能尚未实现" 8 40
                fi
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
    done
}

# 显示用户体验菜单
show_user_experience_menu() {
    local title="用户体验"
    local menu_items=(
        "1" "文件管理器 - 命令行文件管理工具"
        "2" "切换系统语言 - 更改系统显示语言"
        "3" "命令行美化工具 - 美化终端界面"
        "4" "设置系统回收站 - 启用命令行删除保护"
        "5" "命令行历史记录 - 管理命令历史"
        "0" "返回上级菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      用户体验                                       "
            echo "====================================================="
            echo ""
            echo "  1) 文件管理器"
            echo "  2) 切换系统语言"
            echo "  3) 命令行美化工具"
            echo "  4) 设置系统回收站"
            echo "  5) 命令行历史记录"
            echo ""
            echo "  \033[31m0\033[0m) 返回上级菜单"
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
    done
}

# 运行菜单
show_system_tools_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR"