---
title: "JavaSE - 容器与常用集合整理"
tags: ["JavaSE", "Array", "String", "StringBuilder", "List", "Set", "Map"]
created: "2026-08-28"
---

# 第4章 容器 - Array、String & StringBuilder、常见的集合

## 本章目标

1. 掌握数组容器 Array
2. 掌握字符容器 String 和 StringBuilder
3. 掌握单列集合 List 体系的特点以及常见功能
4. 掌握单列集合 Set 体系的特点以及常见功能
5. 掌握双列集合 Map 体系的特点以及常见功能

---

# 一、Array（数组）

Array（数组）是一种线性数据结构，用于存储"多个相同类型的数据"，数组一旦创建，大小不能改变。

## 1.1 定义方式

**静态初始化**：在定义数组的同时存入元素

- 简化格式：`数据类型[] 数组名 = { 元素1, 元素2, 元素3, … }`
- 完整格式：`数据类型[] 数组名 = new 数据类型[]{ 元素1, 元素2, 元素3, … }`
- 区别：完整格式支持先定义后赋值，简化格式必须一气呵成

**动态初始化**：定义数组时先不存入具体的元素值，只确定数据类型和长度

- 格式：`数据类型[] 数组名 = new 数据类型[长度]`

## 1.2 访问与遍历

数组在内存中申请的是一个连续的空间，数组名记录的是数组的首地址。每个元素有一个从 `0` 开始的编号，叫做**索引**（也叫角标、下标）。

访问格式：`数组名[索引]`

遍历数组时可以使用隐藏属性 `length` 动态获取长度：

```Java
// 普通 for 遍历
for (int i = 0; i < 数组名.length; i++) {
    数组名[i]; // 获取元素
}

// 增强 for 遍历
for (元素类型 变量名 : 数组名) {
    变量名;
}
```

> IDE 快捷键：`数组名.fori` 生成普通 for，`数组名.for` 生成增强 for

## 1.3 典型代码

```Java
public class ArrayDemo {
    public static void main(String[] args) {
        // 静态初始化：保存3个同学的名字
        String[] names = {"刘备", "关羽", "张飞"};

        // 动态初始化：存储3个同学的分数
        int[] scores = new int[3];
        scores[0] = 80;
        scores[1] = 90;
        scores[2] = 100;

        // 普通 for 遍历
        for (int i = 0; i < names.length; i++) {
            System.out.println(names[i]);
        }

        // 增强 for 遍历
        for (String name : names) {
            System.out.println(name);
        }
    }
}
```

## 1.4 应用案例：求和与平均值

某部门5名员工的销售额分别是：16、26、36、6、100，计算总销售额和平均销售额

```Java
public class ArraySum {
    public static void main(String[] args) {
        int sum = 0;
        int[] sales = {16, 26, 36, 6, 100};

        for (int i = 0; i < sales.length; i++) {
            sum += sales[i];
        }
        System.out.println("总销售额: " + sum);

        double avg = sum * 1.0 / sales.length;
        System.out.println("平均销售额: " + avg);
    }
}
```

## 1.5 数组注意事项

- 数组一旦创建，**长度不可改变**
- 不能访问不存在的索引，否则抛 `ArrayIndexOutOfBoundsException`（索引越界异常）
- 所有引用数据类型都可以用 `null` 作为默认值，但 `null` 不能直接使用，否则抛 `NullPointerException`（空指针异常）

---

# 二、String & StringBuilder

## 2.1 String 概述

`String` 是不可改变的字符序列，一旦创建则无法改变。

### 创建方式

| 方式 | 示例 | 说明 |
|---|---|---|
| 常量方式（推荐） | `String s = "abc";` | 最常用 |
| 构造：字节数组转字符串 | `new String(byte[] bytes)` | 将字节数组转换为字符串 |
| 构造：字符数组转字符串 | `new String(char[] value)` | 将字符数组转换为字符串 |

```Java
// 构造方式
String s1 = new String();                          // "" 空串，基本没用
String s2 = new String("abc");                     // 也没太大用
byte[] arr = {97, 98, 99};
String s3 = new String(arr);                       // "abc"，将字节数组转换成字符串
char[] arr1 = {'a', 'b', 'c'};
String s4 = new String(arr1);                      // "abc"，将字符数组转换成字符串

// 常量方式（推荐）
String s5 = "abc";
```

## 2.2 String 常用方法

