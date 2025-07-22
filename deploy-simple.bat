@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM USDT工资监控系统 v1.3.0 - SSH密钥部署脚本
REM 目标仓库: git@github.com:Seanminjie/usdt.git

title USDT工资监控系统 v1.3.0 - SSH部署

echo ======================================
echo USDT工资监控系统 v1.3.0 - SSH部署
echo ======================================
echo.

REM 检查Git是否安装
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Git未安装，请先安装Git
    echo 下载地址: https://git-scm.com/downloads
    pause
    exit /b 1
)

echo [INFO] Git已安装

REM 检查是否已经是Git仓库
if not exist ".git" (
    echo [STEP] 初始化Git仓库...
    git init
    echo [INFO] Git仓库初始化完成
) else (
    echo [INFO] 已存在Git仓库
)

REM 创建.gitignore文件
echo [STEP] 创建.gitignore文件...
(
echo # Node.js
echo node_modules/
echo npm-debug.log*
echo yarn-debug.log*
echo yarn-error.log*
echo.
echo # 运行时文件
echo *.log
echo logs/
echo pids/
echo *.pid
echo *.seed
echo *.pid.lock
echo.
echo # 临时文件
echo .tmp/
echo temp/
echo uploads/
echo.
echo # 环境变量
echo .env
echo .env.local
echo .env.development.local
echo .env.test.local
echo .env.production.local
echo.
echo # IDE文件
echo .vscode/
echo .idea/
echo *.swp
echo *.swo
echo *~
echo.
echo # 操作系统文件
echo .DS_Store
echo .DS_Store?
echo ._*
echo .Spotlight-V100
echo .Trashes
echo ehthumbs.db
echo Thumbs.db
echo.
echo # 备份文件
echo *.backup.*
echo *.bak
echo.
echo # 数据文件（可选）
echo employee_data_updated.json
echo.
echo # 构建输出
echo dist/
echo build/
echo.
echo # Vercel
echo .vercel/
) > .gitignore

echo [INFO] .gitignore文件创建完成

REM 配置远程仓库
echo [STEP] 配置远程仓库...
git remote get-url origin >nul 2>&1
if %errorLevel% == 0 (
    echo [WARNING] 远程仓库已存在，更新URL...
    git remote set-url origin https://github.com/Seanminjie/usdt.git
) else (
    git remote add origin https://github.com/Seanminjie/usdt.git
)
echo [INFO] 远程仓库配置完成

REM 添加所有文件
echo [STEP] 添加文件到Git...
git add .
echo [INFO] 文件添加完成

REM 检查Git配置
git config user.name >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] 请配置Git用户信息:
    set /p username="请输入您的用户名: "
    set /p email="请输入您的邮箱: "
    git config user.name "!username!"
    git config user.email "!email!"
    echo [INFO] Git用户信息配置完成
)

REM 提交更改
echo [STEP] 提交更改...
git commit -m "feat: USDT工资监控系统 v1.3.0 完整版 - 一条命令安装支持 - Docker容器化部署 - 在线Excel文件上传 - 智能状态颜色区分 - 自适应响应式布局 - 批量交易检查 - 手工确认功能 - 健康检查API端点"

if %errorLevel% == 0 (
    echo [INFO] 提交完成
) else (
    echo [ERROR] 提交失败，请检查错误信息
    pause
    exit /b 1
)

REM 推送到GitHub
echo [STEP] 推送到GitHub...
echo [INFO] 正在推送到远程仓库...

REM 尝试推送到main分支
git push -u origin main >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] 推送到main分支成功
    goto :success
)

REM 尝试推送到master分支
git push -u origin master >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] 推送到master分支成功
    goto :success
)

REM 如果推送失败，尝试合并
echo [WARNING] 推送失败，尝试合并远程内容...
git pull origin main --allow-unrelated-histories >nul 2>&1
if %errorLevel% neq 0 (
    git pull origin master --allow-unrelated-histories >nul 2>&1
)

REM 再次尝试推送
git push origin main >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] 推送成功
    goto :success
)

git push origin master >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] 推送成功
    goto :success
)

echo [ERROR] 推送失败
echo.
echo 可能的解决方案:
echo 1. 检查网络连接
echo 2. 确认GitHub仓库权限
echo 3. 手动执行: git push -f origin main
pause
exit /b 1

:success
echo.
echo ========================================
echo [SUCCESS] USDT工资监控系统已上传到GitHub
echo ========================================
echo.
echo [INFO] 仓库地址: https://github.com/Seanminjie/usdt
echo.
echo [INFO] 下一步操作:
echo 1. 访问GitHub仓库检查文件
echo 2. 测试一条命令安装功能
echo 3. 更新项目文档
echo.
echo [INFO] 一条命令安装链接:
echo Linux/macOS: curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.sh ^| bash
echo Windows: iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.bat ^| iex
echo.

echo [INFO] 部署完成！
pause
exit /b 0