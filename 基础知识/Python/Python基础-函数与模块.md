---
title: Python基础-函数与模块
tags: [Python, 函数, 模块, 包, 作用域]
created: 2026-08-31
---

# Python基础 - 函数与模块

## 概述

函数是可复用的代码块，模块和包则是组织和管理代码的结构。掌握函数的参数、返回值、作用域，以及模块的导入机制，是写工程级代码的基础。

---

## 函数基础

### 定义与调用

```python
# 语法：def 函数名(参数):
def greet(name):
    """向某人打招呼"""          # docstring：函数说明文档
    print(f"你好, {name}!")

greet("张三")                   # 调用：你好, 张三!
```

### 参数与返回值

```python
# 无参数、无返回值
def say_hello():
    print("Hello!")

# 有参数、有返回值
def circle_area(r):
    """计算圆的面积"""
    return 3.14 * r ** 2

area = circle_area(10)          # 314.0

# 多个返回值 —— 本质是返回元组
def calc_stats(scores):
    """返回最高分、最低分、平均分"""
    return max(scores), min(scores), round(sum(scores) / len(scores), 1)

hi, lo, avg = calc_stats([589, 609, 605, 643, 677])  # 解包赋值
```

### 参数详解

#### 位置参数 vs 关键字参数

```python
def register(name, age, gender, city):
    print(f"{name}, {age}岁, {gender}, {city}")

# 位置参数 —— 按顺序传递
register("张三", 18, "男", "北京")

# 关键字参数 —— 按名称传递，顺序可变
register(gender="男", name="王五", city="上海", age=22)
```

#### 默认参数

```python
# 有默认值的参数必须放在无默认值参数的后面
def register(name, age, city="北京"):
    print(f"{name}, {age}岁, {city}")

register("张三", 18)           # 张三, 18岁, 北京
register("李四", 22, "上海")   # 李四, 22岁, 上海
```

#### 可变参数

```python
# *args —— 接收任意数量的位置参数，打包为元组
def sum_all(*args):
    """计算所有参数之和"""
    return sum(args)

print(sum_all(1, 2, 3, 4))     # 10

# **kwargs —— 接收任意数量的关键字参数，打包为字典
def print_info(**kwargs):
    for key, value in kwargs.items():
        print(f"{key}: {value}")

print_info(name="张三", age=18, city="北京")
```

#### 参数顺序规则

```python
# 完整顺序：位置参数 → 默认参数 → *args → 关键字参数 → **kwargs
def func(a, b, c=10, *args, d=20, **kwargs):
    print(a, b, c, args, d, kwargs)

func(1, 2, 3, 4, 5, d=30, x=100)
# 1 2 3 (4, 5) 30 {'x': 100}
```

---

## 变量作用域

### 全局变量 vs 局部变量

```python
# 全局变量 —— 在函数外定义，函数内外均可读取
tax_rate = 0.05

def cal_tax(total_price):
    # 局部变量 —— 在函数内定义，函数外不可访问
    tax_rate = 0.08
    return total_price * tax_rate

print(cal_tax(10000))   # 800.0（使用局部的 0.08）
print(tax_rate)          # 0.05（全局的不受影响）
```

**查找优先级**：当前作用域 → 外层作用域（LEGB 规则：Local → Enclosing → Global → Built-in）

### global 关键字

```python
# 需要在函数内修改全局变量时，必须先用 global 声明
counter = 0

def increment():
    global counter    # 声明使用全局变量
    counter += 1

increment()
print(counter)        # 1
```

**实践建议**：尽量避免在函数中修改全局变量。用参数和返回值传递数据更安全、更易维护。`global` 主要用于全局计数器、共享配置等场景。

---

## 函数进阶

### 匿名函数 lambda

```python
# lambda 参数: 表达式 —— 适合简短的单行函数
square = lambda x: x ** 2
print(square(5))           # 25

# 常见搭配：作为 sort 的 key
students = [("张三", 85), ("李四", 92), ("王五", 78)]
students.sort(key=lambda s: s[1], reverse=True)  # 按分数降序
```

### 高阶函数

