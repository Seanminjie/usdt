#!/bin/bash

# USDT工资监控系统 v1.3.0 - 一键部署脚本
# 支持快速部署到远程服务器

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 默认配置
DEFAULT_PORT=3000
DEFAULT_INSTALL_DIR="/opt/usdt-monitor"
PROJECT_VERSION="1.3.0"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  USDT工资监控系统 v${PROJECT_VERSION}${NC}"
echo -e "${BLUE}  一键部署脚本${NC}"
echo -e "${BLUE}========================================${NC}"

# 显示帮助信息
show_help() {
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help              显示帮助信息"
    echo "  -s, --server HOST       远程服务器地址"
    echo "  -u, --user USER         SSH用户名"
    echo "  -p, --port PORT         SSH端口 (默认: 22)"
    echo "  -k, --key KEYFILE       SSH私钥文件"
    echo "  -d, --dir DIRECTORY     安装目录 (默认: $DEFAULT_INSTALL_DIR)"
    echo "  --app-port PORT         应用端口 (默认: $DEFAULT_PORT)"
    echo "  --local                 本地安装"
    echo "  --docker                使用Docker部署"
    echo "  --nginx                 配置Nginx反向代理"
    echo "  --ssl                   配置SSL证书"
    echo ""
    echo "示例:"
    echo "  $0 --local                                    # 本地安装"
    echo "  $0 -s 192.168.1.100 -u root                  # 远程安装"
    echo "  $0 -s example.com -u ubuntu -k ~/.ssh/id_rsa # 使用SSH密钥"
    echo "  $0 --docker --nginx --ssl                    # Docker + Nginx + SSL"
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--server)
                SERVER="$2"
                shift 2
                ;;
            -u|--user)
                SSH_USER="$2"
                shift 2
                ;;
            -p|--port)
                SSH_PORT="$2"
                shift 2
                ;;
            -k|--key)
                SSH_KEY="$2"
                shift 2
                ;;
            -d|--dir)
                INSTALL_DIR="$2"
                shift 2
                ;;
            --app-port)
                APP_PORT="$2"
                shift 2
                ;;
            --local)
                LOCAL_INSTALL=true
                shift
                ;;
            --docker)
                USE_DOCKER=true
                shift
                ;;
            --nginx)
                USE_NGINX=true
                shift
                ;;
            --ssl)
                USE_SSL=true
                shift
                ;;
            *)
                echo -e "${RED}未知选项: $1${NC}"
                show_help
                exit 1
                ;;
        esac
    done
}

# 设置默认值
set_defaults() {
    SSH_PORT=${SSH_PORT:-22}
    INSTALL_DIR=${INSTALL_DIR:-$DEFAULT_INSTALL_DIR}
    APP_PORT=${APP_PORT:-$DEFAULT_PORT}
    
    if [ "$LOCAL_INSTALL" = true ]; then
        SERVER="localhost"
        SSH_USER=$(whoami)
    fi
}

# 构建SSH命令
build_ssh_cmd() {
    SSH_CMD="ssh"
    
    if [ -n "$SSH_KEY" ]; then
        SSH_CMD="$SSH_CMD -i $SSH_KEY"
    fi
    
    if [ "$SSH_PORT" != "22" ]; then
        SSH_CMD="$SSH_CMD -p $SSH_PORT"
    fi
    
    SSH_CMD="$SSH_CMD $SSH_USER@$SERVER"
}

# 构建SCP命令
build_scp_cmd() {
    SCP_CMD="scp"
    
    if [ -n "$SSH_KEY" ]; then
        SCP_CMD="$SCP_CMD -i $SSH_KEY"
    fi
    
    if [ "$SSH_PORT" != "22" ]; then
        SCP_CMD="$SCP_CMD -P $SSH_PORT"
    fi
}

# 检查连接
check_connection() {
    if [ "$LOCAL_INSTALL" != true ]; then
        echo -e "${BLUE}检查服务器连接...${NC}"
        
        if ! $SSH_CMD "echo 'Connection test'" >/dev/null 2>&1; then
            echo -e "${RED}无法连接到服务器 $SERVER${NC}"
            echo -e "${YELLOW}请检查：${NC}"
            echo "1. 服务器地址是否正确"
            echo "2. SSH用户名和密钥是否正确"
            echo "3. 服务器是否允许SSH连接"
            exit 1
        fi
        
        echo -e "${GREEN}服务器连接成功${NC}"
    fi
}

