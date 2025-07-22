#!/bin/bash

# USDT工资监控系统 v1.3.0 一键安装脚本
# 支持 Ubuntu/Debian/CentOS/RHEL/macOS

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 项目信息
PROJECT_NAME="usdt-salary-monitor"
PROJECT_VERSION="1.3.0"
GITHUB_REPO="https://github.com/Seanminjie/usdt.git"
INSTALL_DIR="/opt/usdt-monitor"
SERVICE_NAME="usdt-monitor"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  USDT工资监控系统 v${PROJECT_VERSION}${NC}"
echo -e "${BLUE}  一键安装脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 检测操作系统
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            echo -e "${GREEN}检测到 Debian/Ubuntu 系统${NC}"
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            echo -e "${GREEN}检测到 CentOS/RHEL 系统${NC}"
        else
            OS="linux"
            echo -e "${GREEN}检测到 Linux 系统${NC}"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        OS="macos"
        echo -e "${GREEN}检测到 macOS 系统${NC}"
    else
        echo -e "${RED}不支持的操作系统: $OSTYPE${NC}"
        exit 1
    fi
}

# 检查是否为root用户
check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${YELLOW}建议使用 sudo 运行此脚本以获得完整功能${NC}"
        echo -e "${YELLOW}继续安装到用户目录...${NC}"
        INSTALL_DIR="$HOME/usdt-monitor"
        USE_SUDO=""
    else
        echo -e "${GREEN}以管理员权限运行${NC}"
        # 检查是否在Docker容器中或sudo命令是否可用
        if [ -f /.dockerenv ] || ! command -v sudo &> /dev/null; then
            echo -e "${YELLOW}检测到容器环境或sudo不可用，直接使用root权限${NC}"
            USE_SUDO=""
        else
            USE_SUDO="sudo"
        fi
    fi
}

# 安装Node.js
install_nodejs() {
    echo -e "${BLUE}检查 Node.js 安装...${NC}"
    
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        echo -e "${GREEN}Node.js 已安装: v${NODE_VERSION}${NC}"
        
        # 检查版本是否满足要求
        if [ "$(printf '%s\n' "14.0.0" "$NODE_VERSION" | sort -V | head -n1)" = "14.0.0" ]; then
            echo -e "${GREEN}Node.js 版本满足要求 (>=14.0.0)${NC}"
            return
        else
            echo -e "${YELLOW}Node.js 版本过低，需要升级${NC}"
        fi
    fi
    
    echo -e "${BLUE}安装 Node.js...${NC}"
    
    case $OS in
        "debian")
            curl -fsSL https://deb.nodesource.com/setup_18.x | $USE_SUDO bash -
            $USE_SUDO apt-get install -y nodejs
            ;;
        "redhat")
            curl -fsSL https://rpm.nodesource.com/setup_18.x | $USE_SUDO bash -
            $USE_SUDO yum install -y nodejs npm
            ;;
        "macos")
            if command -v brew &> /dev/null; then
                brew install node
            else
                echo -e "${RED}请先安装 Homebrew 或手动安装 Node.js${NC}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}请手动安装 Node.js 18+ 后重新运行此脚本${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${GREEN}Node.js 安装完成${NC}"
}

# 创建安装目录
create_install_dir() {
    echo -e "${BLUE}创建安装目录: ${INSTALL_DIR}${NC}"
    
    if [ -d "$INSTALL_DIR" ]; then
        echo -e "${YELLOW}目录已存在，备份旧版本...${NC}"
        $USE_SUDO mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
    fi
    
    $USE_SUDO mkdir -p "$INSTALL_DIR"
    $USE_SUDO chown -R $USER:$USER "$INSTALL_DIR" 2>/dev/null || true
}

# 下载项目文件
download_project() {
    echo -e "${BLUE}下载项目文件...${NC}"
    
    cd "$INSTALL_DIR"
    
    # 如果有Git仓库，使用git clone
    if command -v git &> /dev/null; then
        git clone "https://github.com/Seanminjie/usdt.git" .
    else
        # 否则创建基本文件结构
        echo -e "${YELLOW}创建项目文件结构...${NC}"
        
        # 创建package.json
        cat > package.json << 'EOF'
{
  "name": "usdt-salary-monitor",
  "version": "1.3.0",
  "description": "USDT工资监控系统 - 监控和分析员工USDT工资接收情况的工具",
  "main": "usdt_monitor.js",
  "scripts": {
    "start": "node usdt_monitor.js",
    "dev": "node usdt_monitor.js",
    "install-deps": "npm install",
    "convert-excel": "node read_excel.js"
  },
  "dependencies": {
    "axios": "^1.6.0",
    "express": "^4.18.2",
    "multer": "^1.4.5-lts.1",
    "xlsx": "^0.18.5"
  },
  "engines": {
    "node": ">=14.0.0"
  },
  "keywords": [
    "usdt",
    "salary",
    "monitor",
    "blockchain",
    "tron",
    "excel",
    "upload",
    "responsive"
  ],
  "author": "USDT Monitor Team",
  "license": "MIT"
}
EOF
        
        # 创建基本目录结构
        mkdir -p public
        
        echo -e "${YELLOW}请手动复制项目文件到 ${INSTALL_DIR}${NC}"
        echo -e "${YELLOW}或提供正确的Git仓库地址${NC}"
    fi
}

