@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: USDT工资监控系统 v1.3.1 Windows一键安装脚本
:: 支持 Windows 10/11

title USDT工资监控系统 v1.3.1 - 一键安装

echo ========================================
echo   USDT工资监控系统 v1.3.1
echo   Windows 一键安装脚本
echo ========================================
echo.

:: 设置变量
set "PROJECT_NAME=usdt-salary-monitor"
set "PROJECT_VERSION=1.3.1"
set "INSTALL_DIR=%USERPROFILE%\usdt-monitor"
set "GITHUB_REPO=https://github.com/Seanminjie/usdt.git"

:: 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [√] 以管理员权限运行
    set "IS_ADMIN=1"
) else (
    echo [!] 建议以管理员权限运行以获得完整功能
    echo [!] 继续安装到用户目录...
    set "IS_ADMIN=0"
)
echo.

:: 检查PowerShell
echo [1/7] 检查 PowerShell...
powershell -Command "Get-Host" >nul 2>&1
if %errorLevel% neq 0 (
    echo [×] PowerShell 不可用，请安装 PowerShell
    pause
    exit /b 1
)
echo [√] PowerShell 可用
echo.

:: 检查和安装Node.js
echo [2/7] 检查 Node.js...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Node.js 未安装，开始下载安装...
    call :install_nodejs
) else (
    for /f "tokens=1 delims=v" %%i in ('node --version') do set "NODE_VERSION=%%i"
    echo [√] Node.js 已安装: !NODE_VERSION!
    
    :: 检查版本
    powershell -Command "if ([version]'!NODE_VERSION!'.CompareTo([version]'14.0.0') -lt 0) { exit 1 }"
    if !errorLevel! neq 0 (
        echo [!] Node.js 版本过低，需要 v14.0.0 或更高版本
        call :install_nodejs
    )
)
echo.

:: 创建安装目录
echo [3/7] 创建安装目录...
if exist "%INSTALL_DIR%" (
    echo [!] 目录已存在，备份旧版本...
    set "BACKUP_DIR=%INSTALL_DIR%.backup.%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "BACKUP_DIR=!BACKUP_DIR: =0!"
    move "%INSTALL_DIR%" "!BACKUP_DIR!" >nul 2>&1
)

mkdir "%INSTALL_DIR%" 2>nul
if not exist "%INSTALL_DIR%" (
    echo [×] 无法创建安装目录: %INSTALL_DIR%
    pause
    exit /b 1
)
echo [√] 安装目录创建完成: %INSTALL_DIR%
echo.

:: 下载项目文件
echo [4/7] 下载项目文件...
cd /d "%INSTALL_DIR%"

:: 检查Git
git --version >nul 2>&1
if %errorLevel% == 0 (
    echo [√] 使用 Git 下载项目...
    git clone "%GITHUB_REPO%" . >nul 2>&1
    if !errorLevel! neq 0 (
        echo [!] Git 下载失败，创建基本文件结构...
        call :create_project_files
    )
) else (
    echo [!] Git 未安装，创建基本文件结构...
    call :create_project_files
)
echo.

:: 安装依赖
echo [5/7] 安装项目依赖...
npm install
if %errorLevel% neq 0 (
    echo [×] 依赖安装失败
    pause
    exit /b 1
)
echo [√] 依赖安装完成
echo.

:: 创建启动脚本
echo [6/7] 创建启动脚本...
call :create_start_scripts
echo [√] 启动脚本创建完成
echo.

:: 配置防火墙
echo [7/7] 配置防火墙...
if "%IS_ADMIN%"=="1" (
    netsh advfirewall firewall add rule name="USDT Monitor" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
    if !errorLevel! == 0 (
        echo [√] 防火墙规则添加成功
    ) else (
        echo [!] 防火墙规则添加失败，请手动配置
    )
) else (
    echo [!] 跳过防火墙配置（需要管理员权限）
)
echo.

:: 显示完成信息
call :show_completion
pause
exit /b 0

:: 安装Node.js函数
:install_nodejs
echo [!] 下载 Node.js LTS 版本...
set "NODE_URL=https://nodejs.org/dist/v18.19.0/node-v18.19.0-x64.msi"
set "NODE_FILE=%TEMP%\nodejs-installer.msi"

:: 使用PowerShell下载
powershell -Command "Invoke-WebRequest -Uri '%NODE_URL%' -OutFile '%NODE_FILE%'"
if %errorLevel% neq 0 (
    echo [×] Node.js 下载失败
    echo [!] 请手动下载安装: https://nodejs.org/
    pause
    exit /b 1
)

echo [!] 安装 Node.js...
msiexec /i "%NODE_FILE%" /quiet /norestart
if %errorLevel% neq 0 (
    echo [×] Node.js 安装失败
    pause
    exit /b 1
)

