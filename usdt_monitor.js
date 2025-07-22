/**
 * USDT交易监控系统
 * 用于监控和分析员工USDT工资的接收情况
 */

const fs = require('fs');
const path = require('path');
const axios = require('axios');
const express = require('express');
const bodyParser = require('body-parser');
const multer = require('multer');
const XLSX = require('xlsx');

// 创建Express应用
const app = express();
const PORT = 3000;

// 配置multer用于文件上传
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, './') // 保存到当前目录
  },
  filename: function (req, file, cb) {
    // 保存为原文件名，但添加时间戳避免冲突
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    const ext = path.extname(file.originalname);
    const name = path.basename(file.originalname, ext);
    cb(null, `${name}_${timestamp}${ext}`)
  }
});

const upload = multer({ 
  storage: storage,
  fileFilter: function (req, file, cb) {
    // 只允许Excel文件
    if (file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' || 
        file.originalname.endsWith('.xlsx')) {
      cb(null, true);
    } else {
      cb(new Error('只允许上传Excel文件(.xlsx)'));
    }
  }
});

// 使用中间件
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public'));

// 全局变量
let employeeData = [];
let validEmployees = [];

// 加载员工数据的函数
function loadEmployeeData() {
  try {
    const data = fs.readFileSync('employee_data.json', 'utf8');
    employeeData = JSON.parse(data);
    console.log(`成功加载了${employeeData.length}条员工记录`);
    
    // 过滤有效的员工数据（有USDT地址的记录）
    validEmployees = employeeData.filter(emp => emp.地址 && emp['实发薪资（usdt）']);
    console.log(`有效员工记录数量: ${validEmployees.length}`);
    
    // 初始化员工状态
    validEmployees.forEach(emp => {
      emp.status = '待确认';
      emp.txHash = '';
      emp.manualConfirm = false;
      emp.otherCurrency = false; // 标记是否使用其他币种支付
      emp.amount = null; // 初始实收金额：空
      emp.txTime = null; // 初始交易时间：空
      emp.notCurrentMonth = false; // 标记是否不是当月记录
      emp.amountDifference = false; // 标记金额是否有差异
    });
    
    return true;
  } catch (error) {
    console.error('读取员工数据失败:', error.message);
    return false;
  }
}

// 处理Excel文件并转换为JSON的函数
function processExcelFile(filePath) {
  try {
    console.log(`正在处理Excel文件: ${filePath}`);
    
    // 读取Excel文件
    const workbook = XLSX.readFile(filePath);
    
    // 获取第一个工作表
    const sheetName = workbook.SheetNames[0];
    const worksheet = workbook.Sheets[sheetName];
    
    // 将工作表转换为JSON
    const data = XLSX.utils.sheet_to_json(worksheet);
    
    // 将数据保存为JSON文件
    fs.writeFileSync('employee_data.json', JSON.stringify(data, null, 2), 'utf8');
    
    console.log('Excel文件已成功转换为JSON格式并保存为employee_data.json');
    console.log(`数据预览: ${data.length}条记录`);
    
    return true;
  } catch (error) {
    console.error(`处理Excel文件失败: ${error.message}`);
    return false;
  }
}

// 初始加载员工数据
loadEmployeeData();

