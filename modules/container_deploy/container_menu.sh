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
        "20" "卸载Docker环境 - 彻底删除Docker及相关组件"
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
            echo "  "
            echo "  20) 卸载Docker环境"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-20]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 12 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1) execute_module "container_deploy/docker/docker_install.sh" ;;
            2) show_docker_status ;;
            3) show_docker_container_menu ;;
            4) show_docker_image_menu ;;
            5) show_docker_network_menu ;;
            6) show_docker_volume_menu ;;
            7) show_docker_prune_menu ;;
            8) execute_module "container_deploy/docker/docker_mirror.sh" ;;
            9) execute_module "container_deploy/docker/docker_edit_config.sh" ;;
            10) show_docker_ipv6_menu ;;
            20) execute_module "container_deploy/docker/docker_uninstall.sh" ;;
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

# 显示Docker状态
show_docker_status() {
    clear
    local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
    local image_count=$(docker images -q 2>/dev/null | wc -l)
    local network_count=$(docker network ls -q 2>/dev/null | wc -l)
    local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)
    
    local title="Docker全局状态"
    local content="Docker版本:\n"
    content+="$(docker -v)\n"
    content+="$(docker compose version)\n\n"
    
    content+="Docker镜像: $image_count\n"
    content+="$(docker image ls)\n\n"
    
    content+="Docker容器: $container_count\n"
    content+="$(docker ps -a)\n\n"
    
    content+="Docker卷: $volume_count\n"
    content+="$(docker volume ls)\n\n"
    
    content+="Docker网络: $network_count\n"
    content+="$(docker network ls)\n\n"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "$title" --msgbox "$content" $dialog_height $dialog_width
    fi
}

# Docker容器管理菜单
show_docker_container_menu() {
    local title="Docker容器管理"
    local menu_items=(
        "1" "查看所有容器 - 显示所有Docker容器"
        "2" "查看运行中容器 - 显示运行中的容器"
        "3" "启动容器 - 启动已停止的容器"
        "4" "停止容器 - 停止运行中的容器"
        "5" "重启容器 - 重启指定容器"
        "6" "删除容器 - 删除指定容器"
        "7" "容器日志 - 查看容器日志"
        "8" "容器终端 - 进入容器终端"
        "9" "容器详情 - 查看容器详细信息"
        "0" "返回上级菜单"
    )
    
    while true; do
        clear
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "====================================================="
            echo "      Docker容器管理                                 "
            echo "====================================================="
            echo ""
            echo "  1) 查看所有容器             6) 删除容器"
            echo "  2) 查看运行中容器           7) 容器日志"
            echo "  3) 启动容器                8) 容器终端"
            echo "  4) 停止容器                9) 容器详情"
            echo "  5) 重启容器                "
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
            1)
                clear
                echo "所有Docker容器:"
                docker ps -a
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            2)
                clear
                echo "运行中的Docker容器:"
                docker ps
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            3)
                clear
                echo "已停止的Docker容器:"
                docker ps -a --filter "status=exited"
                echo ""
                read -p "请输入要启动的容器ID或名称 (多个容器用空格分隔): " containers
                for container in $containers; do
                    docker start $container
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            4)
                clear
                echo "运行中的Docker容器:"
                docker ps
                echo ""
                read -p "请输入要停止的容器ID或名称 (多个容器用空格分隔): " containers
                for container in $containers; do
                    docker stop $container
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            5)
                clear
                echo "所有Docker容器:"
                docker ps -a
                echo ""
                read -p "请输入要重启的容器ID或名称 (多个容器用空格分隔): " containers
                for container in $containers; do
                    docker restart $container
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            6)
                clear
                echo "所有Docker容器:"
                docker ps -a
                echo ""
                read -p "请输入要删除的容器ID或名称 (多个容器用空格分隔): " containers
                read -p "是否强制删除容器? (y/n): " force
                if [ "$force" = "y" ] || [ "$force" = "Y" ]; then
                    for container in $containers; do
                        docker rm -f $container
                    done
                else
                    for container in $containers; do
                        docker rm $container
                    done
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            7)
                clear
                echo "运行中的Docker容器:"
                docker ps
                echo ""
                read -p "请输入要查看日志的容器ID或名称: " container
                read -p "要显示多少行日志? (默认50): " lines
                lines=${lines:-50}
                docker logs --tail $lines $container
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            8)
                clear
                echo "运行中的Docker容器:"
                docker ps
                echo ""
                read -p "请输入要进入的容器ID或名称: " container
                read -p "要运行的命令 (默认/bin/bash): " cmd
                cmd=${cmd:-/bin/bash}
                docker exec -it $container $cmd
                ;;
            9)
                clear
                echo "所有Docker容器:"
                docker ps -a
                echo ""
                read -p "请输入要查看详情的容器ID或名称: " container
                docker inspect $container
                echo ""
                read -p "按Enter键继续..." confirm
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