| 方法 | 说明 |
|---|---|
| `int length()` | 获取字符串长度（字符个数） |
| `char charAt(int index)` | 获取指定索引位置的字符 |
| `char[] toCharArray()` | 将字符串转换成字符数组 |
| `String[] split(String regex)` | 按规则拆分成字符串数组 |
| `String substring(int beginIndex, int endIndex)` | 截取子串（包前不包后） |
| `String substring(int beginIndex)` | 从指定索引截取到末尾 |
| `String replace(CharSequence target, CharSequence replacement)` | 替换内容，得到新字符串 |
| `boolean contains(CharSequence s)` | 判断是否包含指定字符串 |
| `boolean startsWith(String prefix)` | 判断是否以指定字符串开头 |
| `boolean equals(Object anObject)` | 内容比较（区分大小写） |
| `boolean equalsIgnoreCase(String anotherString)` | 内容比较（忽略大小写） |
| `String strip()` | 去除首尾所有 Unicode 空白字符（Java 11+） |

```Java
String s = "黑马程序员";

// length()
System.out.println(s.length());          // 7

// charAt()
System.out.println(s.charAt(3));         // 序

// toCharArray()
char[] array = s.toCharArray();
System.out.println(Arrays.toString(array)); // [黑, 马, 程, 序, 员, 员, 程]

// split()
String s2 = "河北省-石家庄市-裕华区";
String[] arr = s2.split("-");
System.out.println(Arrays.toString(arr)); // [河北省, 石家庄市, 裕华区]

// substring()
String s3 = "黑马程序员";
System.out.println(s3.substring(2, 4));  // 程序（包前不包后）
System.out.println(s3.substring(2));     // 程序员
System.out.println(s3);                 // 黑马程序员（原串不变）

// replace()
String s4 = "TMD,你真TMD的菜";
System.out.println(s4.replace("TMD", "***")); // ***,你真***的菜

// contains()
System.out.println(s4.contains("TMD"));  // true

// startsWith()
System.out.println(s4.startsWith("TMD")); // true

// equals / equalsIgnoreCase
String s5 = "Hello World";
String s6 = "hello world";
System.out.println(s5.equals(s6));              // false
System.out.println(s5.equalsIgnoreCase(s6));    // true
```

> 关键特性：字符串的所有方法都**不会改变原串**，而是返回新串。

## 2.3 String 应用案例：模拟用户登录

```Java
public class LoginDemo {
    public static void main(String[] args) {
        String rightName = "itheima";
        String rightPassword = "123456";

        Scanner sc = new Scanner(System.in);
        for (int i = 0; i < 3; i++) {
            System.out.println("请输入用户名:");
            String name = sc.nextLine();
            System.out.println("请输入密码:");
            String password = sc.nextLine();

            if (rightName.equals(name) && rightPassword.equals(password)) {
                System.out.println("登录成功");
                break;
            } else {
                if (i == 2) {
                    System.out.println("账号锁定，请与管理员联系");
                } else {
                    System.out.println("登录失败，您还剩" + (2 - i) + "次机会");
                }
            }
        }
    }
}
```

## 2.4 StringBuilder

`StringBuilder` 是可变字符序列，适合频繁字符串拼接。

### 常用方法

| 方法 | 说明 |
|---|---|
| `StringBuilder append(...)` | 拼接内容（支持多种类型） |
| `StringBuilder insert(int offset, ...)` | 在指定位置插入内容 |
| `StringBuilder delete(int start, int end)` | 删除指定范围的字符 |
| `StringBuilder reverse()` | 反转内容 |
| `String toString()` | 转为 String |

```Java
StringBuilder sb1 = new StringBuilder();
StringBuilder sb2 = new StringBuilder("abc");

// 拼接（链式调用，改变自身内容）
sb2.append("程序").append("员");
System.out.println(sb2);           // 黑马程序员

// 反转
sb2.reverse();
System.out.println(sb2);           // 员序程马黑

// 长度
System.out.println(sb2.length());  // 5

// 转为字符串
String s = sb2.toString();
System.out.println(s);
```

### StringBuilder 拼接效率为何更高

`String` 是不可变的，所有的 `+`、`+=` 底层都用 `StringBuilder.append()` 完成拼接，再调 `toString()` 转回 String。**每次拼接都会创建新的 StringBuilder 和新的 String 对象**，频繁向堆内存申请空间，所以慢。

`StringBuilder` 自始至终只创建一次对象，所有拼接都在同一个对象上完成，所以效率高。

### String vs StringBuilder

| 对比项 | String | StringBuilder |
|---|---|---|
| 可变性 | 不可变 | 可变 |
| 适用场景 | 字符串不常变化 | 频繁拼接、修改 |
| 拼接效率 | 低（每次创建新对象） | 高（同一对象操作） |

---

# 三、常见的集合

## 3.1 集合体系概览

