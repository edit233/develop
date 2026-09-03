---
title: Python基础-面向对象
tags: [Python, 面向对象, 类, 继承, 多态, 封装]
created: 2026-08-31
---

# Python基础 - 面向对象

## 概述

面向对象编程（OOP）把数据和操作数据的方法封装到「类」中，通过创建对象来使用。与面向过程（关注步骤）不同，OOP 关注的是**谁来做**——把相关属性和行为组织到一个实体里。

核心四概念：**类与对象、封装、继承、多态**。

---

## 类与对象

### 定义与使用

```python
# 类是模板，对象是实例
class Student:
    # 类属性 —— 所有实例共享
    school = "清华"

    # __init__ 构造方法 —— 创建对象时自动调用
    def __init__(self, name, age):
        # 实例属性 —— 每个对象独有
        self.name = name      # self 指向当前对象
        self.age = age

    # 实例方法 —— 第一个参数必须是 self
    def study(self, course):
        print(f"{self.name} 正在学习 {course}")

# 创建对象（实例化）
stu1 = Student("张三", 18)
stu2 = Student("李四", 20)

# 使用
print(stu1.school)         # 清华（类属性，通过对象也能访问）
stu1.study("Python")       # 张三 正在学习 Python
print(stu1.name)           # 张三
```

### self 是什么

`self` 代表当前对象实例，调用方法时 Python 自动传入，不需要手动传：

```python
stu1.study("Python")
# 等价于 Student.study(stu1, "Python")
```

---

## 封装

### 访问控制

```python
class BankAccount:
    def __init__(self, owner, balance):
        self.owner = owner        # 公有属性 —— 外部可直接访问
        self.__balance = balance  # 私有属性 —— 外部不能直接访问（名称改写为 _BankAccount__balance）

    def deposit(self, amount):
        """存款"""
        if amount > 0:
            self.__balance += amount
            print(f"存入 {amount}，余额: {self.__balance}")

    def withdraw(self, amount):
        """取款"""
        if 0 < amount <= self.__balance:
            self.__balance -= amount
            print(f"取出 {amount}，余额: {self.__balance}")
        else:
            print("余额不足")

    def get_balance(self):
        """通过方法间接访问私有属性"""
        return self.__balance

account = BankAccount("张三", 1000)
account.deposit(500)            # 存入 500，余额: 1500
print(account.get_balance())    # 1500
# print(account.__balance)      # ❌ 报错：AttributeError
```

**原则**：用私有属性保护内部状态，通过公有方法提供受控访问（getter/setter 或直接用方法封装逻辑）。

---

## 继承

### 基础继承

```python
# 父类（基类）
class Animal:
    def __init__(self, name, age):
        self.name = name
        self.age = age

    def speak(self):
        print(f"{self.name} 发出声音")

# 子类（派生类）继承父类
class Dog(Animal):
    def __init__(self, name, age, breed):
        super().__init__(name, age)   # 调用父类构造方法
        self.breed = breed            # 子类新增属性

    def speak(self):                   # 重写父类方法
        print(f"{self.name} 汪汪叫")

class Cat(Animal):
    def speak(self):
        print(f"{self.name} 喵喵叫")

# 使用
dog = Dog("旺财", 3, "金毛")
dog.speak()          # 旺财 汪汪叫
dog.speak.__self__   # <Dog object>

cat = Cat("咪咪", 2)
cat.speak()          # 咪咪 喵喵叫
```

### 方法重写（Override）

子类定义与父类同名的方法，自动覆盖父类实现。调用时执行子类版本。

### super() 调用父类方法

```python
class ElectricCar:
    def __init__(self, brand, model, color, battery):
        self.brand = brand
        self.model = model
        self.color = color
        self.battery = battery

    def info(self):
        return f"{self.brand} {self.model}，电池: {self.battery}kWh"

class PremiumElectricCar(ElectricCar):
    def __init__(self, brand, model, color, battery, luxury_pack):
        super().__init__(brand, model, color, battery)  # 复用父类初始化
        self.luxury_pack = luxury_pack
```

---

## 多态

### 基于继承的多态

同一个方法调用，传入不同子类对象，触发不同行为：

```python
class Car:
    def __init__(self, brand, model):
        self.brand = brand
        self.model = model

    def charge(self):
        print(f"{self.brand} {self.model} 正在补充燃料...")

class FuelCar(Car):
    def charge(self):
        print(f"{self.brand} {self.model} 正在加油...")

class ElectricCar(Car):
    def charge(self):
        print(f"{self.brand} {self.model} 正在充电...")

# 同一个函数，传入不同对象 → 不同行为
def handle_charge(car: Car):     # 参数类型声明为父类
    car.charge()                  # 实际调用子类的 charge

handle_charge(FuelCar("BMW", "X5"))        # BMW X5 正在加油...
handle_charge(ElectricCar("BYD", "汉"))    # BYD 汉 正在充电...
```

