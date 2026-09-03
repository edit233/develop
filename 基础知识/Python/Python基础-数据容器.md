---
title: Python基础-数据容器
tags: [Python, 数据容器, list, tuple, set, dict, 字符串]
created: 2026-08-31
---

# Python基础 - 数据容器

## 概述

数据容器用于批量存储数据。Python 提供五种内置容器，根据是否有序、可否重复、可否修改来区分：

| 容器 | 有序 | 可重复 | 可修改 | 典型用途 |
|------|------|--------|--------|----------|
| `list` | ✅ | ✅ | ✅ | 通用有序集合 |
| `tuple` | ✅ | ✅ | ❌ | 不可变数据、函数多返回值 |
| `str` | ✅ | ✅ | ❌ | 文本处理 |
| `set` | ❌ | ❌ | ✅ | 去重、集合运算（交/并/差） |
| `dict` | ✅(3.7+) | key 不可重复 | ✅ | 键值对映射 |

---

## 列表（list）

### 定义与访问

```python
# 定义 —— 方括号，元素用逗号分隔，可存任意类型
scores = [670, 556, 582, 435, 608]
mixed = [42, "hello", 3.14, True]      # 混合类型

# 访问 —— 索引从 0 开始，负索引从 -1 开始（倒数）
print(scores[0])    # 670（第一个元素）
print(scores[-1])   # 608（最后一个元素）

# 修改
scores[0] = 700     # 将第一个元素改为 700

# 删除
del scores[2]       # 删除索引为 2 的元素
```

### 切片

```python
# 语法：序列[开始:结束:步长] —— 左闭右开
nums = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]

nums[2:5]       # [2, 3, 4]       —— 索引 2 到 4
nums[:4]        # [0, 1, 2, 3]    —— 从头到索引 3
nums[6:]        # [6, 7, 8, 9]    —— 索引 6 到末尾
nums[::2]       # [0, 2, 4, 6, 8] —— 步长为 2
nums[::-1]      # [9, 8, ..., 0]  —— 反转列表

# 切片也可以赋值（列表特有的，字符串不行）
nums[1:3] = [10, 20]  # [0, 10, 20, 3, 4, ...]
```

### 常用方法

```python
lst = [3, 1, 4, 1, 5, 9]

lst.append(2)        # 末尾添加元素 → [3, 1, 4, 1, 5, 9, 2]
lst.insert(0, 10)    # 在索引 0 处插入 → [10, 3, 1, ...]
lst.extend([6, 7])   # 批量添加（合并列表）
lst.pop()            # 弹出末尾元素并返回
lst.pop(0)           # 弹出指定索引的元素
lst.remove(1)        # 删除第一个值为 1 的元素
lst.clear()          # 清空列表
lst.sort()           # 原地排序（升序）
lst.sort(reverse=True)  # 降序排序
lst.reverse()        # 原地反转
lst.count(1)         # 统计 1 出现的次数
lst.index(4)         # 查找 4 的索引位置（不存在则报错）
len(lst)             # 列表长度
```

### 列表推导式

```python
# 语法：[表达式 for 变量 in 可迭代对象 if 条件]
squares = [x**2 for x in range(1, 11)]          # [1, 4, 9, 16, ..., 100]
evens = [x for x in range(1, 21) if x % 2 == 0] # [2, 4, 6, ..., 20]
```

---

## 元组（tuple）

### 定义

```python
# 圆括号定义，不可修改（immutable）
point = (10, 20)
colors = ("红", "绿", "蓝")

# 单元素元组必须加逗号（不加会被当成括号表达式）
t1 = (1)      # 这是 int，值为 1
t2 = (1,)     # 这才是 tuple

# 访问方式与 list 相同
print(point[0])     # 10
print(colors[-1])   # 蓝
```

### 为什么用元组

- **不可变**：适合存储不应被修改的数据（如坐标、颜色配置）
- **可哈希**：可以作为字典的 key（list 不行）
- **性能**：比 list 略快，内存占用更小
- **函数多返回值**：Python 函数返回多个值时，实际返回的是元组

```python
def get_min_max(scores):
    return min(scores), max(scores)  # 返回元组

lo, hi = get_min_max([1, 5, 3, 9, 2])  # 解包赋值
```

---

## 字符串（str）

字符串本质是**不可变的字符序列**，支持索引、切片、遍历等序列操作。

