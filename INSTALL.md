# USDT工资监控系统 v1.3.1 - 一键安装指南

## 🚀 一条命令安装

### Linux/Unix/macOS 系统

```bash
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash
```

或者使用 wget：

```bash
wget -qO- https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash
```

### Windows 系统

**方法1：PowerShell（推荐）**
```powershell
iwr -useb https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.bat | iex
```

**方法2：命令提示符**
```cmd
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.bat -o install.bat && install.bat
```

**方法3：手动下载**
1. 下载 `install.bat` 文件
2. 右键选择"以管理员身份运行"

## 📦 离线安装包

如果服务器无法访问外网，可以使用离线安装包：

### 创建离线安装包

在有网络的机器上运行：

```bash
# Linux/macOS
./create-offline-package.sh

# Windows
create-offline-package.bat
```

### 使用离线安装包

将生成的 `usdt-monitor-offline.tar.gz` 或 `usdt-monitor-offline.zip` 传输到目标服务器：

```bash
# Linux/macOS
tar -xzf usdt-monitor-offline.tar.gz
cd usdt-monitor-offline
./install-offline.sh

# Windows
# 解压 usdt-monitor-offline.zip
# 运行 install-offline.bat
```

## 🔧 自定义安装

### 指定安装目录

```bash
# Linux/macOS
export INSTALL_DIR="/custom/path"
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash

# Windows
set INSTALL_DIR=C:\custom\path
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.bat -o install.bat && install.bat
```

### 指定Node.js版本

```bash
# Linux/macOS
export NODE_VERSION="18.19.0"
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash
```

### 跳过系统服务创建

```bash
# Linux/macOS
export SKIP_SERVICE="true"
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash
```

## 🐳 Docker 一键部署

### 使用 Docker

```bash
# 拉取并运行
docker run -d \
  --name usdt-monitor \
  -p 3000:3000 \
  -v $(pwd)/data:/app/data \
  your-username/usdt-salary-monitor:latest

# 或使用 docker-compose
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/docker-compose.yml -o docker-compose.yml
docker-compose up -d
```

### 构建自定义镜像

```bash
# 下载 Dockerfile
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/Dockerfile -o Dockerfile

# 构建镜像
docker build -t usdt-monitor .

# 运行容器
docker run -d -p 3000:3000 usdt-monitor
```

## ☁️ 云服务器部署

### 腾讯云/阿里云/华为云

```bash
# 1. 连接到云服务器
ssh root@your-server-ip

# 2. 运行一键安装命令
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash

# 3. 配置安全组，开放3000端口
```

### AWS EC2

```bash
# 1. 连接到EC2实例
ssh -i your-key.pem ec2-user@your-instance-ip

# 2. 运行安装命令
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash

# 3. 配置安全组规则，允许3000端口入站
```

### Google Cloud Platform

```bash
# 1. 连接到GCP实例
gcloud compute ssh your-instance-name

# 2. 运行安装命令
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/install.sh | bash

# 3. 配置防火墙规则
gcloud compute firewall-rules create allow-usdt-monitor --allow tcp:3000
```

## 🔒 安全配置

### 配置HTTPS（推荐生产环境）

```bash
# 安装 Nginx
sudo apt install nginx  # Ubuntu/Debian
sudo yum install nginx  # CentOS/RHEL

# 配置反向代理
sudo tee /etc/nginx/sites-available/usdt-monitor << 'EOF'
server {
    listen 80;
    server_name your-domain.com;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# 启用站点
sudo ln -s /etc/nginx/sites-available/usdt-monitor /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl reload nginx

# 安装SSL证书（使用Let's Encrypt）
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

### 配置访问控制

```bash
# 编辑配置文件
nano /opt/usdt-monitor/config.json

# 添加IP白名单
{
  "allowedIPs": ["192.168.1.0/24", "10.0.0.0/8"],
  "requireAuth": true,
  "adminPassword": "your-secure-password"
}
```

## 📊 监控和日志

### 系统服务管理

```bash
# 查看服务状态
sudo systemctl status usdt-monitor

# 启动/停止/重启服务
sudo systemctl start usdt-monitor
sudo systemctl stop usdt-monitor
sudo systemctl restart usdt-monitor

# 查看日志
sudo journalctl -u usdt-monitor -f
```

### 性能监控

```bash
# 安装监控工具
npm install -g pm2

# 使用PM2管理进程
pm2 start usdt_monitor.js --name "usdt-monitor"
pm2 monit
pm2 logs usdt-monitor
```

## 🔄 更新和维护

### 自动更新

```bash
# 创建更新脚本
curl -fsSL https://raw.githubusercontent.com/your-username/usdt-salary-monitor/main/update.sh | bash
```

### 手动更新

```bash
cd /opt/usdt-monitor
git pull origin main
npm install
sudo systemctl restart usdt-monitor
```

### 备份数据

```bash
# 创建备份
tar -czf usdt-monitor-backup-$(date +%Y%m%d).tar.gz /opt/usdt-monitor

# 恢复备份
tar -xzf usdt-monitor-backup-20240101.tar.gz -C /
```

## 🆘 故障排除

### 常见问题

1. **端口被占用**
   ```bash
   sudo lsof -i :3000
   sudo kill -9 <PID>
   ```

2. **权限问题**
   ```bash
   sudo chown -R $USER:$USER /opt/usdt-monitor
   chmod +x /opt/usdt-monitor/start.sh
   ```

3. **Node.js版本问题**
   ```bash
   # 使用nvm管理Node.js版本
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
   nvm install 18
   nvm use 18
   ```

4. **防火墙问题**
   ```bash
   # Ubuntu/Debian
   sudo ufw allow 3000
   
   # CentOS/RHEL
   sudo firewall-cmd --permanent --add-port=3000/tcp
   sudo firewall-cmd --reload
   ```

### 获取帮助

- 📧 邮箱：support@usdt-monitor.com
- 💬 QQ群：123456789
- 📱 微信群：扫描二维码加入
- 🐛 问题反馈：https://github.com/your-username/usdt-salary-monitor/issues

## 📝 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件