#!/bin/bash

# USDT工资监控系统 v1.3.1 - 版本检查和自动更新工具
# 支持 Linux/macOS 系统

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 打印函数
print_message() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo
    echo "USDT工资监控系统 - 版本检查工具"
    echo
    echo "用法:"
    echo "  ./version-check.sh                    # 交互式版本检查"
    echo "  ./version-check.sh --auto-update      # 自动更新到最新版本"
    echo "  ./version-check.sh --help             # 显示帮助信息"
    echo
    echo "选项:"
    echo "  --auto-update, -u    自动更新，无需确认"
    echo "  --help, -h          显示帮助信息"
    echo
    echo "功能:"
    echo "  - 检查当前版本和最新版本"
    echo "  - 显示版本更新日志"
    echo "  - 自动下载和安装更新"
    echo "  - 备份当前版本"
    echo "  - 更新依赖包"
    echo
    echo "示例:"
    echo "  ./version-check.sh                    # 检查版本并询问是否更新"
    echo "  ./version-check.sh -u                 # 直接自动更新"
    echo
}

# 检查运行环境
check_environment() {
    print_step "检查运行环境..."
    
    # 检查Node.js
    if ! command -v node >/dev/null 2>&1; then
        print_error "Node.js未安装，请先安装Node.js"
        echo "安装方法:"
        echo "  Ubuntu/Debian: sudo apt-get install nodejs npm"
        echo "  CentOS/RHEL: sudo yum install nodejs npm"
        echo "  macOS: brew install node"
        echo "  或访问: https://nodejs.org/"
        exit 1
    fi
    print_message "Node.js环境正常 ($(node --version))"
    
    # 检查npm
    if ! command -v npm >/dev/null 2>&1; then
        print_error "npm未安装"
        exit 1
    fi
    print_message "npm环境正常 ($(npm --version))"
    
    # 检查网络连接
    print_step "检查网络连接..."
    if ping -c 1 github.com >/dev/null 2>&1; then
        print_message "网络连接正常"
    else
        print_warning "网络连接异常，可能影响版本检查"
    fi
    
    # 检查Git
    print_step "检查Git环境..."
    if command -v git >/dev/null 2>&1; then
        print_message "Git环境正常 ($(git --version | cut -d' ' -f3))"
        GIT_AVAILABLE=1
    else
        print_warning "Git未安装，自动更新功能将不可用"
        echo "安装方法:"
        echo "  Ubuntu/Debian: sudo apt-get install git"
        echo "  CentOS/RHEL: sudo yum install git"
        echo "  macOS: brew install git"
        GIT_AVAILABLE=0
    fi
}

# 主函数
main() {
    echo
    echo "========================================"
    echo "  USDT工资监控系统 - 版本检查工具"
    echo "========================================"
    echo
    
    # 解析命令行参数
    AUTO_UPDATE=0
    while [[ $# -gt 0 ]]; do
        case $1 in
            --auto-update|-u)
                AUTO_UPDATE=1
                shift
                ;;
            --help|-h)
                show_help
                exit 0
                ;;
            *)
                print_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # 检查环境
    check_environment
    
    echo
    print_step "开始版本检查..."
    echo
    
    # 运行Node.js版本检查器
    if [[ $AUTO_UPDATE -eq 1 ]]; then
        print_message "🚀 自动更新模式"
        node version-checker.js --auto-update
    else
        print_message "🔍 交互式检查模式"
        node version-checker.js
    fi
    
    if [[ $? -ne 0 ]]; then
        echo
        print_error "版本检查失败"
        echo
        echo "💡 故障排除:"
        echo "1. 检查网络连接"
        echo "2. 确认GitHub可访问"
        echo "3. 检查防火墙设置"
        echo "4. 稍后重试"
        echo
        exit 1
    fi
    
    echo
    print_message "✅ 版本检查完成"
    echo
}

# 运行主函数
main "$@"