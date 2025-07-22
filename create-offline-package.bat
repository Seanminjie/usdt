@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: USDT工资监控系统 - Windows离线安装包生成脚本

title USDT工资监控系统 - 创建离线安装包

echo ========================================
echo   创建离线安装包 v1.3.1
echo ========================================
echo.

set "PROJECT_NAME=usdt-salary-monitor"
set "PROJECT_VERSION=1.3.0"
set "PACKAGE_NAME=usdt-monitor-offline"
set "TEMP_DIR=%TEMP%\%PACKAGE_NAME%"

:: 检查依赖
echo [1/6] 检查依赖...
node --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [×] Node.js 未安装
    pause
    exit /b 1
)

npm --version >nul 2>&1
if %errorLevel% neq 0 (
    echo [×] npm 未安装
    pause
    exit /b 1
)

echo [√] 依赖检查完成
echo.

:: 创建临时目录
echo [2/6] 创建临时目录...
if exist "%TEMP_DIR%" rmdir /s /q "%TEMP_DIR%"
mkdir "%TEMP_DIR%"
echo [√] 临时目录: %TEMP_DIR%
echo.

:: 复制项目文件
echo [3/6] 复制项目文件...
copy package.json "%TEMP_DIR%\" >nul
copy usdt_monitor.js "%TEMP_DIR%\" >nul
copy read_excel.js "%TEMP_DIR%\" >nul
copy README.md "%TEMP_DIR%\" >nul
copy INSTALL.md "%TEMP_DIR%\" >nul
copy Dockerfile "%TEMP_DIR%\" >nul
copy docker-compose.yml "%TEMP_DIR%\" >nul

:: 复制启动脚本
copy 启动系统.bat "%TEMP_DIR%\" >nul
copy 启动系统.ps1 "%TEMP_DIR%\" >nul
copy 简化启动.bat "%TEMP_DIR%\" >nul

:: 复制public目录
xcopy /E /I public "%TEMP_DIR%\public\" >nul

:: 复制示例数据
if exist employee_data.json copy employee_data.json "%TEMP_DIR%\" >nul
if exist "人员2025.07.xlsx" copy "人员2025.07.xlsx" "%TEMP_DIR%\" >nul

echo [√] 项目文件复制完成
echo.

:: 下载依赖包
echo [4/6] 下载依赖包...
cd /d "%TEMP_DIR%"
npm install --production
if %errorLevel% neq 0 (
    echo [×] 依赖包下载失败
    pause
    exit /b 1
)
echo [√] 依赖包下载完成
echo.

:: 创建离线安装脚本
echo [5/6] 创建离线安装脚本...

:: 创建Windows离线安装脚本
(
echo @echo off
echo chcp 65001 ^>nul
echo setlocal enabledelayedexpansion
echo.
echo title USDT工资监控系统 - 离线安装
echo.
echo echo ========================================
echo echo   USDT工资监控系统 离线安装
echo echo ========================================
echo echo.
echo.
echo set "INSTALL_DIR=%%USERPROFILE%%\usdt-monitor"
echo.
echo :: 检查Node.js
echo node --version ^>nul 2^>^&1
echo if %%errorLevel%% neq 0 ^(
echo     echo [×] Node.js 未安装，请先安装 Node.js 14+ 版本
echo     echo [!] 下载地址: https://nodejs.org/
echo     pause
echo     exit /b 1
echo ^)
echo.
echo for /f "tokens=1 delims=v" %%%%i in ^('node --version'^) do set "NODE_VERSION=%%%%i"
echo echo [√] Node.js 版本: ^^!NODE_VERSION^^!
echo.
echo :: 创建安装目录
echo echo [!] 创建安装目录: %%INSTALL_DIR%%
echo if exist "%%INSTALL_DIR%%" ^(
echo     echo [!] 备份现有安装...
echo     set "BACKUP_DIR=%%INSTALL_DIR%%.backup.%%date:~0,4%%%%date:~5,2%%%%date:~8,2%%_%%time:~0,2%%%%time:~3,2%%%%time:~6,2%%"
echo     set "BACKUP_DIR=^^!BACKUP_DIR: =0^^!"
echo     move "%%INSTALL_DIR%%" "^^!BACKUP_DIR^^!" ^>nul 2^>^&1
echo ^)
echo.
echo mkdir "%%INSTALL_DIR%%" 2^>nul
echo.
echo :: 复制文件
echo echo [!] 安装文件...
echo xcopy /E /I /Y * "%%INSTALL_DIR%%\" ^>nul
echo.
echo echo.
echo echo ========================================
echo echo   离线安装完成！
echo echo ========================================
echo echo.
echo echo 安装目录: %%INSTALL_DIR%%
echo echo 启动方式: 双击 %%INSTALL_DIR%%\start.bat
echo echo 访问地址: http://localhost:3000
echo echo.
echo pause
) > install-offline.bat

:: 创建启动脚本
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

:: 创建说明文件
(
echo # USDT工资监控系统 v1.3.0 - 离线安装包
echo.
echo ## 📦 Windows 安装说明
echo.
echo ### 系统要求
echo - Node.js 14.0.0 或更高版本
echo - Windows 10 或更高版本
echo.
echo ### 安装步骤
echo 1. 解压安装包到任意目录
echo 2. 双击运行 `install-offline.bat`
echo 3. 双击运行 `start.bat` 启动服务
echo.
echo ### 手动安装
echo 如果自动安装失败：
echo 1. 将所有文件复制到目标目录
echo 2. 在目录中打开命令提示符
echo 3. 运行 `node usdt_monitor.js`
echo.
echo ### 访问系统
echo 安装完成后，在浏览器中访问：http://localhost:3000
echo.
echo ### 故障排除
echo 1. 确保Node.js版本 ^>= 14.0.0
echo 2. 检查端口3000是否被占用
echo 3. 确保有足够的磁盘空间
echo 4. 检查防火墙设置
echo.
echo ### 获取帮助
echo - 查看 README.md 获取详细使用说明
echo - 查看 INSTALL.md 获取完整安装指南
) > OFFLINE-README.md

echo [√] 离线安装脚本创建完成
echo.

:: 创建安装包
echo [6/6] 创建安装包...
cd /d "%TEMP%"

:: 检查是否有7zip或WinRAR
where 7z >nul 2>&1
if %errorLevel% == 0 (
    7z a -tzip "%~dp0%PACKAGE_NAME%.zip" "%PACKAGE_NAME%"
    echo [√] 使用7zip创建安装包
) else (
    where winrar >nul 2>&1
    if %errorLevel% == 0 (
        winrar a -afzip "%~dp0%PACKAGE_NAME%.zip" "%PACKAGE_NAME%"
        echo [√] 使用WinRAR创建安装包
    ) else (
        :: 使用PowerShell创建zip
        powershell -Command "Compress-Archive -Path '%PACKAGE_NAME%' -DestinationPath '%~dp0%PACKAGE_NAME%.zip'"
        echo [√] 使用PowerShell创建安装包
    )
)

:: 清理临时文件
echo.
echo [!] 清理临时文件...
rmdir /s /q "%TEMP_DIR%"

:: 显示完成信息
echo.
echo ========================================
echo   离线安装包创建完成！
echo ========================================
echo.
echo 生成的文件：
echo - %PACKAGE_NAME%.zip
echo.
echo 使用方法：
echo 1. 将 %PACKAGE_NAME%.zip 传输到目标计算机
echo 2. 解压到任意目录
echo 3. 双击运行 install-offline.bat
echo.

:: 显示文件大小
for %%F in ("%PACKAGE_NAME%.zip") do echo 包大小: %%~zF 字节
echo.
pause