// 创建HTML页面
const createHtml = () => {
  // 生成员工表格行HTML
let employeeRows = '';
validEmployees.forEach((emp, index) => {
  // 设置行的CSS类，根据不同情况应用不同样式
  let rowClass = '';
  if (emp.otherCurrency) {
    rowClass = 'other-currency-row';
  } else if (emp.notCurrentMonth && !emp.amountDifference) {
    rowClass = 'not-current-month-row';
  } else if (emp.amountDifference) {
    rowClass = 'amount-difference-row';
  }
  
  // 格式化交易时间
  const txTime = emp.txTime ? new Date(emp.txTime).toLocaleString('zh-CN') : '-';
  
  // 根据状态设置不同的CSS类
  let statusClass = 'status-pending'; // 默认待确认
  if (emp.status === '已确认') {
    statusClass = 'status-confirmed';
  } else if (emp.status === '手工确认') {
    statusClass = 'status-manual';
  } else if (emp.status === '金额有差异') {
    statusClass = 'status-amount-difference';
  } else if (emp.status === '非当月金额差异') {
    statusClass = 'status-not-current-month-difference';
  } else if (emp.status === '非当月确认') {
    statusClass = 'status-not-current-month';
  } else if (emp.status === '未找到交易' || emp.status === '检查失败') {
    statusClass = 'status-failed';
  } else if (emp.status === '检查中...') {
    statusClass = 'status-checking';
  }
  
  employeeRows += `
    <tr data-index="${index}" class="${rowClass}">
      <td>${emp.__EMPTY || '未命名'}</td>
      <td>${emp.部门 || '-'}</td>
      <td>${emp['实发薪资（usdt）']}</td>
      <td><a href="https://tronscan.org/#/address/${emp.地址}" target="_blank">${emp.地址}</a></td>
      <td class="${statusClass}">${emp.status}</td>
      <td>${emp.txHash ? `<a href="https://tronscan.org/#/transaction/${emp.txHash}" target="_blank">${emp.txHash.substring(0, 10)}...</a>` : (emp.manualConfirm ? '手工确认 - 其他币种' : '-')}</td>
      <td class="${emp.amount && emp.amount > emp['实发薪资（usdt）'] ? 'amount-higher' : (emp.amount && emp.amount < emp['实发薪资（usdt）'] ? 'amount-lower' : '')}">${emp.amount || '-'} ${emp.amountDifference ? (emp.amount > emp['实发薪资（usdt）'] ? '(高于预期)' : '(低于预期)') : ''}</td>
      <td>${txTime}</td>
      <td class="text-center">
        <div class="d-flex justify-content-center">
          <button class="btn btn-sm btn-primary check-transaction" data-address="${emp.地址}">自动检查</button>
          <button class="btn btn-sm btn-success ms-2 manual-confirm" data-index="${index}">手工确认</button>
        </div>
      </td>
    </tr>
  `;
});

  const html = `
  <!DOCTYPE html>
  <html lang="zh-CN">
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>USDT工资监控系统</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
      body { padding: 20px; max-width: none; }
      
      /* 不同状态使用不同颜色 - 统一使用高对比度颜色 */
      .status-pending { color: #e67e00; font-weight: bold; } /* 待确认 - 橙色 (对比度 > 4.5) */
      .status-confirmed { color: #2d8f47; font-weight: bold; } /* 已确认 - 绿色 (对比度 > 4.5) */
      .status-manual { color: #0056b3; font-weight: bold; } /* 手工确认 - 蓝色 (对比度 > 4.5) */
      .status-amount-difference { color: #0056b3; font-weight: bold; } /* 金额有差异 - 蓝色 (对比度 > 4.5) */
      .status-not-current-month-difference { color: #0056b3; font-weight: bold; } /* 非当月金额差异 - 蓝色 (对比度 > 4.5) */
      .status-not-current-month { color: #d73027; font-weight: bold; } /* 非当月确认 - 红色 (对比度 > 4.5) */
      .status-failed { color: #d73027; font-weight: bold; } /* 检查失败 - 红色 (对比度 > 4.5) */
      .status-checking { color: #008080; font-weight: bold; } /* 检查中 - 青色 (对比度 > 4.5) */
      
      .dashboard-card { margin-bottom: 20px; }
      .action-buttons { margin-top: 20px; }
      .other-currency-row { background-color: #f8f9fa; } /* 其他币种行的背景色 */
      .not-current-month-row { background-color: #ffe6e6; } /* 非当月记录的背景色 */
      .amount-difference-row { background-color: #e6f7ff; } /* 金额有差异的背景色 */
      
      /* 表格样式优化 */
      table.table th {
        background-color: #f0f0f0;
        vertical-align: middle;
        text-align: center;
      }
      table.table td {
        vertical-align: middle;
      }
      /* 确保按钮容器有足够的宽度 */
      table.table td:last-child {
        min-width: 200px;
      }
      
      /* 金额差异提示 - 使用高对比度颜色 */
      .amount-higher { color: #2d8f47; } /* 实收金额高于应发金额 - 绿色 (对比度 > 4.5) */
      .amount-lower { color: #d73027; } /* 实收金额低于应发金额 - 红色 (对比度 > 4.5) */
      
      /* 移除容器宽度限制，使页面自适应 */
      .container-fluid { padding: 0 20px; }
    </style>
  </head>
  <body>
    <div class="container-fluid">
      <h1 class="mb-4">USDT工资监控系统</h1>
      
      <div class="row">
        <div class="col-md-4">
          <div class="card dashboard-card">
            <div class="card-body">
              <h5 class="card-title">总员工数</h5>
              <h2 id="total-employees">${validEmployees.length}</h2>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="card dashboard-card">
            <div class="card-body">
              <h5 class="card-title">已确认收款</h5>
              <h2 id="confirmed-count">0</h2>
            </div>
          </div>
        </div>
        <div class="col-md-4">
          <div class="card dashboard-card">
            <div class="card-body">
              <h5 class="card-title">待确认收款</h5>
              <h2 id="pending-count">${validEmployees.length}</h2>
            </div>
          </div>
        </div>
      </div>

      <div class="action-buttons">
        <button id="check-all" class="btn btn-primary">检查所有交易</button>
        <button id="export-report" class="btn btn-success ms-2">导出报告</button>
        <button id="upload-btn" class="btn btn-warning ms-2" data-bs-toggle="modal" data-bs-target="#uploadModal">导入新表单</button>
      </div>
      
      <!-- 文件上传模态框 -->
      <div class="modal fade" id="uploadModal" tabindex="-1" aria-labelledby="uploadModalLabel" aria-hidden="true">
        <div class="modal-dialog">
          <div class="modal-content">
            <div class="modal-header">
              <h5 class="modal-title" id="uploadModalLabel">导入新的工资表单</h5>
              <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body">
              <form id="uploadForm" enctype="multipart/form-data">
                <div class="mb-3">
                  <label for="excelFile" class="form-label">选择Excel文件 (.xlsx)</label>
                  <input type="file" class="form-control" id="excelFile" name="excelFile" accept=".xlsx" required>
                  <div class="form-text">请选择包含员工工资信息的Excel文件，格式应与现有表单一致。</div>
                </div>
                <div class="alert alert-info">
                  <strong>注意：</strong>
                  <ul class="mb-0">
                    <li>文件格式必须为 .xlsx</li>
                    <li>表格应包含：员工姓名、部门、实发薪资（usdt）、地址等列</li>
                    <li>上传后将替换当前的员工数据</li>
                    <li>建议先备份当前数据</li>
                  </ul>
                </div>
              </form>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">取消</button>
              <button type="button" class="btn btn-primary" id="uploadSubmit">上传并导入</button>
            </div>
          </div>
        </div>
      </div>
      
      <div class="mt-3 mb-3 p-3 border rounded bg-light">
        <h5>颜色说明：</h5>
        <div class="row">
          <div class="col-md-3">
            <div class="p-2 other-currency-row">其他币种支付</div>
          </div>
          <div class="col-md-3">
            <div class="p-2 not-current-month-row">非当月交易记录</div>
          </div>
          <div class="col-md-3">
            <div class="p-2 amount-difference-row">金额有差异</div>
          </div>
          <div class="col-md-3">
            <div><span class="amount-higher">高于预期金额</span> / <span class="amount-lower">低于预期金额</span></div>
          </div>
        </div>
      </div>

      <div class="mt-4">
        <input type="text" id="search-input" class="form-control mb-3" placeholder="搜索员工姓名或地址...">
        <div class="form-check mb-3">
          <input class="form-check-input" type="checkbox" id="show-other-currency">
          <label class="form-check-label" for="show-other-currency">
            显示其他币种支付的员工
          </label>
        </div>
        <div class="table-responsive">
          <table class="table table-striped">
            <thead>
              <tr>
                <th width="10%">员工姓名</th>
                <th width="10%">部门</th>
                <th width="10%">应发金额(USDT)</th>
                <th width="15%">USDT地址</th>
                <th width="8%">状态</th>
                <th width="12%">交易哈希</th>
                <th width="10%">实收金额</th>
                <th width="10%">交易时间</th>
                <th width="15%">操作</th>
              </tr>
            </thead>
            <tbody id="employee-table">
              ${employeeRows}
            </tbody>
          </table>
        </div>
      </div>
    </div>

    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"></script>
    <script>
      // 客户端JavaScript代码
      document.addEventListener('DOMContentLoaded', function() {
        // 搜索功能
        document.getElementById('search-input').addEventListener('keyup', function() {
          filterEmployees();
        });
        
        // 其他币种过滤功能
        document.getElementById('show-other-currency').addEventListener('change', function() {
          filterEmployees();
        });
        
        // 过滤员工列表
        function filterEmployees() {
          const searchValue = document.getElementById('search-input').value.toLowerCase();
          const showOtherCurrency = document.getElementById('show-other-currency').checked;
          const rows = document.querySelectorAll('#employee-table tr');
          
          rows.forEach(row => {
            const text = row.textContent.toLowerCase();
            const matchesSearch = text.includes(searchValue);
            const isOtherCurrency = row.classList.contains('other-currency-row');
            
            // 如果是其他币种的行，只有在勾选显示其他币种时才显示
            if (isOtherCurrency && !showOtherCurrency) {
              row.style.display = 'none';
            } else {
              row.style.display = matchesSearch ? '' : 'none';
            }
          });
        }

        // 检查单个交易
        document.querySelectorAll('.check-transaction').forEach(button => {
          button.addEventListener('click', async function() {
            const address = this.getAttribute('data-address');
            const row = this.closest('tr');
            const statusCell = row.querySelector('td:nth-child(5)');
            const hashCell = row.querySelector('td:nth-child(6)');
            const amountCell = row.querySelector('td:nth-child(7)');
            const timeCell = row.querySelector('td:nth-child(8)');
            
            statusCell.textContent = '检查中...';
            statusCell.className = 'status-checking';
            
            try {
              const response = await fetch('/api/check-transaction?address=' + address);
              const data = await response.json();
              
              if (data.success) {
                if (data.confirmed) {
                  // 显示金额，并检查是否有差异
                  const expectedAmount = parseFloat(row.querySelector('td:nth-child(3)').textContent);
                  const actualAmount = data.amount;
                  
                  // 检查金额差异
                  const hasDifference = data.hasAmountDifference || Math.abs(actualAmount - expectedAmount) > 0.01;
                  
                  // 根据是否为当月记录和是否有金额差异设置不同状态
                  if (hasDifference && data.isCurrentMonth) {
                    // 当月交易但金额有差异
                    statusCell.textContent = '金额有差异';
                    statusCell.className = 'status-amount-difference';
                    row.classList.add('amount-difference-row');
                    row.classList.remove('not-current-month-row');
                  } else if (hasDifference && data.notCurrentMonth) {
                    // 非当月交易且金额有差异
                    statusCell.textContent = '非当月金额差异';
                    statusCell.className = 'status-not-current-month-difference';
                    row.classList.add('amount-difference-row');
                    row.classList.remove('not-current-month-row');
                  } else if (data.notCurrentMonth && !hasDifference) {
                    // 非当月交易但金额无差异
                    statusCell.textContent = '非当月确认';
                    statusCell.className = 'status-not-current-month';
                    row.classList.add('not-current-month-row');
                    row.classList.remove('amount-difference-row');
                  } else {
                    // 当月交易且金额无差异
                    statusCell.textContent = '已确认';
                    statusCell.className = 'status-confirmed';
                    row.classList.remove('not-current-month-row');
                    row.classList.remove('amount-difference-row');
                  }
                  
                  hashCell.innerHTML = '<a href="https://tronscan.org/#/transaction/' + data.txHash + '" target="_blank">' + data.txHash.substring(0, 10) + '...</a>';
                  
                  // 设置金额显示
                  if (hasDifference) {
                    if (actualAmount > expectedAmount) {
                      amountCell.className = 'amount-higher';
                      amountCell.textContent = actualAmount + ' (高于预期)';
                    } else {
                      amountCell.className = 'amount-lower';
                      amountCell.textContent = actualAmount + ' (低于预期)';
                    }
                  } else {
                    amountCell.className = '';
                    amountCell.textContent = actualAmount;
                  }
                  
                  // 显示交易时间
                  if (data.txTime) {
                    const txDate = new Date(data.txTime);
                    timeCell.textContent = txDate.toLocaleString('zh-CN');
                  } else {
                    timeCell.textContent = '-';
                  }
                  
                  updateDashboard();
                } else {
                  statusCell.textContent = '未找到交易';
                  statusCell.className = 'status-failed';
                }
              } else {
                statusCell.textContent = '检查失败';
                statusCell.className = 'status-failed';
              }
            } catch (error) {
              statusCell.textContent = '检查失败';
              statusCell.className = 'status-failed';
              console.error('检查交易失败:', error);
            }
          });
        });
        
        // 手工确认功能
        document.querySelectorAll('.manual-confirm').forEach(button => {
          button.addEventListener('click', function() {
            const row = this.closest('tr');
            const statusCell = row.querySelector('td:nth-child(5)');
            const hashCell = row.querySelector('td:nth-child(6)');
            const amountCell = row.querySelector('td:nth-child(7)');
            const timeCell = row.querySelector('td:nth-child(8)');
            const index = this.getAttribute('data-index');
            
            // 弹出确认对话框
            const confirmResult = confirm('确认此员工已通过其他币种支付工资？');
            if (confirmResult) {
              // 禁用按钮，防止重复点击
              this.disabled = true;
              this.textContent = '处理中...';
              
              statusCell.textContent = '手工确认';
              statusCell.className = 'status-manual';
              hashCell.textContent = '手工确认 - 其他币种';
              
              // 获取当前时间作为手工确认时间
              const now = new Date();
              timeCell.textContent = now.toLocaleString('zh-CN');
              
              // 显示应发金额作为实收金额
              const expectedAmount = row.querySelector('td:nth-child(3)').textContent;
              amountCell.textContent = expectedAmount;
              
              // 发送到服务器记录手工确认
              fetch('/api/manual-confirm', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({ 
                  index: index,
                  confirmTime: now.toISOString()
                })
              }).then(response => response.json())
                .then(data => {
                  if (data.success) {
                    console.log('手工确认成功');
                    updateDashboard();
                  } else {
                    console.error('手工确认失败:', data.message);
                    alert('手工确认失败: ' + data.message);
                  }
                  // 恢复按钮状态
                  this.disabled = false;
                  this.textContent = '手工确认';
                })
                .catch(error => {
                  console.error('手工确认失败:', error);
                  alert('手工确认失败，请查看控制台获取详细信息');
                  // 恢复按钮状态
                  this.disabled = false;
                  this.textContent = '手工确认';
              });
            }
          });
        });

        // 检查所有交易
        document.getElementById('check-all').addEventListener('click', async function() {
          this.disabled = true;
          this.textContent = '检查中...';
          
          const buttons = document.querySelectorAll('.check-transaction');
          let confirmedCount = 0;
          
          for (const button of buttons) {
            const address = button.getAttribute('data-address');
            const row = button.closest('tr');
            const statusCell = row.querySelector('td:nth-child(5)');
            const hashCell = row.querySelector('td:nth-child(6)');
            
            statusCell.textContent = '检查中...';
            statusCell.className = 'status-checking';
            
            try {
              const response = await fetch('/api/check-transaction?address=' + address);
              const data = await response.json();
              
              if (data.success) {
                if (data.confirmed) {
                  // 显示金额，并检查是否有差异
                  const amountCell = row.querySelector('td:nth-child(7)');
                  const timeCell = row.querySelector('td:nth-child(8)');
                  const expectedAmount = parseFloat(row.querySelector('td:nth-child(3)').textContent);
                  const actualAmount = data.amount;
                  
                  // 检查金额差异
                  const hasDifference = data.hasAmountDifference || Math.abs(actualAmount - expectedAmount) > 0.01;
                  
                  // 根据是否为当月记录和是否有金额差异设置不同状态
                  if (hasDifference && data.isCurrentMonth) {
                    // 当月交易但金额有差异
                    statusCell.textContent = '金额有差异';
                    statusCell.className = 'status-amount-difference';
                    row.classList.add('amount-difference-row');
                    row.classList.remove('not-current-month-row');
                  } else if (hasDifference && data.notCurrentMonth) {
                    // 非当月交易且金额有差异
                    statusCell.textContent = '非当月金额差异';
                    statusCell.className = 'status-not-current-month-difference';
                    row.classList.add('amount-difference-row');
                    row.classList.remove('not-current-month-row');
                  } else if (data.notCurrentMonth && !hasDifference) {
                    // 非当月交易但金额无差异
                    statusCell.textContent = '非当月确认';
                    statusCell.className = 'status-not-current-month';
                    row.classList.add('not-current-month-row');
                    row.classList.remove('amount-difference-row');
                  } else {
                    // 当月交易且金额无差异
                    statusCell.textContent = '已确认';
                    statusCell.className = 'status-confirmed';
                    row.classList.remove('not-current-month-row');
                    row.classList.remove('amount-difference-row');
                    confirmedCount++;
                  }
                  
                  hashCell.innerHTML = '<a href="https://tronscan.org/#/transaction/' + data.txHash + '" target="_blank">' + data.txHash.substring(0, 10) + '...</a>';
                  
                  // 设置金额显示
                  if (hasDifference) {
                    if (actualAmount > expectedAmount) {
                      amountCell.className = 'amount-higher';
                      amountCell.textContent = actualAmount + ' (高于预期)';
                    } else {
                      amountCell.className = 'amount-lower';
                      amountCell.textContent = actualAmount + ' (低于预期)';
                    }
                  } else {
                    amountCell.className = '';
                    amountCell.textContent = actualAmount;
                  }
                  
                  timeCell.textContent = new Date(data.txTime).toLocaleString('zh-CN');
                } else {
                  statusCell.textContent = '未找到交易';
                  statusCell.className = 'status-failed';
                }
              } else {
                statusCell.textContent = '检查失败';
                statusCell.className = 'status-failed';
              }
            } catch (error) {
              statusCell.textContent = '检查失败';
              statusCell.className = 'status-failed';
              console.error('检查交易失败:', error);
            }
            
            // 添加延迟以避免API限制
            await new Promise(resolve => setTimeout(resolve, 500));
          }
          
          this.disabled = false;
          this.textContent = '检查所有交易';
          updateDashboard();
        });

        // 导出报告
        document.getElementById('export-report').addEventListener('click', function() {
          const rows = document.querySelectorAll('#employee-table tr');
          let csv = '员工姓名,部门,岗位,应发金额(USDT),USDT地址,状态,交易哈希\\n';
          
          rows.forEach(row => {
            const columns = row.querySelectorAll('td');
            const rowData = [];
            
            columns.forEach((column, index) => {
              if (index !== 7) { // 跳过"操作"列
                let text = column.textContent.trim();
                // 处理链接
                if (index === 4 || index === 6) {
                  const link = column.querySelector('a');
                  text = link ? link.textContent.trim() : text;
                }
                rowData.push('"' + text + '"');
              }
            });
            
            csv += rowData.join(',') + '\\n';
          });
          
          const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
          const url = URL.createObjectURL(blob);
          const link = document.createElement('a');
          link.setAttribute('href', url);
          link.setAttribute('download', 'usdt_salary_report_' + new Date().toISOString().split('T')[0] + '.csv');
          link.style.visibility = 'hidden';
          document.body.appendChild(link);
          link.click();
          document.body.removeChild(link);
        });

        // 更新仪表板
        function updateDashboard() {
          const confirmedCount = document.querySelectorAll('.status-confirmed').length;
          const totalCount = document.getElementById('total-employees').textContent;
          
          document.getElementById('confirmed-count').textContent = confirmedCount;
          document.getElementById('pending-count').textContent = totalCount - confirmedCount;
        }
        
        // 文件上传处理
        document.getElementById('uploadSubmit').addEventListener('click', async function() {
          const fileInput = document.getElementById('excelFile');
          const file = fileInput.files[0];
          
          if (!file) {
            alert('请选择一个Excel文件');
            return;
          }
          
          if (!file.name.endsWith('.xlsx')) {
            alert('请选择.xlsx格式的Excel文件');
            return;
          }
          
          // 禁用按钮，显示上传状态
          this.disabled = true;
          this.textContent = '上传中...';
          
          const formData = new FormData();
          formData.append('excelFile', file);
          
          try {
            const response = await fetch('/api/upload-excel', {
              method: 'POST',
              body: formData
            });
            
            const result = await response.json();
            
            if (result.success) {
              alert('文件上传成功！页面将刷新以显示新数据。');
              // 关闭模态框
              const modal = bootstrap.Modal.getInstance(document.getElementById('uploadModal'));
              modal.hide();
              // 刷新页面以显示新数据
              window.location.reload();
            } else {
              alert('上传失败：' + result.message);
            }
          } catch (error) {
            console.error('上传失败:', error);
            alert('上传失败，请检查网络连接或文件格式');
          } finally {
            // 恢复按钮状态
            this.disabled = false;
            this.textContent = '上传并导入';
          }
        });
        
        // 重置文件输入框当模态框关闭时
        document.getElementById('uploadModal').addEventListener('hidden.bs.modal', function() {
          document.getElementById('excelFile').value = '';
        });
      });
    </script>
  </body>
  </html>
  `;

  // 确保public目录存在
  if (!fs.existsSync('public')) {
    fs.mkdirSync('public');
  }

  // 写入HTML文件
  fs.writeFileSync('public/index.html', html, 'utf8');
  console.log('已生成HTML页面');
};

