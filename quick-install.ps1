# USDT工资监控系统 v1.3.0 - PowerShell一键安装脚本
# 使用方法: iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.ps1 | iex

param(
    [string]$InstallDir = "",
    [int]$Port = 3000
)

# 设置错误处理
$ErrorActionPreference = "Stop"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "[STEP] $Message" "Cyan"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "[INFO] $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "[ERROR] $Message" "Red"
}

# 主函数
function Install-USDTMonitor {
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host "USDT工资监控系统 v1.3.0 一键安装" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    Write-Host ""

    # 配置变量
    $NodeMinVersion = 14
    $ServiceName = "usdt-monitor"
    
    # 检查管理员权限
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    
    if ($IsAdmin) {
        Write-Info "检测到管理员权限"
        if ([string]::IsNullOrEmpty($InstallDir)) {
            $InstallDir = "C:\usdt-monitor"
        }
    } else {
        Write-Warning "非管理员权限，将安装到用户目录"
        if ([string]::IsNullOrEmpty($InstallDir)) {
            $InstallDir = "$env:USERPROFILE\usdt-monitor"
        }
    }

    Write-Info "安装目录: $InstallDir"
    Write-Info "服务端口: $Port"

    # 检查Node.js
    Write-Step "检查Node.js..."
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($majorVersion -ge $NodeMinVersion) {
                Write-Info "Node.js版本检查通过: $nodeVersion"
            } else {
                Write-Warning "Node.js版本过低: $nodeVersion，需要v$NodeMinVersion+"
                Install-NodeJS
            }
        } else {
            throw "Node.js未安装"
        }
    } catch {
        Write-Warning "未检测到Node.js，开始安装..."
        Install-NodeJS
    }

    # 创建安装目录
    Create-InstallDirectory

    # 下载项目文件
    Download-Project

    # 安装依赖
    Install-Dependencies

    # 创建启动脚本
    Create-StartScript

    # 显示结果
    Show-Result
}

# 安装Node.js
function Install-NodeJS {
    Write-Step "安装Node.js..."
    
    try {
        $nodeUrl = "https://nodejs.org/dist/v18.18.0/node-v18.18.0-x64.msi"
        $installerPath = "$env:TEMP\nodejs-installer.msi"
        
        Write-Info "正在下载Node.js安装程序..."
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $nodeUrl -OutFile $installerPath -UseBasicParsing
        
        Write-Info "正在安装Node.js..."
        Start-Process msiexec.exe -ArgumentList "/i", $installerPath, "/quiet", "/norestart" -Wait
        
        Write-Info "Node.js安装完成"
        Remove-Item $installerPath -Force
        
        # 刷新环境变量
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
        
        # 验证安装
        Start-Sleep -Seconds 2
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Info "Node.js安装验证成功: $nodeVersion"
        } else {
            throw "Node.js安装后仍无法使用"
        }
    } catch {
        Write-Error "Node.js安装失败: $($_.Exception.Message)"
        Write-Error "请手动安装Node.js v18+: https://nodejs.org/"
        exit 1
    }
}

# 创建安装目录
function Create-InstallDirectory {
    Write-Step "创建安装目录: $InstallDir"
    
    # 备份旧版本
    if (Test-Path $InstallDir) {
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $backupDir = "$InstallDir.backup.$timestamp"
        Write-Warning "目录已存在，备份旧版本..."
        Move-Item $InstallDir $backupDir
        Write-Info "旧版本已备份到: $backupDir"
    }
    
    # 创建目录
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
    Write-Info "安装目录创建成功"
}

# 下载项目文件
function Download-Project {
    Write-Step "下载项目文件..."
    
    Set-Location $InstallDir
    
    # 检查Git
    try {
        git --version | Out-Null
        Write-Info "使用Git克隆项目..."
        git clone https://github.com/Seanminjie/usdt.git . 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-Info "项目文件下载完成"
            return
        } else {
            Write-Warning "Git克隆失败，创建基本文件结构..."
        }
    } catch {
        Write-Warning "Git未安装，创建基本文件结构..."
    }
    
    # 创建基本文件结构
    Create-BasicFiles
}

