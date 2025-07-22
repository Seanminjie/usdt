@echo off
chcp 65001 >nul
title USDT工资监控系统 v1.3.1 - 调试检查工具
color 0E

echo.
echo ========================================
echo         系统环境调试信息
echo ========================================
echo.

echo [系统信息]
echo 操作系统: %OS%
echo 当前目录: %CD%
echo 用户名: %USERNAME%
echo.

echo [文件检查]
if exist "usdt_monitor.js" (
    echo ✅ usdt_monitor.js - 存在
) else (
    echo ❌ usdt_monitor.js - 不存在
)

if exist "package.json" (
    echo ✅ package.json - 存在
) else (
    echo ❌ package.json - 不存在
)

if exist "employee_data.json" (
    echo ✅ employee_data.json - 存在
) else (
    echo ❌ employee_data.json - 不存在
)

if exist "人员2025.07.xlsx" (
    echo ✅ 人员2025.07.xlsx - 存在
) else (
    echo ❌ 人员2025.07.xlsx - 不存在
)

if exist "node_modules" (
    echo ✅ node_modules - 存在
) else (
    echo ❌ node_modules - 不存在
)

echo.
echo [Node.js检查]
node --version >nul 2>&1
if %errorlevel% equ 0 (
    for /f "tokens=*" %%i in ('node --version') do echo ✅ Node.js版本: %%i
    
    npm --version >nul 2>&1
    if %errorlevel% equ 0 (
        for /f "tokens=*" %%i in ('npm --version') do echo ✅ npm版本: %%i
    ) else (
        echo ❌ npm未安装或不可用
    )
) else (
    echo ❌ Node.js未安装或不在PATH中
)

echo.
echo [端口检查]
netstat -an | findstr ":3000" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口3000已被占用
    echo 占用端口3000的进程:
    netstat -ano | findstr ":3000"
) else (
    echo ✅ 端口3000可用
)

echo.
echo [网络检查]
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% equ 0 (
    echo ✅ 网络连接正常
) else (
    echo ❌ 网络连接异常
)

echo.
echo ========================================
echo 如果所有检查都通过，请尝试运行:
echo 1. 简化启动.bat
echo 2. 或者手动运行: node usdt_monitor.js
echo ========================================
echo.
echo 按任意键退出...
pause >nul