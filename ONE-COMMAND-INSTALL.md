# USDT工资监控系统 v1.3.1 - 一条命令安装指南

## 🚀 一条命令安装

### Linux/Unix/macOS 系统

```bash
curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.sh | bash
```

### Windows 系统

**PowerShell（推荐）:**
```powershell
iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.bat | iex
```

**命令提示符:**
```cmd
curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.bat -o quick-install.bat && quick-install.bat
```

## 📋 安装要求

### 系统要求
- **Linux**: Ubuntu 18.04+, CentOS 7+, Debian 9+
- **macOS**: 10.14+
- **Windows**: Windows 10/11

### 软件要求
- **Node.js**: v14.0.0+ (脚本会自动安装)
- **内存**: 最少 512MB
- **磁盘**: 最少 100MB 可用空间

## 🔧 安装过程

### 自动安装内容
1. **环境检查**: 检测操作系统和权限
2. **Node.js安装**: 自动安装Node.js v18 LTS
3. **项目下载**: 下载或创建项目文件
4. **依赖安装**: 自动安装npm依赖包
5. **服务配置**: 创建系统服务(root权限)
6. **防火墙配置**: 自动开放3000端口
7. **启动脚本**: 创建便捷启动脚本

### 安装位置
- **Linux/macOS (root)**: `/opt/usdt-monitor`
- **Linux/macOS (用户)**: `~/usdt-monitor`
- **Windows (管理员)**: `C:\usdt-monitor`
- **Windows (用户)**: `%USERPROFILE%\usdt-monitor`

## 🎯 快速验证

安装完成后，可以通过以下方式验证：

```bash
# 检查健康状态
curl http://localhost:3000/health

# 访问Web界面
# 浏览器打开: http://localhost:3000
```

## 🔄 服务管理

### Linux/macOS (systemd)
```bash
# 启动服务
sudo systemctl start usdt-monitor

# 停止服务
sudo systemctl stop usdt-monitor

# 重启服务
sudo systemctl restart usdt-monitor

# 查看状态
sudo systemctl status usdt-monitor

# 查看日志
sudo journalctl -u usdt-monitor -f
```

### Windows
```batch
# 使用批处理启动
启动系统.bat

# 使用PowerShell启动
.\启动系统.ps1

# 使用npm启动
npm start
```

## 🛠️ 自定义安装

### 指定安装目录
```bash
# Linux/macOS
export INSTALL_DIR="/custom/path"
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash

# Windows
set INSTALL_DIR=D:\custom\path
quick-install.bat
```

### 指定端口
```bash
# Linux/macOS
export APP_PORT=8080
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash

# Windows
set APP_PORT=8080
quick-install.bat
```

## 🐳 Docker 一键部署

如果您更喜欢使用Docker：

```bash
# 快速启动
docker run -d -p 3000:3000 --name usdt-monitor usdt-monitor:latest

# 使用docker-compose
curl -O https://raw.githubusercontent.com/your-repo/usdt-monitor/main/docker-compose.yml
docker-compose up -d
```

## 📦 离线安装

如果服务器无法访问互联网：

```bash
# 1. 在有网络的机器上创建离线包
./create-offline-package.sh

# 2. 将生成的 usdt-monitor-v1.3.1-offline.tar.gz 传输到目标服务器

```bash
tar -xzf usdt-monitor-v1.3.1-offline.tar.gz
cd usdt-monitor-v1.3.1-offline
./install-offline.sh
```

## 🌐 云服务器部署

### 腾讯云/阿里云/华为云
```bash
# 登录云服务器后直接运行
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash
```

### AWS EC2
```bash
# Amazon Linux 2
sudo yum update -y
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash
```

### Google Cloud Platform
```bash
# Ubuntu/Debian
sudo apt update
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash
```

## 🔒 安全配置

### HTTPS配置
安装完成后，建议配置HTTPS：

```bash
# 使用Let's Encrypt (需要域名)
sudo apt install certbot
sudo certbot --nginx -d your-domain.com
```

### 访问控制
```bash
# 限制访问IP (使用nginx)
sudo nano /etc/nginx/sites-available/usdt-monitor

# 添加访问控制
location / {
    allow 192.168.1.0/24;
    deny all;
    proxy_pass http://localhost:3000;
}
```

## 🚨 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   # 查看端口占用
   netstat -tlnp | grep 3000
   # 或使用其他端口
   export APP_PORT=8080
   ```

2. **权限问题**
   ```bash
   # 确保有执行权限
   chmod +x quick-install.sh
   ```

3. **网络问题**
   ```bash
   # 检查网络连接
   curl -I https://nodejs.org
   # 或使用离线安装包
   ```

4. **Node.js版本问题**
   ```bash
   # 手动安装Node.js
   curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
   sudo apt-get install -y nodejs
   ```

### 日志查看
```bash
# Linux/macOS
sudo journalctl -u usdt-monitor -f

# Windows
# 查看控制台输出或日志文件
```

## 📞 获取帮助

- **文档**: 查看安装目录下的 `README.md`
- **健康检查**: `http://localhost:3000/health`
- **问题反馈**: 提交Issue到项目仓库
- **技术支持**: 联系开发团队

## 🔄 更新系统

```bash
# 重新运行安装脚本即可更新
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash
```

---

## 📝 安装命令总结

**最简单的安装方式：**

```bash
# Linux/macOS
curl -fsSL https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.sh | bash

# Windows PowerShell
iwr -useb https://raw.githubusercontent.com/your-repo/usdt-monitor/main/quick-install.bat | iex
```

安装完成后访问: http://localhost:3000

🎉 **就是这么简单！一条命令，完成所有安装配置！**