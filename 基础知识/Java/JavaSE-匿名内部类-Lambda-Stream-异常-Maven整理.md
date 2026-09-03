---
title: "JavaSE - 匿名内部类、Lambda、Stream、异常整理"
tags: ["JavaSE","匿名内部类","Lambda","Stream","异常"]
created: "2026-08-30"
---

# 匿名内部类、Lambda、Stream、异常

## 一、快速创建子类对象的三种方式

遇到接口或抽象类类型的变量，需要赋值一个对象，但接口和抽象类不能直接实例化。除了传统的定义子类之外，Java 还提供了三种简化方式：

1. **匿名内部类**
2. **Lambda 表达式**
3. **方法引用**（自学补充）

---

## 二、匿名内部类

### 2.1 本质

创建了已知类或已知接口的**子类对象**（实现类也叫子类）。

### 2.2 语法格式

```java
new 已知类型/已知接口(对参数赋值) {
    // 对方法进行重写
};
```

### 2.3 完整示例

接口定义：

```java
public interface A {
    void method();
}
```

使用匿名内部类：

```java
public class Test {
    public static void main(String[] args) {
        // 采用匿名内部类创建子类对象
        A aa = new A() {  // 底层: class XXX implements A()
            @Override
            public void method() {
                System.out.println("我是实现接口的方法");
            }
        };
        aa.method();
    }
}
```

### 2.4 注意事项

1. 匿名内部类也是类，会在磁盘中形成物理 `.class` 文件
2. 匿名内部类本质是创建一个已知类或已知接口的子类对象
3. 当重写的方法超过 4 个时，**不建议**使用匿名内部类
4. 当重写方法过于复杂、内容比较多时，也不建议使用内部类
5. 当子类对象很多地方都要使用时，不建议使用匿名内部类——复用性很差

---

## 三、Lambda 表达式

### 3.1 概述

Lambda 表达式是 JDK 8 开始新增的一种语法形式，**作用：用于简化函数式接口子类对象的创建**。

### 3.2 函数式接口

指有且仅有一个抽象方法的接口，可以使用 `@FunctionalInterface` 注解来检查：

```java
@FunctionalInterface
public interface A {
    void method();
}
```

### 3.3 完整语法格式

```java
(抽象方法参数列表) -> {
    // 对唯一的抽象方法的重写
}
```

### 3.4 简化规则

1. **参数类型可以省略不写**
2. 如果只有**一个参数**，小括号 `()` 也可以省略
3. 如果方法体代码**只有一行**，可以省略花括号 `{}` 不写，同时要省略分号；如果这行代码是 `return` 语句，也必须去掉 `return`

### 3.5 完整示例

接口定义：

```java
@FunctionalInterface
public interface B {
    int method(int num);
}
```

三种写法对比：

```java
public class Test {
    public static void main(String[] args) {
        // 方式1: 匿名内部类方式完成子类创建
        // B b = new B() {
        //     @Override
        //     public int method(int num) {
        //         return num * 2;
        //     }
        // };

        // 方式2: Lambda 的完整格式完成子类创建
        // B b = (int num) -> {
        //     return num * 2;
        // };

        // 方式3: Lambda 的简化格式完成子类创建
        B b = num -> num * 2;

        int method = b.method(2);
        System.out.println(method); // 输出: 4
    }
}
```

> **IDEA 快捷键**：`Alt + Enter` 可以实现匿名内部类和 Lambda 的互转。

---

## 四、Stream 流

### 4.1 概述

Stream 流是 JDK 8 开始新增的一套 API（`java.util.stream.*`），用于**简化操作集合或数组**。Stream 大量结合 Lambda 语法风格编程，提供更强大的数据操作方式，代码更简洁、可读性更好。

### 4.2 获取 Stream 流对象

**（1）集合转 Stream**

单列集合底层接口 Collection 提供 `stream()` 方法：

```java
// default Stream<E> stream()
List<String> list = new ArrayList<>();
list.add("aaa");
list.add("bbb");
list.add("ccc");
list.add("ddd");
Stream<String> s1 = list.stream(); // 将集合转成 Stream
```

**（2）数组转 Stream**

数组工具类 Arrays 提供 `stream(数组)` 方法：

```java
// static <T> Stream<T> stream(T[] array)
String[] arr = {"aaa", "bbb", "ccc", "ddd"};
Stream<String> s2 = Arrays.stream(arr);
```

也可以用 `Stream.of(...)`，但只限于引用类型数组（底层调用的是 `Arrays.stream()`）：

```java
// static Stream<E> of(T... elements)
```

### 4.3 终结方法

**特点：调用后不再返回 Stream 对象，不能继续使用 Stream 功能。**

| 返回值 | 方法 | 作用 |
|--------|------|------|
| `void` | `forEach(Consumer<? super T> action)` | 遍历 Stream 中的元素 |
| `long` | `count()` | 获取流中元素的个数 |

示例：