# 创建部署包
create_deployment_package() {
    echo -e "${BLUE}创建部署包...${NC}"
    
    DEPLOY_DIR=$(mktemp -d)
    PACKAGE_NAME="usdt-monitor-deploy"
    
    # 复制必要文件
    cp package.json "$DEPLOY_DIR/"
    cp usdt_monitor.js "$DEPLOY_DIR/"
    cp read_excel.js "$DEPLOY_DIR/"
    cp README.md "$DEPLOY_DIR/"
    cp -r public "$DEPLOY_DIR/"
    
    # 复制Docker文件（如果需要）
    if [ "$USE_DOCKER" = true ]; then
        cp Dockerfile "$DEPLOY_DIR/"
        cp docker-compose.yml "$DEPLOY_DIR/"
    fi
    
    # 创建部署脚本
    cat > "$DEPLOY_DIR/deploy.sh" << EOF
#!/bin/bash
set -e

INSTALL_DIR="$INSTALL_DIR"
APP_PORT="$APP_PORT"
USE_DOCKER="$USE_DOCKER"
USE_NGINX="$USE_NGINX"
USE_SSL="$USE_SSL"

# 安装Node.js（如果需要）
if [ "\$USE_DOCKER" != true ] && ! command -v node &> /dev/null; then
    echo "安装Node.js..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo bash -
    sudo apt-get install -y nodejs
fi

# 创建安装目录
sudo mkdir -p "\$INSTALL_DIR"
sudo chown -R \$USER:\$USER "\$INSTALL_DIR"

# 复制文件
cp -r * "\$INSTALL_DIR/"
cd "\$INSTALL_DIR"

if [ "\$USE_DOCKER" = true ]; then
    # Docker部署
    echo "使用Docker部署..."
    docker-compose up -d
else
    # 传统部署
    echo "安装依赖..."
    npm install --production
    
    # 创建系统服务
    sudo tee /etc/systemd/system/usdt-monitor.service << EOSERVICE
[Unit]
Description=USDT Salary Monitor System
After=network.target

[Service]
Type=simple
User=\$USER
WorkingDirectory=\$INSTALL_DIR
ExecStart=/usr/bin/node usdt_monitor.js
Restart=always
RestartSec=10
Environment=NODE_ENV=production
Environment=PORT=\$APP_PORT

[Install]
WantedBy=multi-user.target
EOSERVICE
    
    sudo systemctl daemon-reload
    sudo systemctl enable usdt-monitor
    sudo systemctl start usdt-monitor
fi

# 配置Nginx（如果需要）
if [ "\$USE_NGINX" = true ]; then
    echo "配置Nginx..."
    sudo apt-get update
    sudo apt-get install -y nginx
    
    sudo tee /etc/nginx/sites-available/usdt-monitor << EONGINX
server {
    listen 80;
    server_name _;
    
    location / {
        proxy_pass http://localhost:\$APP_PORT;
        proxy_set_header Host \\\$host;
        proxy_set_header X-Real-IP \\\$remote_addr;
        proxy_set_header X-Forwarded-For \\\$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \\\$scheme;
    }
}
EONGINX
    
    sudo ln -sf /etc/nginx/sites-available/usdt-monitor /etc/nginx/sites-enabled/
    sudo nginx -t && sudo systemctl reload nginx
fi

# 配置SSL（如果需要）
if [ "\$USE_SSL" = true ]; then
    echo "配置SSL..."
    sudo apt-get install -y certbot python3-certbot-nginx
    echo "请手动运行: sudo certbot --nginx"
fi

echo "部署完成！"
echo "访问地址: http://localhost:\$APP_PORT"
if [ "\$USE_NGINX" = true ]; then
    echo "Nginx代理: http://\$(hostname -I | awk '{print \$1}')"
fi
EOF
    
    chmod +x "$DEPLOY_DIR/deploy.sh"
    
    # 创建压缩包
    cd "$(dirname "$DEPLOY_DIR")"
    tar -czf "$PACKAGE_NAME.tar.gz" "$(basename "$DEPLOY_DIR")"
    
    echo -e "${GREEN}部署包创建完成: $PACKAGE_NAME.tar.gz${NC}"
}

# 上传并部署
upload_and_deploy() {
    if [ "$LOCAL_INSTALL" = true ]; then
        echo -e "${BLUE}本地部署...${NC}"
        cd "$DEPLOY_DIR"
        ./deploy.sh
    else
        echo -e "${BLUE}上传部署包到服务器...${NC}"
        
        # 上传文件
        $SCP_CMD "$PACKAGE_NAME.tar.gz" "$SSH_USER@$SERVER:/tmp/"
        
        # 远程部署
        $SSH_CMD << EOF
cd /tmp
tar -xzf $PACKAGE_NAME.tar.gz
cd $(basename "$DEPLOY_DIR")
./deploy.sh
rm -rf /tmp/$PACKAGE_NAME.tar.gz /tmp/$(basename "$DEPLOY_DIR")
EOF
    fi
}

# 显示部署结果
show_result() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  部署完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    if [ "$LOCAL_INSTALL" = true ]; then
        echo -e "${BLUE}访问地址:${NC} http://localhost:$APP_PORT"
    else
        echo -e "${BLUE}访问地址:${NC} http://$SERVER:$APP_PORT"
        if [ "$USE_NGINX" = true ]; then
            echo -e "${BLUE}Nginx代理:${NC} http://$SERVER"
        fi
    fi
    
    echo ""
    echo -e "${YELLOW}管理命令:${NC}"
    if [ "$USE_DOCKER" = true ]; then
        echo "查看状态: docker-compose ps"
        echo "查看日志: docker-compose logs -f"
        echo "重启服务: docker-compose restart"
        echo "停止服务: docker-compose down"
    else
        echo "查看状态: sudo systemctl status usdt-monitor"
        echo "查看日志: sudo journalctl -u usdt-monitor -f"
        echo "重启服务: sudo systemctl restart usdt-monitor"
        echo "停止服务: sudo systemctl stop usdt-monitor"
    fi
}

# 清理临时文件
cleanup() {
    if [ -n "$DEPLOY_DIR" ] && [ -d "$DEPLOY_DIR" ]; then
        rm -rf "$DEPLOY_DIR"
    fi
    if [ -f "$PACKAGE_NAME.tar.gz" ]; then
        rm -f "$PACKAGE_NAME.tar.gz"
    fi
}

# 主函数
main() {
    # 设置错误处理
    trap cleanup EXIT
    
    parse_args "$@"
    set_defaults
    
    if [ -z "$SERVER" ]; then
        echo -e "${RED}请指定服务器地址或使用 --local 进行本地安装${NC}"
        show_help
        exit 1
    fi
    
    build_ssh_cmd
    build_scp_cmd
    check_connection
    create_deployment_package
    upload_and_deploy
    show_result
}

# 运行主函数
main "$@"