---
title: Java面向对象 - 封装、继承、静态、多态、抽象类、接口、权限修饰符
tags: [Java, OOP, 面向对象, 封装, 继承, 静态, 多态, 抽象类, 接口, 权限修饰符, 枚举, final]
created: 2026-08-24
updated: 2026-08-26
---
## 一、面向对象基础

Java 是一种面向对象的编程语言。面向对象编程把"现实世界中的事物"抽象成程序中的"对象"，通过对象的"属性"和"行为"来组织代码。

比如现实中的"学生"，在程序中可抽象为 `Student` 对象，属性有姓名、年龄、成绩等，行为有学习、考试等。

**类与对象的关系：** 类是创建对象的模板，对象是类的具体实现。Java 必须先定义类（模板），然后根据模板产生对象。

### 1.1 面向对象编程的基本步骤

**步骤一：定义类**，在类中定义属性和方法：

```java
public class 类名 {
    // 属性 → 使用成员变量来记录
    // 行为 → 使用成员方法来描述
}
```

**步骤二：使用类创建对象**，给属性赋值，调用方法：

```java
类名 对象名 = new 类名();
```

**使用对象的属性：**
```java
对象名.属性名 = 数据;   // 存储数据
对象名.属性名            // 取出数据
```

**使用对象的行为：**
```java
返回值类型 变量名 = 对象名.方法名(参数列表);
```

### 1.2 完整示例：学生类

```java
// =================== Step 1: 定义 Student 类 ===================
class Student {
    // 属性（成员变量）：描述特征
    String name;
    int age;
    double score;

    // 方法：描述行为
    public void study() {
        // this 关键字用于在方法中调用本对象的成员属性
        System.out.println(this.name + "正在学习Java！");
    }

    public void takeExam() {
        System.out.println(this.name + "参加考试，成绩是" + this.score + "分！");
    }
}

// =================== Step 2: 创建对象并使用 ===================
public class Demo1 {
    public static void main(String[] args) {
        // 创建第一个学生对象
        Student s1 = new Student();       // new 关键字用于创建对象
        s1.name = "张三";
        s1.age = 18;
        s1.score = 92.5;
        s1.study();                       // 输出：张三正在学习Java！
        s1.takeExam();                    // 输出：张三参加考试，成绩是92.5分！

        // 再创建一个学生对象（复用 Student 类）
        Student s2 = new Student();
        s2.name = "李四";
        s2.age = 19;
        s2.score = 88.0;
        s2.study();                       // 输出：李四正在学习Java！
    }
}
```

**注意细节：**
- `this` 关键字用于在方法中调用本对象的成员属性
- `new` 关键字用于创建对象，一个类可以创建多个对象

---

## 二、封装

封装是面向对象的三大特征之一（封装、继承、多态），核心思想是：**隐藏对象的内部细节，只对外暴露安全的访问方式**。

类比现实中的"手机"：我们不需要知道内部芯片如何工作（隐藏细节），只需通过屏幕、按键操作（暴露访问方式）即可使用。

### 2.1 封装的三种体现

1. 将重复的步骤封装成方法 → 提高代码复用性
2. 将多个属性封装到类中 → 提高代码复用性
3. **隐藏成员变量，提供公共访问方式 → 提高数据安全性**（重点）

### 2.2 封装的实现步骤

1. 使用 `private` 关键字修饰成员变量（仅当前类内部可访问）
2. 提供 `public` 修饰的 `setter` 方法赋值（可添加校验逻辑，保证数据安全）
3. 提供 `public` 修饰的 `getter` 方法取值

```java
class Student {
    // =================== Step 1: private 修饰成员变量 ===================
    private String name;
    private int age;
    private double score;

    // =================== Step 2: public setter 方法（带校验逻辑） ===================
    public void setName(String name) {
        // 校验：姓名不能为 null 或空字符串
        if (name != null && !name.equals("")) {
            this.name = name;  // this.name 指当前对象的属性，避免与参数名冲突
        } else {
            System.out.println("姓名不能为空！");
        }
    }

    public void setAge(int age) {
        if (age >= 0 && age <= 150) {
            this.age = age;
        } else {
            System.out.println("年龄必须在0-150之间！");
        }
    }

    public void setScore(double score) {
        if (score >= 0 && score <= 100) {
            this.score = score;
        } else {
            System.out.println("成绩必须在0-100之间！");
        }
    }

    // =================== Step 3: public getter 方法 ===================
    public String getName() { return this.name; }
    public int getAge() { return this.age; }
    public double getScore() { return this.score; }

    // 行为方法
    public void study() { System.out.println(this.name + "正在学习Java！"); }
    public void takeExam() { System.out.println(this.name + "参加考试，成绩是" + this.score + "分！"); }
}

public class Demo1 {
    public static void main(String[] args) {
        Student s1 = new Student();
        s1.setName("张三");     // 通过 setter 赋值（原：s1.name = "张三"）
        s1.setAge(18);         // 通过 setter 赋值（原：s1.age = 18）
        s1.setScore(92.5);     // 通过 setter 赋值（原：s1.score = 92.5）
        s1.study();
        s1.takeExam();

        // 单独获取属性值
        System.out.println(s1.getName());
        System.out.println(s1.getAge());
        System.out.println(s1.getScore());
    }
}
```

