---
title: Java基础 - 基础语法、流程控制与方法
tags: [Java, 基础语法, 流程控制, 方法, JDK, IDEA]
created: 2026-08-23
---

## 一、Java 入门

### 1.1 Java 介绍

Java 是 Sun 公司 1995 年推出的高级编程语言，作者：詹姆斯·高斯林（James Gosling）。

**核心优势：**
- **应用广泛**：全球最流行的编程语言之一，国内使用最广泛
- **性能稳定**：多年优化，适配企业级高并发场景
- **生态完善**：开发社区庞大，Spring、MyBatis 等框架丰富

### 1.2 安装 JDK

JDK（Java Development Kit）是 Java 开发者工具包，必须安装才能开发 Java 代码。

**安装步骤：**

1. 下载 JDK：https://www.oracle.com/java/technologies/downloads/
2. 解压到本地安装目录（**路径必须无中文、无空格**）
3. 配置环境变量：
   - 新建变量 `JAVA_HOME`，值为 JDK 安装路径
   - 在 `Path` 中追加 `%JAVA_HOME%\bin`
4. 验证：打开新 CMD，输入 `java -version` 显示版本信息即成功

### 1.3 安装 IDEA

IntelliJ IDEA 是 Java 开发首选 IDE，智能提示强、重构功能完善。

下载地址：https://www.jetbrains.com/zh-cn/idea/download/

**注意：** 2026.4.1 版本 IDEA 默认集成 JDK26，生成的主方法不适配 JDK21，需要手动修改 JDK 版本配置。

### 1.4 项目结构

IDEA 分层管理代码结构：

```
Project（工程）  →  Module（模块）  →  Package（包）  →  Class（类）
```

- **Project**：顶级组织单元，通常一个项目一个工程
- **Module**：项目子单元，对应独立业务
- **Package**：模块内分类管理代码，命名规范为「公司域名倒写 + 业务名称」（如 `com.itheima.demo`）
- **Class**：Java 代码最小单元，所有代码写在类中

**创建步骤：**
1. 创建 `Empty Project`，命名为 `java_base`
2. 设置 JDK 版本为 `21`
3. 创建模块 `day01`
4. 在 `src` 下新建包 `com.itheima.a_quickstart`
5. 在包下创建类 `Demo1`

### 1.5 Hello World 程序

```java
package com.itheima.a_quickstart;

public class Demo1 {
    // main 方法是 Java 程序入口，JVM 自动识别执行
    public static void main(String[] args) {
        // sout 快捷键生成输出语句，将内容打印到控制台
        System.out.println("Hello World");
    }
}
```

**IDEA 常用快捷键：**
- `psvm`：生成 main 方法入口
- `sout`：生成输出语句
- `Ctrl + D`：快速复制当前行

---

## 二、基础语法

### 2.1 注释

Java 支持三种注释方式：

```java
// 单行注释

/* 多行注释 */

/**
 * 文档注释（JavaDoc）
 * 用于生成 API 文档
 */
```

### 2.2 字面量

字面量是数据在程序中的书写格式，常见类型：

| 类型 | 示例 | 说明 |
|------|------|------|
| 整数 | `666`, `-88` | 直接写数字 |
| 小数 | `13.14`, `-5.21` | 带小数点的数字 |
| 字符串 | `"HelloWorld"`, `"黑马"` | 双引号包裹 |
| 字符 | `'A'`, `'0'`, `'我'` | 单引号包裹，且只能一个字符 |
| 布尔值 | `true`, `false` | 只有两个值 |
| 空值 | `null` | 表示空，不是空字符串 `""` |

**特殊转义字符：**
- `\t`：制表符（Tab）
- `\n`：换行符

### 2.3 变量

变量是内存中的一块区域，用于存储数据，**存储的数据可以变化**。

**变量定义格式：**

```java
数据类型 变量名 = 数据值;   // 一步完成声明并赋值

// 示例
int age = 18;              // 定义整数变量，存储年龄
double price = 9.9;        // 定义小数变量，存储价格
String name = "张三";       // 定义字符串变量，存储姓名
```

**注意事项：**
- 变量名不允许重复定义
- 一条语句可以定义多个变量（用逗号分隔）
- 变量在使用之前必须赋值
- 变量作用域在 `{}` 内有效

### 2.4 数据类型

Java 数据类型分为基本数据类型和引用数据类型：

**基本数据类型（8 种）：**

| 类型 | 关键字 | 内存占用 | 取值范围 |
|------|--------|----------|----------|
| 字节型 | `byte` | 1 字节 | -128 ~ 127 |
| 短整型 | `short` | 2 字节 | -32768 ~ 32767 |
| 整型 | `int` | 4 字节 | 约 ±21 亿 |
| 长整型 | `long` | 8 字节 | 非常大 |
| 单精度 | `float` | 4 字节 | -3.403E38 ~ 3.403E38 |
| 双精度 | `double` | 8 字节 | -1.7976931348623157E308 ~ 1.7976931348623157E308 |
| 字符型 | `char` | 2 字节 | 0 ~ 65535 |
| 布尔型 | `boolean` | 1 字节 | `true` / `false` |

