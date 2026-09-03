---
title: "SpringBoot Web开发基础 - 三层架构、IOC与DI"
tags: ["SpringBoot","三层架构","IOC","DI","组件扫描","Web开发"]
created: "2026-09-01"
---

# SpringBoot Web开发基础

## 一、SpringBoot 项目创建

### 1.1 创建方式

- 通过 Spring 官方网站 [start.spring.io](https://start.spring.io) 在线生成
- 通过 IDEA 内置的 Spring Initializr 向导创建

### 1.2 起步依赖

起步依赖本质是一组预定义的依赖坐标集合，通过传递依赖自动引入相关 jar 包。常用起步依赖：

| 起步依赖 | 作用 |
|----------|------|
| spring-boot-starter-web | 包含 Spring MVC、Tomcat、Jackson 等 |
| spring-boot-starter-test | 包含 JUnit、Mockito 等测试工具 |

### 1.3 项目结构约定

SpringBoot 项目约定：
- 启动类放在项目根包下，所有业务类放在启动类所在包的子包中
- src/main/resources 存放配置文件（application.yml / application.properties）
- 配置文件中可通过 server.port 指定端口

---

## 二、三层架构

### 2.1 分层结构与职责

| 层 | 职责 | 注解 |
|----|------|------|
| **Controller（控制层）** | 接收前端请求，调用 Service，返回响应数据 | @RestController |
| **Service（业务层）** | 处理业务逻辑，事务管理 | @Service |
| **Dao（数据访问层）** | 操作数据库，执行 CRUD | @Repository |

### 2.2 分包结构

以 com.example 为根包，标准分包如下：

```
com.example
├── controller/      ← 控制层
├── service/         ← 业务层（接口）
│   └── impl/        ← 业务层实现类
├── dao/             ← 数据访问层（接口）
│   └── impl/        ← 数据访问层实现类
├── pojo/            ← 实体类（Entity / VO / DTO）
├── utils/           ← 工具类
└── Application.java ← 启动类
```

### 2.3 基础标准代码

**Pojo 层 - 实体类**

```java
package com.example.pojo;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data                     // 自动生成 getter/setter/toString/equals/hashCode
@NoArgsConstructor         // 自动生成无参构造方法
@AllArgsConstructor        // 自动生成全参构造方法
public class Emp {
    private Integer id;       // 员工编号
    private String name;      // 员工姓名
    private Integer age;      // 员工年龄
}
```

**Dao 层 - 数据访问接口**

```java
package com.example.dao;

import com.example.pojo.Emp;
import java.util.List;

public interface EmpDao {
    /**
     * 查询所有员工
     * @return 员工列表
     */
    List<Emp> list();

    /**
     * 根据 ID 查询单个员工
     * @param id 员工编号
     * @return 对应员工，不存在则返回 null
     */
    Emp getById(Integer id);

    /**
     * 新增员工
     * @param emp 待插入的员工对象
     */
    void insert(Emp emp);

    /**
     * 修改员工信息
     * @param emp 包含待更新字段的员工对象（需包含 id）
     */
    void update(Emp emp);

    /**
     * 根据 ID 删除员工
     * @param id 员工编号
     */
    void deleteById(Integer id);
}
```

**Dao 层 - 实现类**

```java
package com.example.dao.impl;

import com.example.pojo.Emp;
import com.example.dao.EmpDao;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository  // 标注为数据访问层组件，交给 Spring 容器管理
public class EmpDaoImpl implements EmpDao {

    @Autowired  // Spring 自动注入 JdbcTemplate，无需手动创建
    private JdbcTemplate jdbcTemplate;

    /**
     * 查询所有员工
     * query() 执行查询并返回 List
     * BeanPropertyRowMapper 自动将数据库列名映射到 Emp 属性
     */
    @Override
    public List<Emp> list() {
        return jdbcTemplate.query("select * from emp", new BeanPropertyRowMapper<>(Emp.class));
    }

    /**
     * 根据 ID 查询单个员工
     * queryForObject() 返回单条记录，找不到时抛出 EmptyResultDataAccessException
     */
    @Override
    public Emp getById(Integer id) {
        return jdbcTemplate.queryForObject("select * from emp where id = ?",
                new BeanPropertyRowMapper<>(Emp.class), id);
    }

    /**
     * 新增员工
     * update() 用于 INSERT / UPDATE / DELETE，返回受影响行数
     * ? 为占位符，按顺序对应后面的参数值，防止 SQL 注入
     */
    @Override
    public void insert(Emp emp) {
        jdbcTemplate.update("insert into emp(name, age) values(?, ?)",
                emp.getName(), emp.getAge());
    }

    /**
     * 修改员工信息（按 id 更新 name 和 age）
     */
    @Override
    public void update(Emp emp) {
        jdbcTemplate.update("update emp set name = ?, age = ? where id = ?",
                emp.getName(), emp.getAge(), emp.getId());
    }

    /**
     * 根据 ID 删除员工
     */
    @Override
    public void deleteById(Integer id) {
        jdbcTemplate.update("delete from emp where id = ?", id);
    }
}
```

**Service 层 - 业务接口**

```java
package com.example.service;

import com.example.pojo.Emp;
import java.util.List;

public interface EmpService {
    /** 查询所有员工 */
    List<Emp> list();

    /** 根据 ID 查询单个员工 */
    Emp getById(Integer id);

    /** 新增员工 */
    void insert(Emp emp);

    /** 修改员工信息 */
    void update(Emp emp);

    /** 根据 ID 删除员工 */
    void deleteById(Integer id);
}
```

**Service 层 - 实现类**

```java
package com.example.service.impl;

import com.example.dao.EmpDao;
import com.example.pojo.Emp;
import com.example.service.EmpService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service  // 标注为业务层组件，交给 Spring 容器管理
public class EmpServiceImpl implements EmpService {

    @Autowired  // 注入 Dao 接口的实现类（Spring 自动匹配类型）
    private EmpDao empDao;

    @Override
    public List<Emp> list() {
        // 业务层直接调用 Dao 层完成查询
        return empDao.list();
    }

    @Override
    public Emp getById(Integer id) {
        return empDao.getById(id);
    }

    @Override
    public void insert(Emp emp) {
        // 实际项目中可在此处添加业务校验，如姓名不能为空等
        empDao.insert(emp);
    }

    @Override
    public void update(Emp emp) {
        empDao.update(emp);
    }

    @Override
    public void deleteById(Integer id) {
        empDao.deleteById(id);
    }
}
```

**Controller 层 - 控制器**

```java
package com.example.controller;

import com.example.pojo.Emp;
import com.example.service.EmpService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController    // @Controller + @ResponseBody，返回值直接作为 JSON 响应体
@RequestMapping("/emps")  // 统一前缀：所有接口路径都以 /emps 开头
public class EmpController {

    @Autowired  // 注入 Service 接口，Controller 不直接依赖 Dao
    private EmpService empService;

    /** GET /emps — 查询所有员工 */
    @GetMapping            // 等价于 @RequestMapping(method = RequestMethod.GET)
    public List<Emp> list() {
        return empService.list();
    }

    /** GET /emps/{id} — 根据 ID 查询单个员工 */
    @GetMapping("/{id}")   // {id} 是路径变量占位符
    public Emp getById(@PathVariable Integer id) {
        // @PathVariable 将 URL 中的 {id} 绑定到方法参数 id
        return empService.getById(id);
    }

    /** POST /emps — 新增员工 */
    @PostMapping          // 等价于 @RequestMapping(method = RequestMethod.POST)
    public void insert(@RequestBody Emp emp) {
        // @RequestBody 将请求体中的 JSON 自动反序列化为 Emp 对象
        empService.insert(emp);
    }

    /** PUT /emps — 修改员工信息 */
    @PutMapping           // 等价于 @RequestMapping(method = RequestMethod.PUT)
    public void update(@RequestBody Emp emp) {
        empService.update(emp);
    }

    /** DELETE /emps/{id} — 根据 ID 删除员工 */
    @DeleteMapping("/{id}")  // {id} 是路径变量占位符
        // @PathVariable 将 URL 中的 {id} 绑定到方法参数 id
        empService.deleteById(id);
    }
}
```


### 2.4 请求参数接收

Controller 方法通过以下注解从前端请求中提取参数：

| 注解 | 用途 | 参数来源 |
|------|------|----------|
| `@PathVariable` | 绑定 URL 路径中的变量 | `/emps/{id}` 中的 `{id}` |
| `@RequestBody` | 将请求体 JSON 反序列化为对象 | POST/PUT 请求体 |
| `@RequestParam` | 结定 URL 查询参数或表单参数 | `/emps?name=张三&age=20` |

**@PathVariable** — 路径参数

```java
@GetMapping("/{id}")  // URL 中的 {id} 是占位符
public Emp getById(@PathVariable Integer id) {
    // 请求 GET /emps/1 时，id = 1
    return empService.getById(id);
}
```

路径中可有多个占位符：

```java
@GetMapping("/{deptId}/{empId}")
public Emp getByDeptAndId(@PathVariable Integer deptId, @PathVariable Integer empId) {
    // 请求 GET /emps/10/100 时，deptId = 10，empId = 100
    return empService.getByDeptAndId(deptId, empId);
}
```

占位符名与参数名不一致时，需显式指定：

```java
@GetMapping("/{deptId}/{empId}")
public Emp getByDeptAndId(@PathVariable("deptId") Integer dId,
                          @PathVariable("empId") Integer eId) {
    return empService.getByDeptAndId(dId, eId);
}
```

**@RequestBody** — 请求体 JSON

```java
@PostMapping
public void insert(@RequestBody Emp emp) {
    // 前端发送 JSON：{"name":"张三","age":20}
    // 框架自动反序列化为 Emp 对象
    empService.insert(emp);
}
```

**@RequestParam** — 查询参数 / 表单参数

```java
@GetMapping
public List<Emp> search(@RequestParam(defaultValue = "1") Integer page,
                         @RequestParam(defaultValue = "10") Integer pageSize) {
    // 请求 GET /emps?page=2&pageSize=5
    // 未传时使用 defaultValue 默认值
    return empService.search(page, pageSize);
}
```

> 参数名与 URL 参数名一致时可省略 value，不一致时需显式指定：`@RequestParam("pn") Integer pageNum`

### 2.5 分层解耦

三层之间的依赖通过 **IOC + DI** 实现解耦：
- 每一层只声明所需对象的接口类型，不直接创建具体实现
- 由 Spring 容器管理对象的创建和注入
- 标准写法：Controller -> Service 接口 -> ServiceImpl -> Dao 接口

### 2.6 调用流程

```
请求 -> Controller -> Service -> Dao -> 数据库
响应 <- Controller <- Service <- Dao <- 数据库
```

---

## 三、IOC（控制反转）

### 3.1 概念

IOC（Inversion of Control）：对象的创建和管理权从程序代码**转移给 Spring 容器**。程序不再主动 new 对象，而是从容器中获取。

### 3.2 Bean 声明

将对象交给 IOC 容器管理，需要使用以下注解：

| 注解 | 位置 | 说明 |
|------|------|------|
| @Component | 通用组件类 | 标注在任意需要容器管理的类上 |
| @RestController | 控制层类 | @Controller + @ResponseBody 组合，不可被 @Component 替代 |
| @Service | 业务层类 | @Component 衍生注解 |
| @Repository | 数据访问层类 | @Component 衍生注解 |

> 注意：声明控制器 bean 只能用 @RestController，不能用 @Component。通过注解的 value 属性可指定 bean 名称，未指定则默认为类名首字母小写。

### 3.3 组件扫描

以上注解要生效，必须被 @ComponentScan 扫描到。该注解已包含在 @SpringBootApplication 中，默认扫描范围是**启动类所在包及其子包**。

如需扫描其他包，显式声明：

```java
// 手动指定组件扫描的包路径（当业务类不在启动类所在包及其子包时需要）
@ComponentScan("com.example")
```

---

## 四、DI（依赖注入）

### 4.1 概念

DI（Dependency Injection）：IOC 容器为应用程序提供运行时所依赖的资源（对象）。@Autowired 是最常用的注入注解，默认按**类型**匹配。

### 4.2 多实现冲突及解决方案

当 IOC 容器中存在多个相同类型的 bean 时，框架无法确定注入哪个，会报错。解决方案：

**方案一：@Primary**

标注在被依赖的实现类上，声明该实现优先被选择：

```java
@Service
@Primary  // 标注在实现类上，表示当存在多个同类型 bean 时优先选择此类
public class EmpServiceImpl implements EmpService { ... }
```

**方案二：@Qualifier**

在注入处指定 bean 名称，必须配合 @Autowired 使用：

```java
@Autowired
@Qualifier("empServiceImpl")  // 指定注入 id 为 empServiceImpl 的 bean，必须配合 @Autowired 使用
private EmpService empService;
```

**方案三：@Resource（JDK 注解，不推荐）**

按 bean 名称注入：

```java
@Resource(name = "empServiceImpl")  // JDK 注解，按 bean 名称注入（不推荐，Spring 项目优先用 @Autowired + @Qualifier）
private EmpService empService;
```

---

## 五、核心要点速记

- SpringBoot 项目约定启动类放根包，业务类放子包，省去手动组件扫描配置
- 三层架构：Controller 接请求 -> Service 做业务 -> Dao 操作数据库
- IOC：对象创建权交给 Spring 容器，不再手动 new
- DI：容器自动按类型将依赖注入，多实现用 @Primary 或 @Qualifier 解决冲突
- 四个声明 bean 的注解中，Controller 层只能用 @RestController
