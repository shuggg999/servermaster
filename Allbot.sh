#!/bin/bash

while true; do
    clear  # 清空屏幕
    echo -e "\033[1;36m"  # 设置青色文字
    echo "=============================="
    echo "      多功能命令行工具        "
    echo "=============================="
    echo -e "\033[0m"  # 重置颜色
    echo "1) 显示系统信息"
    echo "2) 列出大文件（前10）"
    echo "3) 检查磁盘空间"
    echo "4) 查看内存使用"
    echo "5) 查看网络连接"
    echo "6) 更新系统"
    echo "7) 安装常用工具"
    echo "8) 生成随机密码"
    echo "0) 退出"
    echo "=============================="
    read -p "请输入选项数字: " choice

    case $choice in
        1)
            echo -e "\n\033[1;32m系统信息：\033[0m"
            neofetch || echo "需要安装 neofetch (sudo apt install neofetch)"
            ;;
        2)
            echo -e "\n\033[1;32m当前目录大文件TOP10：\033[0m"
            du -ah . | sort -rh | head -n 10
            ;;
        3)
            echo -e "\n\033[1;32m磁盘使用情况：\033[0m"
            df -h
            ;;
        4)
            echo -e "\n\033[1;32m内存使用情况：\033[0m"
            free -h
            ;;
        5)
            echo -e "\n\033[1;32m活跃网络连接：\033[0m"
            netstat -tulpn
            ;;
        6)
            echo -e "\n\033[1;33m开始系统更新...\033[0m"
            sudo apt update && sudo apt upgrade -y
            ;;
        7)
            echo -e "\n\033[1;33m安装常用工具...\033[0m"
            sudo apt install -y htop tmux git curl wget tree
            ;;
        8)
            echo -e "\n\033[1;32m生成随机密码：\033[0m"
            openssl rand -base64 12
            ;;
        0)
            echo -e "\n\033[1;31m退出程序...\033[0m"
            exit 0
            ;;
        *)
            echo -e "\n\033[1;31m无效输入，请重新选择！\033[0m"
            ;;
    esac
    
    # 等待用户确认
    echo -e "\n按回车键继续..."
    read
done
