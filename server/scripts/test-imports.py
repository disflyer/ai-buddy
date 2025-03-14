#!/usr/bin/env python
"""
测试导入关键模块，确保依赖正确安装
"""

import sys
print(f"Python version: {sys.version}")
print(f"Python path: {sys.path}")

# 测试导入ruamel.yaml
try:
    from ruamel.yaml import YAML
    print("Successfully imported ruamel.yaml")
except ImportError as e:
    print(f"Failed to import ruamel.yaml: {e}")
    
# 测试导入其他关键模块
modules_to_test = [
    "torch",
    "numpy",
    "pydub",
    "openai",
    "aiohttp",
    "loguru"
]

for module in modules_to_test:
    try:
        __import__(module)
        print(f"Successfully imported {module}")
    except ImportError as e:
        print(f"Failed to import {module}: {e}")

print("Import test completed") 