# 安装依赖
install_dependencies() {
    echo -e "${BLUE}安装项目依赖...${NC}"
    
    cd "$INSTALL_DIR"
    npm install
    
    echo -e "${GREEN}依赖安装完成${NC}"
}

# 创建系统服务
create_service() {
    if [ "$USE_SUDO" = "" ]; then
        echo -e "${YELLOW}跳过系统服务创建（需要管理员权限）${NC}"
        return
    fi
    
    echo -e "${BLUE}创建系统服务...${NC}"
    
    cat > /tmp/${SERVICE_NAME}.service << EOF
[Unit]
Description=USDT Salary Monitor System
After=network.target

[Service]
Type=simple
User=$USER
WorkingDirectory=${INSTALL_DIR}
ExecStart=/usr/bin/node usdt_monitor.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=3000

[Install]
WantedBy=multi-user.target
EOF
    
    $USE_SUDO mv /tmp/${SERVICE_NAME}.service /etc/systemd/system/
    $USE_SUDO systemctl daemon-reload
    $USE_SUDO systemctl enable ${SERVICE_NAME}
    
    echo -e "${GREEN}系统服务创建完成${NC}"
}

# 创建启动脚本
create_start_script() {
    echo -e "${BLUE}创建启动脚本...${NC}"
    
    cat > "${INSTALL_DIR}/start.sh" << 'EOF'
#!/bin/bash

# USDT监控系统启动脚本
cd "$(dirname "$0")"

echo "启动 USDT工资监控系统..."

# 检查端口占用
if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null ; then
    echo "端口 3000 被占用，尝试释放..."
    pkill -f "node usdt_monitor.js" || true
    sleep 2
fi

# 启动服务
node usdt_monitor.js &
PID=$!

echo "系统已启动，PID: $PID"
echo "访问地址: http://localhost:3000"
echo "按 Ctrl+C 停止服务"

# 等待用户中断
trap "kill $PID; exit" INT
wait $PID
EOF
    
    chmod +x "${INSTALL_DIR}/start.sh"
    
    echo -e "${GREEN}启动脚本创建完成${NC}"
}

# 创建防火墙规则
setup_firewall() {
    if [ "$USE_SUDO" = "" ]; then
        echo -e "${YELLOW}跳过防火墙配置（需要管理员权限）${NC}"
        return
    fi
    
    echo -e "${BLUE}配置防火墙...${NC}"
    
    case $OS in
        "debian")
            if command -v ufw &> /dev/null; then
                $USE_SUDO ufw allow 3000/tcp
                echo -e "${GREEN}UFW 防火墙规则已添加${NC}"
            fi
            ;;
        "redhat")
            if command -v firewall-cmd &> /dev/null; then
                $USE_SUDO firewall-cmd --permanent --add-port=3000/tcp
                $USE_SUDO firewall-cmd --reload
                echo -e "${GREEN}Firewalld 防火墙规则已添加${NC}"
            fi
            ;;
    esac
}

# 显示安装完成信息
show_completion() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  安装完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}安装目录:${NC} ${INSTALL_DIR}"
    echo -e "${BLUE}访问地址:${NC} http://localhost:3000"
    echo ""
    echo -e "${YELLOW}启动方式:${NC}"
    echo "1. 手动启动: cd ${INSTALL_DIR} && ./start.sh"
    
    if [ "$USE_SUDO" != "" ]; then
        echo "2. 系统服务: sudo systemctl start ${SERVICE_NAME}"
        echo "3. 开机自启: sudo systemctl enable ${SERVICE_NAME}"
    fi
    
    echo ""
    echo -e "${YELLOW}使用说明:${NC}"
    echo "- 将Excel文件放入安装目录"
    echo "- 或使用网页界面上传Excel文件"
    echo "- 支持实时监控USDT交易状态"
    echo ""
    echo -e "${BLUE}如需帮助，请查看: ${INSTALL_DIR}/README.md${NC}"
}

# 主安装流程
main() {
    detect_os
    check_root
    install_nodejs
    create_install_dir
    download_project
    install_dependencies
    create_service
    create_start_script
    setup_firewall
    show_completion
}

# 运行安装
main "$@"