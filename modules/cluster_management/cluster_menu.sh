#!/bin/bash

# 集群管理
# 此脚本提供集群管理相关功能的菜单界面

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

# 显示集群管理菜单
show_cluster_management_menu() {
    local title="集群管理"
    local menu_items=(
        "1" "服务器列表管理 - 添加/删除/编辑服务器"
        "2" "批量执行任务 - 批量管理服务器"
        "3" "集群备份与还原 - 集群数据备份管理"
        "0" "返回主菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      集群管理菜单                                    "
            echo "====================================================="
            echo ""
            echo "  1) 服务器列表管理          "
            echo "  2) 批量执行任务            "
            echo "  3) 集群备份与还原          "
            echo ""
            echo "  0) 返回主菜单"
            echo ""
            read -p "请选择操作 [0-3]: " choice
        else
            # 使用Dialog显示菜单
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" 15 60 4 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            # 检查是否按下ESC或Cancel
            local status=$?
            if [ $status -ne 0 ]; then
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) execute_module "cluster_management/server_list.sh" ;;
            2) execute_module "cluster_management/batch_tasks.sh" ;;
            3) execute_module "cluster_management/cluster_backup.sh" ;;
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
show_cluster_management_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 