:: 刷新环境变量
call refreshenv.cmd >nul 2>&1
set "PATH=%PATH%;%ProgramFiles%\nodejs"

echo [√] Node.js 安装完成
del "%NODE_FILE%" >nul 2>&1
goto :eof

:: 创建项目文件函数
:create_project_files
echo [!] 创建 package.json...
(
echo {
echo   "name": "usdt-salary-monitor",
echo   "version": "1.3.1",
echo   "description": "USDT工资监控系统 - 监控和分析员工USDT工资接收情况的工具",
echo   "main": "usdt_monitor.js",
echo   "scripts": {
echo     "start": "node usdt_monitor.js",
echo     "dev": "node usdt_monitor.js",
echo     "install-deps": "npm install",
echo     "convert-excel": "node read_excel.js"
echo   },
echo   "dependencies": {
echo     "axios": "^1.6.0",
echo     "express": "^4.18.2",
echo     "multer": "^1.4.5-lts.1",
echo     "xlsx": "^0.18.5"
echo   },
echo   "engines": {
echo     "node": ">=14.0.0"
echo   },
echo   "keywords": [
echo     "usdt",
echo     "salary",
echo     "monitor",
echo     "blockchain",
echo     "tron",
echo     "excel",
echo     "upload",
echo     "responsive"
echo   ],
echo   "author": "USDT Monitor Team",
echo   "license": "MIT"
echo }
) > package.json

mkdir public >nul 2>&1
echo [!] 请手动复制项目文件到安装目录
echo [!] 或提供正确的Git仓库地址
goto :eof

:: 创建启动脚本函数
:create_start_scripts
:: 创建批处理启动脚本
(
echo @echo off
echo chcp 65001 ^>nul
echo title USDT工资监控系统 v1.3.0
echo.
echo echo 启动 USDT工资监控系统...
echo cd /d "%%~dp0"
echo.
echo :: 检查端口占用
echo netstat -ano ^| findstr ":3000" ^>nul 2^>^&1
echo if %%errorLevel%% == 0 ^(
echo     echo [!] 端口 3000 被占用，尝试释放...
echo     for /f "tokens=5" %%%%i in ^('netstat -ano ^| findstr ":3000"'^) do taskkill /PID %%%%i /F ^>nul 2^>^&1
echo     timeout /t 2 /nobreak ^>nul
echo ^)
echo.
echo :: 启动服务
echo echo [√] 启动服务器...
echo start /min node usdt_monitor.js
echo.
echo echo ========================================
echo echo   USDT工资监控系统已启动
echo echo ========================================
echo echo.
echo echo 访问地址: http://localhost:3000
echo echo.
echo echo 按任意键打开浏览器...
echo pause ^>nul
echo start http://localhost:3000
echo.
echo echo 按任意键退出...
echo pause ^>nul
) > start.bat

:: 创建PowerShell启动脚本
(
echo # USDT工资监控系统启动脚本
echo Set-Location $PSScriptRoot
echo.
echo Write-Host "启动 USDT工资监控系统..." -ForegroundColor Green
echo.
echo # 检查端口占用
echo $port3000 = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
echo if ^($port3000^) {
echo     Write-Host "[!] 端口 3000 被占用，尝试释放..." -ForegroundColor Yellow
echo     Stop-Process -Name "node" -Force -ErrorAction SilentlyContinue
echo     Start-Sleep -Seconds 2
echo }
echo.
echo # 启动服务
echo Write-Host "[√] 启动服务器..." -ForegroundColor Green
echo Start-Process -FilePath "node" -ArgumentList "usdt_monitor.js" -WindowStyle Minimized
echo.
echo Write-Host "========================================"
echo Write-Host "  USDT工资监控系统已启动" -ForegroundColor Green
echo Write-Host "========================================"
echo Write-Host ""
echo Write-Host "访问地址: http://localhost:3000" -ForegroundColor Cyan
echo Write-Host ""
echo Write-Host "按任意键打开浏览器..."
echo Read-Host
echo Start-Process "http://localhost:3000"
) > start.ps1

goto :eof

:: 显示完成信息函数
:show_completion
echo ========================================
echo   安装完成！
echo ========================================
echo.
echo 安装目录: %INSTALL_DIR%
echo 访问地址: http://localhost:3000
echo.
echo 启动方式:
echo 1. 双击运行: %INSTALL_DIR%\start.bat
echo 2. PowerShell: %INSTALL_DIR%\start.ps1
echo 3. 命令行: cd "%INSTALL_DIR%" ^&^& node usdt_monitor.js
echo.
echo 使用说明:
echo - 将Excel文件放入安装目录
echo - 或使用网页界面上传Excel文件
echo - 支持实时监控USDT交易状态
echo.
echo 如需帮助，请查看: %INSTALL_DIR%\README.md
echo.
goto :eof