**类型转换：**
- **自动类型转换**：小范围类型 → 大范围类型（如 `int` → `long`）
- **强制类型转换**：大范围类型 → 小范围类型（可能丢失精度）

```java
int a = 10;
double b = a;      // 自动类型转换：int → double，b = 10.0

double c = 3.14;
int d = (int) c;   // 强制类型转换：double → int，d = 3（丢失精度）
```

### 2.5 运算符

#### 算术运算符

| 运算符 | 作用 | 示例 |
|--------|------|------|
| `+` | 加 | `a + b` |
| `-` | 减 | `a - b` |
| `*` | 乘 | `a * b` |
| `/` | 除（整数相除得商） | `a / b` |
| `%` | 取余 | `a % b` |

```java
int a = 10, b = 3;
System.out.println(a + b);  // 13
System.out.println(a - b);  // 7
System.out.println(a * b);  // 30
System.out.println(a / b);  // 3（整数除法取商）
System.out.println(a % b);  // 1（取余数）

// 注意：'a' + 10 的结果是 107（ASCII 码值相加）
System.out.println('a' + 10 + "mjj");  // 107mjj
```

#### 自增自减运算符

- `++`：自增，变量值 +1
- `--`：自减，变量值 -1

**关键区别：**
- **单独使用**：`i++` 和 `++i` 效果相同
- **表达式中**：前缀先运算后赋值，后缀先赋值后运算

```java
int x = 10;
int x1 = x++;    // x1=10, x=11（先赋值 x1，再 x 自增）
int y = 10;
int y1 = ++y;    // y=11, y1=11（先 y 自增，再赋值 y1）
```

#### 赋值运算符

| 运算符 | 示例 | 等价于 |
|--------|------|--------|
| `+=` | `a += b` | `a = a + b` |
| `-=` | `a -= b` | `a = a - b` |
| `*=` | `a *= b` | `a = a * b` |
| `/=` | `a /= b` | `a = a / b` |
| `%=` | `a %= b` | `a = a % b` |

**注意：** `+=` 等运算符包含强制类型转换，如 `byte b = 10; b += 5;` 等价于 `b = (byte)(b + 5);`

#### 关系运算符（比较运算符）

用于比较两个变量的大小，结果为 `boolean` 类型：

| 运算符 | 说明 | 示例 |
|--------|------|------|
| `==` | 等于 | `a == b` |
| `!=` | 不等于 | `a != b` |
| `>`  | 大于 | `a > b` |
| `>=` | 大于等于 | `a >= b` |
| `<`  | 小于 | `a < b` |
| `<=` | 小于等于 | `a <= b` |

#### 逻辑运算符

把多个条件放在一起运算，返回 `boolean` 值：

| 运算符 | 说明 | 特点 |
|--------|------|------|
| `&` | 逻辑与 | 并且，所有条件都为 true 才是 true |
| `\|` | 逻辑或 | 或者，有一个条件为 true 就是 true |
| `!` | 逻辑非 | 取反 |
| `&&` | 短路与 | 同 `&`，但一旦有 false，右边不再执行 |
| `\|\|` | 短路或 | 同 `\|`，但一旦有 true，右边不再执行 |

```java
// & 逻辑与：全部为 true 才是 true
System.out.println(true & true);    // true
System.out.println(true & false);   // false

// | 逻辑或：有一个为 true 就是 true
System.out.println(true | false);   // true
System.out.println(false | false);  // false

// ! 逻辑非：取反
System.out.println(!true);          // false

// 短路运算符：&& || 推荐使用，效率更高
System.out.println(true && false);  // false（有 false 就短路）
System.out.println(true || false);  // true（有 true 就短路）
```

---

## 三、流程控制

### 3.1 分支结构

#### if 语句

```java
// 格式一：if
if (条件语句) {
    代码块;
}

// 格式二：if-else
if (条件语句) {
    代码块1;
} else {
    代码块2;
}

// 格式三：if-else if-else
if (条件语句1) {
    代码块1;
} else if (条件语句2) {
    代码块2;
} else {
    代码块3;
}
```

#### switch 语句

```java
// 格式
switch (表达式) {
    case 值1:
        代码块1;
        break;
    case 值2:
        代码块2;
        break;
    default:
        代码块n;
        break;
}
```

**switch 注意事项：**
- 表达式值只能是 `byte`、`short`、`int`、`char`、`String`、`enum`
- `case` 值必须是常量，不能是变量
- `case` 值不允许重复
- `break` 用于结束 switch，省略会穿透执行下一个 case

