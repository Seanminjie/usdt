# USDT工资监控系统 v1.3.0

## 🚀 一条命令安装

**最快安装方式，适用于任何服务器：**

```bash
# Linux/Unix/macOS
curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.sh | bash

# Windows PowerShell
iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.bat | iex
```

**安装完成后访问：** http://localhost:3000

> 💡 **一条命令完成所有配置**：自动安装Node.js、下载项目、安装依赖、配置服务、开放端口！
> 
> 📖 **详细安装指南**：查看 [ONE-COMMAND-INSTALL.md](./ONE-COMMAND-INSTALL.md)

---

## 项目介绍

这是一个用于监控和分析员工USDT工资接收情况的工具，帮助财务人员避免漏发或错发工资的情况。系统通过监控USDT交易，自动验证员工是否收到了正确金额的工资。

## 功能特点

### 核心功能
- 从Excel文件导入员工信息和USDT地址
- 监控USDT交易，验证员工是否收到工资
- 提供直观的Web界面，显示工资发放状态
- 支持搜索和筛选功能，方便查找特定员工
- 支持导出报告，便于存档和分析
- 支持查看交易详情，链接到区块链浏览器

### v1.3.0 新功能
- **在线文件上传**：支持通过Web界面直接上传Excel文件，无需手动放置文件
- **智能状态颜色**：不同交易状态显示不同颜色，一目了然
  - 🟡 待确认（橙色）
  - 🟢 已确认（绿色）
  - 🔵 手工确认（蓝色）
  - 🟠 金额有差异（橙红色）
  - 🟣 非当月确认（紫色）
  - 🔴 未找到交易（红色）
  - ⚫ 检查失败（深灰色）
- **自适应布局**：页面自动适应不同屏幕尺寸，支持移动设备访问
- **批量操作**：一键检查所有员工的交易状态
- **手工确认**：支持手动确认特殊情况的交易
- **实时更新**：页面状态实时更新，无需刷新

## 系统要求

- Node.js 14.0 或更高版本（推荐 v18+）
- 网络连接（用于查询USDT交易信息）
- 现代浏览器（Chrome, Firefox, Safari, Edge）

## 🚀 快速开始

### 系统要求
- Node.js 14.0.0 或更高版本（推荐 v18+）
- Windows 10/11, Ubuntu 18.04+, CentOS 7+, macOS 10.15+
- 至少 100MB 可用磁盘空间

### 🎯 一条命令安装（推荐）

**Linux/Unix/macOS 系统：**
```bash
curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/install.sh | bash
```

**Windows 系统：**
```powershell
# PowerShell（推荐）
iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/install.bat | iex

# 或命令提示符
curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/install.bat -o install.bat && install.bat
```

### 🐳 Docker 一键部署
```bash
# 使用 Docker Compose
curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/docker-compose.yml -o docker-compose.yml
docker-compose up -d

# 或直接运行
docker run -d -p 3000:3000 --name usdt-monitor Seanminjie/usdt:latest
```

### 📦 离线安装包
如果服务器无法访问外网：
```bash
# 创建离线包
./create-offline-package.sh  # Linux/macOS
# 或
create-offline-package.bat   # Windows

# 使用离线包安装
tar -xzf usdt-monitor-offline.tar.gz && cd usdt-monitor-offline && ./install-offline.sh
```

### 🚀 一键部署到服务器
```bash
# 本地安装
./deploy.sh --local

# 远程部署
./deploy.sh -s your-server.com -u root

# Docker + Nginx + SSL
./deploy.sh -s your-server.com -u ubuntu --docker --nginx --ssl
```

### 传统启动方式

1. **Windows批处理文件**：
   ```
   双击运行 "启动系统.bat"
   ```

2. **PowerShell脚本**：
   ```powershell
   .\启动系统.ps1
   ```

3. **简化启动**：
   ```
   双击运行 "简化启动.bat"
   ```

**Linux/macOS系统：**
```bash
chmod +x 启动系统.sh
./启动系统.sh
```

### 手动安装

