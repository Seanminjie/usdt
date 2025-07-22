@echo off
chcp 65001 >nul
title USDT工资监控系统 v1.3.1 - 版本检查和自动更新工具
color 0A

setlocal enabledelayedexpansion

echo.
echo ========================================
echo   USDT工资监控系统 - 版本检查工具
echo ========================================
echo.

:: 检查Node.js是否可用
echo [1/4] 检查运行环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Node.js未安装，请先安装Node.js
    echo 下载地址: https://nodejs.org/
    pause
    exit /b 1
)
echo ✅ Node.js环境正常

:: 检查网络连接
echo.
echo [2/4] 检查网络连接...
ping -n 1 github.com >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  网络连接异常，可能影响版本检查
) else (
    echo ✅ 网络连接正常
)

:: 检查Git是否可用
echo.
echo [3/4] 检查Git环境...
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ⚠️  Git未安装，自动更新功能将不可用
    echo 下载地址: https://git-scm.com/downloads
    set "GIT_AVAILABLE=0"
) else (
    echo ✅ Git环境正常
    set "GIT_AVAILABLE=1"
)

:: 运行版本检查
echo.
echo [4/4] 开始版本检查...
echo.

:: 检查命令行参数
set "AUTO_UPDATE=0"
if "%1"=="--auto-update" set "AUTO_UPDATE=1"
if "%1"=="-u" set "AUTO_UPDATE=1"
if "%1"=="--help" goto :show_help
if "%1"=="-h" goto :show_help

:: 运行Node.js版本检查器
if "%AUTO_UPDATE%"=="1" (
    echo 🚀 自动更新模式
    node version-checker.js --auto-update
) else (
    echo 🔍 交互式检查模式
    node version-checker.js
)

if %errorlevel% neq 0 (
    echo.
    echo ❌ 版本检查失败
    echo.
    echo 💡 故障排除:
    echo 1. 检查网络连接
    echo 2. 确认GitHub可访问
    echo 3. 检查防火墙设置
    echo 4. 稍后重试
    echo.
    goto :end
)

echo.
echo ✅ 版本检查完成
echo.

goto :end

:show_help
echo.
echo USDT工资监控系统 - 版本检查工具
echo.
echo 用法:
echo   version-check.bat                    # 交互式版本检查
echo   version-check.bat --auto-update      # 自动更新到最新版本
echo   version-check.bat --help             # 显示帮助信息
echo.
echo 选项:
echo   --auto-update, -u    自动更新，无需确认
echo   --help, -h          显示帮助信息
echo.
echo 功能:
echo   - 检查当前版本和最新版本
echo   - 显示版本更新日志
echo   - 自动下载和安装更新
echo   - 备份当前版本
echo   - 更新依赖包
echo.
echo 示例:
echo   version-check.bat                    # 检查版本并询问是否更新
echo   version-check.bat -u                 # 直接自动更新
echo.
goto :end

:end
echo 按任意键退出...
pause >nul
exit /b 0