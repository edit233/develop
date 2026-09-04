---
title: "SpringBoot - 统一响应格式与数据模型"
tags: ["SpringBoot", "Result", "VO", "DTO", "POJO", "日期格式化"]
created: "2026-09-04"
---

# SpringBoot 统一响应格式与数据模型

## 一、统一响应格式 Result

前后端分离项目中，所有接口返回统一的 JSON 结构，前端根据统一格式解析数据。

### 1.1 Result 类定义

```java
package com.example.result;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data                     // 自动生成 getter/setter/toString
@NoArgsConstructor         // 无参构造
@AllArgsConstructor        // 全参构造
public class Result {
    private Integer code;   // 响应码：1 成功，0 失败
    private String msg;     // 提示信息
    private Object data;    // 返回数据（泛型按需改为 T）

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

### 1.2 使用方式

```java
// Controller 中直接使用静态方法返回
@GetMapping("/depts")
public Result list() {
    List<Dept> list = deptService.findAll();
    return Result.success(list);        // 成功 + 数据
}

@PostMapping("/depts")
public Result add(@RequestBody Dept dept) {
    deptService.add(dept);
    return Result.success();            // 成功，无数据
}

// 失败场景
return Result.error("部门不存在");
```

### 1.3 响应 JSON 示例

```json
{
    "code": 1,
    "msg": "success",
    "data": [
        {"id": 1, "name": "研发部"},
        {"id": 2, "name": "市场部"}
    ]
}
```

---

## 二、POJO / VO / DTO 的区别与使用

### 2.1 三者定义

| 名称 | 全称 | 用途 | 存放位置 | 命名规范 |
|------|------|------|----------|----------|
| **POJO / Entity** | Plain Old Java Object | 与数据库表一一对应的实体类 | `pojo/` 或 `entity/` | 表名如 `Dept`、`Emp` |
| **VO** | View Object | 封装前端需要的特殊响应格式，字段可能不完全对应数据库 | `vo/` | 以 `VO` 结尾，如 `DeptVO` |
| **DTO** | Data Transfer Object | 封装前端提交的特殊请求参数，用于接收非实体类的请求数据 | `dto/` | 以 `DTO` 结尾，如 `DeptDTO` |

### 2.2 什么时候用 VO/DTO

**POJO 不够用的场景：**

- 数据库表有 `password` 字段，但接口不能返回密码 → 用 VO 去掉敏感字段
- 数据库表只有 `name`，但前端需要 `name + token` → 用 VO 扩展字段
- 前端提交的参数不是一张表的完整字段 → 用 DTO 接收

**示例：列表查询用 DTO 封装分页参数**

```java
package com.example.dto;

import lombok.Data;

@Data
public class PageQueryDTO {
    private Integer page;       // 当前页码
    private Integer pageSize;   // 每页条数
    private String name;        // 搜索关键词（可选）
}
```

```java
// Controller 接收
@GetMapping("/depts")
public Result page(PageQueryDTO queryDTO) {
    // 框架自动将 ?page=1&pageSize=10&name=研发 映射到对象
    PageResult pageResult = deptService.page(queryDTO);
    return Result.success(pageResult);
}
```

---

## 三、三种请求参数接收方式

### 3.1 @RequestBody — JSON 请求体

```java
@PostMapping("/depts")
public Result add(@RequestBody Dept dept) {
    // 前端发送：POST 请求体 {"name":"服务中心","status":1}
    // 框架自动将 JSON 反序列化为 Dept 对象
    deptService.add(dept);
    return Result.success();
}
```

适用于：POST / PUT 请求，Content-Type 为 `application/json`

### 3.2 @RequestParam — 键值对参数

```java
@GetMapping("/depts")
public Result search(@RequestParam(defaultValue = "1") Integer page,
                     @RequestParam(defaultValue = "10") Integer pageSize,
                     @RequestParam(required = false) String name) {
    // 请求：GET /depts?page=1&pageSize=10&name=研发部
    // required=false 表示该参数可不传，defaultValue 提供默认值
    return Result.success(deptService.search(page, pageSize, name));
}
```

适用于：GET 请求的 URL 查询参数 `?key=value`，或 POST 表单提交。
特点：**参数名相同时 @RequestParam 可省略**

### 3.3 @PathVariable — 路径参数

```java
@GetMapping("/depts/{id}")
public Result findById(@PathVariable Integer id) {
    // 请求：GET /depts/1
    // 框架从 URL 路径 /depts/{id} 中提取 id = 1
    Dept dept = deptService.findById(id);
    return Result.success(dept);
}

@DeleteMapping("/depts/{id}")
public Result delete(@PathVariable("id") Integer id) {
    // 占位符名与参数名不一致时，用 value 显式指定
    deptService.deleteById(id);
    return Result.success();
}
```

适用于：RESTful 风格的 URL，参数嵌在路径中 `/resource/{id}`

### 3.4 三种方式对比速查

| 注解 | 参数位置 | 示例 URL | 使用场景 |
|------|----------|----------|----------|
| `@RequestBody` | 请求体 | `POST /depts` body: `{"name":"服务中心"}` | 提交 JSON（新增/修改） |
| `@RequestParam` | 查询字符串 / 表单 | `/depts?page=1&name=研发` | 条件查询、分页 |
| `@PathVariable` | URL 路径 | `/depts/1` | 根据 ID 操作（查询/删除） |

---

## 四、日期时间格式化注解

数据库中 `datetime` 类型的字段转为 Java 的 `LocalDateTime`，前后端传输时需要格式化。

### 4.1 @DateTimeFormat — 键值对 / 路径参数

处理 `@RequestParam` 和 `@PathVariable` 接收的时间参数：

```java
@GetMapping("/depts")
public Result search(
    @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime startTime,
    @RequestParam @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss") LocalDateTime endTime) {
    // 请求：GET /depts?startTime=2026-01-01 00:00:00&endTime=2026-12-31 23:59:59
    // 框架将字符串按指定格式解析为 LocalDateTime 对象
    return Result.success(deptService.searchByTime(startTime, endTime));
}
```

### 4.2 @JsonFormat — JSON 请求体

处理 `@RequestBody` 中 JSON 里包含的时间参数：

```java
@Data
public class Dept {
    private Integer id;
    private String name;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private LocalDateTime createTime;   // 序列化/反序列化时按指定格式处理
}
```

> **timezone = "GMT+8"** 不加的话会出现 8 小时偏差（默认 UTC），这是最常见的坑。

### 4.3 @DateTimeFormat vs @JsonFormat 对比

| 注解 | 作用对象 | 适用参数类型 | 说明 |
|------|----------|-------------|------|
| `@DateTimeFormat` | `@RequestParam` / `@PathVariable` | URL 参数 / 表单参数 | 解析字符串 → LocalDateTime |
| `@JsonFormat` | `@RequestBody` | JSON 字段 | 序列化 LocalDateTime → 字符串，反序列化反之 |

**推荐做法：** 在实体类字段上同时加两个注解，覆盖所有场景：

```java
@Data
public class Dept {
    private Integer id;
    private String name;

    @DateTimeFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+8")
    private LocalDateTime createTime;
}
```

---

## 速记

- 统一响应用 Result 类：`success()` / `success(data)` / `error(msg)`，前端统一解析 code/msg/data
- POJO 对应数据库表，VO 给前端看，DTO 接收前端请求，三者分开放在不同包下
- `@RequestBody` 接 JSON，`@RequestParam` 接 `?key=value`，`@PathVariable` 接路径参数
- 时间格式化：键值对用 `@DateTimeFormat`，JSON 用 `@JsonFormat`，别忘了 `timezone = "GMT+8"`
