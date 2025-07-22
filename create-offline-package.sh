#!/bin/bash

# USDT工资监控系统 - 离线安装包生成脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

PROJECT_NAME="usdt-salary-monitor"
PROJECT_VERSION="1.3.0"
PACKAGE_NAME="usdt-monitor-offline"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  创建离线安装包 v${PROJECT_VERSION}${NC}"
echo -e "${BLUE}========================================${NC}"

# 检查依赖
check_dependencies() {
    echo -e "${BLUE}检查依赖...${NC}"
    
    if ! command -v node &> /dev/null; then
        echo -e "${RED}Node.js 未安装${NC}"
        exit 1
    fi
    
    if ! command -v npm &> /dev/null; then
        echo -e "${RED}npm 未安装${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}依赖检查完成${NC}"
}

# 创建临时目录
create_temp_dir() {
    echo -e "${BLUE}创建临时目录...${NC}"
    
    TEMP_DIR=$(mktemp -d)
    PACKAGE_DIR="$TEMP_DIR/$PACKAGE_NAME"
    
    mkdir -p "$PACKAGE_DIR"
    echo -e "${GREEN}临时目录: $PACKAGE_DIR${NC}"
}

# 复制项目文件
copy_project_files() {
    echo -e "${BLUE}复制项目文件...${NC}"
    
    # 复制主要文件
    cp package.json "$PACKAGE_DIR/"
    cp usdt_monitor.js "$PACKAGE_DIR/"
    cp read_excel.js "$PACKAGE_DIR/"
    cp README.md "$PACKAGE_DIR/"
    cp INSTALL.md "$PACKAGE_DIR/"
    cp Dockerfile "$PACKAGE_DIR/"
    cp docker-compose.yml "$PACKAGE_DIR/"
    
    # 复制启动脚本
    cp 启动系统.bat "$PACKAGE_DIR/"
    cp 启动系统.ps1 "$PACKAGE_DIR/"
    cp 简化启动.bat "$PACKAGE_DIR/"
    
    # 复制public目录
    cp -r public "$PACKAGE_DIR/"
    
    # 复制示例数据（如果存在）
    if [ -f "employee_data.json" ]; then
        cp employee_data.json "$PACKAGE_DIR/"
    fi
    
    if [ -f "人员2025.07.xlsx" ]; then
        cp "人员2025.07.xlsx" "$PACKAGE_DIR/"
    fi
    
    echo -e "${GREEN}项目文件复制完成${NC}"
}

# 下载依赖包
download_dependencies() {
    echo -e "${BLUE}下载依赖包...${NC}"
    
    cd "$PACKAGE_DIR"
    
    # 创建node_modules目录
    npm install --production
    
    echo -e "${GREEN}依赖包下载完成${NC}"
}

# 创建离线安装脚本
create_offline_installer() {
    echo -e "${BLUE}创建离线安装脚本...${NC}"
    
    # Linux/macOS 离线安装脚本
    cat > "$PACKAGE_DIR/install-offline.sh" << 'EOF'
#!/bin/bash

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

INSTALL_DIR="/opt/usdt-monitor"
SERVICE_NAME="usdt-monitor"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  USDT工资监控系统 离线安装${NC}"
echo -e "${BLUE}========================================${NC}"

# 检查权限
if [ "$EUID" -ne 0 ]; then
    echo -e "${YELLOW}建议使用 sudo 运行此脚本${NC}"
    INSTALL_DIR="$HOME/usdt-monitor"
    USE_SUDO=""
else
    USE_SUDO="sudo"
fi

# 检查Node.js
if ! command -v node &> /dev/null; then
    echo -e "${RED}Node.js 未安装，请先安装 Node.js 14+ 版本${NC}"
    exit 1
fi

NODE_VERSION=$(node --version | cut -d'v' -f2)
echo -e "${GREEN}Node.js 版本: v${NODE_VERSION}${NC}"

# 创建安装目录
echo -e "${BLUE}创建安装目录: ${INSTALL_DIR}${NC}"
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}备份现有安装...${NC}"
    $USE_SUDO mv "$INSTALL_DIR" "${INSTALL_DIR}.backup.$(date +%Y%m%d_%H%M%S)"
fi

$USE_SUDO mkdir -p "$INSTALL_DIR"
$USE_SUDO chown -R $USER:$USER "$INSTALL_DIR" 2>/dev/null || true

# 复制文件
echo -e "${BLUE}安装文件...${NC}"
cp -r * "$INSTALL_DIR/"

# 设置权限
chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true

# 创建系统服务
if [ "$USE_SUDO" != "" ]; then
    echo -e "${BLUE}创建系统服务...${NC}"
    
    cat > /tmp/${SERVICE_NAME}.service << EOSERVICE
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
EOSERVICE
    
    $USE_SUDO mv /tmp/${SERVICE_NAME}.service /etc/systemd/system/
    $USE_SUDO systemctl daemon-reload
    $USE_SUDO systemctl enable ${SERVICE_NAME}
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  离线安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}安装目录:${NC} ${INSTALL_DIR}"
echo -e "${BLUE}启动命令:${NC} cd ${INSTALL_DIR} && node usdt_monitor.js"
if [ "$USE_SUDO" != "" ]; then
    echo -e "${BLUE}系统服务:${NC} sudo systemctl start ${SERVICE_NAME}"
