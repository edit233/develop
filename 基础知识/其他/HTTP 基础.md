---
title: HTTP 基础
tags:
  - http
  - network
created: 2026-09-03
---

# HTTP 基础

来源：李勃老师《零到全栈》模块 5.3

## 概述
HTTP（HyperText Transfer Protocol，超文本传输协议）是客户端与服务器之间交换数据的通信协议。本文档整理了 HTTP 请求响应结构、常见方法与头部。

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

## 关键收获

1. HTTP 是**无状态**协议，每次请求独立处理
2. 方法描述**意图**，而非数据流向
3. `Content-Type` 是实践中必须写的头部
4. 响应必须包含状态行和空行