集合是 Java 用于存储多个数据的容器，相比数组：**长度可动态变化**，提供丰富的操作方法。

集合分为两大体系：

| 体系 | 特点 | 主要实现类 |
|---|---|---|
| **单列集合（Collection）** | 每个元素仅含一个值 | List（有序可重复）、Set（无序不可重复） |
| **双列集合（Map）** | 每个元素是键值对 | HashMap（键唯一，值可重复） |

- **List**：元素有序、可重复、有索引 → 主要实现 `ArrayList`
- **Set**：元素无序、不可重复、无索引 → 主要实现 `HashSet`
- **Map**：键值对，键唯一、值可重复 → 主要实现 `HashMap`

---

## 3.2 List 体系

### 3.2.1 泛型

创建集合对象时看到 `<E>` 叫做**泛型**——一种未知类型，由使用者确定，用来**限定集合存储的数据类型**。

```Java
ArrayList<String> list = new ArrayList<>();
list.add("张三");
// list.add(123);  // 编译报错，泛型限定了只能存 String
```

注意：
- 泛型只能规定为**引用数据类型**，不能是基本数据类型
- 不指定泛型，JVM 默认为 `Object` 类型

### 3.2.2 基本数据类型包装类

集合不能存基本类型，需要用对应的**包装类**：

| 基本类型 | 包装类 |
|---|---|
| byte | Byte |
| short | Short |
| int | Integer |
| long | Long |
| float | Float |
| double | Double |
| char | Character |
| boolean | Boolean |

**自动装箱与拆箱**（JDK 1.5+）：

- **装箱**：基本类型 → 包装类型（自动发生）
- **拆箱**：包装类型 → 基本类型（自动发生）

```Java
ArrayList<Integer> list = new ArrayList<>();
list.add(1);    // 自动装箱：int → Integer
list.add(2);
list.add(3);

int sum = 0;
for (int i = 0; i < list.size(); i++) {
    sum += list.get(i);  // 自动拆箱：Integer → int
}
```

**包装类比基本类型多了什么**：
- 可以存储 `null` 值
- 有实用方法，如字符串转基本类型：
  - `Integer.parseInt(String num)`
  - `Byte.parseByte(String num)`
  - `Long.parseLong(String num)`

**案例：字符串数字累加**

```Java
String s1 = "1123,12,3,123,12,312,2";
String[] arr = s1.split(",");
int num = 0;
for (String s : arr) {
    num += Integer.parseInt(s);
}
System.out.println(num); // 1590
```

### 3.2.3 ArrayList 常用方法

| 方法 | 说明 |
|---|---|
| `boolean add(E e)` | 添加元素到末尾 |
| `void add(int index, E e)` | 在指定位置插入，后续元素后移 |
| `E set(int index, E e)` | 修改指定索引处的元素，返回旧值 |
| `E get(int index)` | 根据索引获取元素 |
| `boolean contains(Object obj)` | 判断是否包含指定元素 |
| `int size()` | 返回元素个数 |
| `boolean remove(E e)` | 按 equals 删除第一个匹配元素 |
| `E remove(int index)` | 按索引删除，返回被删元素 |
| `void clear()` | 清空集合 |

**批量添加技巧**：`Collections.addAll` 可以将数组/可变参数直接加入集合，比逐个 `add` 更简洁：

```Java
ArrayList<String> strings = new ArrayList<>();
String[] str = {"华为手机","小米耳机","华为平板","苹果手机","华为手表"};
Collections.addAll(strings, str);
System.out.println(strings);  // [华为手机, 小米耳机, 华为平板, 苹果手机, 华为手表]
```

**批量删除技巧**：`removeIf` 可以按条件批量删除集合中满足条件的元素：

```Java
ArrayList<String> strings2 = new ArrayList<>();
Collections.addAll(strings2, str);
strings2.removeIf(s -> s.contains("华为"));
System.out.println(strings2);  // [小米耳机, 苹果手机]
```

```Java
List<String> list = new ArrayList<>();
list.add("刘备");
list.add("关羽");
list.add("张飞");
System.out.println(list);            // [刘备, 关羽, 张飞]

list.set(0, "刘皇叔");
System.out.println(list);            // [刘皇叔, 关羽, 张飞]

System.out.println(list.get(0));     // 刘皇叔
System.out.println(list.contains("关羽")); // true
System.out.println(list.size());     // 3

list.remove("周瑜");                 // 无匹配，不删除
list.remove(0);
System.out.println(list);            // [关羽, 张飞]

list.clear();
System.out.println(list);            // []
```

### 3.2.4 List 遍历方式

