---
title: "SpringBoot 全栈开发笔记"
tags: ["SpringBoot", "三层架构", "IOC", "DI", "Result", "VO", "DTO", "Logback", "异常处理", "文件上传", "MyBatis-Plus", "自动填充", "BCrypt", "ThreadLocal", "事务管理", "MyBatis XML", "一对多映射"]
created: "2026-09-01"
updated: "2026-09-11"
category: Java
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
└─- Application.java ← 启动类
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

## 十三、密码安全 — BCrypt 哈希

> **为什么不用 MD5**：MD5 是快速哈希算法，攻击者可用彩虹表、GPU 暴力破解在极短时间内还原常见密码，加盐（salt）也只能缓解；密码存储需要的是**慢哈希**（故意消耗算力），行业标准是 BCrypt / Argon2 / PBKDF2。旧项目常见的 `DigestUtil.md5Hex()`（Hutool 一行 MD5）写法仅作了解，新项目一律使用 BCrypt。

### 13.1 依赖

```xml
<dependency>
    <groupId>org.springframework.security</groupId>
    <artifactId>spring-security-crypto</artifactId>
</dependency>
```

> 只引入轻量的 `spring-security-crypto` 加密工具包即可，不需要引入整个 Spring Security。

### 13.2 使用场景

1. **存储**：注册时用 BCrypt 哈希明文密码后存库（自动生成随机盐，无需手动管理）
2. **验证**：登录时用 `matches()` 对比明文与密文

### 13.3 代码示例

```java
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;

// 建议注册为 Bean（线程安全，可全局复用）
@Bean
public BCryptPasswordEncoder passwordEncoder() {
    return new BCryptPasswordEncoder();  // 默认强度 10，即 2^10 轮哈希迭代
}

// 注册：哈希存储（每次 encode 结果都不同，因为随机盐不同，属正常现象）
user.setPassword(passwordEncoder.encode(user.getPassword()));

// 登录：密文对比（不能用 equals 比较字符串，必须用 matches）
boolean ok = passwordEncoder.matches(rawPassword, user.getPassword());
```

> **与 Python 侧对照**：FastAPI 项目用 pwdlib 的 Argon2（见 [[用户认证与鉴权]]），思路一致——注册时哈希、登录时 matches 对比，且都是自带随机盐的慢哈希。

---

*最后更新：2026-09-07*


---

## 十四、Docker 化部署

### 环境变量覆盖配置

Docker 化后敏感配置通过环境变量注入，不硬编码在 application.yaml 中：

```yaml
# application.yaml 保留默认值（开发环境）
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/qk
    username: root
    password: 123456
```

Spring Boot 3.x 自动支持环境变量覆盖（规则：属性名大写+下划线替换点号）：

| application.yaml 属性 | 环境变量名 |
|---|---|
| spring.datasource.url | SPRING_DATASOURCE_URL |
| spring.datasource.username | SPRING_DATASOURCE_USERNAME |
| spring.datasource.password | SPRING_DATASOURCE_PASSWORD |

docker-compose.yml 中配置：
```yaml
environment:
  - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/qk?useUnicode=true&serverTimezone=Asia/Shanghai
  - SPRING_DATASOURCE_USERNAME=root
  - SPRING_DATASOURCE_PASSWORD=123456
```

### 多模块 Maven 项目 Dockerfile

