#!/bin/bash

# USDT工资监控系统 v1.3.0 - 一键安装脚本
# 支持 Linux/Unix/macOS 系统
# 使用方法: curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置变量
INSTALL_DIR="/opt/usdt-monitor"
SERVICE_NAME="usdt-monitor"
APP_PORT="3000"
NODE_MIN_VERSION="14"

# 打印带颜色的消息
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
    echo -e "${BLUE}[STEP]${NC} $1"
}

# 检查是否为root用户
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_message "检测到root权限，将安装系统服务"
        IS_ROOT=true
        # 检查是否在Docker容器中或sudo命令是否可用
        if [ -f /.dockerenv ] || ! command -v sudo &> /dev/null; then
            print_warning "检测到容器环境或sudo不可用，直接使用root权限"
            USE_SUDO=""
        else
            USE_SUDO="sudo"
        fi
    else
        print_warning "非root用户，将跳过系统服务安装"
        IS_ROOT=false
        USE_SUDO=""
        INSTALL_DIR="$HOME/usdt-monitor"
    fi
}

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS="linux"
        if command -v apt-get >/dev/null 2>&1; then
            DISTRO="debian"
        elif command -v yum >/dev/null 2>&1; then
            DISTRO="rhel"
        elif command -v pacman >/dev/null 2>&1; then
            DISTRO="arch"
        else
            DISTRO="unknown"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        DISTRO="macos"
    else
        OS="unknown"
        DISTRO="unknown"
    fi
    
    print_message "检测到操作系统: $OS ($DISTRO)"
}

# 检查Node.js版本
check_node() {
    if command -v node >/dev/null 2>&1; then
        NODE_VERSION=$(node -v | sed 's/v//')
        NODE_MAJOR=$(echo $NODE_VERSION | cut -d. -f1)
        
        if [ "$NODE_MAJOR" -ge "$NODE_MIN_VERSION" ]; then
            print_message "Node.js版本: v$NODE_VERSION ✓"
            return 0
        else
            print_warning "Node.js版本过低: v$NODE_VERSION (需要 >= v$NODE_MIN_VERSION)"
            return 1
        fi
    else
        print_warning "未检测到Node.js"
        return 1
    fi
}

# 安装Node.js
install_node() {
    print_step "安装Node.js..."
    
    if [[ "$OS" == "linux" ]]; then
        if [[ "$DISTRO" == "debian" ]]; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_18.x | ${USE_SUDO} bash -
            ${USE_SUDO} apt-get install -y nodejs
        elif [[ "$DISTRO" == "rhel" ]]; then
            # CentOS/RHEL/Fedora
            curl -fsSL https://rpm.nodesource.com/setup_18.x | ${USE_SUDO} bash -
            ${USE_SUDO} yum install -y nodejs npm
        elif [[ "$DISTRO" == "arch" ]]; then
            # Arch Linux
            ${USE_SUDO} pacman -S nodejs npm
        else
            print_error "不支持的Linux发行版，请手动安装Node.js v18+"
            exit 1
        fi
    elif [[ "$OS" == "macos" ]]; then
        if command -v brew >/dev/null 2>&1; then
            brew install node
        else
            print_error "请先安装Homebrew或手动安装Node.js v18+"
            exit 1
        fi
    fi
    
    # 验证安装
    if check_node; then
        print_message "Node.js安装成功"
    else
        print_error "Node.js安装失败"
        exit 1
    fi
}

# 创建安装目录
create_install_dir() {
    print_step "创建安装目录: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "目录已存在，备份旧版本..."
        if [[ "$IS_ROOT" == true ]]; then
            ${USE_SUDO} mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        else
            mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
        fi
    fi
    
    if [[ "$IS_ROOT" == true ]]; then
        ${USE_SUDO} mkdir -p "$INSTALL_DIR"
        ${USE_SUDO} chown $USER:$USER "$INSTALL_DIR"
    else
        mkdir -p "$INSTALL_DIR"
    fi
}

# 下载项目文件
download_project() {
    print_step "下载项目文件..."
    
    cd "$INSTALL_DIR"
    
    # 尝试从Git仓库克隆
    if command -v git >/dev/null 2>&1; then
        print_message "使用Git克隆项目..."
        if git clone https://github.com/Seanminjie/usdt.git . 2>/dev/null; then
            print_message "项目文件下载完成"
            return 0
        else
            print_warning "Git克隆失败，创建基本文件结构..."
        fi
    else
        print_warning "Git未安装，创建基本文件结构..."
    fi
    
    # 如果Git克隆失败，创建基本文件结构
    create_basic_files
}

# 创建基本文件结构
create_basic_files() {
    # 创建package.json
    cat > package.json << 'EOF'
{
  "name": "usdt-salary-monitor",
  "version": "1.3.0",
  "description": "USDT工资发放监控系统 - 支持在线上传Excel、自动状态检查、批量操作等功能",
  "main": "usdt_monitor.js",
  "scripts": {
    "start": "node usdt_monitor.js",
    "dev": "node usdt_monitor.js",
    "install-deps": "npm install",
    "convert-excel": "node convert_excel.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "express": "^4.18.2",
    "multer": "^1.4.5",
    "xlsx": "^0.18.5"
  },
  "engines": {
    "node": ">=14.0.0"
  },
  "keywords": [
    "usdt",
    "salary",
    "monitor",
    "tron",
    "blockchain",
    "excel",
    "upload",
    "responsive"
  ],
  "author": "USDT Monitor Team",
  "license": "MIT"
}
EOF

    # 创建基本的启动脚本
    cat > start.sh << 'EOF'
#!/bin/bash
echo "启动USDT工资监控系统..."
node usdt_monitor.js
EOF
    chmod +x start.sh
    
    print_warning "基本文件已创建，请手动复制以下文件到 $INSTALL_DIR:"
    print_warning "- usdt_monitor.js (主程序文件)"
    print_warning "- convert_excel.js (Excel转换工具)"
    print_warning "- 员工工资表.xlsx (示例Excel文件)"
    print_warning "或者从项目仓库下载完整文件"
}