```Java
List<Movie> movies = new ArrayList<>();
movies.add(new Movie("《肖生克的救赎》", 9.7, "罗宾斯"));
movies.add(new Movie("《霸王别姬》", 9.6, "张国荣、张丰毅"));
movies.add(new Movie("《阿甘正传》", 9.5, "汤姆.汉克斯"));

// 方式1：普通 for（有索引场景）
for (int i = 0; i < movies.size(); i++) {
    System.out.println(movies.get(i));
}

// 方式2：增强 for（简洁）
for (Movie movie : movies) {
    System.out.println(movie);
}

// 方式3：迭代器 Iterator
Iterator<Movie> it = movies.iterator();
while (it.hasNext()) {
    System.out.println(it.next());
}

// 方式4：Lambda forEach
movies.forEach(movie -> {
    System.out.println(movie);
});
```

### 3.2.5 List 应用案例：批量删除购物车商品

购物车中有：Java入门、宁夏枸杞、黑枸杞、人字拖、特级枸杞、枸杞子。用户不想买"枸杞"了，批量删除含"枸杞"的商品。

```Java
List<String> list = new ArrayList<>();
list.add("Java入门");
list.add("宁夏枸杞");
list.add("黑枸杞");
list.add("人字拖");
list.add("特级枸杞");
list.add("枸杞子");

// 使用迭代器删除（安全，不会并发修改异常）
Iterator<String> it = list.iterator();
while (it.hasNext()) {
    String name = it.next();
    if (name.contains("枸杞")) {
        it.remove();
    }
}
System.out.println(list); // [Java入门, 人字拖]
```

> **为什么不能用普通 for 或增强 for 直接删除？**
> 普通 for 删除后索引错位会漏删；增强 for 遍历时直接调 `list.remove()` 会抛 `ConcurrentModificationException`。用迭代器的 `remove()` 或倒序 for 循环是安全的。

---

## 3.3 Set 体系

Set 是无序且元素唯一的集合，无索引。

### 3.3.1 HashSet 常用方法

| 方法 | 说明 |
|---|---|
| `boolean add(E e)` | 添加元素 |
| `boolean contains(Object obj)` | 判断是否包含 |
| `int size()` | 返回元素个数 |
| `boolean remove(E e)` | 删除元素 |
| `void clear()` | 清空集合 |

```Java
Set<String> set = new HashSet<>();
set.add("张三");
set.add("李四");
set.add("王五");
System.out.println(set);             // [王五, 张三, 李四]（无序）

System.out.println(set.contains("张三")); // true
System.out.println(set.size());      // 3

set.remove("张三");
System.out.println(set);             // [王五, 李四]

set.clear();
System.out.println(set);             // []
```

### 3.3.2 HashSet 去重原理

**关键：`hashCode()` + `equals()`**

`Object` 类中的 `hashCode()` 默认被 `native` 修饰，底层根据内存地址计算出一个伪地址作为 hash 值。

**去重流程**：
1. 先比较 hash 值
2. hash 值相同再用 `equals()` 比较
3. 两者都相同才判断为重复，才去重

**自定义类型去重示例**：

```Java
public class Student {
    private String name;
    private int age;

    public Student(String name, int age) {
        this.name = name;
        this.age = age;
    }

    @Override
    public boolean equals(Object o) {
        if (o == null || getClass() != o.getClass()) return false;
        Student student = (Student) o;
        return age == student.age && Objects.equals(name, student.name);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, age);
    }
}
```

```Java
Set<Student> set = new HashSet<>();
set.add(new Student("张三", 18));
set.add(new Student("李四", 19));
set.add(new Student("李四", 19));  // 与上一个重复，去重
System.out.println(set);
// [Student{name='张三', age=18}, Student{name='李四', age=19}]
```

**结论**：使用 HashSet 存储自定义类型时，**必须重写 `hashCode()` 和 `equals()` 方法**。基本类型包装类和 String 已经重写过这两个方法。

### 3.3.3 Set vs List

| 对比项 | List | Set |
|---|---|---|
| 有序性 | 有序（按添加顺序） | 无序（HashSet） |
| 重复元素 | 可重复 | 不可重复 |
| 索引 | 有索引 | 无索引 |
| 主要实现 | ArrayList | HashSet |

---

## 3.4 Map 体系

### 3.4.1 概述

Map 是双列集合的顶层接口，每次存储一对元素（**键值对**），**键不能重复**，值可重复。

Set 其实就是用的 Map 左边的键部分。

常用实现类：`HashMap<K, V>`

### 3.4.2 常用方法