### 2.3 成员变量 vs 局部变量


| 区别 | 成员变量 | 局部变量 |
|------|---------|---------|
| 定义位置 | 类中，方法外 | 方法内或方法参数中 |
| 作用范围 | 整个类内部 | 当前方法内 |
| 默认值 | 有（String→null，int→0，double→0.0） | 无默认值，必须先赋值 |
| 内存位置 | 堆内存（对象中） | 栈内存（方法栈帧中） |
| 生命周期 | 随对象创建而产生，随对象被回收而消失 | 随方法调用而产生，随方法执行完毕而消失 |

---

## 三、构造器

构造器（又叫构造方法）用于**在创建对象时给对象属性赋值**。

### 3.1 构造器的特点

1. 方法名必须和类名保持一致
2. 方法没有返回值，也不能使用 `void` 修饰
3. 用 `new` 关键字创建对象时，自动调用构造器给成员变量赋初始值
4. 一个类中如果没有任何构造方法，Java 会自动生成一个无参构造

### 3.2 构造器 vs Setter 赋值

| 对比 | 构造器赋值 | Setter 赋值 |
|------|----------|------------|
| 优点 | 一次性给多个属性赋值 | 可随意选择给哪个属性赋值 |
| 缺点 | 不灵活 | 代码较繁琐 |


**注意：** 创建对象的正确格式是 `类名 对象名 = new 构造函数(参数);`，之前简化的写法是为了快速掌握步骤，本质是 `new` 关键字结合构造函数完成初始化。

```java
class Student {
    private String name;
    private int age;

    // 无参构造器
    public Student() {
    }

    // 有参构造器：创建对象时直接赋值
    public Student(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() { return name; }
    public int getAge() { return age; }
}

// 测试类
public class Demo1 {
    public static void main(String[] args) {
        // 使用构造器在创建对象时直接赋值
        Student student = new Student("张三", 19);
        System.out.println(student.getName());
        System.out.println(student.getAge());
    }
}
```

**多学一招：JavaBean 规范**

标准的封装数据类叫 JavaBean，要求：
1. 类必须是公共的
2. 属性用 `private` 修饰，提供公共的 setter 和 getter
3. 必须含有 `public` 的无参构造

---

## 四、Java 内存划分

JVM 将内存划分为五部分，各有不同作用：

### 4.1 虚拟机栈（VM Stack）

- **作用：** 描述 Java 方法执行的内存模型。每个方法调用时创建一个栈帧入栈，方法执行完毕后出栈
- **栈帧包含：** 局部变量表、操作数栈、动态链接、方法返回地址

### 4.2 堆（Heap）

- **作用：** 存储 Java 对象实例（几乎所有对象和数组都在这里分配内存）
- **特点：** 线程共享，是垃圾回收（GC）的主要区域
- **细分：**
  - 年轻代（Young Generation）：Eden 区 + Survivor 区
  - 老年代（Old Generation）：存放长期存活对象，GC 频率较低

### 4.3 方法区（Method Area）

- **作用：** 存储类信息、字段、方法、JIT 编译后的代码
- **版本差异：**
  - JDK 7 及之前：永久代（PermGen），物理上属于堆
  - JDK 8 及之后：元空间（Metaspace），使用本地内存

### 4.4 本地方法栈（Native Method Stack）

- 与虚拟机栈类似，专门为 native 方法（C/C++ 实现）提供内存支持

### 4.5 程序计数器（Program Counter Register）

- 记录当前线程执行的字节码指令地址，是 JVM 中唯一不会抛出 `OutOfMemoryError` 的区域

---

## 五、继承

继承是面向对象的核心特性之一，允许一个类通过 `extends` 关键字继承父类，继承后可以直接使用父类中非私有的属性和方法。

### 5.1 继承语法

```java
public class 子类 extends 父类 {
}
```

```java
// =================== 继承示例 ===================

// 父类
class A {
    private String name;    // private：子类不能访问
    int age;                // 默认修饰符：子类可以访问

    private void a() {}    // private 方法：子类不能访问
    void b() {}            // 默认修饰符方法：子类可以访问
}

// 子类继承父类
class B extends A {
}

public class Demo1 {
    public static void main(String[] args) {
        B b = new B();
        // System.out.println(b.name);  // 错误，private 属性不能访问
        System.out.println(b.age);     // 正确，非 private 属性可访问
        // b.a();                       // 错误，private 方法不能访问
        b.b();                         // 正确，非 private 方法可访问
    }
}
```

### 5.2 继承的好处

最大好处是**抽取子类中公共代码到父类中，减少重复代码**，提高代码复用性和维护性。


