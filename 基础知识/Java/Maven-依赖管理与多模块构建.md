---
title: "Maven 高级 - 依赖管理与多模块构建"
tags: ["Maven","依赖管理","聚合","继承","Maven高级"]
created: "2026-09-01"
---

# Maven 高级

## 六、Maven

### 6.1 介绍

Maven 是一款用于构建和管理 Java 项目的工具，好处是方便导入 jar 包和项目管理。在 Maven 项目中，如果需要 jar 包，不需要再去官网下载，只需要在 Maven 指定的配置文件中声明需要哪个 jar 包，Maven 就会自动去本地仓库中查找，如果查找不到还会联网去中央仓库下载。

**Maven 三大作用：**

1. **依赖管理** — 可以帮我们管理第三方依赖的下载和冲突等相关操作
2. **一键构建** — Maven 支持按钮式一键编译、测试、打包、部署等操作
3. **统一项目的目录结构** — 不同开发平台 Maven 项目的结构是一样的，可以跨平台开发

### 6.2 安装与配置

**下载地址：** https://maven.apache.org/download.cgi

**安装要求：** 解压路径没有中文、没有空格

**仓库分类：**

- **中央仓库**：Apache 公司内部维护的，是国外网站，访问受限
- **私服**：自己搭建的私服，比如阿里就搭建了私服，镜像了中央仓库的大部分 jar 包，后期可以配置阿里的私服取代中央仓库
- **本地仓库**：Maven 下载软件首先从本地仓库中寻找，然后从私服中寻找，最后从中央仓库寻找。jar 只需要从私服或中央仓库下载一次，提高下载速率

#### 配置本地仓库

找到 Maven 安装路径下 `conf/setting.xml`，在 xml 文件中配置本地仓库路径。

#### 配置阿里云私服

在 `conf/setting.xml` 的 `<mirrors>` 标签内部添加：

```xml
<mirror>
    <id>alimaven</id>
    <name>aliyun maven</name>
    <url>http://maven.aliyun.com/nexus/content/groups/public/</url>
    <mirrorOf>central</mirrorOf>
</mirror>
```

#### 配置 JDK（选择配置）

在 `<profiles>` 中添加：

```xml
<profile>
    <id>jdk-21</id>
    <activation>
        <activeByDefault>true</activeByDefault>
        <jdk>21</jdk>
    </activation>
    <properties>
        <maven.compiler.source>21</maven.compiler.source>
        <maven.compiler.target>21</maven.compiler.target>
        <maven.compiler.compilerVersion>21</maven.compiler.compilerVersion>
    </properties>
</profile>
```

### 6.3 IDEA 配置 Maven 环境

**路径：** `File` → `Settings` → `Build, Execution, Deployment` → `Build Tools` → `Maven`

配置完毕当前工程后，需要关闭当前工程，再配置**全局的 Maven 环境**，保证之后所有新创建的项目都拥有 Maven 环境。

> 如果电脑中有多款 JDK，还需要额外设置 JDK 版本相关配置，否则可能会出现问题。

### 6.4 创建 Maven 项目

在 IDEA 中创建 Java 项目时，选择 Maven 模板，然后设置：
- **GroupId**（组织名，一般为公司域名倒写）
- **ArtifactId**（项目名）
- **Version**（项目版本号）

**项目结构：**

```
项目根目录/
├── src/
│   ├── main/
│   │   ├── java/       # 放置 Java 的包和类
│   │   └── resources/  # 放置项目的配置文件（如数据库连接等）
│   └── test/           # 放置测试内容
└── pom.xml             # Maven 管理相关的配置（依赖都在此配置）
```

### 6.5 依赖管理

依赖指当前项目运行所需要的 jar 包，一个项目中可以引入多个依赖。

**引入依赖步骤：**

1. 在 `pom.xml` 中编写 `<dependencies>` 标签
2. 在 `<dependencies>` 标签中使用 `<dependency>` 引入坐标
3. 定义坐标的 `groupId`、`artifactId`、`version`

```xml
<!-- 依赖管理: 可以引入多个依赖 -->
<dependencies>
    <!-- 每个依赖都是一个 dependency 标签 -->
    <!-- lombok 依赖 -->
    <dependency>
        <groupId>org.projectlombok</groupId>  <!-- 组织名 -->
        <artifactId>lombok</artifactId>        <!-- 项目名 -->
        <version>1.18.38</version>             <!-- 版本号 -->
    </dependency>

    <!-- hutool 依赖 -->
    <dependency>
        <groupId>cn.hutool</groupId>
        <artifactId>hutool-all</artifactId>
        <version>5.8.44</version>
    </dependency>
</dependencies>
```

4. 点击 IDEA 右上角的刷新按钮，引入最新加入的坐标

**注意事项：**

- 如果引入的依赖在本地仓库中不存在，将会连接远程仓库/中央仓库下载依赖（比较耗时，耐心等待）
- 如果不知道依赖的坐标信息，可以到 Maven 中央仓库（https://mvnrepository.com/）中搜索

### 6.6 测试使用 Hutool 工具包