| 方法 | 说明 |
|---|---|
| `V put(K key, V value)` | 添加元素；键重复则覆盖旧值并返回旧值，否则返回 null |
| `int size()` | 获取集合大小 |
| `boolean isEmpty()` | 判断是否为空 |
| `V get(Object key)` | 根据键获取值 |
| `V remove(Object key)` | 根据键删除整个键值对 |
| `boolean containsKey(Object key)` | 判断是否包含某个键 |
| `boolean containsValue(Object value)` | 判断是否包含某个值 |
| `Set<K> keySet()` | 获取全部键的集合 |
| `Collection<V> values()` | 获取全部值的集合 |
| `void clear()` | 清空集合 |

```Java
Map<String, String> map = new HashMap<>();
map.put("001", "玄奘");
map.put("002", "悟空");
map.put("003", "悟能");
map.put("004", "悟净");
map.put("004", "悟净1");  // 键重复，覆盖旧值
System.out.println(map);  // {001=玄奘, 002=悟空, 003=悟能, 004=悟净1}

System.out.println(map.size());        // 4
System.out.println(map.get("001"));    // 玄奘
System.out.println(map.containsKey("001")); // false（已被删除）
System.out.println(map.containsValue("悟空")); // true

Set<String> keys = map.keySet();
Collection<String> values = map.values();
```

### 3.4.3 Map 三种遍历方式

```Java
Map<String, String> map = new HashMap<>();
map.put("001", "玄奘");
map.put("002", "悟空");
map.put("003", "悟能");
map.put("004", "悟净");

// 方式1：keySet() → 遍历键再取值
Set<String> keys = map.keySet();
for (String key : keys) {
    String value = map.get(key);
    System.out.println("key:" + key + ", value:" + value);
}

// 方式2：entrySet() → 遍历键值对
Set<Map.Entry<String, String>> entries = map.entrySet();
for (Map.Entry<String, String> entry : entries) {
    String key = entry.getKey();
    String value = entry.getValue();
    System.out.println("key:" + key + ", value:" + value);
}

// 方式3：Lambda forEach
map.forEach((key, value) -> {
    System.out.println("key:" + key + ", value:" + value);
});
```

### 3.4.4 Map 应用案例

**案例一：统计订单类别数量**

```Java
public class Order {
    private String name;
    private String category;
    private double amount;

    // 构造器、getter/setter、toString 省略
}
```

```Java
List<Order> list = new ArrayList<>();
list.add(new Order("小王", "咖啡", 10));
list.add(new Order("小张", "咖啡", 10));
list.add(new Order("小花", "奶茶", 10));
list.add(new Order("大壮", "奶茶", 20));
list.add(new Order("大嘴", "果茶", 22));
list.add(new Order("大脚", "果茶", 4));
list.add(new Order("小可爱", "果茶", 3));

Map<String, Integer> map = new HashMap<>();
for (Order order : list) {
    String category = order.getCategory();
    if (map.containsKey(category)) {
        map.put(category, map.get(category) + 1);
    } else {
        map.put(category, 1);
    }
}
System.out.println(map); // {咖啡=2, 奶茶=2, 果茶=3}
```

**案例二：从字符串数组提取书名作者**

```Java
String[] bookArr = {"《红楼梦》-曹雪芹", "《西游记》-吴承恩", "《三国演义》-罗贯中", "《水浒传》-施耐庵"};
Map<String, String> map = new HashMap<>();

for (String s : bookArr) {
    String[] split = s.split("-");
    map.put(split[0], split[1]);
}

map.forEach((key, value) -> {
    System.out.println("书名:" + key + ", 作者:" + value);
});
```

---

# 四、本章速记

| 容器/集合 | 核心特征 | 适用场景 |
|---|---|---|
| **Array** | 固定大小，同类型数据 | 数据量固定、需要索引访问 |
| **String** | 不可变字符序列 | 文本存储，不频繁拼接 |
| **StringBuilder** | 可变字符序列 | 频繁拼接、修改字符串 |
| **List (ArrayList)** | 有序、可重复、有索引 | 需要按顺序存储、按索引访问 |
| **Set (HashSet)** | 无序、不可重复 | 去重、判断是否包含 |
| **Map (HashMap)** | 键值对，键唯一 | 有对应关系的数据存储 |

**关键提醒**：
- 集合泛型只能用引用类型，存基本类型用包装类（自动拆装箱）
- HashSet / HashMap 去重依赖 `hashCode()` + `equals()`，自定义类型必须重写
- List 批量删除用迭代器或倒序 for，避免 `ConcurrentModificationException`
- 频繁拼接字符串优先用 `StringBuilder`，不要用 `String` 的 `+`
