# USDT工资监控系统 v1.3.1 - 版本检查和自动更新工具 (PowerShell)
# 支持 Windows PowerShell 和 PowerShell Core

param(
    [switch]$AutoUpdate,
    [switch]$Help
)

# 颜色函数
function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-InfoMessage {
    param([string]$Message)
    Write-ColorText "[INFO] $Message" "Green"
}

function Write-WarningMessage {
    param([string]$Message)
    Write-ColorText "[WARNING] $Message" "Yellow"
}

function Write-ErrorMessage {
    param([string]$Message)
    Write-ColorText "[ERROR] $Message" "Red"
}

function Write-StepMessage {
    param([string]$Message)
    Write-ColorText "[STEP] $Message" "Cyan"
}

# 显示帮助信息
function Show-Help {
    Write-Host ""
    Write-ColorText "USDT工资监控系统 - 版本检查工具" "Green"
    Write-Host ""
    Write-Host "用法:"
    Write-Host "  .\version-check.ps1                    # 交互式版本检查"
    Write-Host "  .\version-check.ps1 -AutoUpdate        # 自动更新到最新版本"
    Write-Host "  .\version-check.ps1 -Help              # 显示帮助信息"
    Write-Host ""
    Write-Host "参数:"
    Write-Host "  -AutoUpdate    自动更新，无需确认"
    Write-Host "  -Help          显示帮助信息"
    Write-Host ""
    Write-Host "功能:"
    Write-Host "  - 检查当前版本和最新版本"
    Write-Host "  - 显示版本更新日志"
    Write-Host "  - 自动下载和安装更新"
    Write-Host "  - 备份当前版本"
    Write-Host "  - 更新依赖包"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  .\version-check.ps1                    # 检查版本并询问是否更新"
    Write-Host "  .\version-check.ps1 -AutoUpdate        # 直接自动更新"
    Write-Host ""
}

# 检查运行环境
function Test-Environment {
    Write-StepMessage "检查运行环境..."
    
    # 检查PowerShell版本
    $psVersion = $PSVersionTable.PSVersion
    Write-InfoMessage "PowerShell版本: $psVersion"
    
    # 检查Node.js
    try {
        $nodeVersion = node --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-InfoMessage "Node.js环境正常 ($nodeVersion)"
        } else {
            throw "Node.js未找到"
        }
    } catch {
        Write-ErrorMessage "Node.js未安装，请先安装Node.js"
        Write-Host "下载地址: https://nodejs.org/"
        return $false
    }
    
    # 检查npm
    try {
        $npmVersion = npm --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-InfoMessage "npm环境正常 ($npmVersion)"
        } else {
            throw "npm未找到"
        }
    } catch {
        Write-ErrorMessage "npm未安装"
        return $false
    }
    
    # 检查网络连接
    Write-StepMessage "检查网络连接..."
    try {
        $ping = Test-Connection -ComputerName "github.com" -Count 1 -Quiet -ErrorAction Stop
        if ($ping) {
            Write-InfoMessage "网络连接正常"
        } else {
            Write-WarningMessage "网络连接异常，可能影响版本检查"
        }
    } catch {
        Write-WarningMessage "网络连接检查失败，可能影响版本检查"
    }
    
    # 检查Git
    Write-StepMessage "检查Git环境..."
    try {
        $gitVersion = git --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-InfoMessage "Git环境正常 ($gitVersion)"
            $script:GitAvailable = $true
        } else {
            throw "Git未找到"
        }
    } catch {
        Write-WarningMessage "Git未安装，自动更新功能将不可用"
        Write-Host "下载地址: https://git-scm.com/downloads"
        $script:GitAvailable = $false
    }
    
    return $true
}

# 主函数
function Main {
    Clear-Host
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  USDT工资监控系统 - 版本检查工具" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    
    # 显示帮助
    if ($Help) {
        Show-Help
        return
    }
    
    # 检查环境
    if (-not (Test-Environment)) {
        Write-Host ""
        Write-ErrorMessage "环境检查失败，无法继续"
        return
    }
    
    Write-Host ""
    Write-StepMessage "开始版本检查..."
    Write-Host ""
    
    # 运行Node.js版本检查器
    try {
        if ($AutoUpdate) {
            Write-InfoMessage "🚀 自动更新模式"
            & node version-checker.js --auto-update
        } else {
            Write-InfoMessage "🔍 交互式检查模式"
            & node version-checker.js
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "版本检查器返回错误代码: $LASTEXITCODE"
        }
    } catch {
        Write-Host ""
        Write-ErrorMessage "版本检查失败: $($_.Exception.Message)"
        Write-Host ""
        Write-Host "💡 故障排除:"
        Write-Host "1. 检查网络连接"
        Write-Host "2. 确认GitHub可访问"
        Write-Host "3. 检查防火墙设置"
        Write-Host "4. 稍后重试"
        Write-Host ""
        return
    }
    
    Write-Host ""
    Write-InfoMessage "✅ 版本检查完成"
    Write-Host ""
}

# 运行主函数
Main