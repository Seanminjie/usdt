@echo off
chcp 65001 >nul
title USDT工资监控系统 v1.3.0 - 一键启动工具
color 0A

:: 添加错误处理
setlocal enabledelayedexpansion

echo.
echo ========================================
echo   USDT工资监控系统 v1.3.0 - 一键启动工具
echo ========================================
echo.
echo 当前工作目录: %CD%
echo.

:: 检查Node.js是否已安装
echo [1/5] 检查Node.js环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未检测到Node.js，正在自动安装...
    echo.
    echo 正在下载Node.js安装程序...
    
    :: 创建临时目录
    if not exist "%temp%\nodejs_installer" mkdir "%temp%\nodejs_installer"
    
    :: 下载Node.js LTS版本
    powershell -Command "& {Invoke-WebRequest -Uri 'https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi' -OutFile '%temp%\nodejs_installer\nodejs.msi'}"
    
    if exist "%temp%\nodejs_installer\nodejs.msi" (
        echo 正在安装Node.js，请按照安装向导完成安装...
        start /wait msiexec /i "%temp%\nodejs_installer\nodejs.msi" /quiet
        
        :: 刷新环境变量
        call refreshenv.cmd >nul 2>&1
        
        :: 再次检查
        node --version >nul 2>&1
        if %errorlevel% neq 0 (
            echo ❌ Node.js安装失败，请手动安装后重试
            echo 下载地址: https://nodejs.org/
            pause
            exit /b 1
        )
        
        :: 清理临时文件
        del /q "%temp%\nodejs_installer\nodejs.msi" >nul 2>&1
        rmdir "%temp%\nodejs_installer" >nul 2>&1
    ) else (
        echo ❌ 下载Node.js失败，请检查网络连接或手动安装
        echo 下载地址: https://nodejs.org/
        pause
        exit /b 1
    )
)

for /f "tokens=*" %%i in ('node --version') do set NODE_VERSION=%%i
echo ✅ Node.js已安装 (版本: %NODE_VERSION%)

:: 检查Node.js版本是否满足要求
for /f "tokens=2 delims=v." %%a in ("%NODE_VERSION%") do set MAJOR_VERSION=%%a
if %MAJOR_VERSION% LSS 14 (
    echo ⚠️  警告: Node.js版本过低，建议升级到v14或更高版本
    echo 当前版本: %NODE_VERSION%
    echo 最低要求: v14.0.0
)

:: 检查npm依赖
echo.
echo [2/5] 检查项目依赖...
if not exist "node_modules" (
    echo 📦 正在安装项目依赖...
    echo.
    echo 安装的依赖包括:
    echo - express: Web服务器框架
    echo - axios: HTTP客户端
    echo - multer: 文件上传处理
    echo - xlsx: Excel文件处理
    echo.
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败，请检查网络连接
        pause
        exit /b 1
    )
) else (
    echo ✅ 项目依赖已存在
    
    :: 检查关键依赖是否存在
    if not exist "node_modules\express" (
        echo ⚠️  检测到依赖不完整，正在重新安装...
        call npm install
    )
)

:: 检查数据文件
echo.
echo [3/5] 检查数据文件...
if not exist "employee_data.json" (
    if exist "人员2025.07.xlsx" (
        echo 📊 检测到Excel文件，正在转换为JSON格式...
        node read_excel.js
        if %errorlevel% neq 0 (
            echo ❌ 数据文件转换失败
            pause
            exit /b 1
        )
    ) else (
        echo ❌ 未找到员工数据文件 (employee_data.json 或 人员2025.07.xlsx)
        echo 请确保数据文件存在于当前目录
        echo.
        echo 💡 提示: 系统启动后可以通过"导入新表单"功能上传Excel文件
        pause
        exit /b 1
    )
)
echo ✅ 数据文件检查完成

:: 检查端口占用和环境准备
echo.
echo [4/5] 环境准备...

:: 检查端口占用
netstat -an | findstr ":3000" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口3000已被占用，正在释放...
    for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000"') do (
        taskkill /PID %%a /F >nul 2>&1
    )
    timeout /t 2 /nobreak >nul
)

:: 创建public目录（如果不存在）
if not exist "public" (
    echo 📁 创建public目录...
    mkdir public
)

echo ✅ 环境准备完成

:: 启动系统
echo.
echo [5/5] 启动USDT工资监控系统 v1.3.0...
echo.
echo 🚀 系统正在启动，请稍候...
echo.
echo ========================================
echo 系统启动后将自动打开浏览器
echo 访问地址: http://localhost:3000
echo 按 Ctrl+C 可停止系统
echo ========================================
echo.
echo 💡 新功能提示:
echo - 支持在线上传Excel文件
echo - 自动状态颜色区分
echo - 自适应页面布局
echo - 批量交易检查
echo - 手工确认功能
echo.

:: 启动系统并在3秒后打开浏览器
echo 正在启动服务器...
start /b node usdt_monitor.js
if %errorlevel% neq 0 (
    echo ❌ 服务器启动失败
    echo 请检查是否有其他程序占用端口3000
    pause
    exit /b 1
)

echo 等待服务器启动...
timeout /t 3 /nobreak >nul

echo 正在打开浏览器...
start http://localhost:3000

echo.
echo ✅ 系统已启动完成！
echo.
echo 💡 使用提示:
echo    - 浏览器会自动打开系统页面
echo    - 如果浏览器未自动打开，请手动访问: http://localhost:3000
echo    - 要停止系统，请关闭此窗口或按 Ctrl+C
echo    - 可以通过"导入新表单"按钮上传新的Excel文件
echo    - 支持自动检查和手工确认两种方式
echo.
echo 按任意键关闭此窗口...
pause