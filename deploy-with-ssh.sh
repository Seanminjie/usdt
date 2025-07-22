#!/bin/bash

# USDT工资监控系统 v1.3.1 - SSH密钥部署脚本
# 目标仓库: git@github.com:Seanminjie/usdt.git

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}USDT工资监控系统 v1.3.0 - SSH部署${NC}"
echo -e "${BLUE}======================================${NC}"
echo

# SSH密钥内容
SSH_KEY_CONTENT="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIK1H6AXY88FG0iXJf/66nbMXv5QgwInLibpNmMK0rDe"

# 检查Git是否安装
if ! command -v git &> /dev/null; then
    echo -e "${RED}[ERROR] Git未安装，请先安装Git${NC}"
    exit 1
fi

echo -e "${GREEN}[INFO] Git已安装${NC}"

# 创建SSH密钥文件
echo -e "${BLUE}[STEP] 配置SSH密钥...${NC}"
SSH_DIR="$HOME/.ssh"
SSH_KEY_FILE="$SSH_DIR/github_usdt_deploy"

# 创建.ssh目录
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# 写入SSH密钥
echo "$SSH_KEY_CONTENT" > "$SSH_KEY_FILE"
chmod 600 "$SSH_KEY_FILE"

# 配置SSH config
SSH_CONFIG="$SSH_DIR/config"
if ! grep -q "github.com-usdt" "$SSH_CONFIG" 2>/dev/null; then
    echo "" >> "$SSH_CONFIG"
    echo "Host github.com-usdt" >> "$SSH_CONFIG"
    echo "    HostName github.com" >> "$SSH_CONFIG"
    echo "    User git" >> "$SSH_CONFIG"
    echo "    IdentityFile $SSH_KEY_FILE" >> "$SSH_CONFIG"
    echo "    IdentitiesOnly yes" >> "$SSH_CONFIG"
fi

echo -e "${GREEN}[INFO] SSH密钥配置完成${NC}"

# 测试SSH连接
echo -e "${BLUE}[STEP] 测试SSH连接...${NC}"
if ssh -T git@github.com-usdt -o StrictHostKeyChecking=no 2>&1 | grep -q "successfully authenticated"; then
    echo -e "${GREEN}[INFO] SSH连接测试成功${NC}"
else
    echo -e "${YELLOW}[WARNING] SSH连接测试可能失败，但继续部署...${NC}"
fi

# 检查是否已经是Git仓库
if [ ! -d ".git" ]; then
    echo -e "${BLUE}[STEP] 初始化Git仓库...${NC}"
    git init
    echo -e "${GREEN}[INFO] Git仓库初始化完成${NC}"
else
    echo -e "${GREEN}[INFO] 已存在Git仓库${NC}"
fi

# 创建.gitignore文件
echo -e "${BLUE}[STEP] 创建.gitignore文件...${NC}"
cat > .gitignore << 'EOF'
# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# 运行时文件
*.log
logs/
pids/
*.pid
*.seed
*.pid.lock

# 临时文件
.tmp/
temp/
uploads/

# 环境变量
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# IDE文件
.vscode/
.idea/
*.swp
*.swo
*~

# 操作系统文件
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# 备份文件
*.backup.*
*.bak

# 数据文件（可选）
employee_data_updated.json

# 构建输出
dist/
build/

# Vercel
.vercel/
EOF

echo -e "${GREEN}[INFO] .gitignore文件创建完成${NC}"

# 配置远程仓库
echo -e "${BLUE}[STEP] 配置远程仓库...${NC}"
if git remote get-url origin &>/dev/null; then
    echo -e "${YELLOW}[WARNING] 远程仓库已存在，更新URL...${NC}"
    git remote set-url origin git@github.com-usdt:Seanminjie/usdt.git
else
    git remote add origin git@github.com-usdt:Seanminjie/usdt.git
fi
echo -e "${GREEN}[INFO] 远程仓库配置完成${NC}"

