@echo off
setlocal enabledelayedexpansion

REM USDT工资监控系统 v1.3.0 - Windows一键安装脚本
REM 使用方法: 
REM   PowerShell: iwr -useb https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.bat | iex
REM   或直接下载运行: quick-install.bat

title USDT工资监控系统 v1.3.0 一键安装

echo ====================================
echo USDT工资监控系统 v1.3.1 - 一键安装
echo ====================================
echo.

REM 配置变量
set "INSTALL_DIR=%USERPROFILE%\usdt-monitor"
set "APP_PORT=3000"
set "NODE_MIN_VERSION=14"

REM 检查管理员权限
net session >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] 检测到管理员权限
    set "IS_ADMIN=true"
    set "INSTALL_DIR=C:\usdt-monitor"
) else (
    echo [WARNING] 非管理员权限，将安装到用户目录
    set "IS_ADMIN=false"
)

REM 检查PowerShell
echo [STEP] 检查PowerShell...
powershell -Command "Get-Host" >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] PowerShell未安装或不可用
    pause
    exit /b 1
)
echo [INFO] PowerShell检查通过

REM 检查Node.js
echo [STEP] 检查Node.js...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [WARNING] 未检测到Node.js，开始安装...
    goto :install_node
) else (
    for /f "tokens=1 delims=." %%a in ('node --version') do (
        set "NODE_MAJOR=%%a"
        set "NODE_MAJOR=!NODE_MAJOR:v=!"
    )
    if !NODE_MAJOR! geq %NODE_MIN_VERSION% (
        echo [INFO] Node.js版本检查通过
        goto :create_dir
    ) else (
        echo [WARNING] Node.js版本过低，开始更新...
        goto :install_node
    )
)

:install_node
echo [STEP] 安装Node.js...
echo [INFO] 正在下载Node.js安装程序...

REM 使用PowerShell下载Node.js
powershell -Command "& {
    $ProgressPreference = 'SilentlyContinue'
    $url = 'https://nodejs.org/dist/v18.18.0/node-v18.18.0-x64.msi'
    $output = '$env:TEMP\nodejs-installer.msi'
    try {
        Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing
        Write-Host '[INFO] Node.js下载完成'
        Start-Process msiexec.exe -ArgumentList '/i', $output, '/quiet', '/norestart' -Wait
        Write-Host '[INFO] Node.js安装完成'
        Remove-Item $output -Force
    } catch {
        Write-Host '[ERROR] Node.js下载或安装失败: ' + $_.Exception.Message
        exit 1
    }
}"

if %errorLevel% neq 0 (
    echo [ERROR] Node.js安装失败
    pause
    exit /b 1
)

REM 刷新环境变量
call refreshenv >nul 2>&1

REM 再次检查Node.js
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Node.js安装后仍无法使用，请重启命令行或重新登录
    pause
    exit /b 1
)

:create_dir
echo [STEP] 创建安装目录: %INSTALL_DIR%

REM 备份旧版本
if exist "%INSTALL_DIR%" (
    echo [WARNING] 目录已存在，备份旧版本...
    set "BACKUP_DIR=%INSTALL_DIR%.backup.%date:~0,4%%date:~5,2%%date:~8,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
    set "BACKUP_DIR=!BACKUP_DIR: =0!"
    move "%INSTALL_DIR%" "!BACKUP_DIR!" >nul
    echo [INFO] 旧版本已备份到: !BACKUP_DIR!
)

mkdir "%INSTALL_DIR%" 2>nul

:download_project
echo [STEP] 下载项目文件...
cd /d "%INSTALL_DIR%"

REM 检查Git
git --version >nul 2>&1
if %errorLevel% == 0 (
    echo [INFO] 使用Git克隆项目...
    git clone https://github.com/Seanminjie/usdt.git . >nul 2>&1
    if %errorLevel% == 0 (
        echo [INFO] 项目文件下载完成
        goto :install_deps
    ) else (
        echo [WARNING] Git克隆失败，创建基本文件结构...
        goto :create_files
    )
) else (
    echo [WARNING] Git未安装，创建基本文件结构...
    goto :create_files
)

:create_files
echo [INFO] 创建基本文件结构...

REM 创建package.json
echo {> package.json
echo   "name": "usdt-salary-monitor",>> package.json
echo   "version": "1.3.0",>> package.json
echo   "description": "USDT工资发放监控系统 - 支持在线上传Excel、自动状态检查、批量操作等功能",>> package.json
echo   "main": "usdt_monitor.js",>> package.json
echo   "scripts": {>> package.json
echo     "start": "node usdt_monitor.js",>> package.json
echo     "dev": "node usdt_monitor.js",>> package.json
echo     "install-deps": "npm install",>> package.json
echo     "convert-excel": "node convert_excel.js">> package.json
echo   },>> package.json
echo   "dependencies": {>> package.json
echo     "axios": "^1.6.0",>> package.json
echo     "express": "^4.18.2",>> package.json
echo     "multer": "^1.4.5",>> package.json
echo     "xlsx": "^0.18.5">> package.json
echo   },>> package.json
echo   "engines": {>> package.json
echo     "node": "^>=14.0.0">> package.json
echo   },>> package.json
echo   "keywords": [>> package.json
echo     "usdt",>> package.json
echo     "salary",>> package.json
echo     "monitor",>> package.json
echo     "tron",>> package.json
echo     "blockchain",>> package.json
echo     "excel",>> package.json
echo     "upload",>> package.json
echo     "responsive">> package.json
echo   ],>> package.json
echo   "author": "USDT Monitor Team",>> package.json
echo   "license": "MIT">> package.json
echo }>> package.json

