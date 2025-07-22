import pandas as pd
import json

# 读取Excel文件
try:
    df = pd.read_excel('人员2025.07.xlsx')
    
    # 将DataFrame转换为字典列表
    data = df.to_dict(orient='records')
    
    # 将数据保存为JSON文件，确保中文正确显示
    with open('employee_data.json', 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, indent=4)
    
    print("Excel文件已成功转换为JSON格式并保存为employee_data.json")
    
    # 打印前5行数据作为预览
    print("\n数据预览:")
    print(df.head())
    
except Exception as e:
    print(f"发生错误: {e}")