```java
// =================== 继承提高复用性：教师与学生 ===================

// 父类：抽取共性属性（name、age）
class Person {
    private String name;
    private int age;

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getAge() { return age; }
    public void setAge(int age) { this.age = age; }
}

// 子类：教师，额外属性 skill
class Teacher extends Person {
    private String skill;
    public String getSkill() { return skill; }
    public void setSkill(String skill) { this.skill = skill; }
}

// 子类：学生，额外属性 hobby
class Student extends Person {
    private String hobby;
    public String getHobby() { return hobby; }
    public void setHobby(String hobby) { this.hobby = hobby; }
}

public class Demo2 {
    public static void main(String[] args) {
        // 创建教师对象
        Teacher teacher = new Teacher();
        teacher.setName("张老师");
        teacher.setAge(30);
        teacher.setSkill("唱歌");
        System.out.println(teacher.getName() + ", " + teacher.getAge() + ", " + teacher.getSkill());

        // 创建学生对象
        Student student = new Student();
        student.setName("张铜学");
        student.setAge(20);
        student.setHobby("玩游戏");
        System.out.println(student.getName() + ", " + student.getAge() + ", " + student.getHobby());
    }
}
```

### 5.3 继承的特点

1. **单继承：** Java 只支持单继承（`A extends B, C` 不合法），但支持多层继承（`A extends B`，`B extends C`）
2. **Object 类：** Java 中所有类的祖宗类。不显式继承任何类时，JVM 默认继承 `Object`

```java
// =================== 多层继承与 Object ===================
class D {}                     // 默认继承 Object
class E extends D {}           // 间接继承 Object
class F extends E {}           // 间接继承 Object

public class Demo3 {
    public static void main(String[] args) {
        F f = new F();
        // 任意对象都可以直接使用 Object 类中的方法
        // toString() 默认显示：类名@内存地址标识
        System.out.println(f.toString());
        System.out.println(f);  // 打印对象时自动调用 toString()
    }
}
```

---

## 六、方法重写

当子类觉得从父类继承的方法不好用或不满足需求时，可以对这个方法进行重写。

### 6.1 重写规则

- 子类重写父类方法必须保证**方法名称、参数列表都一样**
- 重写后方法访问遵循**就近原则**：优先使用本类方法，本类没有再去父类找
- 使用 `@Override` 注解标记重写方法，JVM 会自动检查是否满足重写格式

```java
public class Demo1 {
    public static void main(String[] args) {
        Son son = new Son();
        son.makeFriend();  // 输出：正在通过微信的方式交朋友~~~
    }
}

class Father {
    public void makeFriend() {
        System.out.println("正在通过写信的方式交朋友~~~");
    }
}

class Son extends Father {
    @Override  // 标记这是一个重写方法
    public void makeFriend() {
        System.out.println("正在通过微信的方式交朋友~~~");
    }
}
```

### 6.2 经典应用场景

**重写 `toString` 方法**展示对象属性，**重写 `equals` 方法**按属性值判断对象是否相等：

```java
public class Demo2 {
    public static void main(String[] args) {
        Student s1 = new Student("张三", 19, "北京");
        Student s2 = new Student("张三", 19, "北京");

        // 重写前：com.xxx.Student@3b07d329（内存地址）
        // 重写后：Student{name='张三', age=19, address='北京'}
        System.out.println(s1.toString());

        // 重写前：false（按内存地址比较）
        // 重写后：true（按属性值比较）
        System.out.println(s1.equals(s2));
    }
}

class Student extends Object {
    private String name;
    private int age;
    private String address;

    public Student(String name, int age, String address) {
        this.name = name;
        this.age = age;
        this.address = address;
    }

    @Override
    public boolean equals(Object obj) {
        if (this == obj) return true;               // 同一对象直接返回 true
        if (obj instanceof Student) {               // 判断类型
            Student s = (Student) obj;              // 向下转型
            return this.name.equals(s.name)         // 逐个比较属性值
                && this.age == s.age
                && this.address.equals(s.address);
        }
        return false;
    }

    @Override
    public String toString() {
        return "Student{name='" + name + "', age=" + age + ", address='" + address + "'}";
    }
}
```

---

## 七、super 关键字

子类方法中访问变量和方法时遵循"就近原则"，访问顺序为：**子类局部范围 → 子类成员范围 → 父类成员范围**。

要明确指定访问哪个范围的变量或方法时：
- **`this`：** 强行访问子类的成员
- **`super`：** 强行访问父类的成员

```java
public class Demo {
    public static void main(String[] args) {
        Son son = new Son();
        son.show();
    }
}

class Father {
    int num = 10;  // 父类成员变量
}

class Son extends Father {
    int num = 20;  // 子类成员变量

    public void show() {
        int num = 30;                          // 子类局部变量

        System.out.println(num);               // 30 — 访问局部变量
        System.out.println(this.num);          // 20 — 访问子类成员变量
        System.out.println(super.num);         // 10 — 访问父类成员变量
    }
}
```

**this vs super 对比：**

| 关键字 | 访问目标 | 使用场景 |
|--------|---------|---------|
| `this` | 子类的成员 | 访问子类自身的属性或方法 |
| `super` | 父类的成员 | 访问父类被子类隐藏或重写的属性/方法 |

---

## 八、子类构造器

### 8.1 特点

在继承体系下，子类的所有构造器执行自身逻辑前，**都会先调用父类的构造器**。

- 默认情况下，子类构造器第一行代码都是 `super()`（写不写都有），调用父类无参构造器
- 如果父类没有无参构造器，必须在子类构造器第一行手写 `super(...)` 指定调用父类有参构造器

