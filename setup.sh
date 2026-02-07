#!/bin/bash
# Apache_HW Project Setup Script
# 自动设置项目环境变量

# ============================================
# 自动检测项目根目录
# ============================================
set -e

# 获取当前脚本所在目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export APACHE_HW_ROOT="$SCRIPT_DIR"

# 尝试自动检测项目目录（向上查找特征文件）
detect_project_root() {
    local current_dir="$(pwd)"
    local max_depth=5
    local depth=0
    
    while [ $depth -lt $max_depth ]; do
        if [ -f "$current_dir/README.md" ] && [ -d "$current_dir/flist" ]; then
            echo "$current_dir"
            return 0
        fi
        current_dir="$(dirname "$current_dir")"
        depth=$((depth + 1))
    done
    
    # 如果没找到，使用脚本所在目录
    echo "$SCRIPT_DIR"
}

# 如果环境变量未设置，则自动检测
if [ -z "$APACHE_HW_ROOT" ]; then
    APACHE_HW_ROOT="$(detect_project_root)"
fi

export APACHE_HW_ROOT

# ============================================
# 设置其他常用环境变量
# ============================================
export APACHE_HW_DESIGN="$APACHE_HW_ROOT/design"
export APACHE_HW_FLIST="$APACHE_HW_ROOT/flist"
export APACHE_HW_ESL="$APACHE_HW_DESIGN/pe_core/esl"
export APACHE_HW_SIM="$APACHE_HW_DESIGN/pe_core/sim"
export APACHE_HW_RTL="$APACHE_HW_DESIGN/pe_core/rtl"

# ============================================
# 更新 flist 文件使用相对路径
# ============================================
update_flist_relative() {
    local flist_file="$APACHE_HW_FLIST/pe_top_design.f"
    
    if [ ! -f "$flist_file" ]; then
        echo "Warning: flist file not found: $flist_file"
        return 1
    fi
    
    # 先备份绝对路径版本（如果还没备份过）
    backup_flist_absolute
    
    # 创建临时文件
    local temp_file=$(mktemp)
    
    # 替换绝对路径为相对路径 (相对于项目根目录)
    sed "s|$APACHE_HW_ROOT|.|g" "$flist_file" > "$temp_file"
    
    # 备份原文件并替换
    cp "$flist_file" "${flist_file}.bak"
    mv "$temp_file" "$flist_file"
    
    echo "Updated flist to use relative paths"
}

# ============================================
# 恢复 flist 到绝对路径
# ============================================
restore_flist_absolute() {
    local flist_file="$APACHE_HW_FLIST/pe_top_design.f"
    local backup_file="${flist_file}.bak.absolute"
    
    if [ -f "$backup_file" ]; then
        mv "$backup_file" "$flist_file"
        echo "Restored flist to absolute paths"
    else
        echo "No absolute path backup found"
    fi
}

# 备份原始绝对路径版本
backup_flist_absolute() {
    local flist_file="$APACHE_HW_FLIST/pe_top_design.f"
    local backup_file="${flist_file}.bak.absolute"
    
    if [ ! -f "$backup_file" ] && [ -f "$flist_file" ]; then
        # 当前是相对路径，创建绝对路径版本备份
        local temp_file=$(mktemp)
        sed "s|^\\.|${APACHE_HW_ROOT}|g" "$flist_file" > "$temp_file"
        mv "$temp_file" "$backup_file"
        echo "Backed up absolute path version"
    fi
}

# ============================================
# 打印当前环境设置
# ============================================
print_env() {
    echo "=========================================="
    echo "Apache_HW Environment"
    echo "=========================================="
    echo "APACHE_HW_ROOT=$APACHE_HW_ROOT"
    echo "APACHE_HW_DESIGN=$APACHE_HW_DESIGN"
    echo "APACHE_HW_FLIST=$APACHE_HW_FLIST"
    echo "APACHE_HW_ESL=$APACHE_HW_ESL"
    echo "APACHE_HW_SIM=$APACHE_HW_SIM"
    echo "APACHE_HW_RTL=$APACHE_HW_RTL"
    echo "=========================================="
}

# ============================================
# 主命令处理
# ============================================
case "${1:-print}" in
    print)
        print_env
        ;;
    update-flist)
        update_flist_relative
        ;;
    restore-flist)
        restore_flist_absolute
        ;;
    help|*)
        echo "Apache_HW Project Setup"
        echo ""
        echo "Usage: source setup.sh [command]"
        echo ""
        echo "Commands:"
        echo "  (none)       - Print environment variables"
        echo "  print         - Print environment variables"
        echo "  update-flist  - Update flist to use relative paths"
        echo "  restore-flist - Restore flist to absolute paths"
        echo "  help          - Show this help"
        echo ""
        echo "Environment Variables:"
        echo "  APACHE_HW_ROOT  - Project root directory"
        echo "  APACHE_HW_DESIGN - Design directory"
        echo "  APACHE_HW_FLIST  - Filelist directory"
        echo "  APACHE_HW_ESL    - ESL model directory"
        echo "  APACHE_HW_SIM    - Simulation directory"
        echo "  APACHE_HW_RTL    - RTL directory"
        echo ""
        ;;
esac