### 3.2 循环结构

#### for 循环

```java
// 格式
for (初始化语句; 条件判断语句; 条件控制语句) {
    循环体语句;
}

// 示例：打印 1-10
for (int i = 1; i <= 10; i++) {
    System.out.println(i);
}
```

**执行流程：** 初始化 → 条件判断 → 循环体 → 条件控制 → 条件判断（循环）

#### while 循环

```java
// 格式
初始化语句;
while (条件判断语句) {
    循环体语句;
    条件控制语句;
}

// 示例
int i = 1;
while (i <= 10) {
    System.out.println(i);
    i++;
}
```

#### do-while 循环

```java
// 格式
初始化语句;
do {
    循环体语句;
    条件控制语句;
} while (条件判断语句);

// 至少执行一次循环体
int i = 1;
do {
    System.out.println(i);
    i++;
} while (i <= 10);
```

**三种循环的区别：**
- `for`：知道循环次数
- `while`：不知道循环次数，但先判断后执行
- `do-while`：至少执行一次，先执行后判断

### 3.3 跳转语句

#### break

- 终止循环（只能在循环中使用）
- 结束 switch 语句

```java
for (int i = 1; i <= 100; i++) {
    if (i == 36) {
        break;  // 跳出循环
    }
    System.out.println(i);
}
```

#### continue

- 跳过本次循环，继续下一次

```java
for (int i = 1; i <= 10; i++) {
    if (i == 5) {
        continue;  // 跳过 i=5 的循环
    }
    System.out.println(i);  // 不会输出 5
}
```

### 3.4 循环嵌套

**循环嵌套特点：** 外层循环执行一次，内层循环执行一轮（完整周期）。

**经典案例：打印直角三角形**

```java
/*
  思路：
  1. 用外层循环控制行数
  2. 用内层循环控制每行的 * 个数
  3. 内层循环的次数与外层当前行数相关
*/
for (int i = 1; i <= 5; i++) {          // 外层：控制行数（5行）
    for (int j = 1; j <= i; j++) {      // 内层：每行打印 i 个 *
        System.out.print("*");          // print 不换行
    }
    System.out.println();               // 每行结束后换行
}
```

输出：
```
*
**
***
****
*****
```

### 3.5 经典案例

#### 考核评级（if-else if）

```java
/*
  需求：输入考试分数，输出等级
  规则：>=90 优秀，>=80 良好，>=70 中等，>=60 及格，<60 不及格
*/
Scanner sc = new Scanner(System.in);
System.out.print("请输入考试分数：");
int score = sc.nextInt();

if (score >= 90) {
    System.out.println("优秀");
} else if (score >= 80) {
    System.out.println("良好");
} else if (score >= 70) {
    System.out.println("中等");
} else if (score >= 60) {
    System.out.println("及格");
} else {
    System.out.println("不及格");
}
```

#### 质数判断（循环嵌套）

```java
/*
  质数：大于1的自然数，除了1和它本身没有其他因数
  思路：从2到num-1逐一判断能否整除
*/
Scanner sc = new Scanner(System.in);
System.out.print("请输入数字：");
int num = sc.nextInt();
boolean flag = true;  // 标记是否为质数，默认是

for (int i = 2; i < num; i++) {
    if (num % i == 0) {
        flag = false;  // 找到因数，不是质数
        break;
    }
}

System.out.println(num + (flag ? "是质数" : "不是质数"));
```

#### 猜数字游戏

```java
/*
  随机生成 1-100 的数，循环让用户猜测
  使用 Random 类生成随机数，Scanner 获取用户输入
*/
import java.util.Random;
import java.util.Scanner;

Random r = new Random();
int randomNum = r.nextInt(100) + 1;  // 生成 1-100 的随机整数

Scanner sc = new Scanner(System.in);

while (true) {
    System.out.print("请猜一个1-100的数：");
    int guess = sc.nextInt();

    if (guess > randomNum) {
        System.out.println("猜大了");
    } else if (guess < randomNum) {
        System.out.println("猜小了");
    } else {
        System.out.println("恭喜你猜对了！");
        break;  // 猜对后退出循环
    }
}
```

#### 1-100 数字求和（for 循环）

```java
/*
  计算 1+2+3+...+100 的累加和
*/
int sum = 0;
for (int i = 1; i <= 100; i++) {
    sum = sum + i;  // 累加
}
System.out.println(sum);  // 5050
```

---

## 四、方法

### 4.1 方法定义与调用

方法是完成特定功能的代码块，**所有代码必须写在方法中**。

**定义格式：**

```java
修饰符 返回值类型 方法名(参数列表) {
    方法体;
    return 返回值;  // void 方法可以省略 return
}
```

**方法调用格式：**