```java
public class Demo1 {
    public static void main(String[] args) {
        Son son = new Son();  // 先执行父类构造器，再执行子类构造器
    }
}

class Father {
    String name;

    // 父类只有有参构造（无参构造被覆盖）
    public Father(String name) {
        this.name = name;
        System.out.println("父类的构造器被调用了.......");
    }
}

class Son extends Father {
    public Son() {
        super("张三");  // 父类无无参构造，必须手写 super(...) 调用有参构造
        System.out.println("子类的构造器被调用了.......");
    }
}
```

### 8.2 应用场景

在子类构造器中调用父类有参构造器，给父类传递参数完成父类对象初始化：

```java
public class Demo2 {
    public static void main(String[] args) {
        Teacher teacher = new Teacher("张老师", 36, "教书");
        System.out.println(teacher);
    }
}

// 父类：People
class People {
    private String name;
    private int age;

    public People(String name, int age) {
        this.name = name;
        this.age = age;
    }
    public String getName() { return name; }
    public int getAge() { return age; }
}

// 子类：Teacher 继承 People
class Teacher extends People {
    private String skill;

    public Teacher(String name, int age, String skill) {
        super(name, age);   // super(xxx) 必须声明在构造器第一行，初始化父类数据
        this.skill = skill;
    }

    @Override
    public String toString() {
        return "Teacher{name='" + super.getName() + "', age=" + super.getAge() + ", skill='" + skill + "'}";
    }
}
```

---

## 九、综合案例：员工管理系统

**需求：** 定义经理类（Manager）和程序员类（Coder），采用继承简化书写。

- 共性属性：姓名 name、工号 id、工资 salary
- Manager 额外属性：奖金 bonus
- 行为：工作 work()

**分析：** 定义员工类 Employee 存放共性内容，让 Manager 和 Student 继承 Employee。注意继承必须满足 **is-a** 关系。

```java
// =================== 父类：Employee ===================
public class Employee {
    private String name;
    private int id;
    private double salary;

    public Employee() {}
    public Employee(String name, int id, double salary) {
        this.name = name;
        this.id = id;
        this.salary = salary;
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public double getSalary() { return salary; }
    public void setSalary(double salary) { this.salary = salary; }

    public void work() {}
}
```

```java
// =================== 子类：Manager ===================
public class Manager extends Employee {
    private int bonus;  // 额外属性：奖金

    public Manager() { super(); }
    public Manager(String name, int id, double salary, int bonus) {
        super(name, id, salary);  // 调用父类构造器初始化共性属性
        this.bonus = bonus;
    }

    public int getBonus() { return bonus; }
    public void setBonus(int bonus) { this.bonus = bonus; }

    @Override
    public void work() {
        System.out.println("名字为" + getName() + "的经理,工资为" + getSalary()
            + ",工号为" + getId() + ",奖金为" + bonus + ",正在工作");
    }
}
```

```java
// =================== 子类：Coder ===================
public class Coder extends Employee {
    public Coder() { super(); }
    public Coder(String name, int id, double salary) {
        super(name, id, salary);  // 调用父类构造器
    }

    @Override
    public void work() {
        System.out.println("名字为" + getName() + "的程序员,工资为" + getSalary()
            + ",工号为" + getId() + ",正在工作");
    }
}
```

```java
// =================== 测试类 ===================
public class Test {
    public static void main(String[] args) {
        // 通过 Setter 创建经理
        Manager manager = new Manager();
        manager.setName("林青霞");
        manager.setSalary(5000);
        manager.setId(1001);
        manager.setBonus(5000);
        manager.work();

        // 通过有参构造创建经理
        Manager manager1 = new Manager("梅军建", 1002, 5000000, 5000000);
        manager1.work();

        // 创建程序员
        Coder coder = new Coder("张学友", 1003, 5000);
        coder.work();
    }
}
```

---

## 十、静态（static）

`static` 是 Java 的一个关键字，可修饰成员变量和成员方法。

### 10.1 修饰成员变量

被 `static` 修饰的成员属于**类而非对象**，随着类的加载而加载，可通过"类名"直接访问。

**成员变量分类：**
- **静态变量（类变量）：** 有 `static` 修饰，属于类，所有对象共享，推荐 `类名.变量名` 访问
- **实例变量：** 无 `static` 修饰，属于每个对象，必须 `对象名.变量名` 访问


```java
class Student {
    String name;                    // 实例变量：属于每个对象
    static String nationality;     // 静态变量：属于类，所有对象共享
}

public class Test {
    public static void main(String[] args) {
        // 静态变量通过类名访问，随类加载只初始化一次
        Student.nationality = "中华人民共和国";

        Student s1 = new Student();
        s1.name = "张三";
        Student s2 = new Student();
        s2.name = "李四";

        // 静态变量被所有对象共享
        System.out.println(s1.nationality);  // 中华人民共和国
        System.out.println(s2.nationality);  // 中华人民共和国
    }
}
```

**使用场景：** 只有数据需要被所有对象共享时才用 `static`，不要滥用。

### 10.2 修饰成员方法

