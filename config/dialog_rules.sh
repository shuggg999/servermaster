#!/bin/bash

# ServerMaster Dialog规则
# 本文件定义了所有模块共享的Dialog显示规则

# 定义窗口大小限制
DIALOG_MAX_HEIGHT=40
DIALOG_MAX_WIDTH=140

# 定义常用对话框尺寸
SMALL_DIALOG_HEIGHT=5
SMALL_DIALOG_WIDTH=40
INFO_DIALOG_HEIGHT=10
INFO_DIALOG_WIDTH=50
PROMPT_DIALOG_HEIGHT=10
PROMPT_DIALOG_WIDTH=50
ERROR_DIALOG_HEIGHT=10
ERROR_DIALOG_WIDTH=50

# 获取正确的dialog尺寸
get_dialog_size() {
    # 获取终端大小
    local term_lines=$(tput lines 2>/dev/null || echo 24)
    local term_cols=$(tput cols 2>/dev/null || echo 80)
    
    # 计算dialog窗口大小 (使用终端的85%)
    local dialog_height=$((term_lines * 85 / 100))
    local dialog_width=$((term_cols * 85 / 100))
    
    # 确保不超过最大值
    [ "$dialog_height" -gt "$DIALOG_MAX_HEIGHT" ] && dialog_height=$DIALOG_MAX_HEIGHT
    [ "$dialog_width" -gt "$DIALOG_MAX_WIDTH" ] && dialog_width=$DIALOG_MAX_WIDTH
    
    # 确保最小值
    [ "$dialog_height" -lt 20 ] && dialog_height=20
    [ "$dialog_width" -lt 70 ] && dialog_width=70
    
    echo "$dialog_height $dialog_width"
}

# 显示信息对话框
show_info_dialog() {
    local title="$1"
    local message="$2"
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    dialog --title "$title" --msgbox "$message" $INFO_DIALOG_HEIGHT $INFO_DIALOG_WIDTH
}

# 显示确认对话框
show_confirm_dialog() {
    local title="$1"
    local message="$2"
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    dialog --title "$title" --yesno "$message" $PROMPT_DIALOG_HEIGHT $PROMPT_DIALOG_WIDTH
    return $?
}

# 显示错误对话框
show_error_dialog() {
    local title="$1"
    local message="$2"
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    dialog --title "$title" --msgbox "$message" $ERROR_DIALOG_HEIGHT $ERROR_DIALOG_WIDTH
}

# 显示进度信息
show_progress_dialog() {
    local title="$1"
    local message="$2"
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    dialog --title "$title" --infobox "$message" $SMALL_DIALOG_HEIGHT $SMALL_DIALOG_WIDTH
}

# 显示菜单对话框
show_menu_dialog() {
    local title="$1"
    local prompt="$2"
    local menu_height="$3"
    shift 3
    local menu_items=("$@")
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    # 创建临时文件存储选择结果
    local temp_file=$(mktemp)
    
    # 显示菜单
    dialog --clear --title "$title" \
           --menu "$prompt" $dialog_height $dialog_width $menu_height \
           "${menu_items[@]}" 2> "$temp_file"
    
    # 获取退出状态
    local status=$?
    
    # 读取用户选择
    local choice=""
    if [ -f "$temp_file" ]; then
        choice=$(<"$temp_file")
        rm -f "$temp_file"
    fi
    
    # 返回选择和状态
    echo "$choice|$status"
}

# 显示输入框
show_input_dialog() {
    local title="$1"
    local prompt="$2"
    local default_value="$3"
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    # 创建临时文件存储选择结果
    local temp_file=$(mktemp)
    
    # 显示输入框
    dialog --title "$title" \
           --inputbox "$prompt" $PROMPT_DIALOG_HEIGHT $PROMPT_DIALOG_WIDTH "$default_value" 2> "$temp_file"
    
    # 获取退出状态
    local status=$?
    
    # 读取用户输入
    local input=""
    if [ -f "$temp_file" ]; then
        input=$(<"$temp_file")
        rm -f "$temp_file"
    fi
    
    # 返回输入和状态
    echo "$input|$status"
}

# 显示文本编辑框
show_editor_dialog() {
    local title="$1"
    local file="$2"
    
    # 获取窗口大小
    read dialog_height dialog_width <<< $(get_dialog_size)
    
    # 显示编辑器
    dialog --title "$title" \
           --editbox "$file" $dialog_height $dialog_width
    
    return $?
} 