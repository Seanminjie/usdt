#!/bin/bash

# USDT工资监控系统 - GitHub上传脚本
# 目标仓库: https://github.com/Seanminjie/usdt.git

echo "======================================"
echo "USDT工资监控系统 v1.3.0 - GitHub上传"
echo "======================================"
echo

# 检查Git是否安装
if ! command -v git &> /dev/null; then
    echo "❌ Git未安装，请先安装Git"
    echo "下载地址: https://git-scm.com/downloads"
    exit 1
fi

echo "✅ Git已安装"

# 检查是否已经是Git仓库
if [ ! -d ".git" ]; then
    echo "🔧 初始化Git仓库..."
    git init
    echo "✅ Git仓库初始化完成"
else
    echo "✅ 已存在Git仓库"
fi

# 创建.gitignore文件
echo "📝 创建.gitignore文件..."
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

# 数据文件（可选，根据需要调整）
employee_data_updated.json

# 构建输出
dist/
build/
EOF

echo "✅ .gitignore文件创建完成"

# 添加远程仓库
echo "🔗 配置远程仓库..."
if git remote get-url origin &> /dev/null; then
    echo "⚠️  远程仓库已存在，更新URL..."
    git remote set-url origin https://github.com/Seanminjie/usdt.git
else
    git remote add origin https://github.com/Seanminjie/usdt.git
fi
echo "✅ 远程仓库配置完成"

# 添加所有文件
echo "📁 添加文件到Git..."
git add .
echo "✅ 文件添加完成"

# 检查Git配置
if ! git config user.name &> /dev/null; then
    echo "⚠️  请配置Git用户信息:"
    echo "git config --global user.name \"Your Name\""
    echo "git config --global user.email \"your.email@example.com\""
    echo
    read -p "请输入您的用户名: " username
    read -p "请输入您的邮箱: " email
    git config user.name "$username"
    git config user.email "$email"
    echo "✅ Git用户信息配置完成"
fi

# 提交更改
echo "💾 提交更改..."
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
    echo "✅ 提交完成"
else
    echo "❌ 提交失败，请检查错误信息"
    exit 1
fi

# 推送到GitHub
echo "🚀 推送到GitHub..."
echo "⚠️  如果是首次推送，可能需要输入GitHub用户名和密码/Token"
echo

# 尝试推送
if git push -u origin main 2>/dev/null; then
    echo "✅ 推送到main分支成功"
elif git push -u origin master 2>/dev/null; then
    echo "✅ 推送到master分支成功"
else
    echo "⚠️  推送失败，尝试强制推送..."
    echo "这可能是因为远程仓库已有内容，正在尝试合并..."
    
    # 拉取远程内容并合并
    git pull origin main --allow-unrelated-histories 2>/dev/null || \
    git pull origin master --allow-unrelated-histories 2>/dev/null
    
    # 再次尝试推送
    if git push origin main 2>/dev/null || git push origin master 2>/dev/null; then
        echo "✅ 推送成功"
    else
        echo "❌ 推送失败"
        echo
        echo "可能的解决方案:"
        echo "1. 检查网络连接"
        echo "2. 确认GitHub仓库权限"
        echo "3. 使用Personal Access Token代替密码"
        echo "4. 手动执行: git push -f origin main"
        exit 1
    fi
fi

echo
echo "🎉 成功！USDT工资监控系统已上传到GitHub"
echo "📍 仓库地址: https://github.com/Seanminjie/usdt"
echo
echo "📋 下一步操作:"
echo "1. 访问GitHub仓库检查文件"
echo "2. 更新安装脚本中的下载链接"
echo "3. 测试一条命令安装功能"
echo
echo "🔗 一条命令安装链接:"
echo "Linux/macOS: curl -fsSL https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.sh | bash"
echo "Windows: iwr -useb https://raw.githubusercontent.com/Seanminjie/usdt/main/quick-install.bat | iex"
echo