# Docker镜像管理菜单
show_docker_image_menu() {
    local title="Docker镜像管理"
    local menu_items=(
        "1" "查看所有镜像 - 显示所有Docker镜像"
        "2" "拉取镜像 - 从镜像仓库拉取镜像"
        "3" "删除镜像 - 删除指定镜像"
        "4" "删除未使用镜像 - 清理无标签和未使用镜像"
        "5" "镜像详情 - 查看镜像详细信息"
        "0" "返回上级菜单"
    )
    
    while true; do
        clear
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "====================================================="
            echo "      Docker镜像管理                                 "
            echo "====================================================="
            echo ""
            echo "  1) 查看所有镜像"
            echo "  2) 拉取镜像"
            echo "  3) 删除镜像"
            echo "  4) 删除未使用镜像"
            echo "  5) 镜像详情"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-5]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 6 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1)
                clear
                echo "所有Docker镜像:"
                docker images
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            2)
                clear
                read -p "请输入要拉取的镜像名称(格式: 名称:标签): " image
                docker pull $image
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            3)
                clear
                echo "所有Docker镜像:"
                docker images
                echo ""
                read -p "请输入要删除的镜像ID或名称 (多个镜像用空格分隔): " images
                for image in $images; do
                    docker rmi $image
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            4)
                clear
                read -p "确定要删除所有未使用的镜像吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker image prune -a
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            5)
                clear
                echo "所有Docker镜像:"
                docker images
                echo ""
                read -p "请输入要查看详情的镜像ID或名称: " image
                docker inspect $image
                echo ""
                read -p "按Enter键继续..." confirm
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

# Docker网络管理菜单
show_docker_network_menu() {
    local title="Docker网络管理"
    local menu_items=(
        "1" "查看所有网络 - 显示所有Docker网络"
        "2" "查看容器网络信息 - 显示容器网络配置"
        "3" "创建网络 - 创建新的Docker网络"
        "4" "删除网络 - 删除指定网络"
        "5" "容器加入网络 - 将容器加入指定网络"
        "6" "容器退出网络 - 将容器从指定网络移除"
        "0" "返回上级菜单"
    )
    
    while true; do
        clear
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "====================================================="
            echo "      Docker网络管理                                 "
            echo "====================================================="
            echo ""
            echo "  1) 查看所有网络"
            echo "  2) 查看容器网络信息"
            echo "  3) 创建网络"
            echo "  4) 删除网络"
            echo "  5) 容器加入网络"
            echo "  6) 容器退出网络"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-6]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 7 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1)
                clear
                echo "所有Docker网络:"
                docker network ls
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            2)
                clear
                echo "容器网络信息:"
                echo "----------------------------------------"
                container_ids=$(docker ps -q)
                printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"
                echo "----------------------------------------"
                for container_id in $container_ids; do
                    container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")
                    container_name=$(echo "$container_info" | awk '{print $1}')
                    network_info=$(echo "$container_info" | cut -d' ' -f2-)
                    while IFS= read -r line; do
                        network_name=$(echo "$line" | awk '{print $1}')
                        ip_address=$(echo "$line" | awk '{print $2}')
                        printf "%-25s %-25s %-25s\n" "$container_name" "$network_name" "$ip_address"
                    done <<< "$network_info"
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            3)
                clear
                read -p "请输入要创建的网络名称: " network
                docker network create $network
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            4)
                clear
                echo "所有Docker网络:"
                docker network ls
                echo ""
                read -p "请输入要删除的网络名称: " network
                docker network rm $network
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            5)
                clear
                echo "所有Docker网络:"
                docker network ls
                echo ""
                read -p "请输入要加入的网络名称: " network
                echo ""
                echo "所有Docker容器:"
                docker ps -a
                echo ""
                read -p "请输入要加入网络的容器名称 (多个容器用空格分隔): " containers
                for container in $containers; do
                    docker network connect $network $container
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            6)
                clear
                echo "所有Docker网络:"
                docker network ls
                echo ""
                read -p "请输入要退出的网络名称: " network
                echo ""
                echo "所有Docker容器:"
                docker ps -a
                echo ""
                read -p "请输入要退出网络的容器名称 (多个容器用空格分隔): " containers
                for container in $containers; do
                    docker network disconnect $network $container
                done
                echo ""
                read -p "按Enter键继续..." confirm
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

