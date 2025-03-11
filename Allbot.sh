#!/bin/bash

# 确保从终端读取输入
[ -t 0 ] || exec </dev/tty

trap "echo -e '\n\033[1;31m用户中断退出...\033[0m'; exit 1" SIGINT

while true; do
    clear
    echo -e "\033[1;36m==============================\n      多功能命令行工具\n==============================\033[0m"
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
    read -p "请输入选项数字: " choice </dev/tty

    case "$choice" in
        1)
            echo -e "\n\033[1;32m系统信息：\033[0m"
            if command -v neofetch &>/dev/null; then
                neofetch
            else
                echo "需要安装 neofetch (执行: sudo apt install neofetch)"
            fi
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
            ss -tulpn || netstat -tulpn
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

    read -p "按回车键继续..." </dev/tty
done