**成员方法分类：**
- **静态方法（类方法）：** 有 `static` 修饰，推荐 `类名.方法名` 访问
- **实例方法：** 无 `static` 修饰，必须 `对象名.方法名` 访问

```java
public class Demo2 {
    public static void main(String[] args) {
        Teacher.printHello();              // 静态方法：类名直接调用

        Teacher teacher = new Teacher();
        teacher.printHelloWorld();         // 实例方法：必须通过对象调用
    }
}

class Teacher {
    public static void printHello() {     // 静态方法（类方法）
        System.out.println("Hello");
    }

    public void printHelloWorld() {       // 实例方法
        System.out.println("HelloWorld");
    }
}
```

**访问规则：**

| 方法类型 | 能访问静态变量/方法 | 能访问实例变量/方法 |
|---------|-------------------|-------------------|
| 静态方法 | ✅ | ❌ |
| 实例方法 | ✅ | ✅ |

---

## 十一、工具类

静态方法最常见的应用场景是做**工具类**。

**什么是工具类：** 类中大部分是独立功能的方法，没有非静态属性，不需要创建对象。方法全部用 `static` 修饰，方便通过类名直接调用。

**好处：** 相比实例方法，类方法可直接用类名调用，比较方便，且不用创建对象，节省内存。


**工具类要求：**
1. 每个方法完成一个独立功能
2. 每个方法都使用 `static` 修饰
3. 构造方法私有化（防止创建对象）
4. 类名和方法名见名知意，类名一般使用 `xxxUtil`

```java
// =================== 数学工具类 ===================
class MathUtil {
    private MathUtil() {}  // 私有构造器，防止创建对象

    public static int max(int a, int b) {
        return a > b ? a : b;
    }

    public static int min(int a, int b) {
        return a < b ? a : b;
    }

    public static int sum(int a, int b) {
        return a + b;
    }
}

public class Demo3 {
    public static void main(String[] args) {
        System.out.println(MathUtil.max(10, 20));   // 20
        System.out.println(MathUtil.min(10, 20));   // 10
        System.out.println(MathUtil.sum(10, 20));   // 30
    }
}
```

---

## 十二、Math 工具类

JDK 内置的数学工具类，所有方法均为静态，通过 `Math.方法名()` 直接调用：

```java
public class Test {
    public static void main(String[] args) {
        int abs = Math.abs(100);                   // 求绝对值：100
        System.out.println(abs);

        double ceil = Math.ceil(10.99999999);      // 向上取整：11.0
        System.out.println(ceil);

        double floor = Math.floor(10.99999999);    // 向下取整：10.0
        System.out.println(floor);

        double pow = Math.pow(2, 3);               // 2的3次幂：8.0
        System.out.println(pow);

        long round = Math.round(3.5);              // 四舍五入：4
        System.out.println(round);
    }
}
```

**常用 Math 方法速查：**

| 方法 | 功能 | 示例 |
|------|------|------|
| `Math.abs(数字)` | 求绝对值 | `Math.abs(-5)` → 5 |
| `Math.ceil(数字)` | 向上取整 | `Math.ceil(10.1)` → 11.0 |
| `Math.floor(数字)` | 向下取整 | `Math.floor(10.9)` → 10.0 |
| `Math.pow(a, b)` | 求 a 的 b 次幂 | `Math.pow(2, 3)` → 8.0 |
| `Math.round(数字)` | 四舍五入 | `Math.round(3.5)` → 4 |

## 十三、多态

### 13.1 认识多态

**概念：** 多态指的是对象拥有多种形态，允许对象可以在多种形态中做转型。通过父类类型引用接受所有的子类对象，实现行为多态的目的。

**多态语法：**
```java
父类类型 变量名 = new 子类的对象();
```

**解读：** 将对象从子类形态转型成父类形态，即"将子类看成父类去使用"。多态允许使用父类类型的变量来存储所有的子类对象——在继承或实现关系中，父类称为大类型，子类称为小类型，多态就是"用大类型容器存储小类型对象"。


**多态的三个前提条件：**
1. 必须有继承或实现关系
2. 必须有父类引用指向子类对象
3. 必须有方法重写

```java
package com.itheima.b_多态_认识多态;

/**
 * 多态示例
 * 面向对象编程允许一个父类变量指向它的任何一个子类对象，这个特性叫做多态
 * 多态语法：父类类型 变量名 = new 子类的对象
 * 在继承关系下，创建一个子类对象，再把它赋值给它的父类类型的变量，这样就实现了多态
 */
public class Demo {
    public static void main(String[] args) {
        // 用父类 Animal 类型接收子类 Cat 的对象（多态）
        Animal animal = new Cat();
        animal.eat();  // 运行时根据实际对象类型调用 Cat.eat()
    }
}

// 定义抽象父类 Animal
abstract class Animal {
    public abstract void eat();  // 抽象方法，子类必须重写
}

// 子类 Dog 重写 eat 方法
class Dog extends Animal {
    @Override
    public void eat() {
        System.out.println("狗狗在吃骨头");
    }
}

// 子类 Cat 重写 eat 方法
class Cat extends Animal {
    @Override
    public void eat() {
        System.out.println("猫咪在吃鱼");
    }
}
```

### 13.2 多态的优势

