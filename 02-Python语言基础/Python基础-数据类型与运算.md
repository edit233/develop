---
title: Python基础-数据类型与运算
tags: [Python, 基础语法, 数据类型, 运算符]
created: 2026-08-31
---

# Python基础 - 数据类型与运算

## 概述

Python 基础语法的起点：变量、数据类型、输入输出、以及各类运算符。掌握这些才能进行后续的逻辑编写。

---

## 变量与数据类型

### 变量

变量是存储数据的容器，Python 中变量无需声明类型，由赋值时的值决定。

```python
# 变量赋值 —— Python 是动态类型语言，变量类型由赋值决定
name = "张三"       # str 字符串
age = 18            # int 整数
height = 1.75       # float 浮点数
is_student = True   # bool 布尔值

# 同时给多个变量赋值
x, y, z = 1, 2, 3

# 交换两个变量的值（Python 特有的简洁写法）
a, b = 10, 20
a, b = b, a         # 交换后 a=20, b=10
```

**命名规则**：
- 只能包含字母、数字、下划线，且不能以数字开头
- 区分大小写（`name` 和 `Name` 是不同变量）
- 不能使用 Python 关键字（如 `if`、`for`、`class` 等）
- 推荐蛇形命名法：`user_name`、`total_price`

### 数据类型

| 类型 | 关键字 | 示例 | 说明 |
|------|--------|------|------|
| 整数 | `int` | `42`, `-7`, `0` | 无大小限制 |
| 浮点数 | `float` | `3.14`, `-0.5` | 有精度问题，计算时注意 |
| 字符串 | `str` | `"hello"`, `'world'` | 单双引号均可 |
| 布尔值 | `bool` | `True`, `False` | 注意首字母大写 |
| 空值 | `NoneType` | `None` | 表示"没有值"，不是 0 也不是空字符串 |

```python
# 查看变量类型
x = 42
print(type(x))  # <class 'int'>

# 类型转换
num_str = "123"
num_int = int(num_str)      # str → int
num_float = float(num_str)  # str → float
back_str = str(num_int)     # int → str

# 注意：int("3.14") 会报错，需要先 float 再 int
pi = int(float("3.14"))     # 正确写法：先转 float → 再转 int → 3
```

### 字符串详解

```python
# 定义方式
s1 = "Hello"           # 双引号
s2 = 'World'           # 单引号
s3 = """多行
字符串"""               # 三引号（多行）

# 字符串拼接
greeting = s1 + " " + s2  # "Hello World"

# f-string 格式化（推荐）
name, age = "张三", 18
print(f"我叫{name}，今年{age}岁")  # 我叫张三，今年18岁
print(f"圆周率: {3.14159:.2f}")     # 保留两位小数: 3.14

# 常用方法
"hello".upper()          # "HELLO" —— 转大写
"HELLO".lower()          # "hello" —— 转小写
" hello ".strip()        # "hello" —— 去除首尾空白
"a,b,c".split(",")       # ["a", "b", "c"] —— 按分隔符切割
"-".join(["a","b","c"])  # "a-b-c" —— 用分隔符连接
"hello world".replace("world", "python")  # "hello python"
"hello".startswith("he")  # True —— 是否以某字符串开头
"hello".endswith("lo")    # True —— 是否以某字符串结尾
"hello".count("l")        # 2 —— 统计出现次数
"hello".find("ll")        # 2 —— 查找索引位置（找不到返回 -1）
```

### 输入与输出

```python
# 输出 —— print()
print("Hello World")             # 基本输出
print("a", "b", "c", sep="-")    # 指定分隔符: a-b-c
print("Hello", end="")           # 不换行
print("World")                   # 输出: HelloWorld

# 输入 —— input()，返回值始终是字符串
username = input("请输入用户名: ")   # 返回 str 类型
age = int(input("请输入年龄: "))     # 需要 int() 转换
price = float(input("请输入价格: ")) # 需要 float() 转换
```

---

## 运算符

### 算术运算符

| 运算符 | 含义 | 示例 | 结果 |
|--------|------|------|------|
| `+` | 加 | `10 + 3` | `13` |
| `-` | 减 | `10 - 3` | `7` |
| `*` | 乘 | `10 * 3` | `30` |
| `/` | 除（结果为 float） | `10 / 3` | `3.3333...` |
| `//` | 整除（向下取整） | `10 // 3` | `3` |
| `%` | 取余 | `10 % 3` | `1` |
| `**` | 幂运算 | `2 ** 10` | `1024` |

```python
# 注意：Python 的 // 是向下取整（floor division）
print(-7 // 2)    # -4（不是 -3）
print(7 // 2)     # 3
```

### 赋值运算符

```python
x = 10
x += 5   # x = x + 5  → 15
x -= 3   # x = x - 3  → 12
x *= 2   # x = x * 2  → 24
x /= 4   # x = x / 4  → 6.0
x //= 2  # x = x // 2 → 3.0
x %= 2   # x = x % 2  → 1.0
x **= 3  # x = x ** 3 → 1.0
```

### 比较运算符

返回布尔值 `True` / `False`：

| 运算符 | 含义 | 示例 |
|--------|------|------|
| `==` | 等于 | `100 == 100` → `True` |
| `!=` | 不等于 | `100 != 100` → `False` |
| `>` | 大于 | `100 > 100` → `False` |
| `>=` | 大于等于 | `100 >= 100` → `True` |
| `<` | 小于 | `100 < 100` → `False` |
| `<=` | 小于等于 | `100 <= 100` → `True` |

```python
# Python 支持链式比较（其他语言不常见）
n = 15
print(10 <= n <= 20)   # True —— 等价于 10 <= n and n <= 20
```

### 逻辑运算符

| 运算符 | 含义 | 规则 |
|--------|------|------|
| `and` | 逻辑与 | 两边都为 True 才为 True |
| `or` | 逻辑或 | 任一边为 True 就为 True |
| `not` | 逻辑非 | 取反：True → False，False → True |

```python
# and：两个条件都满足
age = 25
income = 15000
can_loan = age >= 18 and income >= 10000  # True

# or：至少一个满足
is_vip = True
has_coupon = False
can_discount = is_vip or has_coupon  # True

# not：取反
is_raining = False
bring_umbrella = not is_raining  # True
```

### 运算符优先级（从高到低）

```
**（幂运算）
+x, -x, ~x（一元运算符）
*, /, //, %
+, -
==, !=, >, >=, <, <=
not
and
or
```

**实践建议**：优先级记不住时用括号明确优先级，可读性更好。

---

## 最佳实践

- 变量命名用蛇形命名法，见名知意
- 链式比较 `10 <= n <= 20` 比 `n >= 10 and n <= 20` 更 Pythonic
- `input()` 返回字符串，需要数值时记得类型转换
- f-string 是字符串格式化的首选方式
- 运算符优先级不确定时加括号

## 常见陷阱

- `/` 返回 float：`10 / 2` 结果是 `5.0`，不是 `5`
- `//` 向下取整：`-7 // 2` 结果是 `-4`，不是 `-3`
- 浮点数精度：`0.1 + 0.2` 不等于 `0.3`，涉及精确计算用 `decimal` 模块
- `int("3.14")` 报错：字符串转 int 不能包含小数点，需先 `float()` 再 `int()`
