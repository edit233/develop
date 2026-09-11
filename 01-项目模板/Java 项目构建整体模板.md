---
title: Java 项目构建整体模板
tags: [项目模板, Java, SpringBoot, Maven, MyBatisPlus, 后端, MOC]
created: 2026-09-11
category: 项目模板
---

# Java 项目构建整体模板

> 从零搭建一个 **SpringBoot + Maven + MyBatis-Plus 后端项目** 的完整模板。涵盖：环境准备 → 项目创建 → 目录结构 → 核心骨架 → 三层架构 → 多模块 → 部署。每个环节的详细写法见对应知识笔记，本文只保留**最小可用的骨架**。

## 一、技术选型总览

| 领域 | 选型 | 说明 |
|------|------|------|
| 构建 | **Maven** | 依赖管理 + 一键构建 + 统一目录结构 |
| 框架 | **SpringBoot 3.x**（起步依赖） | 内嵌 Tomcat，开箱即用 |
| ORM | **MyBatis-Plus** | BaseMapper / IService 业务层增强 |
| 数据库 | MySQL | 驱动 `com.mysql.cj.jdbc.Driver` |
| 简化 | **Lombok** | @Data / @NoArgsConstructor 省去样板代码 |
| 工具 | Hutool（可选） | 文件、日期等常用工具集 |
| 日志 | **Logback**（SpringBoot 自带） | logback.xml 配置 |
| JDK | 21（按需 17+） | settings.xml 中配置 JDK 版本 |

## 二、环境准备（一次配好，全局生效）

1. **安装 Maven**：解压路径不能有中文和空格 → https://maven.apache.org/download.cgi
2. **配置本地仓库**：`conf/settings.xml` 中指定本地仓库路径
3. **配置阿里云私服**（加速依赖下载）：

```xml
<mirror>
    <id>alimaven</id>
    <name>aliyun maven</name>
    <url>https://maven.aliyun.com/repository/public</url>
    <mirrorOf>central</mirrorOf>
</mirror>
```

4. **IDEA 配置**：`File → Settings → Build Tools → Maven`，配完当前工程后**关闭工程再配全局**，保证新项目都生效（多 JDK 时额外注意 JDK 版本配置）。

详见 → [[Maven-依赖管理与多模块构建]]

## 三、项目创建

**方式一：IDEA + Maven 模板**（普通 Java 工程）

- GroupId（组织名，公司域名倒写）/ ArtifactId（项目名）/ Version
- 结构：`src/main/java`（包和类）+ `src/main/resources`（配置文件）+ `src/test` + `pom.xml`

**方式二：Spring Initializr**（SpringBoot 工程，推荐）

选择 SpringBoot 版本 + 勾选起步依赖（Web、MyBatis、MySQL Driver、Lombok），自动生成骨架。

## 四、标准目录结构（三层架构）

```
项目根目录/
├── pom.xml                              # Maven 依赖配置
└── src/main/
    ├── java/com/公司/项目名/
    │   ├── 项目名Application.java       # 启动类（@SpringBootApplication）
    │   ├── controller/                   # 控制层：接收请求、返回响应
    │   ├── service/                     # 业务层：接口 + 实现类（impl/）
    │   ├── mapper/                      # 数据访问层：MyBatis-Plus Mapper 接口
    │   ├── pojo/                        # 数据模型
    │   │   ├── entity/                  # 实体类（对应表结构，MyBatisPlus-数据库操作）
    │   │   ├── dto/                     # 封装请求参数
    │   │   └── vo/                      # 封装响应数据
    │   ├── config/                      # 配置类（MyBatis-Plus 拦截器等）
    │   ├── exception/                  # 自定义异常 + 全局异常处理器
    │   └── utils/                      # 工具类
    └── resources/
        ├── application.yaml             # 核心配置（数据源、MyBatis-Plus）
        ├── mapper/                      # MyBatis XML（动态 SQL、多表映射）
        └── logback.xml                  # 日志配置
```

**调用流程**：`Controller（接收请求）→ Service（业务逻辑/事务）→ Mapper（SQL）→ 数据库`，与 Python 侧的 Router → Service → Repository 完全同构，见 [[业务模块标准写法]] 的跨语言对照。

## 五、核心骨架代码

### pom.xml（起步依赖）

