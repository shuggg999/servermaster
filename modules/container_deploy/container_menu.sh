#!/bin/bash

# 容器与应用部署
# 此脚本提供容器与应用部署相关功能的菜单界面

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

# 显示容器与应用部署菜单
show_container_deploy_menu() {
    local title="容器与应用部署"
    local menu_items=(
        "1" "Docker管理 - 安装与管理Docker环境"
        "2" "LDNMP建站 - 网站环境与应用部署"
        "3" "应用市场 - 各类应用一键部署"
        "0" "返回主菜单"
    )
    
    while true; do
        # 确保我们在正确的目录
        cd "$INSTALL_DIR"
        
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      容器与应用部署菜单                               "
            echo "====================================================="
            echo ""
            echo "  1) Docker管理              "
            echo "  2) LDNMP建站               "
            echo "  3) 应用市场                "
            echo ""
            echo "  0) 返回主菜单"
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
                cd "$CURRENT_DIR"  # 恢复原始目录
                return
            fi
        fi
        
        case $choice in
            1) show_docker_management_menu ;;
            2) show_ldnmp_website_menu ;;
            3) show_app_market_menu ;;
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

# Docker管理菜单
show_docker_management_menu() {
    local title="Docker管理"
    local menu_items=(
        "1" "Docker环境安装/更新 - 安装或更新Docker引擎"
        "2" "Docker全局状态查看 - 查看Docker系统状态"
        "3" "Docker容器管理 - 管理运行中的容器"
        "4" "Docker镜像管理 - 管理本地Docker镜像"
        "5" "Docker网络管理 - 管理Docker网络配置"
        "6" "Docker卷管理 - 管理Docker存储卷"
        "7" "Docker清理 - 清理未使用的资源"
        "8" "Docker源切换 - 更改Docker镜像源"
        "9" "Docker配置编辑 - 编辑Docker配置文件"
        "10" "Docker IPv6管理 - 配置Docker IPv6支持"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      Docker管理                                     "
            echo "====================================================="
            echo ""
            echo "  1) Docker环境安装/更新        6) Docker卷管理"
            echo "  2) Docker全局状态查看        7) Docker清理"
            echo "  3) Docker容器管理           8) Docker源切换"
            echo "  4) Docker镜像管理           9) Docker配置编辑"
            echo "  5) Docker网络管理           10) Docker IPv6管理"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-10]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 11 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "container_deploy/docker_install.sh" ;;
            2) execute_module "container_deploy/docker_status.sh" ;;
            3) execute_module "container_deploy/docker_container.sh" ;;
            4) execute_module "container_deploy/docker_image.sh" ;;
            5) execute_module "container_deploy/docker_network.sh" ;;
            6) execute_module "container_deploy/docker_volume.sh" ;;
            7) execute_module "container_deploy/docker_clean.sh" ;;
            8) execute_module "container_deploy/docker_mirror.sh" ;;
            9) execute_module "container_deploy/docker_config.sh" ;;
            10) execute_module "container_deploy/docker_ipv6.sh" ;;
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

# LDNMP建站菜单
show_ldnmp_website_menu() {
    local title="LDNMP建站"
    local menu_items=(
        "1" "环境安装与管理 - 安装/配置LDNMP环境"
        "2" "应用部署 - 部署各类网站应用"
        "3" "站点数据管理 - 备份/还原站点数据"
        "4" "环境优化与保护 - 优化性能与安全"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      LDNMP建站                                      "
            echo "====================================================="
            echo ""
            echo "  1) 环境安装与管理"
            echo "  2) 应用部署"
            echo "  3) 站点数据管理"
            echo "  4) 环境优化与保护"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-4]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 5 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "container_deploy/ldnmp_install.sh" ;;
            2) show_ldnmp_application_menu ;;
            3) show_ldnmp_data_management_menu ;;
            4) execute_module "container_deploy/ldnmp_optimize.sh" ;;
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

# LDNMP应用部署菜单
show_ldnmp_application_menu() {
    local title="LDNMP应用部署"
    local menu_items=(
        "1" "WordPress - 部署WordPress博客/网站"
        "2" "Discuz论坛 - 部署Discuz论坛网站"
        "3" "可道云桌面 - 部署可道云网盘程序"
        "4" "苹果CMS影视站 - 部署影视网站"
        "5" "独角数发卡网 - 部署自动发卡网站"
        "6" "flarum论坛网站 - 部署现代轻论坛"
        "7" "typecho轻量博客 - 部署typecho博客"
        "8" "LinkStack共享链接平台 - 部署链接共享平台"
        "9" "自定义动态/静态站点 - 部署自定义网站"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      LDNMP应用部署                                  "
            echo "====================================================="
            echo ""
            echo "  1) WordPress               6) flarum论坛网站"
            echo "  2) Discuz论坛              7) typecho轻量博客"
            echo "  3) 可道云桌面              8) LinkStack共享链接平台"
            echo "  4) 苹果CMS影视站           9) 自定义动态/静态站点"
            echo "  5) 独角数发卡网"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-9]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 10 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "container_deploy/ldnmp_wordpress.sh" ;;
            2) execute_module "container_deploy/ldnmp_discuz.sh" ;;
            3) execute_module "container_deploy/ldnmp_kodcloud.sh" ;;
            4) execute_module "container_deploy/ldnmp_maccms.sh" ;;
            5) execute_module "container_deploy/ldnmp_dujiaoka.sh" ;;
            6) execute_module "container_deploy/ldnmp_flarum.sh" ;;
            7) execute_module "container_deploy/ldnmp_typecho.sh" ;;
            8) execute_module "container_deploy/ldnmp_linkstack.sh" ;;
            9) execute_module "container_deploy/ldnmp_custom.sh" ;;
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