// 创建HTML页面
createHtml();

// 健康检查端点（用于Docker和监控）
app.get('/health', (req, res) => {
  try {
    const healthStatus = {
      status: 'healthy',
      timestamp: new Date().toISOString(),
      version: '1.3.0',
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      employeeCount: validEmployees ? validEmployees.length : 0,
      services: {
        express: 'running',
        fileSystem: fs.existsSync('./') ? 'accessible' : 'error'
      }
    };
    
    res.status(200).json(healthStatus);
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      error: error.message
    });
  }
});

// API路由：检查交易
app.get('/api/check-transaction', async (req, res) => {
  const { address } = req.query;
  
  if (!address) {
    return res.status(400).json({ success: false, message: '缺少地址参数' });
  }

  try {
    // 查找该地址对应的员工记录
    const employee = validEmployees.find(emp => emp.地址.toLowerCase() === address.toLowerCase());
    
    if (!employee) {
      return res.status(404).json({ success: false, message: '未找到该地址对应的员工记录' });
    }

    // 调用Tron API检查交易
    const transactionInfo = await checkTronTransaction(address, employee['实发薪资（usdt）']);
    
    // 如果交易已确认，更新HTML页面
    if (transactionInfo.confirmed) {
      // 更新HTML页面
      createHtml();
    }
    
    return res.json({
      success: true,
      confirmed: transactionInfo.confirmed,
      txHash: transactionInfo.txHash,
      amount: transactionInfo.amount,
      txTime: transactionInfo.txTime,
      isCurrentMonth: transactionInfo.isCurrentMonth,
      notCurrentMonth: transactionInfo.notCurrentMonth
    });
  } catch (error) {
    console.error('检查交易失败:', error);
    return res.status(500).json({ success: false, message: '检查交易失败' });
  }
});