**优势 1：等号左右两边松耦合，更便于修改和维护**

**优势 2：定义方法时，可以使用父类类型作为形参，该方法可以接收该父类下所有子类的对象**

#### 榨汁机案例

编写一个方法模拟榨汁机的榨汁功能，完成不同水果榨汁效果。

**父类 Fruit：**
```java
public abstract class Fruit {
    public void getJuice();  // 抽象方法，获取水果汁
}
```

**子类 Apple：**
```java
public class Apple extends Fruit {
    public void getJuice() {
        System.out.println("获取苹果汁~~~");
    }
}
```

**子类 Banana：**
```java
public class Banana extends Fruit {
    public void getJuice() {
        System.out.println("获取香蕉汁~~~");
    }
}
```

**未使用多态（方法通用性差，每种水果都要写一个方法）：**
```java
public class Test {
    public static void main(String[] args) {
        zha(new Apple());
        zha(new Orange());
        zha(new Banana());
        // ... 随着不同的水果，方法根本写不完
    }

    // 每种水果都要写一个重载方法，代码重复严重
    public static void zha(Orange orange) {
        orange.getJuice();
        System.out.println("加一些科技狠活~~~");
        System.out.println("放1克糖精");
        System.out.println("果葡糖浆");
        System.out.println("将其整合到杯中");
    }
    public static void zha(Apple apple) {
        apple.getJuice();
        System.out.println("加一些科技狠活~~~");
        System.out.println("放1克糖精");
        System.out.println("果葡糖浆");
        System.out.println("将其整合到杯中");
    }
}
```

**使用多态（一个方法搞定所有水果）：**
```java
public class Test {
    public static void main(String[] args) {
        zha(new Apple());
        zha(new Orange());
        zha(new Banana());
        // ... 所有水果都能用同一个方法
    }

    // 使用父类 Fruit 类型作为参数，提高方法扩展性
    public static void zha(Fruit fruit) {
        fruit.getJuice();                      // 多态调用，实际执行子类的 getJuice()
        System.out.println("加一些科技狠活~~~");
        System.out.println("放1克糖精");
        System.out.println("果葡糖浆");
        System.out.println("将其整合到杯中");
    }
}
```

### 13.3 多态的弊端

多态的弊端：**多态形态下无法调用子类独有的方法**

在多态下，`父类类型 变量名 = new 子类的对象()` 这个过程中，**子类中独有的方法会被隐藏（丢失）**。


**解决方案：强制类型转换（向下转型）**

```java
public class Test {
    public static void main(String[] args) {
        Animal a = new Dog();       // 多态：父类引用指向子类对象
        a.eat();                    // OK：eat() 是父类定义的方法
        // a.lookDoor();           // 编译报错：lookDoor() 是 Dog 独有的方法

        Dog d = (Dog) a;           // 强制类型转换：将 Animal 转为 Dog
        d.lookDoor();              // OK：现在可以调用 Dog 独有的方法了
    }
}
```


**转成其他类型会报错：**
```java
public class Test {
    public static void main(String[] args) {
        Animal a = new Dog();       // 多态
        // Cat c = (Cat) a;        // 运行报错 ClassCastException：Dog 不能转成 Cat
    }
}
```


### 13.4 instanceof 关键字

为了**防止强制类型转换时出现类型不匹配的错误**，可以使用 `instanceof` 关键字判断对象的实际类型：

```java
public class Test {
    public static void main(String[] args) {
        Animal a = new Dog();       // 多态
        // 先判断 a 是否是 Dog 类型，再强制转换
        if (a instanceof Dog) {    // instanceof：判断 a 是否是 Dog 的实例
            Dog d = (Dog) a;       // 安全转换
            d.lookDoor();
        }
    }
}
```

## 十四、抽象类

### 14.1 抽象类和抽象方法

**概念：** 由 `abstract` 修饰的方法称为抽象方法，抽象方法只有方法声明没有方法体。包含抽象方法的类必须是抽象类。

**定义格式：**
```java
// 修饰符 abstract class 类名 {
//     修饰符 abstract 返回值类型 方法名(参数列表);
// }

public abstract class Animal {
    public abstract void eat();     // 抽象方法：只有声明，没有方法体
}
```

**特点：**
1. 抽象类不能直接创建对象（只能创建子类对象）
2. 抽象类可以有构造方法（供子类调用 super 初始化）
3. 抽象类的子类必须重写所有抽象方法，否则子类也要声明为抽象类

```java
// 定义抽象父类
abstract class Animal {
    public abstract void eat();  // 抽象方法
}

// 子类必须重写抽象方法
class Dog extends Animal {
    @Override
    public void eat() {
        System.out.println("狗狗在吃骨头");
    }
}

class Cat extends Animal {
    @Override
    public void eat() {
        System.out.println("猫咪在吃鱼");
    }
}

public class Demo {
    public static void main(String[] args) {
        // Animal a = new Animal();  // 编译报错：抽象类不能直接创建对象
        Dog d = new Dog();           // OK：创建子类对象
        d.eat();
    }
}
```

### 14.2 抽象类的使用场景

**场景：父类知道子类要做什么，但不知道具体怎么做。**


**案例——员工系统：**

