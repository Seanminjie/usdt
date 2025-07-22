@echo off
setlocal enabledelayedexpansion

REM USDT工资监控系统 v1.3.0 - SSH密钥部署脚本
REM 目标仓库: git@github.com:Seanminjie/usdt.git

title USDT工资监控系统 v1.3.0 - SSH部署

echo ======================================
echo USDT工资监控系统 v1.3.1 - SSH部署
echo ======================================
echo.

REM SSH密钥内容
set "SSH_KEY_CONTENT=ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIK1H6AXY88FG0iXJf/66nbMXv5QgwInLibpNmMK0rDe"

REM 检查Git是否安装
git --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Git未安装，请先安装Git
    echo 下载地址: https://git-scm.com/downloads
    pause
    exit /b 1
)

echo [INFO] Git已安装

REM 配置SSH密钥
echo [STEP] 配置SSH密钥...
set "SSH_DIR=%USERPROFILE%\.ssh"
set "SSH_KEY_FILE=%SSH_DIR%\github_usdt_deploy"

REM 创建.ssh目录
if not exist "%SSH_DIR%" mkdir "%SSH_DIR%"

REM 写入SSH密钥
echo %SSH_KEY_CONTENT%> "%SSH_KEY_FILE%"

REM 配置SSH config
set "SSH_CONFIG=%SSH_DIR%\config"
findstr /C:"github.com-usdt" "%SSH_CONFIG%" >nul 2>&1
if %errorLevel% neq 0 (
    echo.>> "%SSH_CONFIG%"
    echo Host github.com-usdt>> "%SSH_CONFIG%"
    echo     HostName github.com>> "%SSH_CONFIG%"
    echo     User git>> "%SSH_CONFIG%"
    echo     IdentityFile %SSH_KEY_FILE%>> "%SSH_CONFIG%"
    echo     IdentitiesOnly yes>> "%SSH_CONFIG%"
)

echo [INFO] SSH密钥配置完成

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
echo # Node.js> .gitignore
echo node_modules/>> .gitignore
echo npm-debug.log*>> .gitignore
echo yarn-debug.log*>> .gitignore
echo yarn-error.log*>> .gitignore
echo.>> .gitignore
echo # 运行时文件>> .gitignore
echo *.log>> .gitignore
echo logs/>> .gitignore
echo pids/>> .gitignore
echo *.pid>> .gitignore
echo *.seed>> .gitignore
echo *.pid.lock>> .gitignore
echo.>> .gitignore
echo # 临时文件>> .gitignore
echo .tmp/>> .gitignore
echo temp/>> .gitignore
echo uploads/>> .gitignore
echo.>> .gitignore
echo # 环境变量>> .gitignore
echo .env>> .gitignore
echo .env.local>> .gitignore
echo .env.development.local>> .gitignore
echo .env.test.local>> .gitignore
echo .env.production.local>> .gitignore
echo.>> .gitignore
echo # IDE文件>> .gitignore
echo .vscode/>> .gitignore
echo .idea/>> .gitignore
echo *.swp>> .gitignore
echo *.swo>> .gitignore
echo *~>> .gitignore
echo.>> .gitignore
echo # 操作系统文件>> .gitignore
echo .DS_Store>> .gitignore
echo .DS_Store?>> .gitignore
echo ._*>> .gitignore
echo .Spotlight-V100>> .gitignore
echo .Trashes>> .gitignore
echo ehthumbs.db>> .gitignore
echo Thumbs.db>> .gitignore
echo.>> .gitignore
echo # 备份文件>> .gitignore
echo *.backup.*>> .gitignore
echo *.bak>> .gitignore
echo.>> .gitignore
echo # 数据文件（可选）>> .gitignore
echo employee_data_updated.json>> .gitignore
echo.>> .gitignore
echo # 构建输出>> .gitignore
echo dist/>> .gitignore
echo build/>> .gitignore
echo.>> .gitignore
echo # Vercel>> .gitignore
echo .vercel/>> .gitignore

echo [INFO] .gitignore文件创建完成

REM 配置远程仓库
echo [STEP] 配置远程仓库...
git remote get-url origin >nul 2>&1
if %errorLevel% == 0 (
    echo [WARNING] 远程仓库已存在，更新URL...
    git remote set-url origin git@github.com-usdt:Seanminjie/usdt.git
) else (
    git remote add origin git@github.com-usdt:Seanminjie/usdt.git
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
git commit -m "feat: USDT工资监控系统 v1.3.0 完整版

🚀 新功能:
- 一条命令安装支持 (Linux/macOS/Windows)
- Docker容器化部署
- 在线Excel文件上传
- 智能状态颜色区分
- 自适应响应式布局
- 批量交易检查
- 手工确认功能
- 健康检查API端点

📦 部署方式:
- 传统安装 (install.sh/install.bat)
- 一键安装 (quick-install.sh/quick-install.bat)
- Docker部署 (Dockerfile + docker-compose.yml)
- 离线安装包 (create-offline-package.*)
- 远程部署 (deploy.sh)

🛠️ 技术栈:
- Node.js + Express.js
- Bootstrap 5 响应式UI
- Multer文件上传
- XLSX Excel处理
- Axios HTTP客户端
- Docker容器化

📚 文档:
- README.md - 项目说明
- INSTALL.md - 详细安装指南
- ONE-COMMAND-INSTALL.md - 一条命令安装指南
- DEPLOYMENT-COMPLETE.md - 部署完成总结"

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

REM 询问是否删除SSH密钥文件
set /p cleanup="是否删除临时SSH密钥文件? (y/N): "
if /i "%cleanup%"=="y" (
    del "%SSH_KEY_FILE%" >nul 2>&1
    echo [INFO] SSH密钥文件已删除
)

echo [INFO] 部署完成！
pause
exit /b 0