```python
# 函数可以作为参数传递，也可以作为返回值

# map：对每个元素应用函数
nums = [1, 2, 3, 4, 5]
squared = list(map(lambda x: x**2, nums))  # [1, 4, 9, 16, 25]

# filter：过滤元素
evens = list(filter(lambda x: x % 2 == 0, nums))  # [2, 4]

# sorted 的 key 参数
names = ["Alice", "Bob", "Charlie"]
sorted_names = sorted(names, key=len)  # 按长度排序
```

### 嵌套调用与闭包

```python
# 嵌套调用 —— 函数内部调用其他函数，遵循栈结构（后进先出）
def outer():
    print("outer before")
    inner()
    print("outer after")

def inner():
    print("inner")

outer()
# outer before → inner → outer after

# 闭包 —— 内部函数引用外部函数的变量，且外部函数已返回
def make_multiplier(n):
    def multiplier(x):
        return x * n     # 引用了外部的 n
    return multiplier

double = make_multiplier(2)
print(double(5))          # 10
print(double(10))         # 20
```

---

## 模块（Module）

### 导入方式

```python
# 方式一：import 模块名（推荐，命名空间清晰）
import math
print(math.pi)                # 3.141592653589793

# 方式二：from 模块 import 功能（直接用，不需要前缀）
from math import pi, sqrt
print(pi)                     # 3.141592653589793

# 方式三：from 模块 import *（不推荐，容易命名冲突）
from math import *

# 方式四：as 起别名
import numpy as np            # 常见约定
from math import sqrt as sq
```

### `__name__` 变量

```python
# 每个 .py 文件都有 __name__ 变量
# 直接运行时：__name__ == "__main__"
# 被导入时：__name__ == 模块名

# 标准写法 —— 让脚本既能被导入又能直接运行
def main():
    print("程序入口")

if __name__ == "__main__":
    main()
```

### 内置模块速查

```python
import os          # 文件和目录操作
os.listdir(".")           # 列出当前目录文件
os.path.exists("file.py") # 判断文件是否存在

import random      # 随机数
random.randint(1, 100)    # 1-100 的随机整数
random.choice([1,2,3])    # 随机选一个
random.shuffle(lst)       # 原地打乱列表

import json        # JSON 序列化
data = {"name": "张三"}
json_str = json.dumps(data, ensure_ascii=False)   # dict → str
obj = json.loads(json_str)                         # str → dict

import time        # 时间相关
time.time()               # 当前时间戳
time.sleep(2)             # 暂停 2 秒
```

---

## 包（Package）

### 结构

```
utils/                  # 包（文件夹）
├── __init__.py         # 包的标识文件，可描述包信息
├── my_var.py           # 模块：常量
└── my_fun.py           # 模块：函数
```

```python
# utils/__init__.py
__version__ = "1.0.0"
__author__ = "张三"
__all__ = ["my_fun", "my_var"]   # 控制 from utils import * 的范围
```

### 导入包中的模块

```python
# 方式一：import 包名.模块名
import utils.my_fun
utils.my_fun.log_separator()

# 方式二：from 包名 import 模块名
from utils import my_fun
my_fun.log_separator()

# 方式三：from 包名.模块名 import 功能名
from utils.my_fun import log_separator
log_separator()

# 方式四：from 包名 import *（需 __init__.py 中定义 __all__）
from utils import *
```

---

## 最佳实践

- 函数职责单一，一个函数只做一件事
- 用 docstring 描述函数的用途、参数、返回值
- 优先用参数/返回值传递数据，少用 global
- 模块命名蛇形（`my_module.py`），类名用 PascalCase
- 脚本文件加 `if __name__ == "__main__"` 保护
- `from module import *` 不推荐，容易命名污染

## 常见陷阱

- 默认参数用可变对象（list/dict）会有坑：默认值只创建一次，后续调用共享

```python
# ❌ 错误写法
def add_item(item, lst=[]):
    lst.append(item)
    return lst

# ✅ 正确写法
def add_item(item, lst=None):
    if lst is None:
        lst = []
    lst.append(item)
    return lst
```

- `global` 声明必须在使用之前，否则报错
- 包的 `__init__.py` 是必需的（Python 3.3+ 的命名空间包除外）
