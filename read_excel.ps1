# PowerShell脚本读取Excel文件

# 检查是否已安装ImportExcel模块
$moduleInstalled = Get-Module -ListAvailable -Name ImportExcel
if (-not $moduleInstalled) {
    Write-Host "正在安装ImportExcel模块..."
    Install-Module -Name ImportExcel -Force -Scope CurrentUser
}

# 读取Excel文件
try {
    $excelPath = "$PSScriptRoot\人员2025.07.xlsx"
    $jsonPath = "$PSScriptRoot\employee_data.json"
    
    Write-Host "正在读取Excel文件: $excelPath"
    
    # 读取Excel文件
    $data = Import-Excel -Path $excelPath
    
    # 将数据转换为JSON并保存
    $jsonData = $data | ConvertTo-Json -Depth 4 -Encoding UTF8
    $jsonData | Out-File -FilePath $jsonPath -Encoding utf8
    
    Write-Host "Excel文件已成功转换为JSON格式并保存为employee_data.json"
    
    # 显示前5行数据作为预览
    Write-Host "\n数据预览:"
    $data | Select-Object -First 5 | Format-Table
    
} catch {
    Write-Host "发生错误: $_"
}