```python
s = "Hello Python"

# 切片 —— 与 list 语法相同
s[0:5]       # "Hello"
s[::-1]      # "nohtyP olleH"（反转）

# 常用方法
s.upper()                    # "HELLO PYTHON"
s.lower()                    # "hello python"
s.strip()                    # 去除首尾空白
s.split(" ")                 # ["Hello", "Python"]
"-".join(["a", "b", "c"])   # "a-b-c"
s.replace("Hello", "Hi")    # "Hi Python"
s.find("Python")            # 6（索引位置）
s.count("l")                # 2
s.startswith("Hello")       # True
s.endswith("Python")        # True
s.isdigit()                 # 是否全为数字
s.isalpha()                 # 是否全为字母

# f-string 格式化（最常用）
name, score = "张三", 95.678
print(f"姓名: {name}, 分数: {score:.1f}")  # 保留1位小数
```

---

## 集合（set）

### 定义与特点

```python
# 花括号定义，自动去重，无序
s1 = {1, 2, 3, 4, 5}
s2 = {3, 4, 5, 6, 7}

# 注意：空集合必须用 set()，不能用 {}（这是空字典）
empty_set = set()   # ✅ 空集合
empty_dict = {}     # ✅ 空字典
```

### 常用方法

```python
s = {10, 20, 30}

s.add(40)           # 添加元素
s.remove(20)        # 删除元素（不存在则报错）
s.discard(100)      # 删除元素（不存在不报错，推荐）
s.pop()             # 随机弹出一个元素
s.clear()           # 清空
```

### 集合运算

```python
a = {1, 2, 3, 4, 5}
b = {4, 5, 6, 7, 8}

a & b               # 交集: {4, 5}
a | b               # 并集: {1, 2, 3, 4, 5, 6, 7, 8}
a - b               # 差集: {1, 2, 3}（在 a 中但不在 b 中）
a ^ b               # 对称差集: {1, 2, 3, 6, 7, 8}（不同时在两者中）

# 等价的 method 写法
a.intersection(b)       # 交集
a.union(b)              # 并集
a.difference(b)         # 差集
a.symmetric_difference(b)  # 对称差集
```

### 集合推导式

```python
# 快速构建集合
unique_lengths = {len(word) for word in ["hello", "hi", "hey", "ok"]}
# {2, 3, 5} —— 自动去重
```

---

## 字典（dict）

### 定义与访问

```python
# 键值对（key: value）存储，key 必须是不可变类型（str/int/float/tuple）
scores = {"王林": 670, "韩立": 556, "李慕婉": 582}

# 访问
print(scores["王林"])           # 670
print(scores.get("紫灵", 0))   # 0（key 不存在时返回默认值，不报错）

# 修改 / 新增
scores["紫灵"] = 435           # 不存在则新增
scores["王林"] = 680           # 已存在则修改

# 删除
del scores["韩立"]             # 删除指定 key
popped = scores.pop("李慕婉")  # 删除并返回 value
```

### 遍历

```python
scores = {"王林": 670, "韩立": 556, "李慕婉": 582}

# 遍历 key
for key in scores:
    print(key)

# 遍历 value
for value in scores.values():
    print(value)

# 遍历键值对
for key, value in scores.items():
    print(f"{key}: {value}")
```

### 常用方法

```python
d = {"a": 1, "b": 2}

d.keys()             # dict_keys(["a", "b"]) —— 所有 key
d.values()           # dict_values([1, 2])   —— 所有 value
d.items()            # dict_items([("a",1), ("b",2)]) —— 键值对元组
d.update({"c": 3})   # 批量更新/新增
d.clear()            # 清空
"d" in d             # True —— 判断 key 是否存在
len(d)               # 元素个数
```

### 嵌套字典

```python
# 字典可以嵌套，适合存储结构化数据
shopping_cart = {
    "手机": {"price": 6999, "num": 1},
    "耳机": {"price": 299, "num": 2},
}

# 访问嵌套数据
print(shopping_cart["手机"]["price"])  # 6999
```

---

## 容器通用操作

```python
# len() 获取长度
len([1, 2, 3])         # 3
len({"a": 1, "b": 2})  # 2

# in / not in 判断是否包含
3 in [1, 2, 3]         # True
"hello" in "hello world"  # True

# + 拼接（list、str、tuple 支持）
[1, 2] + [3, 4]        # [1, 2, 3, 4]

# * 重复
[0] * 5                # [0, 0, 0, 0, 0]
"ab" * 3               # "ababab"
```

---

## 最佳实践

- 需要按键查找 → 用 `dict`
- 需要去重或集合运算 → 用 `set`
- 需要有序可修改 → 用 `list`
- 数据不可变/做字典 key → 用 `tuple`
- 遍历字典用 `.items()` 比先取 key 再取 value 更高效

## 常见陷阱

- 空集合用 `set()`，`{}` 是空字典
- dict 的 key 不能是 list/set/dict（不可哈希类型）
- list 切片返回新列表（浅拷贝），嵌套对象仍是引用
- `remove()` 找不到元素会报错，`discard()` 不会