父类 `Employee` 定义抽象方法 `work()`，子类 `Teacher`、`Doctor` 各自实现具体的 `work()` 逻辑：

```java
// 抽象父类：员工（知道员工要工作，但不知道具体做什么）
abstract class Employee {
    private String name;
    private double salary;

    public Employee(String name, double salary) {
        this.name = name;
        this.salary = salary;
    }

    public abstract void work();  // 抽象方法：留给子类实现

    // getter/setter/toString 省略
}

// 子类：老师（实现具体的 work 方法）
class Teacher extends Employee {
    public Teacher(String name, double salary) {
        super(name, salary);
    }

    @Override
    public void work() {
        System.out.println("老师正在教书育人");
    }
}

// 子类：医生（实现具体的 work 方法）
class Doctor extends Employee {
    public Doctor(String name, double salary) {
        super(name, salary);
    }

    @Override
    public void work() {
        System.out.println("医生正在救死扶伤");
    }
}

public class Demo {
    public static void main(String[] args) {
        Teacher t = new Teacher("张老师", 8000);
        t.work();  // 输出：老师正在教书育人

        Doctor d = new Doctor("李医生", 15000);
        d.work();  // 输出：医生正在救死扶伤
    }
}
```

## 十五、接口

### 15.1 接口的定义

**概念：** 接口（Interface）是 Java 中一种抽象类型，是抽象方法的集合（Java 8 后也可以有默认方法和静态方法）。接口用 `interface` 关键字定义。

**定义格式：**
```java
// public interface 接口名 {
//     // 常量（默认 public static final）
//     // 抽象方法（默认 public abstract）
//     // 默认方法（Java 8+，public default）
//     // 静态方法（Java 8+，public static）
// }
```

**接口中的成员特点：**
- 成员变量：默认被 `public static final` 修饰（常量）
- 成员方法：默认被 `public abstract` 修饰（抽象方法）
- 默认方法（JDK 8+）：使用 `default` 修饰，有方法体，实现类可选择重写也可直接继承使用
- 静态方法（JDK 8+）：使用 `static` 修饰，属于接口本身，只能通过 `接口名.方法名()` 调用
- 私有方法（JDK 9+）：使用 `private` 修饰，抽取默认方法或静态方法中的公共重复代码，只供接口内部使用
- 不能有构造方法
- `private` 和 `abstract` 冲突，`final` 和 `abstract` 冲突

```java
public interface Swim {
    // 常量：默认 public static final
    public static final int NUM = 10;

    // 抽象方法：默认 public abstract
    public abstract void swim();

    // 默认方法（JDK 8+）：实现类可重写，也可直接继承使用
    default void breathe() {
        System.out.println("在水中呼吸");
    }

    // 静态方法（JDK 8+）：只能通过接口名调用
    static void showInfo() {
        System.out.println("游泳接口");
    }

    // 私有实例方法（JDK 9+）：供默认方法调用，外部不可见
    private void commonLogic() {
        System.out.println("公共逻辑");
    }

    // 私有静态方法（JDK 9+）：供静态方法调用
    private static void staticLogic() {
        System.out.println("静态公共逻辑");
    }
}

// 类实现接口
public class Dog extends Animal implements Swim {
    @Override
    public void eat() {
        System.out.println("狗狗在吃骨头");
    }

    @Override
    public void swim() {
        System.out.println("狗狗在游泳");
    }
}
```

### 15.2 接口的使用场景

**场景：当一个类既要是某种类型，又要具备某种行为时，使用接口。**

**案例——运动员系统：**

```java
// 抽象父类：运动员（定义公共属性和行为）
abstract class Athlete {
    private String name;
    private int age;

    public Athlete(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public abstract void train();  // 训练（抽象方法，子类必须实现）
}

// 接口：游泳能力（定义游泳行为）
interface Swim {
    public abstract void swim();  // 游泳（抽象方法）
}

// 篮球运动员：继承运动员 + 实现游泳接口
class BasketballPlayer extends Athlete implements Swim {
    public BasketballPlayer(String name, int age) {
        super(name, age);
    }

    @Override
    public void train() {
        System.out.println("篮球运动员正在训练投篮");
    }

    @Override
    public void swim() {
        System.out.println("篮球运动员在游泳锻炼");
    }
}

// 足球运动员：继承运动员 + 实现游泳接口
class FootballPlayer extends Athlete implements Swim {
    public FootballPlayer(String name, int age) {
        super(name, age);
    }

    @Override
    public void train() {
        System.out.println("足球运动员正在训练射门");
    }

    @Override
    public void swim() {
        System.out.println("足球运动员在游泳锻炼");
    }
}
```

### 15.3 接口和抽象类的区别

| 特性 | 抽象类 | 接口 |
|------|--------|------|
| 关键字 | `abstract class` | `interface` |
| 构造方法 | 有 | 没有 |
| 成员变量 | 可以有普通变量 | 只能有常量（`public static final`） |
| 方法 | 可以有抽象方法和普通方法 | 只能有抽象方法（Java 8 后有默认方法） |
| 继承关系 | 单继承 | 多实现 |
| 设计理念 | "is-a" 关系 | "has-a / can-do" 能力 |