```java
List<String> list = new ArrayList<>();
list.add("aaa");
list.add("bbbertertert");
list.add("cccadsf");
list.add("dddsdfgfdt");

// 遍历 Stream 的元素
list.stream().forEach(s -> System.out.println(s));

// 求出流中元素的个数
long count = list.stream().count();
System.out.println(count);
```

### 4.4 中间方法

**特点：调用后返回新的 Stream 对象，可以继续链式调用。**

| 返回值 | 方法 | 作用 |
|--------|------|------|
| `Stream<R>` | `filter(Predicate<? super T> predicate)` | 根据条件过滤元素 |
| `Stream` | `limit(long maxSize)` | 只取前几个元素 |
| `Stream` | `skip(long n)` | 跳过前几个元素 |
| `Stream` | `distinct()` | 去重（采用 Hash 去重） |
| `Stream` | `sorted()` | 自然排序 |
| `Stream` | `sorted(比较器)` | 比较器排序 |
| `Stream<T>` | `static concat(Stream a, Stream b)` | 将两个流合并成一个流 |
| `Stream<R>` | `map(Function<? super T, ? extends R> mapper)` | 将流的元素修改成另外一种类型 |
| `Stream<R>` | `flatMap(Function<? super T, ? extends Stream<? extends R>> mapper)` | 处理嵌套集合或数组，将所有元素处理成一条流 |

示例：

```java
List<String> list = new ArrayList<>();
list.add("林青霞");
list.add("张学友");
list.add("梅军建");

// filter: 过滤长度 > 3 的元素
list.stream().filter(s -> s.length() > 3).forEach(s -> System.out.println(s));

// limit: 只要前 3 个
list.stream().limit(3).forEach(s -> System.out.println(s));

// skip: 跳过前 2 个
list.stream().skip(2).forEach(s -> System.out.println(s));

// distinct: Hash 去重
list.stream().distinct().forEach(s -> System.out.println(s));

// sorted: 自然排序
list.stream().sorted().forEach(s -> System.out.println(s));

// sorted + 比较器: 按字符串长度排序
list.stream().sorted((o1, o2) -> o1.length() - o2.length()).forEach(s -> System.out.println(s));

// concat: 合并两个流
List<String> list1 = new ArrayList<>();
list1.add("林青霞");
list1.add("张学友");
list1.add("梅军建");
Stream.concat(list.stream(), list1.stream()).forEach(s -> System.out.println(s));

// map: 将元素修改为另一种类型
list.stream().map(s -> s.substring(1)).forEach(name -> System.out.println(name));

// flatMap: 处理嵌套循环的数据
String[][] arr = {
    {"张学友", "张三", "张伟"},
    {"林青霞", "常昵"},
    {"王祖蓝", "王伟", "王伟"},
};
Arrays.stream(arr)
    .flatMap(strings -> Arrays.stream(strings).map(name -> name.substring(1)))
    .forEach(s -> System.out.println(s));
```

### 4.5 转换方法

| 返回值 | 方法 | 作用 |
|--------|------|------|
| `<R,A> R` | `collect(Collector<? super T,A,R> collector)` | 将流收集成集合，可以继续使用集合的功能 |
| `List` | `toList()` | 转成 List（JDK 16 及之后才能使用） |
| `Object[]` | `toArray()` | 将流转成数组 |

示例：

```java
List<String> list = new ArrayList<>();
list.add("林青霞");
list.add("张学友");
list.add("梅军建");

// collect: 将流转成集合后，可以使用集合的方法
List<String> collect = list.stream()
    .filter(name -> name.startsWith("张"))
    .collect(Collectors.toList());

// toList: JDK 16 才有的功能
List<String> list1 = list.stream().toList();
```

### 4.6 注意事项

1. Stream 流元素的操作**不会影响**原集合或数组（指不会影响集合元素个数，如果操作元素地址内部的数据肯定会受影响）
2. Stream 流对象**只能使用一次**，但凡被操作了就不能再使用——Stream 主打链式编程解决所有问题，禁止对流进行二次操作

---

## 五、异常处理

### 5.1 异常介绍

程序在编译或执行过程中出现的错误（如数组索引越界、除以 0、文件不存在）就是异常，异常若未处理会直接导致程序终止。

**异常分类：**

```
Throwable
├── Error: 大部分描述硬件相关的问题，和我们的关系不大
└── Exception
    ├── 运行时异常（RuntimeException 及其子类）: 描述常识性问题，编译期间不会有错误提醒
    └── 编译时异常: 描述专业性问题，编译期间就会有错误提醒，必须处理后才能继续编码
```

- **运行时异常**：`RuntimeException` 及其子类，编译阶段不会出现错误提醒，运行时才出现（如数组索引越界异常）。一般描述的是常识性问题
- **编译时异常**：编译阶段就会出现错误提醒的（如日期解析异常、文件不存在异常）。通常描述的是专业性问题

示例：

