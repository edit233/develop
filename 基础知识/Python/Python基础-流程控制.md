---
title: Python基础-流程控制
tags: [Python, 基础语法, 条件判断, 循环]
created: 2026-08-31
---

# Python基础 - 流程控制

## 概述

程序默认从上到下逐行执行，流程控制让你能根据条件分支或重复执行代码。核心三类：条件判断、循环、循环控制。

---

## 条件判断

### if 基础

```python
# if 语法 —— 条件为 True 才执行缩进块
score = 695
if score > 680:
    print("欢迎你，来清华读书")
    print("恭喜你即将踏入精彩的大学生活")
```

**注意**：Python 用缩进（通常 4 个空格）定义代码块，不用花括号。同一个 if 块中缩进空格数必须一致。

### if...else

```python
# 二选一：条件成立执行 A，否则执行 B
account = input("请输入账号: ")
password = input("请输入密码: ")

if account == "18888888888" and password == "666888":
    print("登录成功")
else:
    print("登录失败")
```

### if...elif...else

```python
# 多条件分支：从上往下匹配，命中一个就不再往下
score = 85

if score >= 90:
    grade = "A"
elif score >= 80:
    grade = "B"
elif score >= 70:
    grade = "C"
elif score >= 60:
    grade = "D"
else:
    grade = "F"

print(f"成绩等级: {grade}")  # B
```

### 三元表达式

```python
# 条件为真时的值 if 条件 else 条件为假时的值
age = 20
status = "成年" if age >= 18 else "未成年"
```

### match...case（Python 3.10+）

```python
# 类似其他语言的 switch-case，但更强大
choice = input("请选择操作(1-5): ")

match choice:
    case "1":
        print("添加")
    case "2":
        print("修改")
    case "3":
        print("删除")
    case "4":
        print("查询")
    case "5":
        print("退出")
    case _:               # _ 是通配符，匹配所有未匹配的情况
        print("无效操作")
```

---

## 循环

### while 循环

```python
# while 条件为 True 就一直执行
count = 0
while count < 5:
    print(f"第 {count + 1} 次循环")
    count += 1

# 经典：输入验证循环
while True:
    username = input("请输入用户名(输入 q 退出): ")
    if username == "q":
        break
    if username == "":
        print("用户名不能为空！")
        continue
    print(f"欢迎你, {username}")
```

### for 循环

```python
# for 循环 —— 遍历可迭代对象（字符串、列表、range 等）

# 遍历字符串
for char in "Hello":
    print(char)  # H e l l o 逐行输出

# 遍历列表
for item in [1, 2, 3, 4, 5]:
    print(item)

# range() 生成数字序列
# range(stop)            → 0 到 stop-1
# range(start, stop)     → start 到 stop-1
# range(start, stop, step) → start 到 stop-1，步长 step
for i in range(1, 6):        # 1, 2, 3, 4, 5
    print(i)

for i in range(0, 10, 2):    # 0, 2, 4, 6, 8（步长 2）
    print(i)

for i in range(5, 0, -1):    # 5, 4, 3, 2, 1（倒序）
    print(i)
```

### 嵌套循环

```python
# 外层控制行，内层控制列
# 九九乘法表
for i in range(1, 10):
    for j in range(1, i + 1):
        print(f"{j} * {i} = {i * j}", end="\t")
    print()  # 换行

# 输出结果：
# 1 * 1 = 1
# 1 * 2 = 2   2 * 2 = 4
# 1 * 3 = 3   2 * 3 = 6   3 * 3 = 9
# ...
```

---

## 循环控制

### break —— 终止循环

```python
# break 立即跳出当前循环，循环后的 else 块不会执行
while True:
    pwd = input("请输入密码: ")
    if pwd == "666888":
        print("密码正确")
        break          # 跳出循环
    print("密码错误，请重试")
```

### continue —— 跳过本次

```python
# continue 跳过当前迭代，直接进入下一次循环
for i in range(1, 11):
    if i % 3 == 0:
        continue       # 跳过 3 的倍数
    print(i)           # 输出 1, 2, 4, 5, 7, 8, 10
```

### while...else / for...else

```python
# else 块在循环正常结束（非 break）时执行
# 被 break 终止的循环，else 不执行

# 示例：查找质数
for n in range(2, 10):
    for i in range(2, n):
        if n % i == 0:
            break
    else:              # 循环正常结束（没有 break），说明是质数
        print(f"{n} 是质数")
```

---

## 最佳实践

- 条件判断优先用 `if...elif...else`，避免过深嵌套
- `while True` + `break` 适合需要持续验证的场景（如登录）
- 嵌套循环不宜超过 3 层，过深时考虑拆分函数
- `match...case` 适合替代长串 `if...elif` 的值匹配场景

## 常见陷阱

- 缩进错误是 Python 最常见的语法错误，注意 Tab 和空格不要混用
- `break` 只能出现在循环中，不能单独使用
- `while True` 别忘了循环体内要有退出条件，否则死循环
- `for...else` 的 else 容易被误解，它在**循环正常结束**时执行，break 会跳过它