# Docker卷管理菜单
show_docker_volume_menu() {
    local title="Docker卷管理"
    local menu_items=(
        "1" "查看所有卷 - 显示所有Docker卷"
        "2" "创建卷 - 创建新的Docker卷"
        "3" "删除卷 - 删除指定卷"
        "4" "删除未使用卷 - 清理所有未使用的卷"
        "5" "卷详情 - 查看卷的详细信息"
        "0" "返回上级菜单"
    )
    
    while true; do
        clear
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "====================================================="
            echo "      Docker卷管理                                   "
            echo "====================================================="
            echo ""
            echo "  1) 查看所有卷"
            echo "  2) 创建卷"
            echo "  3) 删除卷"
            echo "  4) 删除未使用卷"
            echo "  5) 卷详情"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-5]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 6 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1)
                clear
                echo "所有Docker卷:"
                docker volume ls
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            2)
                clear
                read -p "请输入要创建的卷名称: " volume
                docker volume create $volume
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            3)
                clear
                echo "所有Docker卷:"
                docker volume ls
                echo ""
                read -p "请输入要删除的卷名称 (多个卷用空格分隔): " volumes
                for volume in $volumes; do
                    docker volume rm $volume
                done
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            4)
                clear
                read -p "确定要删除所有未使用的卷吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker volume prune -f
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            5)
                clear
                echo "所有Docker卷:"
                docker volume ls
                echo ""
                read -p "请输入要查看详情的卷名称: " volume
                docker volume inspect $volume
                echo ""
                read -p "按Enter键继续..." confirm
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

# Docker清理菜单
show_docker_prune_menu() {
    local title="Docker清理"
    local menu_items=(
        "1" "清理所有资源 - 清理容器、镜像、网络和卷"
        "2" "清理未使用镜像 - 删除未使用的镜像"
        "3" "清理未使用容器 - 删除停止的容器"
        "4" "清理未使用网络 - 删除未使用的网络"
        "5" "清理未使用卷 - 删除未使用的卷"
        "0" "返回上级菜单"
    )
    
    while true; do
        clear
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "====================================================="
            echo "      Docker清理                                     "
            echo "====================================================="
            echo ""
            echo "  1) 清理所有资源"
            echo "  2) 清理未使用镜像"
            echo "  3) 清理未使用容器"
            echo "  4) 清理未使用网络"
            echo "  5) 清理未使用卷"
            echo ""
            echo "  0) 返回上级菜单"
            echo ""
            read -p "请选择操作 [0-5]: " choice
        else
            # 获取对话框尺寸
            read dialog_height dialog_width <<< $(get_dialog_size)
            
            choice=$(dialog --clear --title "$title" \
                --menu "请选择一个选项:" $dialog_height $dialog_width 6 \
                "${menu_items[@]}" 2>&1 >/dev/tty)
            
            local status=$?
            if [ $status -ne 0 ]; then
                return
            fi
        fi
        
        case $choice in
            1)
                clear
                read -p "警告: 这将删除所有未使用的容器、镜像、网络和卷。确定要继续吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker system prune -af --volumes
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            2)
                clear
                read -p "确定要删除所有未使用的镜像吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker image prune -af
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            3)
                clear
                read -p "确定要删除所有停止的容器吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker container prune -f
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            4)
                clear
                read -p "确定要删除所有未使用的网络吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker network prune -f
                fi
                echo ""
                read -p "按Enter键继续..." confirm
                ;;
            5)
                clear
                read -p "确定要删除所有未使用的卷吗? (y/n): " confirm
                if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
                    docker volume prune -f
                fi
                echo ""
                read -p "按Enter键继续..." confirm
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