# LDNMP站点数据管理菜单
show_ldnmp_data_management_menu() {
    local title="LDNMP站点数据管理"
    local menu_items=(
        "1" "备份全站数据 - 备份网站和数据库"
        "2" "定时远程备份 - 设置自动备份任务"
        "3" "还原全站数据 - 从备份恢复数据"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      LDNMP站点数据管理                               "
            echo "====================================================="
            echo ""
            echo "  1) 备份全站数据"
            echo "  2) 定时远程备份"
            echo "  3) 还原全站数据"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-3]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 4 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "container_deploy/ldnmp_backup.sh" ;;
            2) execute_module "container_deploy/ldnmp_auto_backup.sh" ;;
            3) execute_module "container_deploy/ldnmp_restore.sh" ;;
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

# 应用市场菜单
show_app_market_menu() {
    local title="应用市场"
    local menu_items=(
        "1" "服务器面板类 - 各类服务器管理面板"
        "2" "文件存储类 - 网盘与文件存储系统"
        "3" "远程访问类 - 远程桌面与访问工具"
        "4" "监控工具类 - 服务器监控工具"
        "5" "下载工具类 - 各类下载应用"
        "6" "邮件服务类 - 邮件服务器程序"
        "7" "即时通讯类 - 聊天与通讯工具"
        "8" "项目管理类 - 项目管理与任务工具"
        "9" "多媒体类 - 媒体管理与处理系统"
        "10" "速度测试类 - 网络测速工具"
        "11" "安全工具类 - 网络安全与防护工具"
        "12" "办公协作类 - 在线办公与协作工具"
        "13" "容器管理类 - 容器管理工具"
        "14" "网站功能类 - 各类实用网站工具"
        "15" "AI工具类 - AI相关应用工具"
        "16" "安全防护类 - 安全与监控防护工具"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      应用市场                                       "
            echo "====================================================="
            echo ""
            echo "  1) 服务器面板类              9) 多媒体类"
            echo "  2) 文件存储类                10) 速度测试类"
            echo "  3) 远程访问类                11) 安全工具类"
            echo "  4) 监控工具类                12) 办公协作类"
            echo "  5) 下载工具类                13) 容器管理类"
            echo "  6) 邮件服务类                14) 网站功能类"
            echo "  7) 即时通讯类                15) AI工具类"
            echo "  8) 项目管理类                16) 安全防护类"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-16]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 17 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) show_server_panel_apps_menu ;;
            2) show_file_storage_apps_menu ;;
            3) show_remote_access_apps_menu ;;
            4) show_monitoring_apps_menu ;;
            5) show_download_apps_menu ;;
            6) show_mail_apps_menu ;;
            7) show_communication_apps_menu ;;
            8) show_project_management_apps_menu ;;
            9) show_multimedia_apps_menu ;;
            10) show_speed_test_apps_menu ;;
            11) show_security_apps_menu ;;
            12) show_office_apps_menu ;;
            13) show_container_apps_menu ;;
            14) show_website_apps_menu ;;
            15) show_ai_apps_menu ;;
            16) show_security_protection_apps_menu ;;
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

# 服务器面板类菜单
show_server_panel_apps_menu() {
    local title="服务器面板类应用"
    local menu_items=(
        "1" "宝塔面板官方版 - 最流行的服务器管理面板"
        "2" "aaPanel宝塔国际版 - 宝塔面板国际版"
        "3" "1Panel新一代管理面板 - 新一代服务器管理面板"
        "4" "NginxProxyManager可视化面板 - Nginx反向代理管理工具"
        "0" "返回上级菜单"
    )
    
    show_app_submenu "$title" "${menu_items[@]}"
}

# 文件存储类菜单
show_file_storage_apps_menu() {
    local title="文件存储类应用"
    local menu_items=(
        "1" "AList多存储文件列表程序 - 多存储聚合工具"
        "2" "Cloudreve网盘 - 支持多家云存储的网盘系统"
        "3" "简单图床图片管理程序 - 图片上传与管理工具"
        "4" "Nextcloud网盘 - 功能全面的私有云盘"
        "0" "返回上级菜单"
    )
    
    show_app_submenu "$title" "${menu_items[@]}"
}

# 通用的应用子菜单显示函数
show_app_submenu() {
    local title="$1"
    shift
    local menu_items=("$@")
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      $title                                       "
            echo "====================================================="
            echo ""
            
            # 动态显示菜单项
            local i=1
            while [ $i -lt ${#menu_items[@]} ]; do
                if [ "${menu_items[$i]}" = "0" ]; then
                    break
                fi
                echo "  ${menu_items[$i]}) ${menu_items[$((i+1))]}"
                i=$((i+2))
            done
            
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-$((i/2))]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width $((${#menu_items[@]}/2)) \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        if [ "$choice" = "0" ]; then
            return
        elif [ -n "$choice" ] && [ "$choice" -ge 1 ] && [ "$choice" -le $((${#menu_items[@]}/2-1)) ]; then
            # 提取应用名称，用于构建模块路径
            local app_name=$(echo "${menu_items[$((choice*2-1))]}" | cut -d' ' -f1 | tr '[:upper:]' '[:lower:]')
            execute_module "container_deploy/apps/${app_name}.sh"
        else
            if [ "$USE_TEXT_MODE" = true ]; then
                echo "无效选择，请重试"
                sleep 1
            else
                dialog --title "错误" --msgbox "无效选项: $choice\n请重新选择" 8 40
            fi
        fi
    done
}

# 运行菜单
show_container_deploy_menu

# 确保在脚本结束时恢复原始目录
cd "$CURRENT_DIR" 