// API路由：手工确认
app.post('/api/manual-confirm', (req, res) => {
  const { index, confirmTime } = req.body;
  
  if (index === undefined) {
    return res.status(400).json({ success: false, message: '缺少员工索引参数' });
  }

  try {
    // 记录手工确认状态
    if (validEmployees[index]) {
      validEmployees[index].status = '手工确认';
      validEmployees[index].manualConfirm = true;
      validEmployees[index].otherCurrency = true; // 标记为其他币种支付
      validEmployees[index].txTime = confirmTime || new Date().toISOString(); // 记录确认时间
      validEmployees[index].amount = validEmployees[index]['实发薪资（usdt）']; // 设置金额为应发金额
      
      // 更新HTML页面
      createHtml();
      
      // 这里可以添加持久化存储逻辑
      // 例如：将更新后的员工数据写入JSON文件
      fs.writeFileSync('employee_data_updated.json', JSON.stringify(validEmployees, null, 2), 'utf8');
      
      return res.json({ success: true });
    } else {
      return res.status(404).json({ success: false, message: '未找到该索引对应的员工记录' });
    }
  } catch (error) {
    console.error('手工确认失败:', error);
    return res.status(500).json({ success: false, message: '手工确认失败' });
  }
});

// API路由：上传Excel文件
app.post('/api/upload-excel', upload.single('excelFile'), (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: '没有上传文件' });
    }
    
    console.log('收到文件上传:', req.file.filename);
    
    // 处理Excel文件
    const success = processExcelFile(req.file.path);
    
    if (success) {
      // 重新加载员工数据
      const loadSuccess = loadEmployeeData();
      
      if (loadSuccess) {
        // 重新生成HTML页面
        createHtml();
        
        // 删除上传的临时文件
        try {
          fs.unlinkSync(req.file.path);
        } catch (deleteError) {
          console.warn('删除临时文件失败:', deleteError.message);
        }
        
        console.log('文件上传和处理成功');
        return res.json({ 
          success: true, 
          message: '文件上传成功，数据已更新',
          employeeCount: validEmployees.length
        });
      } else {
        return res.status(500).json({ success: false, message: '重新加载数据失败' });
      }
    } else {
      // 删除上传的临时文件
      try {
        fs.unlinkSync(req.file.path);
      } catch (deleteError) {
        console.warn('删除临时文件失败:', deleteError.message);
      }
      
      return res.status(500).json({ success: false, message: '处理Excel文件失败' });
    }
  } catch (error) {
    console.error('文件上传失败:', error);
    
    // 删除上传的临时文件（如果存在）
    if (req.file && req.file.path) {
      try {
        fs.unlinkSync(req.file.path);
      } catch (deleteError) {
        console.warn('删除临时文件失败:', deleteError.message);
      }
    }
    
    return res.status(500).json({ success: false, message: '文件上传失败: ' + error.message });
  }
});