# Docker IPv6菜单
show_docker_ipv6_menu() {
    local title="Docker IPv6管理"
    local menu_items=(
        "1" "开启Docker IPv6 - 启用Docker容器IPv6支持"
        "2" "关闭Docker IPv6 - 禁用Docker容器IPv6支持"
        "3" "查看IPv6状态 - 检查当前IPv6配置"
        "0" "返回上级菜单"
    )
    
    while true; do
        clear
        if [ "$USE_TEXT_MODE" = true ]; then
            echo "====================================================="
            echo "      Docker IPv6管理                                "
            echo "====================================================="
            echo ""
            echo "  1) 开启Docker IPv6"
            echo "  2) 关闭Docker IPv6"
            echo "  3) 查看IPv6状态"
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
            1)
                execute_module "container_deploy/docker/docker_ipv6_enable.sh"
                ;;
            2)
                execute_module "container_deploy/docker/docker_ipv6_disable.sh"
                ;;
            3)
                clear
                echo "Docker IPv6 配置状态:"
                cat /etc/docker/daemon.json 2>/dev/null | grep -i ipv6
                if [ $? -ne 0 ]; then
                    echo "未找到IPv6相关配置或daemon.json文件不存在"
                fi
                echo ""
                read -p "按Enter键继续..." confirm
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

# 编辑Docker配置
edit_docker_config() {
    clear
    if [ ! -f /etc/docker/daemon.json ]; then
        mkdir -p /etc/docker
        echo "{}" > /etc/docker/daemon.json
    fi
    
    if command -v nano >/dev/null 2>&1; then
        nano /etc/docker/daemon.json
    else
        vim /etc/docker/daemon.json
    fi
    
    read -p "是否重启Docker服务应用更改? (y/n): " restart
    if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
        systemctl restart docker
        echo "Docker服务已重启"
    fi
    
    echo ""
    read -p "按Enter键继续..." confirm
}

# 卸载Docker
uninstall_docker() {
    clear
    local title="卸载Docker环境"
    local message="警告: 这将删除所有容器、镜像和Docker相关组件。\n此操作无法撤销!\n\n确定要卸载Docker环境吗?"
    
    local confirm
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$message"
        read -p "确认卸载? (y/n): " confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        
        dialog --title "$title" --yesno "$message" 10 60
        local status=$?
        if [ $status -eq 0 ]; then
            confirm="y"
        else
            confirm="n"
        fi
    fi
    
    if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
        echo "正在停止所有Docker容器..."
        docker ps -a -q | xargs -r docker stop
        
        echo "正在删除所有Docker容器..."
        docker ps -a -q | xargs -r docker rm -f
        
        echo "正在删除所有Docker镜像..."
        docker images -q | xargs -r docker rmi -f
        
        echo "正在删除Docker网络..."
        docker network prune -f
        
        echo "正在删除Docker卷..."
        docker volume prune -f
        
        echo "正在卸载Docker软件包..."
        if command -v apt >/dev/null 2>&1; then
            apt purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
        elif command -v yum >/dev/null 2>&1; then
            yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
        elif command -v dnf >/dev/null 2>&1; then
            dnf remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose
        fi
        
        echo "正在删除Docker配置文件和数据..."
        rm -rf /var/lib/docker
        rm -rf /var/lib/containerd
        rm -rf /etc/docker
        
        echo "Docker卸载完成"
    else
        echo "卸载操作已取消"
    fi
    
    echo ""
    read -p "按Enter键继续..." confirm
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
            1) show_ldnmp_environment_menu ;;
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

# LDNMP环境安装与管理菜单
show_ldnmp_environment_menu() {
    local title="LDNMP环境安装与管理"
    local menu_items=(
        "1" "LDNMP环境安装 - 安装LNMP基础环境"
        "2" "环境配置管理 - 管理已安装环境配置"
        "3" "环境状态查看 - 查看环境运行状态"
        "4" "PHP版本管理 - 安装/切换PHP版本"
        "5" "Mysql管理 - 管理数据库账号和权限"
        "6" "Nginx管理 - 修改Nginx配置"
        "7" "环境迁移工具 - 迁移环境到其他服务器"
        "8" "更新环境组件 - 更新已安装的环境组件"
        "9" "环境清理工具 - 清理环境缓存和文件"
        "0" "返回上级菜单"
    )
    
    while true; do
        if [ "$USE_TEXT_MODE" = true ]; then
            clear
            echo "====================================================="
            echo "      LDNMP环境安装与管理                             "
            echo "====================================================="
            echo ""
            echo "  1) LDNMP环境安装            6) Nginx管理"
            echo "  2) 环境配置管理             7) 环境迁移工具"
            echo "  3) 环境状态查看             8) 更新环境组件"
            echo "  4) PHP版本管理              9) 环境清理工具"
            echo "  5) Mysql管理"
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
            1) execute_module "container_deploy/ldnmp_install.sh" ;;
            2) execute_module "container_deploy/ldnmp_config_management.sh" ;;
            3) show_ldnmp_status ;;
            4) execute_module "container_deploy/ldnmp_php_management.sh" ;;
            5) execute_module "container_deploy/ldnmp_mysql_management.sh" ;;
            6) execute_module "container_deploy/ldnmp_nginx_management.sh" ;;
            7) execute_module "container_deploy/ldnmp_migration.sh" ;;
            8) execute_module "container_deploy/ldnmp_update.sh" ;;
            9) execute_module "container_deploy/ldnmp_cleanup.sh" ;;
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

