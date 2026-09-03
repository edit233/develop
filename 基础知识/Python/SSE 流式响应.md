---
title: SSE 流式响应
tags: [FastAPI, 大类, SSE, 流式, 前后端]
created: 2026-08-14
---

## 概述
SSE（Server-Sent Events）让服务端持续向前端推送数据，适合流式对话：AI 每生成一段文本就立刻返回，无需等待完整回复。FastAPI 原生支持，无需第三方库。

## 核心对象
- `ServerSentEvent(data=..., event=...)`：一条事件，`data` 为内容，`event` 为事件类型；
- `EventSourceResponse`：路由响应类，自动设置 `text/event-stream`、`Cache-Control: no-cache`、`X-Accel-Buffering: no`，空闲时自动发送保活注释。

## 标准写法
```python
from fastapi import APIRouter
from fastapi.sse import EventSourceResponse, ServerSentEvent

router = APIRouter()

@router.post("/chat", response_class=EventSourceResponse)
async def chat(请求: 请求模型):
    """流式接口：用 yield 逐条返回事件"""
    for i in range(10):                              # 模拟持续返回
        yield ServerSentEvent(data=f"message_{i}", event="message")
    yield ServerSentEvent(data="[DONE]", event="done")   # 结束标识
```

## 对接 AI 流式输出
把模型 / Agent 的流式文本片段逐个封装成事件：
```python
from collections.abc import AsyncIterator
from fastapi.sse import ServerSentEvent

async def 生成事件流() -> AsyncIterator[ServerSentEvent]:
    stream = await agent.astream_events(输入, config, version="v3")   # 见 [[LangChain Agent 开发]]
    async for message in stream.messages:    # 本次运行的 AI 消息流
        async for text in message.text:      # 持续生成的文本片段
            yield ServerSentEvent(data=text, event="message")
    yield ServerSentEvent(data="[DONE]", event="done")

@router.post("/chat", response_class=EventSourceResponse)
async def chat(请求: 请求模型):
    async for sse in 生成事件流():
        yield sse
```

注意：
- 校验逻辑放在生成器最前或独立依赖中：SSE 响应一旦建立，很难再返回普通错误 JSON；
- 前端用 EventSource / fetch 读取流；后端无需手动拼接 `event:`、`data:` 与空行。

## 相关大类
- [[FastAPI 应用与路由]] —— 路由注册与响应
- [[LangChain Agent 开发]] —— Agent 流式调用（stream_events / astream_events）

## 参考
- [FastAPI Server-Sent Events](https://fastapi.tiangolo.com/advanced/server-sent-events/)