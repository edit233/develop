---
title: SpringBoot AOP —— 面向切面编程与操作日志
tags: [SpringBoot, AOP, 面向切面, 切面, 通知, 切点表达式, 操作日志, AspectJ]
created: 2026-09-11
category: Java
---

# SpringBoot AOP —— 面向切面编程与操作日志

## 概述

AOP（Aspect Oriented Programming，面向切面编程）：**在不改变原有方法代码的基础上，动态为它们添加指定功能**——减少重复代码、方便维护、代码无侵入。本文覆盖 AOP 概念、五种通知类型、切点表达式两种写法、连接点信息获取，以及完整实战案例：**用 AOP + 自定义注解把增删改操作日志落库**（源自轻客管家项目第 13 章）。

典型应用场景：
- **记录系统操作日志**（本文实战案例）
- **权限控制**
- **事务管理** —— `@Transactional` 底层就是 AOP 实现的：方法运行前自动开启事务，运行完毕后自动提交/回滚（见 [[SpringBoot-全栈开发笔记]] 事务管理章节）

## 一、快速入门：统计方法执行耗时

以"统计部门管理各业务层方法执行耗时"为例。原始方式要在每个 Controller 方法里都写开始/结束时间——冗余繁琐；AOP 只需一个切面类。

**① 导入依赖**

```xml
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-aop</artifactId>
</dependency>
```

**② 编写切面类**

```java
@Component      // 交给 IOC 容器管理
@Aspect         // 当前类为切面类
@Slf4j
public class RecordTimeAspect {

    // 指定为 com.itheima.controller 包下所有类中的所有方法添加逻辑
    // *  表示匹配一个单词（包下的一层 / 任意方法名 / 任意返回值）
    // .. 表示匹配任意多个单词（任意层级包 / 任意参数列表）
    @Around("execution(* com.itheima.controller.*.*(..))")
    public Object recordTime(ProceedingJoinPoint pjp) throws Throwable {
        long begin = System.currentTimeMillis();   // 记录开始时间
        Object result = pjp.proceed();               // 执行原始方法
        long end = System.currentTimeMillis();     // 记录结束时间
        log.info("方法执行耗时: {}毫秒", end - begin);
        return result;                               // 返回原始方法的返回值
    }
}
```

启动服务访问任意接口，控制台即输出耗时——原有业务代码零改动。

## 二、核心概念

| 概念 | 说明 | 案例对应 |
|------|------|----------|
| **切入点（PointCut）** | 要进行功能增强的方法；用切点表达式或自定义注解挑选 | controller 包下所有方法 |
| **通知（Advice）** | 重复的共性逻辑，最终体现为一个方法 | 计算耗时的代码 |
| **切面（Aspect）** | 通知与切入点的对应关系，描述通知在切入点的什么位置执行 | `@Aspect` 标注的类 |

## 三、五种通知类型

| 注解 | 类型 | 执行时机 |
|------|------|----------|
| `@Around` | 环绕通知（功能最强大） | 目标方法**前、后**都被执行，可编程控制 |
| `@Before` | 前置通知 | 目标方法**前**执行 |
| `@After` | 后置通知 | 目标方法**后**执行，**无论是否有异常**都执行 |
| `@AfterReturning` | 返回后通知 | 目标方法**正常返回后**执行，有异常不执行 |
| `@AfterThrowing` | 异常后通知 | 目标方法**发生异常时**执行 |

```java
@Slf4j
@Component
@Aspect
public class MyAspect1 {

    // 前置通知
    @Before("execution(* com.itheima.controller.*.*(..))")
    public void before(JoinPoint joinPoint) { log.info("before ..."); }

    // 后置通知（无论是否异常都执行）
    @After("execution(* com.itheima.controller.*.*(..))")
    public void after(JoinPoint joinPoint) { log.info("after ..."); }

    // 返回后通知（正常返回才执行）
    @AfterReturning("execution(* com.itheima.controller.*.*(..))")
    public void afterReturning(JoinPoint joinPoint) { log.info("afterReturning ..."); }

    // 异常通知
    @AfterThrowing("execution(* com.itheima.controller.*.*(..))")
    public void afterThrowing(JoinPoint joinPoint) { log.info("afterThrowing ..."); }
}
```

**注意事项**：
- `@Around` 环绕通知必须自己调用 `ProceedingJoinPoint.proceed()` 让原始方法执行，其他四种通知不需要
- `@Around` 方法的返回值**必须声明为 `Object`** 并返回原始方法的返回值，否则调用方拿不到返回结果

**用 @Pointcut 抽取公共切点表达式**（避免每个通知注解重复写表达式，改一处即可）：

```java
@Slf4j
@Component
@Aspect
public class MyAspect1 {

    // 切入点方法：公共的切入点表达式
    @Pointcut("execution(* com.itheima.controller.*.*(..))")
    private void pt() {}

    @Before("pt()")           // 引用公共表达式
    public void before(JoinPoint joinPoint) { log.info("before ..."); }

    @After("pt()")
    public void after(JoinPoint joinPoint) { log.info("after ..."); }

    @AfterReturning("pt()")
    public void afterReturning(JoinPoint joinPoint) { log.info("afterReturning ..."); }

    @AfterThrowing("pt()")
    public void afterThrowing(JoinPoint joinPoint) { log.info("afterThrowing ..."); }
}
```

## 四、切点表达式：两种写法

### 1）execution —— 按方法签名匹配

```
execution(访问修饰符?  返回值  包名.类名.方法名(方法参数) throws 异常?)
```

带 `?` 的部分可省略。示例：`execution(* com.itheima.controller.*.*(..))`。