```dockerfile
# 阶段一：构建
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /app
COPY backend/qk-parent/pom.xml backend/qk-parent/pom.xml
COPY backend/qk-parent/qk-common/pom.xml backend/qk-parent/qk-common/pom.xml
COPY backend/qk-parent/qk-entity/pom.xml backend/qk-parent/qk-entity/pom.xml
COPY backend/qk-parent/qk-management/pom.xml backend/qk-parent/qk-management/pom.xml
RUN cd backend/qk-parent && mvn dependency:go-offline -B
COPY backend/ backend/
RUN cd backend/qk-parent && mvn package -DskipTests -B

# 阶段二：运行
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=build /app/backend/qk-parent/qk-management/target/qk-management-*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

关键点：先 COPY pom.xml 再 RUN 再 COPY 源码，利用 Docker 层缓存避免每次重新下载依赖。

*最后更新：2026-09-07*

---

## 十五、ThreadLocal 跨层数据共享

### 15.1 问题场景

拦截器中解析出当前登录用户 ID，但 Service 层也需要使用该信息。传统做法是层层传参，但会污染方法签名。

### 15.2 ThreadLocal 概念

ThreadLocal（线程局部变量）能让**同一个线程内的不同层**共享数据，互不干扰。

| 方法 | 作用 |
|------|------|
| set(T value) | 设置当前线程的线程局部变量 |
| get() | 返回当前线程的线程局部变量 |
| 
emove() | 移除当前线程的线程局部变量（防止内存泄漏） |

### 15.3 实现模式

**工具类封装：**

```java
public class UserHolder {
    private static ThreadLocal<Integer> CURRENT_USER = new ThreadLocal<>();

    public static void setCurrentUser(Integer userId) {
        CURRENT_USER.set(userId);
    }

    public static Integer getCurrentUser() {
        return CURRENT_USER.get();
    }

    public static void removeCurrentUser() {
        CURRENT_USER.remove();
    }
}
```

**拦截器中存入（解析 token 后）：**

```java
@Override
public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
    // ... 解析 token ...
    Claims claims = JwtUtil.parseToken(jwt);
    Integer userId = claims.get("id", Integer.class);
    UserHolder.setCurrentUser(userId);  // 存入 ThreadLocal
    return true;
}

@Override
public void afterCompletion(...) {
    UserHolder.removeCurrentUser();  // 请求结束后必须清理
}
```

**Service 中取出：**

```java
@Override
@Transactional(rollbackFor = Exception.class)
public void trackClue(Clue clue) {
    Integer currentUserId = UserHolder.getCurrentUser();  // 直接获取
    // ... 业务逻辑 ...
}
```

> **关键点：** fterCompletion 中必须调用 
emove()，否则 ThreadLocal 会在长生命周期线程池中造成内存泄漏或数据串线。

---

## 十六、Spring 事务管理

### 16.1 问题场景

线索跟进需要同时执行两步操作：更新线索基本信息 + 插入跟进记录。如果第一步成功、第二步失败，会造成数据不一致。

### 16.2 事务概念

事务是一组不可分割的操作集合，要么全部成功，要么全部失败回滚。

### 16.3 手动事务（SQL 层面）

```sql
START TRANSACTION;

UPDATE clue SET subject = 1, level = 1 WHERE id = 8;
INSERT INTO clue_track_record (clue_id, user_id, record, ...) VALUES (8, 1, '...');

COMMIT;   -- 全部成功
ROLLBACK; -- 任何一步失败
```

### 16.4 Spring 声明式事务 — @Transactional

Spring 通过 AOP 代理自动管理事务，只需一个注解：

```java
@Transactional(rollbackFor = Exception.class)
@Override
public void trackClue(Clue clue) {
    // 步骤 1：更新线索
    this.updateById(clue);

    // 步骤 2：插入跟进记录
    clueTrackRecordMapper.insert(trackRecord);
    // 如果此处抛异常，步骤 1 也会回滚
}
```

**工作原理：**

- 方法执行前 → 开启事务
- 方法正常结束 → 提交事务
- 方法抛出异常 → 回滚事务

### 16.5 rollbackFor 配置

默认只对 RuntimeException 和 Error 回滚，checked 异常不会触发回滚。建议始终显式指定：

```java
@Transactional(rollbackFor = Exception.class)  // 所有异常都回滚
```

### 16.6 事务失效的常见场景

| 场景 | 原因 |
|------|------|
| 方法非 public | Spring AOP 只代理 public 方法 |
| 同类内部调用 | this 调用绕过了代理对象 |
| 异常被 catch 吞掉 | 代理感知不到异常，不会回滚 |
| 非 Spring 管理的对象调用 | 没有经过 AOP 代理 |

---

## 十七、MyBatis XML 一对多映射

### 17.1 问题场景

查询线索详情时，一条线索对应多条跟进记录。MyBatis-Plus 的 BaseMapper 无法直接处理这种一对多的嵌套查询，需要手写 XML。

### 17.2 resultMap 手动映射

**什么时候用 resultMap vs resultType：**

- 
resultType：字段名与属性名直接对应，简单查询
- 
resultMap：字段名不对应、或需要嵌套映射复杂结构

**映射规则：**

| 标签 | 用途 | 示例 |
|------|------|------|
| `<id>` | 主键映射 | `<id property="id" column="id"/>` |
| `<result>` | 普通属性映射 | `<result property="phone" column="phone"/>` |
| `<collection>` | 一对多集合映射 | `<collection property="trackRecords" ofType="..."/>` |

### 17.3 完整示例：线索 + 跟进记录

**SQL — 需要加别名避免列名冲突：**

```sql
SELECT
    c.id, c.phone, c.name, c.status,
    tr.id tr_id, tr.clue_id tr_clue_id, tr.record tr_record,
    u.name tr_assign_name