### 鸭子类型（Duck Typing）

Python 的多态不依赖继承，只要对象有对应方法就能用：

```python
# 三个完全无关的类，没有继承关系，但都有 swimming 方法
class Dog:
    def swimming(self):
        print(f"{self.name} 在游泳")

class Duck:
    def swimming(self):
        print(f"{self.name} 在游泳")

class Pig:
    def swimming(self):
        print(f"{self.name} 在游泳")

# 只要有 swimming 方法，就能传进来
def go_swimming(obj):
    obj.swimming()

go_swimming(Dog())     # Dog 在游泳
go_swimming(Duck())    # Duck 在游泳
go_swimming(Pig())     # Pig 在游泳
```

**核心**：关注对象**能做什么**（有什么方法），而不是**是什么类型**。

---

## 综合案例：图书管理系统

展示了类的设计、继承、封装的综合运用：

```python
import json

class Book:
    def __init__(self, book_id, title, author, total_num):
        self.book_id = book_id
        self.title = title
        self.author = author
        self.total_num = total_num          # 总库存
        self.__available_num = total_num    # 可借数量（私有）

    def get_available_num(self):
        return self.__available_num

    def borrow(self):
        if self.__available_num > 0:
            self.__available_num -= 1
            return True
        return False

    def return_book(self):
        if self.__available_num < self.total_num:
            self.__available_num += 1
            return True
        return False

class Member:
    def __init__(self, member_id, name, password):
        self.member_id = member_id
        self.name = name
        self.__password = password
        self.__borrowed_books = []     # 已借图书列表

    def get_password(self):
        return self.__password

    def get_borrowed_books(self):
        return self.__borrowed_books

    def get_max_books(self):
        return 3                        # 普通会员最多借 3 本

    def borrow_book(self, book):
        if len(self.__borrowed_books) >= self.get_max_books():
            print(f"借阅失败，已达上限 {self.get_max_books()} 本")
            return
        if book.borrow():
            self.__borrowed_books.append(book)
            print(f"借阅成功: {book.title}")
        else:
            print(f"借阅失败: {book.title} 库存不足")

    def return_book(self, book):
        if book in self.__borrowed_books:
            book.return_book()
            self.__borrowed_books.remove(book)
            print(f"归还成功: {book.title}")
        else:
            print("归还失败，你没有借过这本书")

class VipMember(Member):
    def __init__(self, member_id, name, password, vip_level):
        super().__init__(member_id, name, password)
        self.vip_level = vip_level

    def get_max_books(self):
        return 6 + self.vip_level    # VIP 等级越高，可借越多

class LibrarySystem:
    def __init__(self):
        self.books = {}
        self.members = {}
        self.current_member = None

    def login(self):
        member_id = input("请输入会员卡号: ")
        password = input("请输入会员密码: ")
        if member_id in self.members:
            member = self.members[member_id]
            if member.get_password() == password:
                self.current_member = member
                print(f"登录成功, 欢迎 {member.name}")
                return True
        print("登录失败")
        return False

    def borrow_book(self):
        book_id = input("请输入图书编号: ")
        if book_id in self.books:
            self.current_member.borrow_book(self.books[book_id])

    def return_book(self):
        book_id = input("请输入要归还的图书编号: ")
        if book_id in self.books:
            self.current_member.return_book(self.books[book_id])

    def show_borrowed(self):
        for book in self.current_member.get_borrowed_books():
            print(f"  {book.book_id} - {book.title}")

    def run(self):
        if self.login():
            while True:
                print("\n1.借书  2.还书  3.查看借阅  4.退出")
                choice = input("请选择: ")
                match choice:
                    case "1": self.borrow_book()
                    case "2": self.return_book()
                    case "3": self.show_borrowed()
                    case "4": break
```

**设计要点**：
- `Book` 用私有属性保护库存，通过 `borrow()`/`return_book()` 受控修改
- `Member` 定义公共接口，`VipMember` 通过重写 `get_max_books()` 改变借阅上限——多态
- `LibrarySystem` 负责业务流程编排，不关心具体会员类型——面向接口编程

---

## 最佳实践

- `__init__` 中定义实例属性，类属性用于所有实例共享的数据
- 私有属性用 `__` 前缀，通过方法暴露受控访问
- 子类只在需要扩展或修改父类行为时才继承，不要为了复用代码强行继承
- 多态优先用鸭子类型，不需要刻意构造继承体系
- `super().__init__()` 在子类构造中调用，确保父类初始化完整

## 常见陷阱

- `__init__` 忘了 `self` 参数：`def __init__(name):` → 报错
- 忘了 `super().__init__()`：子类不会自动调用父类构造方法
- 私有属性 `__name` 在子类中不能直接访问（名称改写为 `_类名__name`）
- `self` 不是关键字，只是约定俗成的名称，但强烈建议不要改