1. 确保已安装Node.js环境
2. 克隆或下载本项目到本地
3. 在项目目录中运行以下命令安装依赖：

```bash
npm install
```

4. 启动系统：

```bash
npm start
```

5. 在浏览器中访问 http://localhost:3000

## 使用方法

### 数据导入

**方法一：在线上传（推荐）**
1. 启动系统后，点击页面上的"导入新表单"按钮
2. 选择Excel文件并上传
3. 系统会自动处理并刷新页面

**方法二：文件放置**
1. 将Excel文件放在项目根目录，命名为`人员2025.07.xlsx`
2. 运行转换命令：`node read_excel.js`

### Excel文件格式要求

确保Excel文件包含以下字段：
- **员工姓名**（第一列，必填）
- **部门**（可选）
- **岗位**（可选）
- **基本薪资（usdt）**（必填）
- **实发薪资（usdt）**（必填）
- **地址**（USDT-TRC20地址，必填）

### 交易检查

- **单个检查**：点击员工行中的"检查"按钮
- **批量检查**：点击"检查所有交易"按钮
- **手工确认**：对于特殊情况，可以点击"手工确认"按钮

### 状态说明

| 状态 | 颜色 | 说明 |
|------|------|------|
| 待确认 | 🟡 橙色 | 交易已发起，等待区块链确认 |
| 已确认 | 🟢 绿色 | 交易已成功确认，金额正确 |
| 手工确认 | 🔵 蓝色 | 人工确认的交易 |
| 金额有差异 | 🟠 橙红色 | 交易金额与预期不符 |
| 非当月确认 | 🟣 紫色 | 交易时间不在当月范围内 |
| 未找到交易 | 🔴 红色 | 未找到相关交易记录 |
| 检查失败 | ⚫ 深灰色 | 系统检查过程中出现错误 |

### 导出和分析

- **导出报告**：点击"导出报告"按钮，生成CSV格式的详细报告
- **查看详情**：点击USDT地址或交易哈希查看区块链详情

## 技术架构

- **前端**：HTML5, CSS3 (Bootstrap 5), JavaScript (ES6+)
- **后端**：Node.js, Express.js
- **文件处理**：multer (文件上传), xlsx (Excel处理)
- **网络请求**：axios
- **响应式设计**：Bootstrap Grid System

## 配置说明

### 环境变量（可选）
```bash
PORT=3000                    # 服务器端口
TRON_API_KEY=your_api_key   # TRON API密钥
```

### API配置
在实际使用中，需要配置真实的TRON API密钥以获取准确的交易信息。

## 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查找占用端口的进程
   netstat -ano | findstr :3000
   # 结束进程
   taskkill /PID <进程ID> /F
   ```

2. **Node.js版本过低**
   - 访问 https://nodejs.org/ 下载最新LTS版本

3. **依赖安装失败**
   ```bash
   # 清除缓存并重新安装
   npm cache clean --force
   npm install
   ```

4. **Excel文件格式错误**
   - 确保文件为.xlsx格式
   - 检查必填字段是否完整
   - 确保USDT地址格式正确

### 日志查看

系统启动后，控制台会显示详细的运行日志，包括：
- 服务器启动状态
- 文件处理结果
- API调用情况
- 错误信息

## 更新日志

### v1.3.0 (2024-01-XX)
- ✨ 新增在线Excel文件上传功能
- 🎨 优化状态颜色显示，支持多种状态区分
- 📱 实现响应式布局，支持移动设备
- 🚀 改进启动脚本，增加自动环境检查
- 🔧 优化错误处理和用户提示
- 📊 增强批量操作功能

### v1.2.0
- 基础监控功能
- Excel文件导入
- 交易状态检查
- 报告导出

## 许可证

本项目仅供学习和内部使用，请勿用于商业用途。

## 支持

如遇问题，请检查：
1. Node.js版本是否符合要求
2. 网络连接是否正常
3. Excel文件格式是否正确
4. 防火墙设置是否阻止了端口访问

---

**注意**：本系统目前使用模拟数据进行演示，实际使用时需要配置真实的TRON API以获取准确的交易信息。
