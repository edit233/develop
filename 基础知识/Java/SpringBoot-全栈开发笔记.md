---
title: "SpringBoot 全栈开发笔记"
tags: ["SpringBoot", "三层架构", "IOC", "DI", "Result", "VO", "DTO", "Logback", "异常处理", "文件上传", "MyBatis-Plus", "自动填充", "MD5"]
created: "2026-09-01"
updated: "2026-09-07"
---

# SpringBoot 全栈开发笔记

## 一、项目创建与结构约定

### 1.1 创建方式

- [start.spring.io](https://start.spring.io) 在线生成
- IDEA 内置 Spring Initializr 向导

### 1.2 起步依赖

| 起步依赖 | 作用 |
|----------|------|
| spring-boot-starter-web | Spring MVC + Tomcat + Jackson |
| spring-boot-starter-test | JUnit + Mockito |

### 1.3 项目结构约定

- 启动类放在项目根包下，所有业务类放在启动类所在包的子包中
- `src/main/resources` 存放配置文件
- 配置文件中通过 `server.port` 指定端口

---

## 二、三层架构

### 2.1 分层职责

| 层 | 职责 | 注解 |
|----|------|------|
| **Controller（控制层）** | 接收请求，调用 Service，返回响应 | @RestController |
| **Service（业务层）** | 处理业务逻辑，事务管理 | @Service |
| **Mapper（数据访问层）** | 操作数据库，执行 CRUD | @Mapper |

### 2.2 分包结构

```
com.example
├── controller/      ← 控制层
├── service/         ← 业务层（接口）
│   └── impl/        ← 业务层实现类
├── mapper/          ← 数据访问层（接口）
├── pojo/            ← 实体类
├── dto/             ← 数据传输对象
├── vo/              ← 视图对象
├── utils/           ← 工具类
└── Application.java ← 启动类
```

### 2.3 调用流程

```
请求 -> Controller -> Service -> Mapper -> 数据库
响应 <- Controller <- Service <- Mapper <- 数据库
```

### 2.4 分层解耦

三层之间的依赖通过 **IOC + DI** 实现解耦：
- 每一层只声明所需对象的接口类型，不直接创建具体实现
- 由 Spring 容器管理对象的创建和注入
- 标准写法：Controller -> Service 接口 -> ServiceImpl -> Mapper 接口

---

## 三、IOC（控制反转）

### 3.1 概念

对象的创建和管理权从程序代码**转移给 Spring 容器**。程序不再主动 new 对象，而是从容器中获取。

### 3.2 Bean 声明注解

| 注解 | 位置 | 说明 |
|------|------|------|
| @Component | 通用组件类 | 标注在任意需要容器管理的类上 |
| @RestController | 控制层类 | @Controller + @ResponseBody，**不能用 @Component 替代** |
| @Service | 业务层类 | @Component 衍生注解 |
| @Mapper | 数据访问层接口 | MyBatis 注解，也可用 @MapperScan 在启动类上批量扫描 |

### 3.3 组件扫描

注解需被 `@ComponentScan` 扫描到，该注解已包含在 `@SpringBootApplication` 中，默认扫描**启动类所在包及其子包**。需要扫描其他包时显式声明：

```java
@ComponentScan("com.example")
```

---

## 四、DI（依赖注入）

### 4.1 概念

IOC 容器为应用程序提供运行时所依赖的资源。`@Autowired` 最常用，默认按**类型**匹配。

### 4.2 多实现冲突解决方案

**@Primary** — 标注在实现类上，声明优先选择：

```java
@Service
@Primary
public class EmpServiceImpl implements EmpService { ... }
```

**@Qualifier** — 在注入处指定 bean 名称，配合 @Autowired：

```java
@Autowired
@Qualifier("empServiceImpl")
private EmpService empService;
```

**@Resource** — JDK 注解，按 bean 名称注入（Spring 项目不推荐，优先用 @Autowired + @Qualifier）。

---

## 五、请求参数接收

### 5.1 三种注解对比

| 注解 | 参数位置 | 示例 URL | 使用场景 |
|------|----------|----------|----------|
| `@RequestBody` | 请求体 | `POST /depts` body: `{"name":"服务中心"}` | 提交 JSON（新增/修改） |
| `@RequestParam` | 查询字符串/表单 | `/depts?page=1&name=研发` | 条件查询、分页 |
| `@PathVariable` | URL 路径 | `/depts/1` | 根据 ID 操作（查询/删除） |

### 5.2 @RequestBody — JSON 请求体

```java
@PostMapping("/depts")
public Result add(@RequestBody Dept dept) {
    deptService.add(dept);
    return Result.success();
}
```

### 5.3 @RequestParam — 键值对参数

```java
@GetMapping("/depts")
public Result search(@RequestParam(defaultValue = "1") Integer page,
                     @RequestParam(defaultValue = "10") Integer pageSize,
                     @RequestParam(required = false) String name) {
    return Result.success(deptService.search(page, pageSize, name));
}
```

> 参数名与 URL 参数名一致时可省略 value，不一致时需显式指定：`@RequestParam("pn") Integer pageNum`

### 5.4 @PathVariable — 路径参数

```java
@GetMapping("/{id}")
public Result findById(@PathVariable Integer id) {
    return Result.success(deptService.findById(id));
}

// 占位符名与参数名不一致时，显式指定
@DeleteMapping("/{id}")
public Result delete(@PathVariable("id") Integer id) {
    deptService.deleteById(id);
    return Result.success();
}
```

---

## 六、统一响应格式 Result

### 6.1 Result 类定义

```java
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Result {
    private Integer code;   // 1 成功，0 失败
    private String msg;
    private Object data;

    public static Result success() {
        return new Result(1, "success", null);
    }
    public static Result success(Object data) {
        return new Result(1, "success", data);
    }
    public static Result error(String msg) {
        return new Result(0, msg, null);
    }
}
```

### 6.2 响应 JSON 结构

```json
{
    "code": 1,
    "msg": "success",
    "data": { ... }
}
```

---

## 七、POJO / VO / DTO 数据模型

| 名称 | 全称 | 用途 | 存放位置 | 命名 |
|------|------|------|----------|------|
| **POJO / Entity** | Plain Old Java Object | 与数据库表一一对应 | `pojo/` 或 `entity/` | 表名如 `Dept` |
| **VO** | View Object | 封装前端需要的响应格式 | `vo/` | 以 `VO` 结尾 |
| **DTO** | Data Transfer Object | 封装前端提交的请求参数 | `dto/` | 以 `DTO` 结尾 |

**什么时候用 VO/DTO：**

- 数据库有 `password` 但接口不能返回 → 用 VO 去掉敏感字段
- 数据库只有 `name` 但前端需要 `name + token` → 用 VO 扩展字段
- 前端提交的参数不是一张表的完整字段 → 用 DTO 接收

---

## 八、日期时间格式化

### 8.1 @DateTimeFormat — 键值对 / 路径参数

```java
@GetMapping("/depts")
public Result search(
    @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime startTime) {
    return Result.success(deptService.searchByTime(startTime));
}
```

### 8.2 @JsonFormat — JSON 请求体

```java
@Data
public class Dept {
    private Integer id;
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private LocalDateTime createTime;
}
```

> **timezone = "GMT+8"** 不加会出现 8 小时偏差（默认 UTC）。

### 8.3 对比

| 注解 | 作用对象 | 适用参数类型 |
|------|----------|-------------|
| `@DateTimeFormat` | `@RequestParam` / `@PathVariable` | URL 参数 / 表单参数 |
| `@JsonFormat` | `@RequestBody` | JSON 字段 |

**推荐做法**：实体类时间字段上同时加两个注解，覆盖所有场景。

---

## 九、日志框架 Logback

### 9.1 为什么不用 System.out.println

| 问题 | 说明 |
|------|------|
| 不能开关控制 | 无法通过配置关闭特定级别的日志 |
| 不能持久化 | 输出到控制台后无法保存到文件 |
| 不能分级别 | 所有信息混在一起 |
| 阻塞主线程 | 影响业务性能 |

### 9.2 基本使用

SpringBoot 已集成 Logback，只需 `@Slf4j` 注解即可获取日志对象：

```java
@Slf4j
public class DeptController {
    public Result addDept(@RequestBody Dept dept) {
        log.info("新增部门,参数:{}", dept);  // {} 为占位符，性能优于字符串拼接
        deptService.addDept(dept);
        return Result.success();
    }
}
```

### 9.3 日志级别

从低到高：`TRACE` < `DEBUG` < `INFO` < `WARN` < `ERROR`

> 配置的日志级别会过滤低于该级别的输出。例如设为 INFO，则 TRACE 和 DEBUG 不输出。

### 9.4 配置文件 logback.xml

```xml
<configuration>
    <property name="pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"/>

    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder><pattern>${pattern}</pattern></encoder>
    </appender>

    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>D:/logs/app.log</file>
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>D:/logs/app.%d{yyyy-MM-dd}.%i.log</fileNamePattern>
            <maxFileSize>100MB</maxFileSize>
            <maxHistory>30</maxHistory>
            <totalSizeCap>1GB</totalSizeCap>
        </rollingPolicy>
        <encoder><pattern>${pattern}</pattern></encoder>
    </appender>

    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="FILE"/>
    </root>
</configuration>
```

也可以在 `application.yml` 中直接配置：

```yaml
logging:
  level:
    root: INFO
    com.itheima: DEBUG
```

---

## 十、全局异常处理

### 10.1 为什么需要

Controller 抛出异常时，SpringBoot 默认返回 HTML 错误页，前端无法解析。全局异常处理器的目的是：
1. **统一异常格式** — 包装为 Result 对象
2. **精确提示** — 不同异常类型返回对应错误信息
3. **日志记录** — 将异常信息写入日志便于排查

### 10.2 核心注解

| 注解 | 作用 |
|------|------|
| @RestControllerAdvice | 全局异常处理器，组合了 @ControllerAdvice + @ResponseBody |
| @ExceptionHandler(异常类型.class) | 标记方法处理特定异常 |

### 10.3 兜底异常处理

```java
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)
    public Result handlerException(Exception e) {
        log.error("服务器发生异常", e);
        return Result.error("对不起,操作失败,请联系管理员");
    }
}
```

### 10.4 精确异常处理

```java
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(DuplicateKeyException.class)
    public Result handlerDuplicateKeyException(DuplicateKeyException e) {
        if (e.getMessage().contains("dept.name")) {
            log.error("部门名称已存在");
            return Result.error("部门名称已存在");
        }
        return Result.error("对不起,操作失败,请联系管理员");
    }

    @ExceptionHandler(Exception.class)
    public Result handlerException(Exception e) {
        log.error("服务器发生异常", e);
        return Result.error("对不起,操作失败,请联系管理员");
    }
}
```

### 10.5 异常匹配优先级

子类异常优先匹配，父类异常兜底。例如：

```
DuplicateKeyException → DataAccessException → RuntimeException → Exception
```

### 10.6 最佳实践

- 一个项目通常只有一个全局异常处理器类
- 精确异常处理已知业务异常，Exception.class 兜底
- 每个 handler 方法都记录 `log.error()` 并包含异常对象
- 返回给用户的错误信息不要暴露技术细节

---

## 十一、文件上传

### 11.1 概述

前后端分离项目中，文件（头像、附件等）通常上传到对象存储（如阿里云 OSS），数据库只保存 URL。

### 11.2 流程

1. 前端通过 `multipart/form-data` 格式发送 POST 请求
2. 后端接收 `MultipartFile` 对象，上传到 OSS，获取文件访问 URL
3. 将 URL 存入数据库对应字段

### 11.3 通用实现

```java
@Slf4j
@RestController
@RequestMapping("/file")
public class FileController {

    @PostMapping("/upload")
    public Result upload(MultipartFile file) throws IOException {
        log.info("文件上传: {}", file.getOriginalFilename());

        // 生成唯一文件名，防止重名覆盖
        String originalFilename = file.getOriginalFilename();
        String extension = originalFilename.substring(originalFilename.lastIndexOf("."));
        String fileName = UUID.randomUUID().toString() + extension;

        // 上传到 OSS 并获取 URL
        String url = ossUtils.upload(file.getBytes(), fileName);

        return Result.success(url);
    }
}
```

### 11.4 注意事项

| 要点 | 说明 |
|------|------|
| 文件名 | UUID 生成唯一文件名，避免重名覆盖 |
| 类型限制 | 校验文件后缀和 MIME 类型，防止恶意上传 |
| 大小限制 | 配置 `spring.servlet.multipart.max-file-size` |
| 存储位置 | 生产用 OSS，开发可用本地磁盘 |

---

## 十二、MyBatis-Plus 业务层增强

### 12.1 IService 模板方法

MyBatis-Plus 提供 `IService` 接口和 `ServiceImpl` 默认实现，封装了常用 Service 方法：

| 类别 | 方法 | 说明 |
|------|------|------|
| **新增** | `save` / `saveBatch` | 单个/批量插入 |
| | `saveOrUpdate` | 有 ID 则更新，无 ID 则新增 |
| | `saveOrUpdateBatch` | 批量新增或修改 |
| **删除** | `removeById` / `removeByIds` | 根据 id 单个/批量删除 |
| | `remove(Wrapper)` | 根据条件删除 |
| **修改** | `updateById` | 根据 id 更新非 null 字段 |
| | `update(T, Wrapper)` | 按 T 内数据修改匹配的数据 |
| **查询** | `getById` / `getOne(Wrapper)` | 查询单条 |
| | `list()` / `listByIds` / `list(Wrapper)` | 查询集合 |
| | `count()` / `count(Wrapper)` | 统计数量 |
| | `getBaseMapper()` | 获取 BaseMapper 实现 |
| **分页** | `page(Page, Wrapper)` | 分页查询 |

### 12.2 快速入门

```java
// Service 接口
public interface UserService extends IService<User> {
    // 自定义业务方法
}

// Service 实现类 — 无需手动实现 IService 中的 CRUD 方法
@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {
    // 复杂业务逻辑在此编写
}
```

> 简单 CRUD 直接用 IService 方法，复杂业务（多表、自定义 SQL）在自己的 Service 实现类中编写。

### 12.3 多表查询与分页结合

MyBatis-Plus 适合单表操作。多表查询需手写 SQL，但可借助 `Page` 对象实现分页：

```java
// ServiceImpl
@Override
public PageResult<User> getUsers(UserDto userDto) {
    Page<User> p = new Page<>(userDto.getPage(), userDto.getPageSize());
    userMapper.selectByPage(p, userDto);  // Page 传入 Mapper，自动追加分页逻辑
    return new PageResult<>(p.getTotal(), p.getRecords());
}
```

```java
// Mapper 接口 — 返回类型是 Page
Page<User> selectByPage(Page<User> page, UserDto userDto);
```

### 12.4 自动填充

创建时间和更新时间的填充逻辑不应堆积在 Controller 层，MyBatis-Plus 的自动填充机制解决此问题。

#### 实体类标记

```java
@Data
public class User {
    @TableId
    private Integer id;

    @TableField(fill = FieldFill.INSERT)           // 插入时填充
    private LocalDateTime createTime;

    @TableField(fill = FieldFill.INSERT_UPDATE)    // 插入和更新时都填充
    private LocalDateTime updateTime;
}
```

| FieldFill 值 | 触发时机 |
|----------------|---------|
| `INSERT` | 仅插入时 |
| `UPDATE` | 仅更新时 |
| `INSERT_UPDATE` | 插入和更新时 |

#### 实现 MetaObjectHandler

```java
@Slf4j
@Component
public class MyMetaObjectHandler implements MetaObjectHandler {

    @Override
    public void insertFill(MetaObject metaObject) {
        this.setFieldValByName("createTime", LocalDateTime.now(), metaObject);
        this.setFieldValByName("updateTime", LocalDateTime.now(), metaObject);
    }

    @Override
    public void updateFill(MetaObject metaObject) {
        this.setFieldValByName("updateTime", LocalDateTime.now(), metaObject);
    }
}
```

#### 三种填充方式对比

| 方式 | 行为 |
|------|------|
| `strictInsertFill` / `strictUpdateFill` | 目标属性**有值则跳过** |
| `metaObject.setValue` | **不管有没有值都覆盖** |
| `setFieldValByName` | **先判断属性是否存在**，存在才填充 |

> **推荐 `setFieldValByName`**：源码先做 `metaObject.hasSetter(fieldName)` 判断，健壮性最好。

---

## 十三、密码安全 — MD5 加密

### 13.1 使用场景

1. **存储**：保存用户信息时，将明文密码 MD5 加密后存入数据库
2. **验证**：用户登录时，将输入的明文密码 MD5 加密后与数据库密文对比

### 13.2 代码示例

```java
// 使用 Hutool 的 DigestUtil
user.setPassword(DigestUtil.md5Hex(user.getUsername() + "123"));
```

> `DigestUtil.md5Hex()` 来自 Hutool 工具库，一行代码完成 MD5 哈希。注意 MD5 不是加密算法而是哈希算法，生产环境建议加盐（salt）或使用 BCrypt 等更安全的方案。

---

*最后更新：2026-09-07*
