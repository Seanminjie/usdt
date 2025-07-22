// 使用Node.js读取Excel文件
const fs = require('fs');
const path = require('path');
const XLSX = require('xlsx');

// 列出当前目录下的所有文件
const files = fs.readdirSync('.');
console.log('当前目录下的文件:');
console.log(files);

// 查找Excel文件
const excelFiles = files.filter(file => file.endsWith('.xlsx'));
console.log('\nExcel文件:');
console.log(excelFiles);

if (excelFiles.length === 0) {
  console.log('未找到Excel文件');
  process.exit(1);
}

// 读取第一个Excel文件
const excelFile = excelFiles[0];
try {
  console.log(`\n正在读取Excel文件: ${excelFile}`);
  
  // 读取Excel文件
  const workbook = XLSX.readFile(excelFile);
  
  // 获取第一个工作表
  const sheetName = workbook.SheetNames[0];
  const worksheet = workbook.Sheets[sheetName];
  
  // 将工作表转换为JSON
  const data = XLSX.utils.sheet_to_json(worksheet);
  
  // 将数据保存为JSON文件
  fs.writeFileSync('employee_data.json', JSON.stringify(data, null, 2), 'utf8');
  
  console.log('Excel文件已成功转换为JSON格式并保存为employee_data.json');
  
  // 打印前5行数据作为预览
  console.log('\n数据预览:');
  console.log(data.slice(0, 5));
  
} catch (error) {
  console.error(`发生错误: ${error.message}`);
}