```xml
<parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.4.3</version>
</parent>

<dependencies>
    <!-- Web：内嵌 Tomcat + SpringMVC -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-web</artifactId>
    </dependency>
    <!-- MyBatis-Plus -->
    <dependency>
        <groupId>com.baomidou</groupId>
        <artifactId>mybatis-plus-spring-boot3-starter</artifactId>
        <version>最新版</version>
    </dependency>
    <!-- MySQL 驱动 -->
    <dependency>
        <groupId>com.mysql</groupId>
        <artifactId>mysql-connector-j</artifactId>
        <scope>runtime</scope>
    </dependency>
    <!-- Lombok：@Data 省样板代码 -->
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <optional>true</optional>
    </dependency>
    <!-- 测试 -->
    <dependency>
        <groupId>org.springframework.boot</groupId>
        <artifactId>spring-boot-starter-test</artifactId>
        <scope>test</scope>
    </dependency>
</dependencies>
```

> 坐标（groupId / artifactId / version）到 https://mvnrepository.com/ 搜索；依赖传递、冲突规则（直接依赖优先、层级浅优先）、scope 生效范围详见 [[Maven-依赖管理与多模块构建]]。

### application.yaml

```yaml
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/数据库名?useSSL=false&serverTimezone=Asia/Shanghai
    username: 用户名
    password: 密码
    driver-class-name: com.mysql.cj.jdbc.Driver

mybatis-plus:
  configuration:
    log-impl: org.apache.ibatis.logging.stdout.StdOutImpl   # 控制台打印 SQL（开发期）
    map-underscore-to-camel-case: true                     # 下划线转驼峰
  global-config:
    db-config:
      id-type: assign_id          # 主键策略：雪花算法

logging:
  level:
    com.公司.项目名: info
```

### 启动类

```java
@SpringBootApplication
@MapperScan("com.公司.项目名.mapper")   // 扫描 Mapper 接口
public class 项目名Application {
    public static void main(String[] args) {
        SpringApplication.run(项目名Application.class, args);
    }
}
```

### 实体类（Lombok + MyBatis-Plus 注解）

```java
@Data                                      // getter/setter/toString/equals/hashCode
@NoArgsConstructor                          // 无参构造
@AllArgsConstructor                         // 全参构造
@TableName("表名")                          // 对应数据库表
public class 实体名 {
    @TableId(type = IdType.ASSIGN_ID)      // 主键：雪花算法
    private Long id;
    private String name;                    // 驼峰自动映射下划线列
    @TableField(fill = FieldFill.INSERT)    // 自动填充（如创建时间）
    private LocalDateTime createTime;
}
```

### Mapper 接口

```java
public interface 实体名Mapper extends BaseMapper<实体名> {
    // 继承即拥有 insert/selectById/selectList/updateById/deleteById...
    // 复杂 SQL 写 XML：resources/mapper/实体名Mapper.xml（动态 SQL 见对应笔记）
}
```

### 三层调用示例（Controller → Service → Mapper）

```java
// Controller
@RestController
@RequestMapping("/api/资源名")
public class 实体名Controller {
    @Autowired
    private 实体名Service service;

    @GetMapping("/{id}")
    public Result<实体名> getById(@PathVariable Long id) {   // 路径参数
        return Result.success(service.getById(id));
    }

    @PostMapping
    public Result<Void> add(@RequestBody 创建DTO dto) {       // JSON 请求体
        service.add(dto);
        return Result.success();
    }
}
```

统一响应格式 `Result`（code/message/data）、请求参数三种注解（@RequestBody / @RequestParam / @PathVariable）、VO/DTO 数据模型、@DateTimeFormat / @JsonFormat 日期格式化 → 全部详见 [[SpringBoot-全栈开发笔记]]。

### 全局异常处理

```java
@RestControllerAdvice
public class GlobalExceptionHandler {
    @ExceptionHandler(Exception.class)          // 兜底
    public Result handleException(Exception e) {
        e.printStackTrace();
        return Result.error("操作失败");
    }
}
```

精确异常处理、匹配优先级 → [[SpringBoot-全栈开发笔记]]（与 Python 侧 [[日志与异常处理]] 的 ApplicationError 体系对照）。

## 六、MyBatis-Plus 数据访问

| 能力 | 用法 | 详见 |
|------|------|------|
| 基本 CRUD | Mapper 继承 `BaseMapper<T>`，直接 `selectList(null)` | [[MyBatisPlus-数据库操作与动态SQL]] |
| 条件查询 | `LambdaQueryWrapper`（编译期字段安全） | 同上 |
| 分页 | 配置 `MybatisPlusInterceptor` + `Page<T>` | 同上 |
| 动态 SQL | XML 中 `<where>` + `<if>`、`<foreach>` 批量 | 同上 |
| 业务层增强 | `ServiceImpl implements IService` | 同上 |
| 自动填充 | `MetaObjectHandler` 填充创建/更新时间 | 同上 |