REM 创建启动脚本
echo @echo off> start.bat
echo echo 启动USDT工资监控系统...>> start.bat
echo node usdt_monitor.js>> start.bat

echo [WARNING] 基本文件已创建，请手动复制以下文件到 %INSTALL_DIR%:
echo [WARNING] - usdt_monitor.js (主程序文件)
echo [WARNING] - convert_excel.js (Excel转换工具)
echo [WARNING] - 员工工资表.xlsx (示例Excel文件)
echo [WARNING] 或者从项目仓库下载完整文件

:install_deps
echo [STEP] 安装项目依赖...
if exist "package.json" (
    npm install --production
    if %errorLevel% == 0 (
        echo [INFO] 依赖安装完成
    ) else (
        echo [ERROR] 依赖安装失败
        pause
        exit /b 1
    )
) else (
    echo [ERROR] package.json文件不存在
    pause
    exit /b 1
)

:create_scripts
echo [STEP] 创建启动脚本...

REM 创建增强版启动脚本
echo @echo off> 启动系统.bat
echo title USDT工资监控系统 v1.3.0>> 启动系统.bat
echo echo ====================================>> 启动系统.bat
echo echo USDT工资监控系统 v1.3.0>> 启动系统.bat
echo echo ====================================>> 启动系统.bat
echo echo.>> 启动系统.bat
echo echo [INFO] 正在启动系统...>> 启动系统.bat
echo cd /d "%INSTALL_DIR%">> 启动系统.bat
echo node usdt_monitor.js>> 启动系统.bat
echo pause>> 启动系统.bat

REM 创建PowerShell启动脚本
echo # USDT工资监控系统 v1.3.0 PowerShell启动脚本> 启动系统.ps1
echo Write-Host "====================================" -ForegroundColor Green>> 启动系统.ps1
echo Write-Host "USDT工资监控系统 v1.3.0" -ForegroundColor Green>> 启动系统.ps1
echo Write-Host "====================================" -ForegroundColor Green>> 启动系统.ps1
echo Write-Host>> 启动系统.ps1
echo Write-Host "[INFO] 正在启动系统..." -ForegroundColor Blue>> 启动系统.ps1
echo Set-Location "%INSTALL_DIR%">> 启动系统.ps1
echo node usdt_monitor.js>> 启动系统.ps1

:configure_firewall
if "%IS_ADMIN%"=="true" (
    echo [STEP] 配置防火墙...
    netsh advfirewall firewall add rule name="USDT Monitor" dir=in action=allow protocol=TCP localport=%APP_PORT% >nul 2>&1
    if %errorLevel% == 0 (
        echo [INFO] 防火墙规则已添加
    ) else (
        echo [WARNING] 防火墙配置失败，请手动开放端口 %APP_PORT%
    )
) else (
    echo [WARNING] 非管理员权限，跳过防火墙配置
    echo [WARNING] 请手动开放端口 %APP_PORT% 或以管理员身份运行
)

:show_result
echo.
echo ====================================
echo [INFO] USDT工资监控系统 v1.3.0 安装完成!
echo ====================================
echo.
echo [INFO] 安装目录: %INSTALL_DIR%
echo [INFO] 访问地址: http://localhost:%APP_PORT%
echo [INFO] 健康检查: http://localhost:%APP_PORT%/health
echo.
echo [INFO] 启动方式:
echo   1. 双击运行: 启动系统.bat
echo   2. PowerShell: .\启动系统.ps1
echo   3. 命令行: npm start
echo.
echo [INFO] 使用说明:
echo   1. 准备Excel工资表文件
echo   2. 通过网页界面上传Excel文件
echo   3. 系统自动检查USDT交易状态
echo   4. 支持手工确认和批量操作
echo.
echo [INFO] 如需帮助，请查看: %INSTALL_DIR%\README.md
echo.

REM 询问是否立即启动
set /p "START_NOW=是否立即启动系统? (Y/N): "
if /i "%START_NOW%"=="Y" (
    echo [INFO] 正在启动系统...
    start "" "%INSTALL_DIR%\启动系统.bat"
    timeout /t 3 >nul
    start "" "http://localhost:%APP_PORT%"
)

echo [INFO] 安装完成，按任意键退出...
pause >nul
exit /b 0