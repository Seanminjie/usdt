# USDT工资监控系统 v1.3.0 - PowerShell启动脚本
param(
    [switch]$NoAutoOpen,
    [switch]$Verbose
)

# 设置控制台编码
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# 设置错误处理
$ErrorActionPreference = "Stop"

function Write-ColorText {
    param(
        [string]$Text,
        [string]$Color = "White"
    )
    Write-Host $Text -ForegroundColor $Color
}

function Write-Step {
    param(
        [string]$Step,
        [string]$Message
    )
    Write-ColorText "[$Step] $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorText "✅ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorText "⚠️  $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorText "❌ $Message" "Red"
}

function Write-Info {
    param([string]$Message)
    Write-ColorText "💡 $Message" "Blue"
}

Clear-Host
Write-ColorText "========================================" "Green"
Write-ColorText "  USDT工资监控系统 v1.3.1 - PowerShell启动工具" "Green"
Write-ColorText "========================================" "Green"
Write-Host ""
Write-ColorText "当前工作目录: $(Get-Location)" "Gray"
Write-Host ""

try {
    # 检查Node.js
    Write-Step "1/5" "检查Node.js环境..."
    
    try {
        $nodeVersion = node --version 2>$null
        if ($nodeVersion) {
            Write-Success "Node.js已安装 (版本: $nodeVersion)"
            
            # 检查版本是否满足要求
            $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
            if ($majorVersion -lt 14) {
                Write-Warning "Node.js版本过低，建议升级到v14或更高版本"
                Write-Host "当前版本: $nodeVersion" -ForegroundColor Yellow
                Write-Host "最低要求: v14.0.0" -ForegroundColor Yellow
            }
        }
    }
    catch {
        Write-Error "未检测到Node.js"
        Write-Host ""
        Write-Host "正在尝试自动安装Node.js..." -ForegroundColor Yellow
        
        # 检查是否有Chocolatey
        try {
            choco --version 2>$null | Out-Null
            Write-Host "使用Chocolatey安装Node.js..." -ForegroundColor Yellow
            
            # 检查管理员权限
            $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
            $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
            $isAdmin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
            
            if (-not $isAdmin) {
                Write-Warning "需要管理员权限来安装Node.js"
                Write-Host "请以管理员身份运行此脚本，或手动安装Node.js" -ForegroundColor Red
                Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Blue
                Read-Host "按回车键退出"
                exit 1
            }
            
            choco install nodejs -y
            refreshenv
            
            # 重新检查
            $nodeVersion = node --version 2>$null
            if ($nodeVersion) {
                Write-Success "Node.js安装成功 (版本: $nodeVersion)"
            } else {
                throw "Node.js安装失败"
            }
        }
        catch {
            Write-Error "自动安装失败，请手动安装Node.js"
            Write-Host "下载地址: https://nodejs.org/" -ForegroundColor Blue
            Read-Host "按回车键退出"
            exit 1
        }
    }

    # 检查npm依赖
    Write-Host ""
    Write-Step "2/5" "检查项目依赖..."
    
    if (-not (Test-Path "node_modules")) {
        Write-Host "📦 正在安装项目依赖..." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "安装的依赖包括:" -ForegroundColor Gray
        Write-Host "- express: Web服务器框架" -ForegroundColor Gray
        Write-Host "- axios: HTTP客户端" -ForegroundColor Gray
        Write-Host "- multer: 文件上传处理" -ForegroundColor Gray
        Write-Host "- xlsx: Excel文件处理" -ForegroundColor Gray
        Write-Host ""
        
        npm install
        if ($LASTEXITCODE -ne 0) {
            Write-Error "依赖安装失败，请检查网络连接"
            Read-Host "按回车键退出"
            exit 1
        }
    } else {
        Write-Success "项目依赖已存在"
        
        # 检查关键依赖是否存在
        if (-not (Test-Path "node_modules\express")) {
            Write-Warning "检测到依赖不完整，正在重新安装..."
            npm install
        }
    }

    # 检查数据文件
    Write-Host ""
    Write-Step "3/5" "检查数据文件..."
    
    if (-not (Test-Path "employee_data.json")) {
        if (Test-Path "人员2025.07.xlsx") {
            Write-Host "📊 检测到Excel文件，正在转换为JSON格式..." -ForegroundColor Yellow
            node read_excel.js
            if ($LASTEXITCODE -ne 0) {
                Write-Error "数据文件转换失败"
                Read-Host "按回车键退出"
                exit 1
            }
        } else {
            Write-Error "未找到员工数据文件 (employee_data.json 或 人员2025.07.xlsx)"
            Write-Host "请确保数据文件存在于当前目录" -ForegroundColor Red
            Write-Host ""
            Write-Info "提示: 系统启动后可以通过'导入新表单'功能上传Excel文件"
            Read-Host "按回车键退出"
            exit 1
        }
    }
    Write-Success "数据文件检查完成"

    # 环境准备
    Write-Host ""
    Write-Step "4/5" "环境准备..."
    
    # 检查端口占用
    $portInUse = Get-NetTCPConnection -LocalPort 3000 -ErrorAction SilentlyContinue
    if ($portInUse) {
        Write-Warning "端口3000已被占用，正在释放..."
        $portInUse | ForEach-Object {
            try {
                Stop-Process -Id $_.OwningProcess -Force -ErrorAction SilentlyContinue
            } catch {
                # 忽略错误
            }
        }
        Start-Sleep -Seconds 2
    }
    
    # 创建public目录
    if (-not (Test-Path "public")) {
        Write-Host "📁 创建public目录..." -ForegroundColor Yellow
        New-Item -ItemType Directory -Path "public" | Out-Null
    }
    
    Write-Success "环境准备完成"

    # 启动系统
    Write-Host ""
    Write-Step "5/5" "启动USDT工资监控系统 v1.3.0..."
    Write-Host ""
    Write-Host "🚀 系统正在启动，请稍候..." -ForegroundColor Green
    Write-Host ""
    Write-ColorText "========================================" "Green"
    Write-ColorText "系统启动后将自动打开浏览器" "Green"
    Write-ColorText "访问地址: http://localhost:3000" "Green"
    Write-ColorText "按 Ctrl+C 可停止系统" "Green"
    Write-ColorText "========================================" "Green"
    Write-Host ""
    Write-Info "新功能提示:"
    Write-Host "- 支持在线上传Excel文件" -ForegroundColor Gray
    Write-Host "- 自动状态颜色区分" -ForegroundColor Gray
    Write-Host "- 自适应页面布局" -ForegroundColor Gray
    Write-Host "- 批量交易检查" -ForegroundColor Gray
    Write-Host "- 手工确认功能" -ForegroundColor Gray
    Write-Host ""

    # 启动服务器
    Write-Host "正在启动服务器..." -ForegroundColor Yellow
    $job = Start-Job -ScriptBlock { 
        Set-Location $using:PWD
        node usdt_monitor.js 
    }
    
    # 等待服务器启动
    Write-Host "等待服务器启动..." -ForegroundColor Yellow
    Start-Sleep -Seconds 3
    
    # 检查服务器是否启动成功
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 5 -ErrorAction Stop
        Write-Success "服务器启动成功！"
    }
    catch {
        Write-Error "服务器启动失败"
        Write-Host "可能的原因:" -ForegroundColor Red
        Write-Host "1. 端口3000被其他程序占用" -ForegroundColor Red
        Write-Host "2. 防火墙阻止了连接" -ForegroundColor Red
        Write-Host "3. Node.js版本不兼容" -ForegroundColor Red
        
        # 停止后台任务
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -ErrorAction SilentlyContinue
        
        Read-Host "按回车键退出"
        exit 1
    }

    # 打开浏览器
    if (-not $NoAutoOpen) {
        Write-Host "正在打开浏览器..." -ForegroundColor Yellow
        Start-Process "http://localhost:3000"
    }

    Write-Host ""
    Write-Success "系统已启动完成！"
    Write-Host ""
    Write-Info "使用提示:"
    Write-Host "   - 浏览器会自动打开系统页面" -ForegroundColor Gray
    Write-Host "   - 如果浏览器未自动打开，请手动访问: http://localhost:3000" -ForegroundColor Gray
    Write-Host "   - 要停止系统，请按 Ctrl+C 或关闭此窗口" -ForegroundColor Gray
    Write-Host "   - 可以通过'导入新表单'按钮上传新的Excel文件" -ForegroundColor Gray
    Write-Host "   - 支持自动检查和手工确认两种方式" -ForegroundColor Gray
    Write-Host ""
    
    # 等待用户输入或作业完成
    Write-Host "按 Ctrl+C 停止系统，或按任意键查看服务器日志..." -ForegroundColor Yellow
    
    # 监控作业状态
    while ($job.State -eq "Running") {
        if ([Console]::KeyAvailable) {
            $key = [Console]::ReadKey($true)
            if ($key.Key -eq "C" -and $key.Modifiers -eq "Control") {
                break
            }
            # 显示作业输出
            Receive-Job $job
        }
        Start-Sleep -Milliseconds 100
    }
    
    # 清理
    Stop-Job $job -ErrorAction SilentlyContinue
    Remove-Job $job -ErrorAction SilentlyContinue

} catch {
    Write-Error "启动过程中发生错误: $($_.Exception.Message)"
    Write-Host ""
    Write-Host "错误详情:" -ForegroundColor Red
    Write-Host $_.Exception.ToString() -ForegroundColor Red
    Write-Host ""
    Write-Host "请检查以下项目:" -ForegroundColor Yellow
    Write-Host "1. Node.js是否正确安装" -ForegroundColor Yellow
    Write-Host "2. 网络连接是否正常" -ForegroundColor Yellow
    Write-Host "3. 防火墙设置是否正确" -ForegroundColor Yellow
    Write-Host "4. 是否有足够的磁盘空间" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "按回车键退出"
    exit 1
}