# 创建基本文件结构
function Create-BasicFiles {
    Write-Info "创建基本文件结构..."
    
    # 创建package.json
    $packageJson = @{
        name = "usdt-salary-monitor"
        version = "1.3.0"
        description = "USDT工资发放监控系统 - 支持在线上传Excel、自动状态检查、批量操作等功能"
        main = "usdt_monitor.js"
        scripts = @{
            start = "node usdt_monitor.js"
            dev = "node usdt_monitor.js"
            "install-deps" = "npm install"
            "convert-excel" = "node convert_excel.js"
        }
        dependencies = @{
            axios = "^1.6.0"
            express = "^4.18.2"
            multer = "^1.4.5"
            xlsx = "^0.18.5"
        }
        engines = @{
            node = ">=14.0.0"
        }
        keywords = @("usdt", "salary", "monitor", "tron", "blockchain", "excel", "upload", "responsive")
        author = "USDT Monitor Team"
        license = "MIT"
    }
    
    $packageJson | ConvertTo-Json -Depth 10 | Out-File -FilePath "package.json" -Encoding UTF8
    
    # 创建启动脚本
    @"
@echo off
echo 启动USDT工资监控系统...
node usdt_monitor.js
"@ | Out-File -FilePath "start.bat" -Encoding ASCII
    
    Write-Warning "基本文件已创建，请手动复制以下文件到 $InstallDir :"
    Write-Warning "- usdt_monitor.js (主程序文件)"
    Write-Warning "- convert_excel.js (Excel转换工具)"
    Write-Warning "- 员工工资表.xlsx (示例Excel文件)"
    Write-Warning "或者从项目仓库下载完整文件"
}

# 安装依赖
function Install-Dependencies {
    Write-Step "安装项目依赖..."
    
    if (Test-Path "package.json") {
        npm install --production
        if ($LASTEXITCODE -eq 0) {
            Write-Info "依赖安装完成"
        } else {
            Write-Error "依赖安装失败"
            exit 1
        }
    } else {
        Write-Error "package.json文件不存在"
        exit 1
    }
}

# 创建启动脚本
function Create-StartScript {
    Write-Step "创建启动脚本..."
    
    # 创建PowerShell启动脚本
    @"
# USDT工资监控系统启动脚本
Write-Host "启动USDT工资监控系统..." -ForegroundColor Green
Set-Location "$InstallDir"
node usdt_monitor.js
"@ | Out-File -FilePath "$InstallDir\start.ps1" -Encoding UTF8
    
    Write-Info "启动脚本创建完成"
}

# 显示结果
function Show-Result {
    Write-Host ""
    Write-Host "====================================" -ForegroundColor Green
    Write-Host "USDT工资监控系统 v1.3.0 安装完成!" -ForegroundColor Green
    Write-Host "====================================" -ForegroundColor Green
    Write-Host ""
    
    Write-Info "安装目录: $InstallDir"
    Write-Info "访问地址: http://localhost:$Port"
    Write-Info "健康检查: http://localhost:$Port/health"
    Write-Host ""
    
    Write-Info "启动命令:"
    Write-Host "  cd `"$InstallDir`" && npm start" -ForegroundColor White
    Write-Host "  或者运行: $InstallDir\start.ps1" -ForegroundColor White
    Write-Host ""
    
    Write-Info "使用说明:"
    Write-Host "  1. 准备Excel工资表文件" -ForegroundColor White
    Write-Host "  2. 通过网页界面上传Excel文件" -ForegroundColor White
    Write-Host "  3. 系统自动检查USDT交易状态" -ForegroundColor White
    Write-Host "  4. 支持手工确认和批量操作" -ForegroundColor White
    Write-Host ""
    
    Write-Info "如需帮助，请查看: $InstallDir\README.md"
}

# 错误处理
trap {
    Write-Error "安装过程中发生错误: $($_.Exception.Message)"
    Write-Error "请检查网络连接和系统权限"
    exit 1
}

# 运行主程序
Install-USDTMonitor