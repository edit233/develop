---
title: "SpringBoot 日志框架 - Logback"
tags: ["SpringBoot","Logback","日志","SLF4J"]
created: "2026-09-04"
---

# SpringBoot 日志框架 - Logback

## 一、为什么不用 System.out.println

System.out.println 打日志的缺点：

| 问题 | 说明 |
|------|------|
| 不能开关控制 | 无法通过配置关闭特定级别的日志 |
| 不能持久化 | 输出到控制台后无法保存到文件 |
| 不能分级别 | 所有信息混在一起，无法区分 info/warn/error |
| 阻塞主线程 | 当前线程执行输出，影响业务性能 |

Logback 是目前主流的日志框架，解决以上所有问题，且 SpringBoot 已内置集成。

---

## 二、基本使用

### 2.1 引入方式

SpringBoot 已集成 Logback 依赖，只需在类上添加 @Slf4j 注解即可获取日志对象。

`java
import lombok.extern.slf4j.Slf4j;

@Slf4j                    // Lombok 注解，自动生成 private static final Logger log = LoggerFactory.getLogger(...)
public class DeptController {

    // 调用 log.info() 输出参数信息，{} 为占位符，性能优于字符串拼接
    public Result addDept(@RequestBody Dept dept) {
        log.info("新增部门,参数:{}", dept);
        deptService.addDept(dept);
        return Result.success();
    }
}
`

### 2.2 日志级别

Logback 提供四个核心级别，从低到高：

| 级别 | 方法 | 用途 |
|------|------|------|
| TRACE | log.trace() | 追踪信息，最细粒度 |
| DEBUG | log.debug() | 调试信息 |
| INFO | log.info() | 普通运行信息 |
| WARN | log.warn() | 警告信息 |
| ERROR | log.error() | 错误信息 |

> 配置的日志级别会过滤低于该级别的输出。例如设置为 INFO，则 TRACE 和 DEBUG 不会输出。

### 2.3 Controller 完整示例

`java
@Slf4j
@RestController
public class DeptController {

    @Autowired
    private DeptService deptService;

    @PostMapping("/depts")
    public Result addDept(@RequestBody Dept dept) {
        log.info("新增部门,参数:{}", dept);
        deptService.addDept(dept);
        return Result.success();
    }

    @GetMapping("/depts")
    public Result listDepts(String name, Integer status,
                            @RequestParam(defaultValue = "1") Integer page,
                            @RequestParam(defaultValue = "10") Integer pageSize) {
        log.info("分页查询部门, 参数: name={}, status={}, page={}, pageSize={}", name, status, page, pageSize);
        PageResult<Dept> pageResult = deptService.findDeptsByPage(name, status, page, pageSize);
        return Result.success(pageResult);
    }

    @GetMapping("/depts/{id}")
    public Result findById(@PathVariable Integer id) {
        log.info("查询部门ID为{}的部门信息", id);
        Dept dept = deptService.findById(id);
        return Result.success(dept);
    }

    @PutMapping("/depts")
    public Result updateDept(@RequestBody Dept dept) {
        log.info("修改部门信息：{}", dept);
        deptService.updateById(dept);
        return Result.success();
    }

    @DeleteMapping("/depts/{id}")
    public Result deleteDept(@PathVariable("id") Integer id) {
        log.info("删除部门：{}", id);
        deptService.deleteById(id);
        return Result.success();
    }
}
`

---

## 三、配置文件

Logback 的配置文件为 logback.xml，放在 src/main/resources 目录下，SpringBoot 启动时自动读取。

### 3.1 核心配置结构

`xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <!-- 输出格式：时间 级别 线程名 日志内容 -->
    <property name="pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n"/>

    <!-- 控制台输出：target="System.out" -->
    <appender name="CONSOLE" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
            <pattern></pattern>
        </encoder>
    </appender>

    <!-- 文件输出：滚动记录，按天切割，单文件最大 100MB，保留 30 天 -->
    <appender name="FILE" class="ch.qos.logback.core.rolling.RollingFileAppender">
        <file>D:/logs/app.log</file>                          <!-- 日志文件路径 -->
        <rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
            <fileNamePattern>D:/logs/app.%d{yyyy-MM-dd}.%i.log</fileNamePattern>  <!-- 按天+序号切割 -->
            <maxFileSize>100MB</maxFileSize>                  <!-- 单文件最大大小 -->
            <maxHistory>30</maxHistory>                       <!-- 保留天数 -->
            <totalSizeCap>1GB</totalSizeCap>                 <!-- 总大小上限 -->
        </rollingPolicy>
        <encoder>
            <pattern></pattern>
        </encoder>
    </appender>

    <!-- root Logger：最低级别为 INFO，绑定控制台和文件输出 -->
    <root level="INFO">
        <appender-ref ref="CONSOLE"/>
        <appender-ref ref="FILE"/>
    </root>
</configuration>
`

### 3.2 配置要点

| 配置项 | 作用 |
|--------|------|
| <property> | 定义可复用变量，如日志输出格式 |
| <appender> | 日志输出目的地，ConsoleAppender 输出到控制台，RollingFileAppender 输出到文件 |
| <rollingPolicy> | 控制日志文件的滚动策略（按时间、大小切割） |
| <root level="INFO"> | 全局日志级别，低于 INFO 的日志不输出 |
| <appender-ref> | 将 appender 绑定到 root logger |

### 3.3 通过配置文件控制日志级别

可以在 pplication.yml 中直接配置日志级别，无需修改 logback.xml：

`yaml
logging:
  level:
    root: INFO                           # 全局级别
    com.itheima: DEBUG                   # 指定包的日志级别
`

---

## 四、最佳实践

- 日志输出使用 {} 占位符，避免字符串拼接，减少性能开销
- 在方法入口用 log.info() 记录关键参数，便于排查问题
- 异常处理中用 log.error("描述", e) 记录完整堆栈
- 生产环境日志级别设为 INFO，开发调试时临时切换为 DEBUG
- 日志文件配置滚动策略和大小限制，避免磁盘撑爆
