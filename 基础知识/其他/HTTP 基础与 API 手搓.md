---
title: HTTP 基础与 API 手搓
tags:
  - http
  - api
  - network
  - python
created: 2026-09-03
---

# HTTP 基础与 API 手搓

来源：李勃老师《零到全栈》模块 5.3

## 概述
HTTP（HyperText Transfer Protocol，超文本传输协议）是客户端与服务器之间交换数据的通信协议。本文档基于课程内容，整理了 HTTP 请求响应结构、常见方法与头部、以及使用 Python `http.server` 模块手搓 API 的实践过程。

## HTTP 的一去一回：请求和响应

HTTP 通信遵循 请求-响应 模型：
- **请求（Request）**：客户端发送给服务器的消息
- **响应（Response）**：服务器返回给客户端的消息

### 请求结构
```
GET /api/profile HTTP/1.1      <- 请求行 (方法 + 路径 + 版本)
Host: localhost:8000           <- 请求头
User-Agent: curl/8.7.1
Accept: */*

                              <- 空行 (头结束)
                              <- 请求体 (可选，POST/PUT 时包含数据)
```

### 响应结构
```
HTTP/1.0 200 OK                <- 状态行 (版本 + 状态码 + 状态文本)
Content-Type: application/json <- 响应头
Server: BaseHTTP/0.6 Python/3.12.0
Date: Thu, 03 Jul 2026 15:42:10 GMT

                              <- 空行 (头结束)
{"heroTitle": "...", ...}     <- 响应体 (数据)
```

## 用 curl -v 验证
使用 `curl -v` 可以查看完整的请求和响应报文：
```bash
# 查 IP (GET 请求)
curl -v https://api.ipify.org?format=json

# 调用 DeepSeek API (POST 请求)
curl -v https://api.deepseek.com/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-xxx" \
  -d '{"model": "deepseek-chat", "messages": [{"role": "user", "content": "Hello"}]}'
```
输出中的三种记号：
- `>` 开头：请求原文
- `<` 开头：响应原文
- `*` 开头：curl 的旁白说明

## HTTP 方法与头部

### 常见方法
| 方法 | 意图 |
|------|------|
| GET | 获取资源 (通常不带请求体) |
| POST | 提交数据处理 (内容在请求体) |
| PUT | 整体替换资源 |
| PATCH | 部分修改资源 |
| DELETE | 删除资源 |
| HEAD | 仅获取响应头，不获取体 (探路) |
| OPTIONS | 询问服务器支持哪些方法 |

**注意**：方法描述的是**请求意图**，而非数据流向。无论 GET 还是 POST，都是一次完整的请求-响应循环。

### 常见请求头
| 请求头 | 作用 |
|--------|------|
| Host | 目标服务器地址 |
| User-Agent | 客户端标识 (浏览器/工具) |
| Accept | 可接受的响应格式 |
| Content-Type | 请求体格式 (JSON/Form 等) |
| Authorization | 身份凭证 (如 Bearer Token) |

### 常见响应头
| 响应头 | 作用 |
|--------|------|
| Content-Type | 响应体格式 |
| Server | 服务器软件标识 |
| Cache-Control | 缓存策略 |
| Set-Cookie | 设置客户端 Cookie |
| Access-Control-Allow-Origin | CORS 跨域设置 |

## HTTP 版本演进
- **HTTP/1.0**：基础版本，每次请求新建 TCP 连接
- **HTTP/1.1**：默认持久连接 (Keep-Alive)，管道化
- **HTTP/2**：多路复用、头部压缩、服务器推送
- **HTTP/3**：基于 QUIC 协议，更快的连接建立

版本号出现在状态行和请求行中 (如 `HTTP/1.1 200 OK`)，但语义 (方法、状态码等) 基本一致。

## 手搓 API 的核心要素

### 必须处理的部分
1. **请求行解析**：读取方法和路径，决定返回什么内容
2. **状态行返回**：必须返回状态码 (如 `200 OK` 或 `404 Not Found`)
3. **空行分隔**：头和体之间必须有一个空行
4. **响应体**：实际要返回的数据 (通常为 JSON)

### 必须写的响应头
- `Content-Type`：告诉客户端数据格式 (如 `application/json`)
  - 虽然规范允许省略，但省略后客户端只能猜测格式，实践中必须写

## Python http.server 实现示例

### 基础代码
```python
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

profile = {
    "heroTitle": "关于我",
    "heroSubtitle": "一个正在学习全栈的开发者",
    # ... 其他字段
}

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/api/profile":
            self.send_response(200)
            self.send_header("Content-Type", "application/json; charset=utf-8")
            self.end_headers()
            self.wfile.write(json.dumps(profile, ensure_ascii=False).encode("utf-8"))
        else:
            self.send_response(404)
            self.end_headers()

if __name__ == "__main__":
    HTTPServer(("", 8000), Handler).serve_forever()
```

### 代码解析
- `BaseHTTPRequestHandler`：处理 HTTP 请求的基类
- `do_GET`：处理 GET 请求的方法
- `send_response(200)`：发送状态行
- `send_header()`：发送响应头 (可多次调用)
- `end_headers()`：发送空行，表示头结束
- `wfile.write()`：写入响应体 (需 encode 为字节)

### 运行与测试
```bash
# 启动服务
python3 main.py

# 另开终端测试
curl http://localhost:8000/api/profile
# 或浏览器访问 http://localhost:8000/api/profile
```

访问日志示例：
```
127.0.0.1 - - [03/Jul/2026 15:42:10] "GET /api/profile HTTP/1.1" 200 -
```

## 实验：响应头与服务端信息

### 实验一：Content-Type 的作用
修改代码，尝试不同的 Content-Type：
- `text/html; charset=utf-8`：浏览器渲染为 HTML
- `text/plain`：浏览器显示纯文本

结论：`Content-Type` 决定了客户端如何解析响应体。

### 实验二：服务端获取的信息
在 `do_GET` 中打印：
```python
print(self.headers)          # 所有请求头
print(self.client_address)   # 客户端 IP 和端口
```
服务端可以获取：User-Agent、Accept、客户端 IP 等信息。

**边界感**：虽然服务端能看到很多信息，但应遵守隐私和安全规范，不滥用这些数据。

## 关键收获

1. HTTP 是**无状态**协议，每次请求独立处理
2. 方法描述**意图**，而非数据流向
3. `Content-Type` 是实践中必须写的头部
4. 响应必须包含状态行和空行
5. `http.server` 是 Python 标准库中的轻量级 HTTP 服务器，适合学习和原型开发
6. 生产环境建议使用 FastAPI、Flask 等框架

## 相关链接
- [模块 5.1：究竟什么是 API？](https://xn--ygr25xpohxwz.com/zero-to-fullstack/lessons/module-5-1/)
- [模块 5.2：Python 的安装和环境设置](https://xn--ygr25xpohxwz.com/zero-to-fullstack/lessons/module-5-2/)