**接口的好处：**
- 支持多实现，一个类可以同时实现多个接口
- 适合定义行为规范，不关心具体实现细节


## 十六、final 关键字

**概念：** `final` 修饰的类、方法、变量不能被修改。

**用法：**

```java
// 1. final 修饰类：不能被继承
public final class String { }  // String 类是 final 的，不能被继承

// 2. final 修饰方法：不能被重写
public class Animal {
    public final void eat() {  // 子类不能重写此方法
        System.out.println("动物在吃东西");
    }
}

// 3. final 修饰变量：值不能被修改（基本类型值不能变，引用类型引用不能变，但对象内容可变）
final int MAX = 100;
// MAX = 200;  // 编译报错

final int[] arr = {1, 2, 3};
arr[0] = 10;   // OK：数组内容可以修改
// arr = new int[5];  // 编译报错：引用不能重新赋值
```

## 十七、枚举

### 17.1 枚举的概念

**概念：** 枚举是一个特殊的类，它的值为**固定常量**，适合描述有限的固定选项（如性别、季节、星期等）。

**枚举类格式：**
```java
// 修饰符 enum 枚举类名 {
//     枚举项1, 枚举项2, ...;
//     其他成员...
// }
```

**枚举的特点：**
1. 枚举类的第一行只能罗列一些名称，且默认都是常量，每个常量记住的就是枚举类的一个对象
2. 枚举类的构造器都是私有的（自己提供也只能是私有的），因此枚举类对外不能创建对象
3. 编译器为枚举类新增了几个方法，并且所有枚举类都是 `java.lang.Enum` 的子类，可以使用父类的方法

```java
public class Demo {
    public static void main(String[] args) {
        // 1. 使用枚举赋值
        Student student = new Student();
        student.setName("张三");
        student.setSex(Sex.MAN);
        System.out.println(student);

        // 2. 枚举的常用方法
        System.out.println(Arrays.toString(Sex.values()));  // [MAN, WOMEN]：获取所有枚举值
        System.out.println(Sex.valueOf("MAN"));              // MAN：根据名称获取枚举对象
    }
}

class Student {
    private String name;
    private Sex sex;

    public void setSex(Sex sex) { this.sex = sex; }
    public void setName(String name) { this.name = name; }

    @Override
    public String toString() {
        return "Student{name='" + name + "', sex='" + sex + "'}";
    }
}

// 定义枚举类
enum Sex {
    // 第一行罗列枚举常量，每个常量都是枚举类的一个对象
    MAN, WOMEN;

    // 构造器必须是私有的
    private Sex() {}
}
```

## 十八、权限修饰符

### 18.1 概念

权限修饰符用来限制类中的成员（成员变量、成员方法、构造器）能够被访问的范围。

Java 中共有 **4 种权限修饰符**：

| 修饰符 | 本类 | 本包 | 不同包子类 | 不同包无关类 |
|--------|------|------|------------|--------------|
| `public` | ✅ | ✅ | ✅ | ✅ |
| `protected` | ✅ | ✅ | ✅ | ❌ |
| 默认（缺省） | ✅ | ✅ | ❌ | ❌ |
| `private` | ✅ | ❌ | ❌ | ❌ |

**常用：`public` 和 `private` 两个最常用**

### 18.2 演示

**定义四种权限修饰的方法：**
```java
package cn.itcast.review.demo2;
public class A {
    public void method() {
        // 在本类中四种权限修饰的方法都可以访问
        this.publicMethod();
        this.protectedMethod();
        this.defaultMethod();
        this.privateMethod();
    }

    public void publicMethod() {
        System.out.println("我是 public 修饰的方法");
    }
    protected void protectedMethod() {
        System.out.println("我是 protected 修饰的方法");
    }
    void defaultMethod() {
        System.out.println("我是 default 修饰的方法");
    }
    private void privateMethod() {
        System.out.println("我是 private 修饰的方法");
    }
}
```

**本包其他类访问：**
```java
package cn.itcast.review.demo2;
import cn.itcast.review.demo2.A;
public class Test {
    public static void main(String[] args) {
        A a = new A();
        a.publicMethod();       // OK
        a.protectedMethod();   // OK
        a.defaultMethod();     // OK
        // a.privateMethod();  // 编译报错：私有方法本包其他类不能访问
    }
}
```

**不同包的子类访问：**
```java
package cn.itcast.review.demo3;
import cn.itcast.review.demo2.A;

public class B extends A {
    public void method() {
        super.publicMethod();      // OK
        super.protectedMethod();   // OK
        // super.defaultMethod();  // 编译报错
        // super.privateMethod();  // 编译报错
    }
}
```

**不同包的无关类访问：**
```java
package cn.itcast.review.demo3;
import cn.itcast.review.demo2.A;

// Java 中导包原则：
// 只有 java.lang 包以及本包下的类使用时不需要强制导入，否则必须先导入才能使用
public class Test {
    public static void main(String[] args) {
        A a = new A();
        a.publicMethod();       // OK：不同包无关类只能访问 public
        // a.protectedMethod();  // 编译报错
        // a.defaultMethod();    // 编译报错
        // a.privateMethod();    // 编译报错
    }
}
```