SQL 本身（DDL/DML/DQL/连接查询）→ [[SQL 语言全解]]

## 七、多模块构建（项目变大时）

```
父工程（packaging=pom）
├── common/        # 公共依赖、工具类
├── 项目名-dao/    # 数据访问
├── 项目名-service/
└── 项目名-web/    # 启动模块
```

- **聚合**：父 pom 用 `<modules>` 一键构建所有子模块
- **继承·家产**：父 `<dependencies>` 中的依赖，子模块直接继承（只放全员必需的）
- **继承·家规**：父 `<dependencyManagement>` 管版本，子模块引用时省略 version
- 常用命令：`mvn clean` / `compile` / `package` / `install`

详见 → [[Maven-依赖管理与多模块构建]]

## 八、部署

### Docker 化（多阶段构建 + 环境变量覆盖配置）

```dockerfile
# ---- 构建阶段 ----
FROM maven:3.9-eclipse-temurin-21 AS builder
WORKDIR /build
COPY pom.xml .
COPY src ./src
RUN mvn package -DskipTests

# ---- 运行阶段 ----
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /build/target/*.jar app.jar
ENTRYPOINT ["java", "-jar", "app.jar"]
```

`application.yaml` 保留开发默认值，生产用环境变量覆盖：`SPRING_DATASOURCE_URL`、`SPRING_DATASOURCE_PASSWORD` 等。详见 [[SpringBoot-全栈开发笔记]]（Docker 化部署章节）、[[Docker 基础操作]]。

### Nginx 反向代理

前后端分离：Nginx 托管前端静态资源 + `/api` 转发到 SpringBoot → [[Nginx 部署实战]]

## 九、构建检查清单

- [ ] Maven 全局环境已配（本地仓库 + 阿里云私服 + IDEA 全局配置）
- [ ] `pom.xml` 依赖坐标正确，刷新后成功下载
- [ ] 三层分包清晰：controller / service（+impl）/ mapper / pojo（entity/dto/vo）
- [ ] 启动类加了 `@MapperScan`，Mapper 接口被扫描
- [ ] `application.yaml` 数据源、MyBatis-Plus 配置齐全
- [ ] 统一响应 `Result` + 全局异常处理器已就位
- [ ] 实体类用 Lombok + MyBatis-Plus 注解，驼峰映射开启
- [ ] 分页插件（MybatisPlusInterceptor）已配置
- [ ] 日志用 Logback（logback.xml），不用 System.out.println
- [ ] 密码用 BCrypt 哈希存储（不存明文、不用 MD5，见 [[SpringBoot-全栈开发笔记]] 密码安全章节）
- [ ] 事务方法加 `@Transactional(rollbackFor = Exception.class)`
- [ ] 生产部署用环境变量覆盖敏感配置

## 相关笔记

**模板组成**：
- [[Maven-依赖管理与多模块构建]] —— 依赖坐标、传递与冲突、聚合/继承、常用命令
- [[SpringBoot-全栈开发笔记]] —— 三层架构、IOC/DI、参数接收、Result、VO/DTO、Logback、全局异常、文件上传、事务
- [[MyBatisPlus-数据库操作与动态SQL]] —— CRUD、Wrapper、分页、动态 SQL、IService、自动填充
- [[SpringBoot-AOP-面向切面编程与操作日志]] —— 操作日志、耗时统计等横切增强
- [[SQL 语言全解]] —— 数据库层 SQL

**语言基础**：
- [[Java基础 - 基础语法、流程控制与方法]] / [[Java面向对象全解 - 从基础到接口]] / [[JavaSE-容器与常用集合整理]] / [[JavaSE-匿名内部类-Lambda-Stream-异常整理]]

**配套**：
- [[Python 项目构建整体模板]] —— Python 侧对照模板（同构的三层架构）
- [[SQLAlchemy 异步操作]] / [[业务模块标准写法]] —— Python 侧 ORM 与分层对照
- [[用户认证与鉴权]] —— Python 侧 Argon2 密码哈希 / JWT 认证对照
- [[Docker 基础操作]] / [[Nginx 部署实战]] / [[Linux 运维操作]] —— 部署链路
