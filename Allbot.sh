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
            if ! command -v neofetch &>/dev/null; then
                echo "需要安装 neofetch (sudo apt install neofetch)"
            else
                neofetch
            fi
            ;;
        0)
            echo -e "\n\033[1;31m退出程序...\033[0m"
            exit 0
            ;;
        # 其他选项保持不变...
        *)
            echo -e "\n\033[1;31m无效输入，请重新选择！\033[0m"
            ;;
    esac

    read -p "按回车键继续..." </dev/tty
done
