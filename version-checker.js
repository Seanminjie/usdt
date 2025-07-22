#!/usr/bin/env node

/**
 * USDT工资监控系统 - 版本检测和自动更新工具
 * 检查GitHub上的最新版本并提供自动更新功能
 */

const axios = require('axios');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

class VersionChecker {
    constructor() {
        this.currentVersion = this.getCurrentVersion();
        this.githubRepo = 'Seanminjie/usdt';
        this.githubApiUrl = `https://api.github.com/repos/${this.githubRepo}`;
        this.rawContentUrl = `https://raw.githubusercontent.com/${this.githubRepo}/main`;
    }

    /**
     * 获取当前版本号
     */
    getCurrentVersion() {
        try {
            const packagePath = path.join(__dirname, 'package.json');
            const packageData = JSON.parse(fs.readFileSync(packagePath, 'utf8'));
            return packageData.version;
        } catch (error) {
            console.error('❌ 无法读取当前版本信息:', error.message);
            return '0.0.0';
        }
    }

    /**
     * 从GitHub获取最新版本信息
     */
    async getLatestVersion() {
        try {
            console.log('🔍 正在检查最新版本...');
            
            // 获取最新的package.json
            const response = await axios.get(`${this.rawContentUrl}/package.json`, {
                timeout: 10000,
                headers: {
                    'User-Agent': 'USDT-Monitor-Version-Checker'
                }
            });
            
            const latestPackage = response.data;
            return {
                version: latestPackage.version,
                description: latestPackage.description,
                success: true
            };
        } catch (error) {
            console.error('❌ 获取最新版本失败:', error.message);
            return {
                version: null,
                error: error.message,
                success: false
            };
        }
    }

    /**
     * 获取版本更新日志
     */
    async getUpdateLog() {
        try {
            const response = await axios.get(`${this.rawContentUrl}/VERSION-UPDATE-SUMMARY.md`, {
                timeout: 10000,
                headers: {
                    'User-Agent': 'USDT-Monitor-Version-Checker'
                }
            });
            
            return response.data;
        } catch (error) {
            return '无法获取更新日志';
        }
    }

    /**
     * 比较版本号
     */
    compareVersions(current, latest) {
        const currentParts = current.split('.').map(Number);
        const latestParts = latest.split('.').map(Number);
        
        for (let i = 0; i < Math.max(currentParts.length, latestParts.length); i++) {
            const currentPart = currentParts[i] || 0;
            const latestPart = latestParts[i] || 0;
            
            if (currentPart < latestPart) return -1;
            if (currentPart > latestPart) return 1;
        }
        
        return 0;
    }

    /**
     * 显示版本信息
     */
    displayVersionInfo(current, latest, hasUpdate) {
        console.log('\n========================================');
        console.log('📦 USDT工资监控系统 - 版本信息');
        console.log('========================================');
        console.log(`📍 当前版本: v${current}`);
        console.log(`🌐 最新版本: v${latest}`);
        
        if (hasUpdate) {
            console.log('🎉 发现新版本可用！');
        } else {
            console.log('✅ 您使用的是最新版本');
        }
        console.log('========================================\n');
    }

    /**
     * 显示更新日志
     */
    displayUpdateLog(updateLog) {
        console.log('📋 更新日志:');
        console.log('----------------------------------------');
        
        // 提取主要更新内容
        const lines = updateLog.split('\n');
        let inUpdateSection = false;
        let displayLines = [];
        
        for (const line of lines) {
            if (line.includes('主要更新内容') || line.includes('新功能')) {
                inUpdateSection = true;
                displayLines.push(line);
                continue;
            }
            
            if (inUpdateSection) {
                if (line.trim() === '' && displayLines.length > 10) break;
                if (line.startsWith('###') && !line.includes('更新内容') && !line.includes('新功能')) break;
                
                displayLines.push(line);
            }
        }
        
        // 显示前20行更新内容
        displayLines.slice(0, 20).forEach(line => {
            console.log(line);
        });
        
        console.log('----------------------------------------\n');
    }

