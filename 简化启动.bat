@echo off
chcp 65001 >nul
title USDT工资监控系统 v1.3.1 - 简化启动工具
color 0A

echo.
echo ========================================
echo   USDT工资监控系统 v1.3.0 - 简化启动工具
echo ========================================
echo.
echo 当前工作目录: %CD%
echo.

:: 检查必要文件
echo [检查] 验证必要文件...
if not exist "usdt_monitor.js" (
    echo ❌ 未找到 usdt_monitor.js 文件
    echo 请确保在正确的目录中运行此脚本
    goto :error_exit
)

if not exist "package.json" (
    echo ❌ 未找到 package.json 文件
    echo 请确保在正确的目录中运行此脚本
    goto :error_exit
)

echo ✅ 必要文件检查完成

:: 检查Node.js
echo.
echo [检查] Node.js环境...
node --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 未检测到Node.js
    echo.
    echo 请先安装Node.js:
    echo 1. 访问 https://nodejs.org/
    echo 2. 下载并安装LTS版本 (推荐v18或更高版本)
    echo 3. 重新运行此脚本
    goto :error_exit
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

:: 检查依赖
echo.
echo [检查] 项目依赖...
if not exist "node_modules" (
    echo 📦 正在安装项目依赖...
    echo 这可能需要几分钟时间，请耐心等待...
    echo.
    echo 安装的依赖包括:
    echo - express: Web服务器框架
    echo - axios: HTTP客户端
    echo - multer: 文件上传处理
    echo - xlsx: Excel文件处理
    echo.
    npm install
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败
        echo 请检查网络连接或手动运行: npm install
        goto :error_exit
    )
    echo ✅ 依赖安装完成
) else (
    echo ✅ 项目依赖已存在
    
    :: 检查关键依赖是否存在
    if not exist "node_modules\express" (
        echo ⚠️  检测到依赖不完整，正在重新安装...
        npm install
    )
)

:: 检查数据文件
echo.
echo [检查] 数据文件...
if not exist "employee_data.json" (
    if exist "人员2025.07.xlsx" (
        echo 📊 检测到Excel文件，正在转换...
        node read_excel.js
        if %errorlevel% neq 0 (
            echo ❌ 数据文件转换失败
            goto :error_exit
        )
        echo ✅ 数据文件转换完成
    ) else (
        echo ❌ 未找到数据文件
        echo 请确保以下文件之一存在:
        echo - employee_data.json (JSON格式的员工数据)
        echo - 人员2025.07.xlsx (Excel格式的员工数据)
        echo.
        echo 💡 提示: 系统启动后可以通过"导入新表单"功能上传Excel文件
        goto :error_exit
    )
) else (
    echo ✅ 数据文件已存在
)

:: 检查端口占用
echo.
echo [检查] 端口状态...
netstat -an | findstr ":3000" >nul 2>&1
if %errorlevel% equ 0 (
    echo ⚠️  端口3000已被占用
    echo 正在尝试释放端口...
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

:: 启动系统
echo.
echo [启动] USDT工资监控系统 v1.3.0...
echo.
echo 🚀 正在启动服务器...
echo 访问地址: http://localhost:3000
echo.
echo 💡 新功能提示:
echo - 支持在线上传Excel文件
echo - 自动状态颜色区分
echo - 自适应页面布局
echo - 批量交易检查
echo.

:: 启动服务器
node usdt_monitor.js
if %errorlevel% neq 0 (
    echo.
    echo ❌ 服务器启动失败
    echo 可能的原因:
    echo - 端口3000被其他程序占用
    echo - 数据文件格式错误
    echo - 网络连接问题
    echo - 依赖包缺失或损坏
    echo.
    echo 🔧 解决方案:
    echo 1. 重新运行此脚本
    echo 2. 手动运行: npm install
    echo 3. 检查防火墙设置
    goto :error_exit
)

goto :end

:error_exit
echo.
echo ========================================
echo 启动失败，请检查上述错误信息
echo ========================================
echo.
echo 📞 需要帮助？
echo - 检查Node.js是否正确安装
echo - 确保网络连接正常
echo - 验证数据文件格式正确
echo.
echo 按任意键退出...
pause >nul
exit /b 1

:end
echo.
echo 系统已停止运行
echo 感谢使用USDT工资监控系统！
echo 按任意键退出...
pause >nul