### 2）@annotation —— 按自定义注解匹配（更精准）

实现步骤：**① 编写自定义注解类 → ② 在需要增强的方法上标注注解 → ③ 切面类用 `@annotation` 声明切点**。

```java
// ① 自定义注解
@Target(ElementType.METHOD)          // 可标注的位置：方法上
@Retention(RetentionPolicy.RUNTIME)  // 生效阶段：运行时仍保留
public @interface LogOperation {
}
```

```java
// ② 在需要记录日志的方法上标注
@LogOperation
@PostMapping("/depts")
public Result addDept(@RequestBody Dept dept) { ... }
```

```java
// ③ 切面类中用注解方式声明切点
@Around("@annotation(com.itheima.aspect.anno.LogOperation)")
public Object aroundAdvice(ProceedingJoinPoint joinPoint) throws Throwable { ... }
```

## 五、连接点信息（JoinPoint）

Spring 用 `JoinPoint` 抽象了切入点，可获得目标类名、方法名、方法参数等信息：

- `@Around` 通知 → 只能用 **`ProceedingJoinPoint`**（其子接口，多了 `proceed()`）
- 其他四种通知 → 只能用 **`JoinPoint`**

## 六、实战案例：操作日志落库

**需求**：增、删、改相关接口被调用时，把操作日志（操作人、操作类、方法、请求参数、返回值、耗时）记录到数据库表，便于数据追踪。

### 1）建表

```sql
use qk;
-- 操作日志表
create table operate_log(
    id              int unsigned auto_increment comment 'ID' primary key,
    operate_user_id int unsigned comment '操作用户ID',
    operate_time    datetime comment '操作时间',
    class_name      varchar(100) comment '操作的类名',
    method_name     varchar(100) comment '操作的方法名',
    method_params   varchar(1000) comment '方法参数',
    return_value    varchar(2000) comment '返回值',
    cost_time       bigint comment '方法执行耗时, 单位:ms'
) comment '操作日志表';
```

### 2）实体类

```java
@Data
@TableName("operate_log")
public class OperateLog {
    @TableId
    private Integer id;             // ID
    private Integer operateUserId;  // 操作用户ID
    private LocalDateTime operateTime; // 操作时间
    private String className;       // 类名称
    private String methodName;      // 方法名称
    private String methodParams;    // 方法参数
    private String returnValue;     // 返回值
    private Long costTime;          // 耗时
}
```

### 3）Mapper 接口

```java
@Mapper
public interface OperateLogMapper extends BaseMapper<OperateLog> {
}
```

### 4）记录日志的切面类

```java
@Aspect
@Component
public class LogAspect {

    @Autowired
    private OperateLogMapper operateLogMapper;

    @Around("@annotation(com.itheima.aspect.anno.LogOperation)")
    public Object aroundAdvice(ProceedingJoinPoint joinPoint) throws Throwable {
        long startTime = System.currentTimeMillis();

        // 记录请求参数
        Object[] args = joinPoint.getArgs();
        String methodParams = Arrays.toString(args);

        // 执行目标方法
        Object result = joinPoint.proceed();

        // 计算耗时
        long costTime = System.currentTimeMillis() - startTime;

        // 保存日志
        OperateLog log = new OperateLog();
        log.setOperateUserId(UserHolder.getCurrentUser());                    // 操作用户（来自 ThreadLocal）
        log.setOperateTime(LocalDateTime.now());                             // 操作时间
        log.setClassName(joinPoint.getTarget().getClass().getName());        // 类名
        log.setMethodName(joinPoint.getSignature().getName());               // 方法名
        log.setMethodParams(methodParams);                                    // 参数
        log.setReturnValue(result.toString());                                // 返回值
        log.setCostTime(costTime);                                            // 耗时
        operateLogMapper.insert(log);
        return result;
    }
}
```

> 操作人 `UserHolder.getCurrentUser()` 来自 **ThreadLocal 跨层数据共享**（登录拦截器解析 token 后存入当前线程，Service/切面直接取）——完整模式见 [[SpringBoot-全栈开发笔记]] ThreadLocal 章节。

### 5）在切点上添加注解

在 Controller 层需要记录日志的**增、删、改**方法上加 `@LogOperation`（查询方法通常不记录）：

```java
@LogOperation
@PostMapping("/depts")
public Result addDept(@RequestBody Dept dept) { ... }

@LogOperation
@PutMapping("/depts")
public Result updateDept(@RequestBody Dept dept) { ... }

@LogOperation
@DeleteMapping("/depts/{id}")
public Result deleteDept(@PathVariable("id") Integer id) { ... }
```

测试增删改后，数据库表中即记录了：谁、什么时间、调用了哪个类的哪个方法、传了什么参数、返回了什么、耗时多少。

## 相关笔记

- [[SpringBoot-全栈开发笔记]] —— 三层架构、ThreadLocal（操作人来源）、事务管理（@Transactional 的 AOP 底层）、Logback 日志
- [[MyBatisPlus-数据库操作与动态SQL]] —— 日志落库所用 BaseMapper、实体注解
- [[SQL 常用函数与统计技巧]] —— 同章的 SQL 函数与首页概览统计实战
- [[日志与异常处理]] —— Python 侧日志体系对照（structlog + 业务异常）
- [[Java 项目构建整体模板]] —— 完整项目骨架（操作日志是常见的横切增强）
- [[Maven-依赖管理与多模块构建]] —— spring-boot-starter-aop 起步依赖

## 来源

- 轻客管家项目课程 第 13 章（日志管理、统计相关 SQL 函数、首页概览）