```java
public class Test {
    public static void main(String[] args) {
        // 编译时异常: 在编译期间就会有错误提醒，必须手动处理
        try {
            FileInputStream fis = new FileInputStream("F:\\b.jpeg");
            System.out.println("后续代码");
        } catch (FileNotFoundException e) {
            throw new RuntimeException(e);
        }
        System.out.println("啦啦啦");
    }

    // 演示运行时异常
    private static void demo1() {
        int[] arr = {1, 2, 3, 4};
        // 运行时异常: 编译期间不受检，运行期间发现问题才报错，终止程序
        System.out.println(arr[-100]);
        System.out.println("剩余的代码");
    }
}
```

### 5.2 抛出异常（throws）

在 Java 的方法调用中，如果一个方法中出现了异常，本方法自己不处理，默认会抛给调用方法去处理。如果发生的是非运行时异常，需要在方法上明确使用 `throws` 关键字声明抛出。

**格式：**

```java
public void 方法名() throws 异常1, 异常2, 异常3 {
    方法体
}
```

**执行流程：** 异常会沿着调用栈向上抛出，本方法的后续代码依然会受到影响。

```java
public class Test {
    public static void main(String[] args) throws FileNotFoundException {
        // 遇到编译时异常可以通过 throws 关键字声明出去
        FileInputStream fis = new FileInputStream("F:\\b.jpeg");
        // 后续代码依然会受到异常的影响，因为只是将异常抛出去了，并没有真正处理
        System.out.println("啦啦啦");
    }
}
```

### 5.3 捕获异常（try…catch）

直接在当前方法中，使用 try-catch 结构捕获并处理异常。异常处理后，后续的代码可以继续执行。**捕获异常才是真正处理异常的方式。**

**格式：**

```java
try {
    // 可能出现问题的代码
    // 出现问题后不需要执行的代码
} catch (异常类型1 异常名) {
    // 处理方式
} catch (异常类型2 异常名) {
    // 处理方式
}
```

**执行流程：** 首先执行 try 中的代码，一旦发现异常对象，try 剩余的代码将不再执行，就会找 catch 进行匹配。一旦匹配成功则会执行对应 catch 中的语句体，然后整个 try-catch 结束。如果 try 没有异常则 catch 不会执行。

```java
public class Test {
    public static void main(String[] args) {
        // Alt + Ctrl + T ==> 抓异常    Alt + Enter
        try {
            FileInputStream fis = new FileInputStream("F:\\b.jpeg");
            System.out.println("后续代码");
        } catch (FileNotFoundException e) {
            System.out.println("文件不存在");
        }

        System.out.println("啦啦啦"); // 异常被处理后，这行会正常执行
    }
}
```

### 5.4 throws 与 try-catch 对比

| 方式 | 关键字 | 位置 | 是否真正处理 | 后续代码 |
|------|--------|------|-------------|----------|
| 抛出异常 | `throws` | 方法签名上 | 否，只是声明 | 受异常影响 |
| 捕获异常 | `try-catch` | 方法体内 | 是 | 正常执行 |

### 5.5 自定义异常

Java 无法为世界上全部问题提供异常类，自己写的代码中的某种问题如果想通过异常来表示，就需要自定义异常类。

**步骤：**

1. 定义一个异常类型，继承 `RuntimeException`（常识性问题）或 `Exception`（专业性问题）
2. 重写无参和带 `String` 原因的构造方法即可
3. 通过 `throw` 将创建的异常抛给调用者

**自定义异常类：**

```java
public class AgeOutOfBoundsException extends RuntimeException {

    public AgeOutOfBoundsException() {
    }

    public AgeOutOfBoundsException(String message) {
        super(message);
    }
}
```

**使用自定义异常的实体类：**

```java
public class Student {

    private String name;
    private int age;

    public Student() {
    }

    public Student(String name, int age) {
        this.name = name;
        if (age < 0 || age > 150) {
            // 通过 throw 将异常抛给调用者
            throw new AgeOutOfBoundsException("年龄不合法哦, 你是人类吗?");
        } else {
            this.age = age;
        }
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        if (age < 0 || age > 150) {
            throw new AgeOutOfBoundsException("年龄不合法哦, 你是人类吗?");
        } else {
            this.age = age;
        }
    }
}
```

**测试类：**

```java
public class Test {
    public static void main(String[] args) {
        Student student = new Student();
        student.setAge(1000); // 抛出 AgeOutOfBoundsException
        student.setName("小明");
        System.out.println(student.getAge());
    }
}
```

> 如果描述的是一些专业性问题，可以定义成编译时异常，只需让自定义异常继承 `Exception` 即可，剩余步骤一致。

---

- 匿名内部类本质是快速创建子类对象，适合"一次性实现"
- Lambda 是函数式接口匿名内部类的简写，`Alt + Enter` 可互转
- Stream 重点掌握 `filter` + `map` + `collect`，注意流只能使用一次
- 异常处理优先明确异常边界，编译时异常必须 `throws` 或 `try-catch`
- 自定义异常：继承 `RuntimeException` 或 `Exception`，重写构造，用 `throw` 抛出