/**
 * 检查Tron交易
 * @param {string} address - USDT地址
 * @param {number} expectedAmount - 预期金额
 * @returns {Promise<Object>} - 交易信息
 */
async function checkTronTransaction(address, expectedAmount) {
  try {
    // 使用Tron API查询交易
    const response = await axios.get(`https://api.trongrid.io/v1/accounts/${address}/transactions/trc20`, {
      params: {
        limit: 50,  // 增加查询数量以便找到更多交易
        contract_address: 'TR7NHqjeKQxGTCi8q8ZY4pL8otSzgjLj6t' // USDT合约地址
      }
    });
    
    // 获取当前月份
    const currentDate = new Date();
    const currentMonth = currentDate.getMonth();
    const currentYear = currentDate.getFullYear();
    
    // 处理响应数据
    const transactions = response.data.data;
    
    // 查找当月交易
    let exactMatchTx = null;      // 精确匹配的交易
    let closeMatchTx = null;      // 金额相近的交易
    let anyCurrentMonthTx = null; // 任何当月交易
    
    // 查找非当月交易
    let exactMatchNonCurrentTx = null;  // 精确匹配的非当月交易
    let closeMatchNonCurrentTx = null;  // 金额相近的非当月交易
    
    transactions.forEach(tx => {
      // 检查是否是收款交易
      if (tx.to.toLowerCase() === address.toLowerCase()) {
        const txAmount = parseInt(tx.value) / 1000000; // USDT有6位小数
        const txDate = new Date(tx.block_timestamp);
        const isSameMonth = txDate.getMonth() === currentMonth && txDate.getFullYear() === currentYear;
        
        if (isSameMonth) {
          // 当月交易
          if (Math.abs(txAmount - expectedAmount) < 0.01) {
            // 精确匹配（误差小于0.01）
            if (!exactMatchTx) exactMatchTx = tx;
          } else if (Math.abs(txAmount - expectedAmount) < expectedAmount * 0.5) {
            // 金额相近（误差小于50%）
            if (!closeMatchTx) closeMatchTx = tx;
          }
          // 记录任何当月交易
          if (!anyCurrentMonthTx) anyCurrentMonthTx = tx;
        } else {
          // 非当月交易
          if (Math.abs(txAmount - expectedAmount) < 0.01) {
            // 精确匹配（误差小于0.01）
            if (!exactMatchNonCurrentTx) exactMatchNonCurrentTx = tx;
          } else if (Math.abs(txAmount - expectedAmount) < expectedAmount * 0.5) {
            // 金额相近（误差小于50%）
            if (!closeMatchNonCurrentTx) closeMatchNonCurrentTx = tx;
          }
        }
      }
    });
    
    // 确定最佳匹配交易（优先级：当月精确 > 当月相近 > 非当月精确 > 非当月相近）
    let bestMatch = exactMatchTx || closeMatchTx || exactMatchNonCurrentTx || closeMatchNonCurrentTx;
    let isCurrentMonth = !!(exactMatchTx || closeMatchTx);
    let hasAmountDifference = false;
    
    // 如果找到交易，更新员工记录
    if (bestMatch) {
      const employeeIndex = validEmployees.findIndex(emp => 
        emp.地址.toLowerCase() === address.toLowerCase()
      );
      
      if (employeeIndex !== -1) {
        const actualAmount = parseInt(bestMatch.value) / 1000000;
        
        // 检查金额差异
        hasAmountDifference = Math.abs(actualAmount - expectedAmount) > 0.01;
        
        // 设置状态
        if (isCurrentMonth) {
          validEmployees[employeeIndex].status = hasAmountDifference ? '金额有差异' : '已确认';
        } else {
          validEmployees[employeeIndex].status = hasAmountDifference ? '非当月金额差异' : '非当月确认';
          validEmployees[employeeIndex].notCurrentMonth = true;
        }
        
        validEmployees[employeeIndex].txHash = bestMatch.transaction_id;
        validEmployees[employeeIndex].amount = actualAmount;
        validEmployees[employeeIndex].txTime = bestMatch.block_timestamp;
        
        if (hasAmountDifference) {
          validEmployees[employeeIndex].amountDifference = true;
        }
      }
    }
    
    return {
      confirmed: !!bestMatch,
      txHash: bestMatch ? bestMatch.transaction_id : '',
      amount: bestMatch ? parseInt(bestMatch.value) / 1000000 : 0,
      txTime: bestMatch ? bestMatch.block_timestamp : null,
      isCurrentMonth: isCurrentMonth,
      notCurrentMonth: !!bestMatch && !isCurrentMonth,
      hasAmountDifference: hasAmountDifference
    };
  } catch (error) {
    console.error('检查Tron交易失败:', error);
    return {
      confirmed: false,
      txHash: '',
      amount: 0,
      hasAmountDifference: false
    };
  }
}

// 启动服务器
app.listen(PORT, () => {
  console.log(`USDT工资监控系统已启动，访问 http://localhost:${PORT}`);
});