# 显示LDNMP环境状态
show_ldnmp_status() {
    clear
    local title="LDNMP环境状态"
    
    # 获取容器状态
    local nginx_status=$(docker ps --format "{{.Names}} {{.Status}}" | grep -E "nginx|openresty" | awk '{print $2}')
    local php_status=$(docker ps --format "{{.Names}} {{.Status}}" | grep -E "php" | awk '{print $2}')
    local mysql_status=$(docker ps --format "{{.Names}} {{.Status}}" | grep -E "mysql|mariadb" | awk '{print $2}')
    local redis_status=$(docker ps --format "{{.Names}} {{.Status}}" | grep -E "redis" | awk '{print $2}')
    
    # 获取容器版本
    local nginx_version=$(docker exec $(docker ps -q --filter name=nginx) nginx -v 2>&1 | grep -oE "[0-9]+\.[0-9]+\.[0-9]+" || echo "未运行")
    local php_version=$(docker exec $(docker ps -q --filter name=php) php -v 2>&1 | grep -oE "^PHP [0-9]+\.[0-9]+\.[0-9]+" || echo "未运行")
    local mysql_version=$(docker exec $(docker ps -q --filter name=mysql) mysql -V 2>&1 | grep -oE "Distrib [0-9]+\.[0-9]+\.[0-9]+" || echo "未运行")
    local redis_version=$(docker exec $(docker ps -q --filter name=redis) redis-server -v 2>&1 | grep -oE "v=[0-9]+\.[0-9]+\.[0-9]+" || echo "未运行")
    
    # 获取站点数量
    local sites_count=$(find /var/www/ -maxdepth 1 -type d | wc -l)
    sites_count=$((sites_count-1)) # 减去/var/www/本身
    
    # 获取网络端口使用情况
    local port_80=$(netstat -tuln | grep -w ":80" || echo "未使用")
    local port_443=$(netstat -tuln | grep -w ":443" || echo "未使用")
    local port_3306=$(netstat -tuln | grep -w ":3306" || echo "未使用")
    
    # 获取系统信息
    local disk_usage=$(df -h /var/www/ | awk 'NR==2 {print $5 " 已用, 剩余 " $4}')
    local mem_usage=$(free -h | awk '/^Mem:/ {print $3 " 已用, 剩余 " $7 " (总计 " $2 ")"}')
    
    # 准备显示内容
    local content="LDNMP环境状态概览:\n\n"
    content+="容器状态:\n"
    content+="Nginx: ${nginx_status:-未运行} (版本: ${nginx_version})\n"
    content+="PHP: ${php_status:-未运行} (版本: ${php_version})\n"
    content+="MySQL: ${mysql_status:-未运行} (版本: ${mysql_version})\n"
    content+="Redis: ${redis_status:-未运行} (版本: ${redis_version})\n\n"
    
    content+="站点信息:\n"
    content+="当前部署站点数量: $sites_count\n\n"
    
    content+="网络端口情况:\n"
    content+="端口 80 (HTTP): ${port_80}\n"
    content+="端口 443 (HTTPS): ${port_443}\n"
    content+="端口 3306 (MySQL): ${port_3306}\n\n"
    
    content+="资源使用情况:\n"
    content+="磁盘使用率: $disk_usage\n"
    content+="内存使用率: $mem_usage\n\n"
    
    content+="Docker容器列表:\n"
    content+="$(docker ps --format "表: {{.Names}} | 状态: {{.Status}} | 镜像: {{.Image}}")\n"
    
    if [ "$USE_TEXT_MODE" = true ]; then
        echo -e "$content"
        echo ""
        read -p "按Enter键继续..." confirm
    else
        # 获取对话框尺寸
        read dialog_height dialog_width <<< $(get_dialog_size)
        dialog --title "$title" --msgbox "$content" $dialog_height $dialog_width
    fi
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