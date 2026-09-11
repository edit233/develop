---
title: SQL 常用函数与统计技巧
tags: [SQL, MySQL, 函数, 统计, count, if, case when, 首页概览, MyBatis]
created: 2026-09-11
category: 数据库
---

# SQL 常用函数与统计技巧

## 概述

开发中最常用的一批 MySQL 小函数：字符串拼接/截取、日期提取/间隔、空值与条件判断，以及**单行多状态计数**统计技巧（一条 SQL 同时统计总数 + 各状态数），最后给出完整实战：首页数据概览接口的三层实现（源自轻客管家项目第 13 章）。

## 一、字符串函数

### concat —— 拼接

```sql
-- 例：查询包含"开"字的部门
select *
from dept
where name like concat('%', '开', '%');
```

### substr —— 截取

```sql
-- 格式：substr(字符串列, 开始索引[, 长度])
-- 注意：索引从 1 开始
-- 例：查询线索名字去掉姓（从第 2 个字符开始取）
select substr(name, 2) from clue;
```

## 二、日期函数

### 取时间的某一部分：date / year / month / day

```sql
-- 例：按年分组求每年用户数
select year(create_time), count(*)
from user
group by year(create_time);
```

### datediff —— 两段时间的间隔天数

```sql
-- 格式：datediff(大时间, 小时间)
-- 例：求用户入职天数
select
    user.name,
    user.create_time,
    datediff(now(), create_time)
from user;
```

## 三、条件判断函数

### ifnull —— 空值替换默认值

效果：列值为 `null` 时用默认值替换。常配合聚合函数使用（**聚合函数对 null 无效**）。

```sql
-- 例：user_id 大量为 null，先替换再计数
select count(ifnull(clue.user_id, 0))
from clue;
```

### if —— 双条件（类似 Java 三元运算符）

格式：`if(条件, 值1, 值2)`。适合**只有两种情况**的场景。

```sql
-- 例：性别 1 显示"男"，0 显示"女"
select if(gender = 1, '男', '女')
from user;
```

### case when —— 多条件

适合**多种情况**的场景：

```sql
-- 例：查询线索并显示状态的中文
select clue.name,
       clue.status,
       (case
            when status = 1 then '待分配'
            when status = 2 then '待跟进'
            when status = 3 then '跟进中'
            when status = 4 then '伪线索'
            when status = 5 then '转商机'
            else '未知'
       end)
from clue
```

## 四、统计技巧：单行多状态计数

首页概览类需求（一次返回总数 + 各状态数）的标准写法：**`count(if(条件, 1, null))`**。

```sql
-- 统计线索：总数 + 各状态数，一条 SQL 搞定
select
    count(1)                                    as clue_total,
    count(if(status = 1, 1, null))              as clue_wait_allot,
    count(if(status = 2, 1, null))              as clue_wait_follow,
    count(if(status = 3, 1, null))              as clue_following,
    count(if(status = 4, 1, null))              as clue_false,
    count(if(status = 5, 1, null))              as clue_convert_business
from clue;
```

**原理**：`count` 忽略 `null`——条件成立计 1，不成立计 null（不被统计）。

> **等价写法**：`sum(status = 1)`（条件为真返回 1，否则 0）或 `count(*) where ...` 分组后转行列，效果相同，`count(if())` 在固定少量状态时最直观。

## 五、综合实战：首页数据概览

需求：登录后首页展示**线索概览**（总数/待分配/待跟进/跟进中/伪线索/转商机）与**商机概览**（总数/待分配/待跟进/跟进中/回收/转客户）。这是三层架构 + MyBatis XML 自定义查询的典型应用（见 [[MyBatisPlus-数据库操作与动态SQL]]）。

### 1）封装 VO（响应结构）

```java
// com.qk.vo.OverviewVO —— 线索和商机统计信息实体类
@Data
public class OverviewVO {
    private Integer clueTotal;             // 总线索数
    private Integer clueWaitAllot;         // 待分配线索数量
    private Integer clueWaitFollow;        // 待跟进线索数量
    private Integer clueFollowing;         // 跟进中线索数量
    private Integer clueFalse;             // 伪线索数量
    private Integer clueConvertBusiness;  // 转商机线索数量

    private Integer businessTotal;             // 总商机数
    private Integer businessWaitAllot;        // 待分配商机数量
    private Integer businessWaitFollow;       // 待跟进商机数量
    private Integer businessFollowing;       // 跟进中商机数量
    private Integer businessFalse;            // 回收商机数量
    private Integer businessConvertCustomer; // 转客户商机数量
}
```

