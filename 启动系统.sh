#!/bin/bash

# USDT工资监控系统 - Linux/Mac 一键启动脚本

# 设置颜色
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}"
echo "========================================"
echo "   USDT工资监控系统 - 一键启动工具"
echo "========================================"
echo -e "${NC}"

# 检查Node.js是否已安装
echo -e "${YELLOW}[1/4] 检查Node.js环境...${NC}"
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ 未检测到Node.js${NC}"
    echo -e "${YELLOW}正在尝试安装Node.js...${NC}"
    
    # 检测操作系统
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install node
        else
            echo -e "${RED}请先安装Homebrew或手动安装Node.js${NC}"
            echo "Homebrew安装: /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
            echo "Node.js下载: https://nodejs.org/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v apt-get &> /dev/null; then
            # Ubuntu/Debian
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
            sudo apt-get install -y nodejs
        elif command -v yum &> /dev/null; then
            # CentOS/RHEL
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo bash -
            sudo yum install -y nodejs npm
        else
            echo -e "${RED}请手动安装Node.js${NC}"
            echo "下载地址: https://nodejs.org/"
            exit 1
        fi
    else
        echo -e "${RED}不支持的操作系统，请手动安装Node.js${NC}"
        exit 1
    fi
    
    # 再次检查
    if ! command -v node &> /dev/null; then
        echo -e "${RED}❌ Node.js安装失败，请手动安装${NC}"
        exit 1
    fi
fi

NODE_VERSION=$(node --version)
echo -e "${GREEN}✅ Node.js已安装 (版本: $NODE_VERSION)${NC}"

# 检查npm依赖
echo -e "${YELLOW}[2/4] 检查项目依赖...${NC}"
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}📦 正在安装项目依赖...${NC}"
    npm install
    if [ $? -ne 0 ]; then
        echo -e "${RED}❌ 依赖安装失败，请检查网络连接${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ 项目依赖已存在${NC}"
fi

# 检查数据文件
echo -e "${YELLOW}[3/4] 检查数据文件...${NC}"
if [ ! -f "employee_data.json" ]; then
    if [ -f "人员2025.07.xlsx" ]; then
        echo -e "${YELLOW}📊 检测到Excel文件，正在转换为JSON格式...${NC}"
        node read_excel.js
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ 数据文件转换失败${NC}"
            exit 1
        fi
    else
        echo -e "${RED}❌ 未找到员工数据文件 (employee_data.json 或 人员2025.07.xlsx)${NC}"
        echo "请确保数据文件存在于当前目录"
        exit 1
    fi
fi
echo -e "${GREEN}✅ 数据文件检查完成${NC}"

# 启动系统
echo -e "${YELLOW}[4/4] 启动USDT工资监控系统...${NC}"
echo
echo -e "${BLUE}🚀 系统正在启动，请稍候...${NC}"
echo
echo "========================================"
echo "系统启动后请访问: http://localhost:3000"
echo "按 Ctrl+C 可停止系统"
echo "========================================"
echo

# 启动系统
node usdt_monitor.js &
SERVER_PID=$!

# 等待服务器启动
sleep 3

# 尝试打开浏览器
if command -v xdg-open &> /dev/null; then
    # Linux
    xdg-open http://localhost:3000
elif command -v open &> /dev/null; then
    # macOS
    open http://localhost:3000
fi

echo -e "${GREEN}✅ 系统已启动完成！${NC}"
echo
echo -e "${BLUE}💡 使用提示:${NC}"
echo "   - 请在浏览器中访问: http://localhost:3000"
echo "   - 要停止系统，请按 Ctrl+C"
echo

# 等待用户中断
trap "echo -e '\n${YELLOW}正在停止系统...${NC}'; kill $SERVER_PID; exit 0" INT

# 保持脚本运行
wait $SERVER_PID