```java
package com.itheima.a;

import cn.hutool.core.io.FileUtil;
import java.nio.file.Paths;

public class Demo1 {

    public static void main(String[] args) {
        // 使用 Hutool 工具包完成文件拷贝功能
        copySingleFile();
        copyDirectory();
    }

    // 单文件拷贝（最常用）
    private static void copySingleFile() {
        try {
            String srcFile = Paths.get("D:/test/source.txt").toString();   // 源文件路径
            String destFile = Paths.get("D:/test/target.txt").toString(); // 目标文件路径

            // 核心 API: 拷贝文件，第三个参数 true 表示覆盖目标文件
            FileUtil.copy(srcFile, destFile, true);
            System.out.println("单文件拷贝成功");
        } catch (Exception e) {
            System.err.println("单文件拷贝失败：" + e.getMessage());
        }
    }

    // 文件夹拷贝（递归拷贝子文件/子文件夹）
    private static void copyDirectory() {
        try {
            Path srcDir = Paths.get("F:\\aaa");   // 源文件夹路径
            Path destDir = Paths.get("F:\\mjj");  // 目标文件夹路径

            // 核心 API: 递归拷贝整个文件夹，默认覆盖已存在文件
            FileUtil.copy(srcDir, destDir);
            System.out.println("文件夹拷贝成功");
        } catch (Exception e) {
            System.err.println("文件夹拷贝失败：" + e.getMessage());
        }
    }
}
```

### 6.7 测试使用 Lombok 工具包

Lombok 是一款用于简化实体类书写的工具包：

- `@Data`：相当于 getter/setter/toString/equals/hashCode 方法
- `@NoArgsConstructor`：相当于无参构造方法
- `@AllArgsConstructor`：相当于全参构造方法

```java
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data            // getter/setter/toString/equals/hashCode
@NoArgsConstructor  // 无参构造方法
@AllArgsConstructor // 全参构造方法
class User {
    private String name;
    private int age;
}
```

```java
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

public class Demo2 {
    public static void main(String[] args) {
        User user = new User("张三", 18);
        System.out.println(user.getName());
        System.out.println(user.getAge());
        System.out.println(user);
    }
}
```

### 6.8 依赖传递

依赖传递指的是当我们引入第三方依赖的时候，该第三方相关的依赖也会被一并引入。比如 Spring-Web 相关的起步依赖，就通过依赖传递引入了其关联的所有依赖。

### 6.9 依赖冲突

Maven 除了依赖传递特性之外，还会解决依赖冲突：

- **直接依赖冲突**：后面的依赖版本会将前面的依赖覆盖
- **直接依赖和间接依赖冲突**：直接依赖优先
- **间接依赖和间接依赖冲突**：如果层级一致则声明优先，如果层级不一致则层级浅的优先

### 6.10 依赖范围

Maven 可以通过 `scope` 设置 jar 的生效阶段：

| scope 值 | 生效阶段 |
|----------|----------|
| `compile` | 编译、测试、运行 |
| `test` | 仅测试 |
| `provided` | 编译、测试 |
| `runtime` | 测试、运行 |

jar 的坐标出厂就已经设置好了依赖范围，我们只需知道这个概念即可。例如 JUnit 单元测试只需在测试环境下生效：

```xml
<!-- 导入测试的起步依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-test</artifactId>
    <scope>test</scope>
</dependency>
```

### 6.11 排除依赖

有时候引入依赖但不想要它传递的依赖，可以通过排除依赖进行设置：

```xml
<!-- 导入 spring-web 的起步依赖 -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-web</artifactId>
    <!-- 排除 tomcat 的传递依赖 -->
    <exclusions>
        <exclusion>
            <artifactId>spring-boot-starter-tomcat</artifactId>
            <groupId>org.springframework.boot</groupId>
        </exclusion>
    </exclusions>
</dependency>
```

### 6.12 常用命令

| 命令 | 作用 |
|------|------|
| `mvn clean` | 清理编译产生的文件 |
| `mvn compile` | 编译源代码 |
| `mvn package` | 打包项目 |
| `mvn install` | 安装到本地仓库 |

---


### 6.13 Maven的聚合

项目模块多时，每个模块都要单独编译、打包、测试。Maven **聚合**功能可以一键构建所有子模块。

**步骤：**
1. 创建一个公共模块（聚合模块 / 父模块），<packaging> 设为 pom
2. 在父模块的 pom.xml 中用 <modules> 标签聚合子模块
3. 对父模块执行任何 Maven 操作，所有被聚合的子模块同步执行

`xml
<packaging>pom</packaging>

<modules>
    <module>../day06_test1</module>
    <module>../day06_test2</module>
    <module>../day06_test3</module>
</modules>
`

---

### 6.14 Maven的继承

聚合的子模块可能共享相同的 jar 依赖，可以通过父工程统一管理，提高复用性。

#### 家产（共享依赖）

父工程 <dependencies> 中定义的依赖，子模块**直接继承**使用：

`xml
<dependencies>
    <dependency>
        <groupId>junit</groupId>
        <artifactId>junit</artifactId>
        <version>4.13.2</version>
        <scope>test</scope>
    </dependency>
</dependencies>
`

> 只有**所有子模块都要用**的依赖才放家产中。

#### 家规（版本管理）

父工程 <dependencyManagement> 中声明依赖版本，子模块引用时**无需指定版本**：

`xml
<dependencyManagement>
    <dependencies>
        <dependency>
            <groupId>org.springframework.boot</groupId>
            <artifactId>spring-boot-starter-web</artifactId>
            <version>3.4.3</version>
        </dependency>
    </dependencies>
</dependencyManagement>
`

子模块使用时只写 groupId + artifactId，版本由父工程统一管控。

---

---

## 本章速记

- Maven 先掌握安装配置（本地仓库 + 阿里云私服）、依赖坐标、依赖传递与冲突规则
- 多模块用聚合一键构建，用继承（家产/家规）统一管理依赖版本
- 依赖冲突规则：直接依赖优先、层级浅的优先、声明顺序覆盖
