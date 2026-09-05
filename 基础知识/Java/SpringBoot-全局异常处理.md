---
title: "SpringBoot 全局异常处理"
tags: ["SpringBoot","异常处理","RestControllerAdvice","ExceptionHandler"]
created: "2026-09-04"
---

# SpringBoot 全局异常处理

## 一、为什么需要全局异常处理

当 Controller 抛出异常时（如数据库唯一约束冲突），SpringBoot 默认返回 HTML 格式的错误页面，前端无法正常解析。全局异常处理器的目的是：

1. **统一异常格式** — 将异常包装为 Result 对象，前端按统一格式解析
2. **精确提示** — 针对不同异常类型返回对应的错误信息
3. **日志记录** — 将异常信息写入日志，便于排查

---

## 二、核心注解

| 注解 | 作用 |
|------|------|
| @RestControllerAdvice | 标记类为全局异常处理器，组合了 @ControllerAdvice + @ResponseBody |
| @ExceptionHandler(异常类型.class) | 标记方法处理特定异常，参数接收捕获到的异常对象 |

---

## 三、使用步骤

### 3.1 基本全局异常处理

捕获所有 Exception，返回统一的错误 Result：

`java
import com.itheima.common.Result;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@Slf4j
@RestControllerAdvice                         // 声明全局异常处理器
public class GlobalExceptionHandler {

    @ExceptionHandler(Exception.class)         // 捕获所有 Exception 类型的异常
    public Result handlerException(Exception e) {
        log.error("服务器发生异常", e);          // 记录完整异常堆栈到日志
        return Result.error("对不起,操作失败,请联系管理员");  // 返回统一错误响应
    }
}
`

### 3.2 精确异常处理

针对特定异常做更精确的提示（如唯一约束冲突）：

`java
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(DuplicateKeyException.class)     // 专门处理数据库唯一约束冲突
    public Result handlerException(DuplicateKeyException e) {
        if (e.getMessage().contains("dept.name")) {     // 判断异常信息包含哪个字段冲突
            log.error("部门名称已存在");
            return Result.error("部门名称已存在");
        }
        return Result.error("对不起,操作失败,请联系管理员");
    }

    @ExceptionHandler(Exception.class)                 // 兜底处理所有其他异常
    public Result handlerException(Exception e) {
        log.error("服务器发生异常", e);
        return Result.error("对不起,操作失败,请联系管理员");
    }
}
`

> DuplicateKeyException 由 @ExceptionHandler 捕获优先级高于 Exception.class，Spring 会按具体类型优先匹配。

---

## 四、异常处理优先级

当异常类型存在继承关系时，Spring 按以下规则匹配：

`
子类异常 @ExceptionHandler     ← 优先匹配
父类异常 @ExceptionHandler     ← 兜底
`

例如 DuplicateKeyException extends DataAccessException extends RuntimeException extends Exception，匹配顺序为：

1. 先查是否有 DuplicateKeyException 的处理方法
2. 没有则查 DataAccessException
3. 再没有则查 RuntimeException
4. 最终兜底 Exception

---

## 五、最佳实践

- 一个项目中通常只有一个全局异常处理器类
- 用精确异常处理器处理已知业务异常（如唯一约束、参数校验）
- 用 Exception.class 兜底，避免未捕获异常导致前端收到 HTML 错误页
- 每个 handler 方法都要记录 log.error()，包含异常对象以保留堆栈
- 返回的错误信息对用户友好，不要暴露技术细节