```java
// 有返回值的方法：可以用变量接收，也可以直接打印
int result = add(10, 20);     // 接收返回值
System.out.println(add(10, 20));  // 直接打印

// 无返回值的方法：直接调用
printHello();
```

**方法定义三要素：**
1. **返回值类型**：方法执行完毕后返回的数据类型（无返回值用 `void`）
2. **形参列表**：方法执行需要的外部数据（可以没有参数）
3. **方法体**：具体的业务逻辑代码

### 4.2 方法案例

#### 求两个整数的和

```java
public static int add(int a, int b) {
    int sum = a + b;      // 计算两数之和
    return sum;            // 返回计算结果
}

// 调用
int result = add(10, 20);  // result = 30
```

#### 无返回值的方法

```java
/*
  打印任意行的 n 行 * 号
  - 返回值类型：void（只打印不返回）
  - 参数：int n（需要外部传入行数）
*/
public static void printStar(int n) {
    for (int i = 1; i <= n; i++) {
        for (int j = 1; j <= i; j++) {
            System.out.print("*");
        }
        System.out.println();
    }
}

// 调用
printStar(3);  // 打印 3 行 * 号
```

#### 键盘录入求 1 到 n 的和

```java
import java.util.Scanner;

public static int sum(int n) {
    int sum = 0;
    // 从 1 累加到 n
    for (int i = 1; i <= n; i++) {
        sum = sum + i;
    }
    return sum;  // 返回累加结果
}

// 主方法中调用
Scanner sc = new Scanner(System.in);
System.out.print("请输入数字：");
int n = sc.nextInt();
int result = sum(n);
System.out.println(result);
```

#### 判断奇偶

```java
/*
  判断整数是奇数还是偶数
  - 通过 num % 2 == 0 判断
  - 返回值类型：void（在方法内直接输出）
*/
public static void judgeOddOrEven(int num) {
    if (num % 2 == 0) {
        System.out.println(num + "是一个偶数");
    } else {
        System.out.println(num + "是一个奇数");
    }
}

// 调用
judgeOddOrEven(9);   // 9是一个奇数
judgeOddOrEven(20);  // 20是一个偶数
```

### 4.3 方法重载

在同一个类中，允许存在多个**方法名相同但参数列表不同**的方法，称为方法重载。

**核心要点：**
1. 识别重载只看**方法名（相同）和参数列表（不同）**，与返回值无关
2. 形参列表不同包括三个维度：**类型、数量、顺序**（任意一个不同即可）
3. JVM 通过参数的不同自动匹配对应方法

**重载的意义：** 用相同的方法名实现相似功能，减少记忆多个方法名的成本。

```java
public class OverloadDemo {
    // 两个 int 数相加
    public static int add(int a, int b) {
        return a + b;
    }

    // 三个 int 数相加（数量不同 → 重载）
    public static int add(int a, int b, int c) {
        return a + b + c;
    }

    // 四个 int 数相加（数量不同 → 重载）
    public static int add(int a, int b, int c, int d) {
        return a + b + c + d;
    }

    // 两个 double 数相加（类型不同 → 重载）
    public static double add(double a, double b) {
        return a + b;
    }

    // int 和 double 的顺序不同 → 重载
    public static double add(int b, double a) {
        return a + b;
    }

    public static double add(double a, int b) {
        return a + b;
    }

    public static void main(String[] args) {
        // JVM 根据实参自动匹配对应的方法
        System.out.println(add(1, 2));         // 调用 int,int 版本
        System.out.println(add(1, 2, 3));      // 调用 int,int,int 版本
        System.out.println(add(1, 2, 3, 4));   // 调用 int,int,int,int 版本
        System.out.println(add(1.5, 2.5));     // 调用 double,double 版本
    }
}
```

---

## 五、键盘录入

`java.util.Scanner` 是 Java 提供的键盘录入类，用于获取用户从键盘输入的数据。

**使用步骤：**

```java
import java.util.Scanner;  // 1. 导入 Scanner 包

public class ScannerDemo {
    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);  // 2. 创建 Scanner 对象

        // 3. 获取不同类型的数据
        System.out.print("请输入您的姓名：");
        String name = sc.next();          // 获取字符串

        System.out.print("请输入您的年龄：");
        int age = sc.nextInt();           // 获取整数

        System.out.print("请输入您的身高（米）：");
        double height = sc.nextDouble();  // 获取小数

        // 输出录入的数据
        System.out.println("=== 用户信息 ===");
        System.out.println("姓名：" + name);
        System.out.println("年龄：" + age + "岁");
        System.out.println("身高：" + height + "米");
    }
}
```

**Scanner 常用方法：**

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `sc.next()` | `String` | 获取用户输入的字符串 |
| `sc.nextInt()` | `int` | 获取用户输入的整数 |
| `sc.nextDouble()` | `double` | 获取用户输入的小数 |