fi
echo -e "${BLUE}访问地址:${NC} http://localhost:3000"
EOF

    # Windows 离线安装脚本
    cat > "$PACKAGE_DIR/install-offline.bat" << 'EOF'
@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

title USDT工资监控系统 - 离线安装

echo ========================================
echo   USDT工资监控系统 离线安装
echo ========================================
echo.

set "INSTALL_DIR=%USERPROFILE%\usdt-monitor"

:: 检查Node.js
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [×] Node.js 未安装，请先安装 Node.js 14+ 版本
    echo [!] 下载地址: https://nodejs.org/
    pause
    exit /b 1
)

for /f "tokens=1 delims=v" %%i in ('node --version') do set "NODE_VERSION=%%i"
echo [√] Node.js 版本: !NODE_VERSION!

:: 创建安装目录
echo [!] 创建安装目录: %INSTALL_DIR%
if exist "%INSTALL_DIR%" (
    echo [!] 备份现有安装...
    set "BACKUP_DIR=%INSTALL_DIR%.backup.%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "BACKUP_DIR=!BACKUP_DIR: =0!"
    move "%INSTALL_DIR%" "!BACKUP_DIR!" >nul 2>&1
)

mkdir "%INSTALL_DIR%" 2>nul

:: 复制文件
echo [!] 安装文件...
xcopy /E /I /Y * "%INSTALL_DIR%\" >nul

echo.
echo ========================================
echo   离线安装完成！
echo ========================================
echo.
echo 安装目录: %INSTALL_DIR%
echo 启动方式: 双击 %INSTALL_DIR%\start.bat
echo 访问地址: http://localhost:3000
echo.
pause
EOF

    chmod +x "$PACKAGE_DIR/install-offline.sh"
    
    echo -e "${GREEN}离线安装脚本创建完成${NC}"
}

# 创建说明文件
create_readme() {
    echo -e "${BLUE}创建说明文件...${NC}"
    
    cat > "$PACKAGE_DIR/OFFLINE-README.md" << 'EOF'
# USDT工资监控系统 v1.3.0 - 离线安装包

## 📦 安装说明

### 系统要求
- Node.js 14.0.0 或更高版本
- 操作系统：Windows 10+, Ubuntu 18.04+, CentOS 7+, macOS 10.15+

### 安装步骤

#### Linux/macOS
```bash
# 1. 解压安装包
tar -xzf usdt-monitor-offline.tar.gz
cd usdt-monitor-offline

# 2. 运行安装脚本
sudo ./install-offline.sh

# 3. 启动服务
sudo systemctl start usdt-monitor
```

#### Windows
```cmd
# 1. 解压安装包到任意目录
# 2. 双击运行 install-offline.bat
# 3. 双击运行 start.bat 启动服务
```

### 手动安装
如果自动安装脚本失败，可以手动安装：

```bash
# 1. 复制文件到目标目录
cp -r * /opt/usdt-monitor/

# 2. 进入目录
cd /opt/usdt-monitor

# 3. 启动服务
node usdt_monitor.js
```

### 访问系统
安装完成后，在浏览器中访问：http://localhost:3000

### 故障排除
1. 确保Node.js版本 >= 14.0.0
2. 检查端口3000是否被占用
3. 确保有足够的磁盘空间
4. 检查防火墙设置

### 获取帮助
- 查看 README.md 获取详细使用说明
- 查看 INSTALL.md 获取完整安装指南
EOF

    echo -e "${GREEN}说明文件创建完成${NC}"
}

# 打包文件
create_package() {
    echo -e "${BLUE}创建安装包...${NC}"
    
    cd "$TEMP_DIR"
    
    # 创建tar.gz包
    tar -czf "${PACKAGE_NAME}.tar.gz" "$PACKAGE_NAME"
    
    # 创建zip包（Windows兼容）
    if command -v zip &> /dev/null; then
        zip -r "${PACKAGE_NAME}.zip" "$PACKAGE_NAME"
    fi
    
    # 移动到当前目录
    mv "${PACKAGE_NAME}.tar.gz" "$OLDPWD/"
    if [ -f "${PACKAGE_NAME}.zip" ]; then
        mv "${PACKAGE_NAME}.zip" "$OLDPWD/"
    fi
    
    echo -e "${GREEN}安装包创建完成${NC}"
}

# 清理临时文件
cleanup() {
    echo -e "${BLUE}清理临时文件...${NC}"
    rm -rf "$TEMP_DIR"
    echo -e "${GREEN}清理完成${NC}"
}

# 显示完成信息
show_completion() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  离线安装包创建完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}生成的文件：${NC}"
    echo "- ${PACKAGE_NAME}.tar.gz (Linux/macOS)"
    if [ -f "${PACKAGE_NAME}.zip" ]; then
        echo "- ${PACKAGE_NAME}.zip (Windows)"
    fi
    echo ""
    echo -e "${BLUE}使用方法：${NC}"
    echo "1. 将安装包传输到目标服务器"
    echo "2. 解压安装包"
    echo "3. 运行对应的离线安装脚本"
    echo ""
    echo -e "${BLUE}包大小：${NC}"
    ls -lh ${PACKAGE_NAME}.* | awk '{print $9 ": " $5}'
}

# 主函数
main() {
    check_dependencies
    create_temp_dir
    copy_project_files
    download_dependencies
    create_offline_installer
    create_readme
    create_package
    cleanup
    show_completion
}

# 运行主函数
main "$@"