FROM clue c
LEFT JOIN clue_track_record tr ON c.id = tr.clue_id
LEFT JOIN user u ON tr.user_id = u.id
WHERE c.id = #{id}
ORDER BY tr.create_time DESC
```

**XML 映射：**

```xml
<resultMap id="clueRresultMap" type="com.itheima.entity.Clue">
    <!-- 主键 -->
    <id property="id" column="id"/>
    <!-- 线索基本信息 -->
    <result property="phone" column="phone"/>
    <result property="channel" column="channel"/>
    <result property="name" column="name"/>
    <result property="status" column="status"/>
    <!-- ... 其他字段 ... -->

    <!-- 一对多：跟进记录集合 -->
    <collection property="trackRecords" ofType="com.itheima.entity.ClueTrackRecord">
        <id property="id" column="tr_id"/>
        <result property="clueId" column="tr_clue_id"/>
        <result property="userId" column="tr_user_id"/>
        <result property="record" column="tr_record"/>
        <result property="assignName" column="tr_assign_name"/>
        <!-- ... 其他字段 ... -->
    </collection>
</resultMap>

<select id="getClueById" resultMap="clueRresultMap">
    SELECT ... FROM clue c
    LEFT JOIN clue_track_record tr ON c.id = tr.clue_id
    LEFT JOIN user u ON tr.user_id = u.id
    WHERE c.id = #{id}
</select>
```

### 17.4 实体类扩展字段

查询结果中存在数据库表中没有的字段（如归属人姓名），需要用 @TableField(exist = false) 标记：

```java
@Data
public class Clue {
    // ... 数据库字段 ...

    @TableField(exist = false)
    private String assignName;           // 归属人姓名（来自 JOIN）

    @TableField(exist = false)
    private List<ClueTrackRecord> trackRecords;  // 跟进记录列表（一对多）
}
```

### 17.5 dynamic SQL 条件查询

多条件动态查询配合 <where> + <if> 实现：

```xml
<select id="listClues" resultType="com.itheima.entity.Clue">
    SELECT c.*, u.name as assign_name
    FROM clue c LEFT JOIN user u ON c.user_id = u.id
    <where>
        <if test="dto.clueId != null">AND c.id = #{dto.clueId}</if>
        <if test="dto.phone != null and dto.phone != ''">
            AND c.phone LIKE CONCAT('%', #{dto.phone}, '%')
        </if>
        <if test="dto.status != null">AND c.status = #{dto.status}</if>
    </where>
    ORDER BY c.update_time DESC
</select>
```

> <where> 标签会自动去除开头多余的 AND，避免 SQL 语法错误。

---

*最后更新：2026-09-11*

## 相关笔记
- [[Java 项目构建整体模板]] —— 完整项目骨架
- [[Maven-依赖管理与多模块构建]] —— 依赖管理
- [[MyBatisPlus-数据库操作与动态SQL]] —— 数据访问层
- [[业务模块标准写法]] —— Python 三层架构对照
- [[用户认证与鉴权]] —— Python JWT 认证对照
- [[Docker 基础操作]] —— Docker 化部署
- [[SpringBoot-AOP-面向切面编程与操作日志]] —— AOP 与操作日志实战、@Transactional 的底层、ThreadLocal 操作人来源