# 安装依赖
install_dependencies() {
    print_step "安装项目依赖..."
    
    cd "$INSTALL_DIR"
    
    if [ -f "package.json" ]; then
        npm install --production
        print_message "依赖安装完成"
    else
        print_error "package.json文件不存在"
        exit 1
    fi
}

# 创建系统服务
create_service() {
    if [[ "$IS_ROOT" != true ]]; then
        print_warning "非root用户，跳过系统服务创建"
        return
    fi
    
    print_step "创建系统服务..."
    
    # 创建systemd服务文件
    ${USE_SUDO} tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=USDT Salary Monitor System
After=network.target

[Service]
Type=simple
User=nobody
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/node usdt_monitor.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=${APP_PORT}

# 日志配置
StandardOutput=journal
StandardError=journal
SyslogIdentifier=${SERVICE_NAME}

[Install]
WantedBy=multi-user.target
EOF

    # 重新加载systemd并启用服务
    ${USE_SUDO} systemctl daemon-reload
    ${USE_SUDO} systemctl enable ${SERVICE_NAME}
    
    print_message "系统服务创建完成"
}

# 配置防火墙
configure_firewall() {
    if [[ "$IS_ROOT" != true ]]; then
        print_warning "非root用户，跳过防火墙配置"
        return
    fi
    
    print_step "配置防火墙..."
    
    # 检查并配置ufw
    if command -v ufw >/dev/null 2>&1; then
        ${USE_SUDO} ufw allow ${APP_PORT}/tcp
        print_message "UFW防火墙规则已添加"
    # 检查并配置firewalld
    elif command -v firewall-cmd >/dev/null 2>&1; then
        ${USE_SUDO} firewall-cmd --permanent --add-port=${APP_PORT}/tcp
        ${USE_SUDO} firewall-cmd --reload
        print_message "Firewalld防火墙规则已添加"
    else
        print_warning "未检测到防火墙管理工具，请手动开放端口 ${APP_PORT}"
    fi
}

# 启动服务
start_service() {
    print_step "启动服务..."
    
    cd "$INSTALL_DIR"
    
    if [[ "$IS_ROOT" == true ]] && [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
        # 使用systemd启动
        ${USE_SUDO} systemctl start ${SERVICE_NAME}
        
        # 检查服务状态
        if ${USE_SUDO} systemctl is-active --quiet ${SERVICE_NAME}; then
            print_message "系统服务启动成功"
        else
            print_error "系统服务启动失败"
            ${USE_SUDO} systemctl status ${SERVICE_NAME}
        fi
    else
        # 直接启动
        print_message "使用直接启动模式..."
        print_message "请运行以下命令启动服务:"
        print_message "cd $INSTALL_DIR && npm start"
    fi
}

# 显示安装结果
show_result() {
    echo
    echo "=================================="
    print_message "USDT工资监控系统 v1.3.0 安装完成!"
    echo "=================================="
    echo
    print_message "安装目录: $INSTALL_DIR"
    print_message "访问地址: http://localhost:${APP_PORT}"
    print_message "健康检查: http://localhost:${APP_PORT}/health"
    echo
    
    if [[ "$IS_ROOT" == true ]]; then
        print_message "系统服务管理命令:"
        if [ "$USE_SUDO" != "" ]; then
            echo "  启动服务: sudo systemctl start ${SERVICE_NAME}"
            echo "  停止服务: sudo systemctl stop ${SERVICE_NAME}"
            echo "  重启服务: sudo systemctl restart ${SERVICE_NAME}"
            echo "  查看状态: sudo systemctl status ${SERVICE_NAME}"
            echo "  查看日志: sudo journalctl -u ${SERVICE_NAME} -f"
        else
            echo "  启动服务: systemctl start ${SERVICE_NAME}"
            echo "  停止服务: systemctl stop ${SERVICE_NAME}"
            echo "  重启服务: systemctl restart ${SERVICE_NAME}"
            echo "  查看状态: systemctl status ${SERVICE_NAME}"
            echo "  查看日志: journalctl -u ${SERVICE_NAME} -f"
        fi
    else
        print_message "启动命令:"
        echo "  cd $INSTALL_DIR && npm start"
    fi
    
    echo
    print_message "使用说明:"
    echo "  1. 准备Excel工资表文件"
    echo "  2. 通过网页界面上传Excel文件"
    echo "  3. 系统自动检查USDT交易状态"
    echo "  4. 支持手工确认和批量操作"
    echo
    print_message "如需帮助，请查看: $INSTALL_DIR/README.md"
}

# 主安装流程
main() {
    echo "=================================="
    print_message "USDT工资监控系统 v1.3.0 一键安装"
    echo "=================================="
    echo
    
    # 检查环境
    check_root
    detect_os
    
    # 检查并安装Node.js
    if ! check_node; then
        install_node
    fi
    
    # 创建安装目录
    create_install_dir
    
    # 下载项目文件
    download_project
    
    # 安装依赖
    install_dependencies
    
    # 创建系统服务
    create_service
    
    # 配置防火墙
    configure_firewall
    
    # 启动服务
    start_service
    
    # 显示结果
    show_result
}

# 错误处理
trap 'print_error "安装过程中发生错误，请检查上述输出信息"' ERR

# 运行主程序
main "$@"