### 2）Controller

```java
@Slf4j
@RestController
@RequestMapping("/report")
public class ReportController {

    @Autowired
    private ReportService reportService;

    // 获取首页概览数据 - /report/overview
    @GetMapping("/overview")
    public Result getOverview() {
        log.info("获取首页概览数据");
        OverviewVO overview = reportService.getOverview();
        return Result.success(overview);
    }
}
```

### 3）Service

```java
@Service
public class ReportServiceImpl implements ReportService {

    @Autowired
    private ClueMapper clueMapper;
    @Autowired
    private BusinessMapper businessMapper;

    @Override
    public OverviewVO getOverview() {
        // 1. 获取线索概览数据
        OverviewVO clueOverviewVO = clueMapper.getClueOverviewData();
        // 2. 获取商机概览数据
        OverviewVO businessOverviewVO = businessMapper.getBusinessOverviewData();
        // 3. 合并数据返回（把商机数据拷入线索 VO，忽略线索字段）
        BeanUtils.copyProperties(businessOverviewVO, clueOverviewVO,
                "clueTotal", "clueWaitAllot", "clueWaitFollow",
                "clueFollowing", "clueFalse", "clueConvertBusiness");
        return clueOverviewVO;
    }
}
```

### 4）Mapper + XML

```java
// ClueMapper 接口
OverviewVO getClueOverviewData();
// BusinessMapper 接口
OverviewVO getBusinessOverviewData();
```

```xml
<!-- ClueMapper.xml：统计列别名（下划线）自动映射 VO 驼峰属性 -->
<select id="getClueOverviewData" resultType="com.qk.vo.OverviewVO">
    select
        count(1)                        as clue_total,
        count(if(status = 1, 1, null))  as clue_wait_allot,
        count(if(status = 2, 1, null))  as clue_wait_follow,
        count(if(status = 3, 1, null))  as clue_following,
        count(if(status = 4, 1, null))  as clue_false,
        count(if(status = 5, 1, null))  as clue_convert_business
    from clue;
</select>
```

```xml
<!-- BusinessMapper.xml（不存在则新建） -->
<?xml version="1.0" encoding="UTF-8" ?>
<!DOCTYPE mapper PUBLIC "-//mybatis.org//DTD Mapper 3.0//EN" "http://mybatis.org/dtd/mybatis-3-mapper.dtd">
<mapper namespace="com.qk.mapper.BusinessMapper">
    <select id="getBusinessOverviewData" resultType="com.qk.vo.OverviewVO">
        select
            count(1)                        as business_total,
            count(if(status = 1, 1, null))  as business_wait_allot,
            count(if(status = 2, 1, null))  as business_wait_follow,
            count(if(status = 3, 1, null))  as business_following,
            count(if(status = 4, 1, null))  as business_false,
            count(if(status = 5, 1, null))  as business_convert_customer
        from business;
    </select>
</mapper>
```

**要点**：
- `resultType` 直接映射 VO，列别名下划线 → 属性驼峰（`map-underscore-to-camel-case`）
- 两条单表统计 SQL 各查一半字段，Service 层用 `BeanUtils.copyProperties(源, 目标, 忽略属性...)` 合并，避免写一条大关联 SQL

## 相关笔记

- [[SQL 语言全解]] —— DDL/DML/DQL 基础（本文函数的前置知识）
- [[MyBatisPlus-数据库操作与动态SQL]] —— XML 自定义查询、resultType 映射
- [[SpringBoot-全栈开发笔记]] —— 三层架构与统一响应 Result
- [[SpringBoot-AOP-面向切面编程与操作日志]] —— 同章的 AOP 操作日志实战
- [[SQLAlchemy 异步操作]] —— Python 侧 ORM 分组统计对照

## 来源

- 轻客管家项目课程 第 13 章（日志管理、统计相关 SQL 函数、首页概览）