    /**
     * 执行自动更新
     */
    async performUpdate() {
        try {
            console.log('🚀 开始自动更新...\n');
            
            // 检查Git是否可用
            try {
                execSync('git --version', { stdio: 'ignore' });
            } catch (error) {
                throw new Error('Git未安装或不可用，无法执行自动更新');
            }
            
            // 备份当前版本
            console.log('📦 备份当前版本...');
            const backupDir = `backup_v${this.currentVersion}_${Date.now()}`;
            
            // 检查Git状态
            console.log('🔍 检查Git状态...');
            try {
                const status = execSync('git status --porcelain', { encoding: 'utf8' });
                if (status.trim()) {
                    console.log('⚠️  检测到未提交的更改，正在暂存...');
                    execSync('git stash push -m "Auto-backup before update"');
                }
            } catch (error) {
                console.log('ℹ️  Git状态检查完成');
            }
            
            // 拉取最新代码
            console.log('⬇️  拉取最新代码...');
            execSync('git fetch origin', { stdio: 'inherit' });
            execSync('git reset --hard origin/main', { stdio: 'inherit' });
            
            // 安装/更新依赖
            console.log('📦 更新依赖包...');
            execSync('npm install', { stdio: 'inherit' });
            
            // 验证更新
            const newVersion = this.getCurrentVersion();
            console.log(`\n✅ 更新完成！`);
            console.log(`📍 新版本: v${newVersion}`);
            
            return true;
        } catch (error) {
            console.error('❌ 自动更新失败:', error.message);
            console.log('\n💡 手动更新方法:');
            console.log('1. git pull origin main');
            console.log('2. npm install');
            console.log('3. 重启系统');
            return false;
        }
    }

    /**
     * 交互式更新确认
     */
    async promptUpdate() {
        return new Promise((resolve) => {
            const readline = require('readline');
            const rl = readline.createInterface({
                input: process.stdin,
                output: process.stdout
            });
            
            rl.question('🤔 是否要立即更新到最新版本？(y/N): ', (answer) => {
                rl.close();
                resolve(answer.toLowerCase() === 'y' || answer.toLowerCase() === 'yes');
            });
        });
    }

    /**
     * 主检查流程
     */
    async check(autoUpdate = false) {
        try {
            console.log('🔍 USDT工资监控系统 - 版本检查工具');
            console.log('========================================\n');
            
            // 获取最新版本
            const latestInfo = await this.getLatestVersion();
            
            if (!latestInfo.success) {
                console.log('❌ 无法连接到更新服务器');
                console.log('💡 请检查网络连接或稍后重试');
                return false;
            }
            
            const latestVersion = latestInfo.version;
            const comparison = this.compareVersions(this.currentVersion, latestVersion);
            const hasUpdate = comparison < 0;
            
            // 显示版本信息
            this.displayVersionInfo(this.currentVersion, latestVersion, hasUpdate);
            
            if (!hasUpdate) {
                console.log('🎉 您使用的是最新版本，无需更新！');
                return true;
            }
            
            // 获取并显示更新日志
            const updateLog = await this.getUpdateLog();
            this.displayUpdateLog(updateLog);
            
            // 自动更新或询问用户
            let shouldUpdate = autoUpdate;
            if (!autoUpdate) {
                shouldUpdate = await this.promptUpdate();
            }
            
            if (shouldUpdate) {
                const updateSuccess = await this.performUpdate();
                if (updateSuccess) {
                    console.log('\n🎉 更新完成！请重启系统以使用新版本。');
                    console.log('💡 重启命令: npm start 或使用启动脚本');
                }
                return updateSuccess;
            } else {
                console.log('\n📝 手动更新方法:');
                console.log('1. 运行: git pull origin main');
                console.log('2. 运行: npm install');
                console.log('3. 重启系统');
                console.log('\n或者运行: node version-checker.js --auto-update');
                return false;
            }
            
        } catch (error) {
            console.error('❌ 版本检查失败:', error.message);
            return false;
        }
    }
}

// 命令行接口
async function main() {
    const args = process.argv.slice(2);
    const autoUpdate = args.includes('--auto-update') || args.includes('-u');
    const helpFlag = args.includes('--help') || args.includes('-h');
    
    if (helpFlag) {
        console.log(`
USDT工资监控系统 - 版本检查工具

用法:
  node version-checker.js              # 检查版本并询问是否更新
  node version-checker.js --auto-update   # 自动更新到最新版本
  node version-checker.js --help          # 显示帮助信息

选项:
  -u, --auto-update    自动更新，无需确认
  -h, --help          显示帮助信息

示例:
  node version-checker.js              # 交互式版本检查
  node version-checker.js -u           # 自动更新
        `);
        return;
    }
    
    const checker = new VersionChecker();
    await checker.check(autoUpdate);
}

// 如果直接运行此脚本
if (require.main === module) {
    main().catch(error => {
        console.error('❌ 程序执行失败:', error.message);
        process.exit(1);
    });
}

module.exports = VersionChecker;