# 添加所有文件
echo -e "${BLUE}[STEP] 添加文件到Git...${NC}"
git add .
echo -e "${GREEN}[INFO] 文件添加完成${NC}"

# 检查Git配置
if ! git config user.name &>/dev/null; then
    echo -e "${YELLOW}[WARNING] 配置Git用户信息...${NC}"
    read -p "请输入您的用户名: " username
    read -p "请输入您的邮箱: " email
    git config user.name "$username"
    git config user.email "$email"
    echo -e "${GREEN}[INFO] Git用户信息配置完成${NC}"
fi

# 提交更改
echo -e "${BLUE}[STEP] 提交更改...${NC}"
git commit -m "feat: USDT工资监控系统 v1.3.0 完整版

🚀 新功能:
- 一条命令安装支持 (Linux/macOS/Windows)
- Docker容器化部署
- 在线Excel文件上传
- 智能状态颜色区分
- 自适应响应式布局
- 批量交易检查
- 手工确认功能
- 健康检查API端点

📦 部署方式:
- 传统安装 (install.sh/install.bat)
- 一键安装 (quick-install.sh/quick-install.bat)
- Docker部署 (Dockerfile + docker-compose.yml)
- 离线安装包 (create-offline-package.*)
- 远程部署 (deploy.sh)

🛠️ 技术栈:
- Node.js + Express.js
- Bootstrap 5 响应式UI
- Multer文件上传
- XLSX Excel处理
- Axios HTTP客户端
- Docker容器化

📚 文档:
- README.md - 项目说明
- INSTALL.md - 详细安装指南
- ONE-COMMAND-INSTALL.md - 一条命令安装指南
- DEPLOYMENT-COMPLETE.md - 部署完成总结"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}[INFO] 提交完成${NC}"
else
    echo -e "${RED}[ERROR] 提交失败，请检查错误信息${NC}"
    exit 1
fi

# 推送到GitHub
echo -e "${BLUE}[STEP] 推送到GitHub...${NC}"
echo -e "${YELLOW}[INFO] 正在推送到远程仓库...${NC}"

# 尝试推送到main分支
if git push -u origin main 2>/dev/null; then
    echo -e "${GREEN}[INFO] 推送到main分支成功${NC}"
elif git push -u origin master 2>/dev/null; then
    echo -e "${GREEN}[INFO] 推送到master分支成功${NC}"
else
    echo -e "${YELLOW}[WARNING] 推送失败，尝试合并远程内容...${NC}"
    
    # 尝试拉取并合并
    if git pull origin main --allow-unrelated-histories 2>/dev/null; then
        git push origin main
    elif git pull origin master --allow-unrelated-histories 2>/dev/null; then
        git push origin master
    else
        echo -e "${RED}[ERROR] 推送失败${NC}"
        echo
        echo "可能的解决方案:"
        echo "1. 检查网络连接"
        echo "2. 确认GitHub仓库权限"
        echo "3. 手动执行: git push -f origin main"
        exit 1
    fi
fi

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}[SUCCESS] USDT工资监控系统已上传到GitHub${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${BLUE}[INFO] 仓库地址: https://github.com/Seanminjie/usdt${NC}"
echo
echo -e "${BLUE}[INFO] 下一步操作:${NC}"
echo "1. 访问GitHub仓库检查文件"
echo "2. 测试一条命令安装功能"
echo "3. 更新项目文档"
echo
echo -e "${BLUE}[INFO] 一条命令安装链接:${NC}"
echo -e "${YELLOW}Linux/macOS:${NC} curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.sh | bash"
echo -e "${YELLOW}Windows:${NC} iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.bat | iex"
echo

# 清理SSH密钥文件（可选）
read -p "是否删除临时SSH密钥文件? (y/N): " cleanup
if [[ $cleanup =~ ^[Yy]$ ]]; then
    rm -f "$SSH_KEY_FILE"
    echo -e "${GREEN}[INFO] SSH密钥文件已删除${NC}"
fi

echo -e "${GREEN}[INFO] 部署完成！${NC}"