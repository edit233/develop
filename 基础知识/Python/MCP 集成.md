---
title: MCP 集成
tags: [MCP, 大类, 工具, AI, 协议]
created: 2026-08-14
---

## 概述
MCP（Model Context Protocol）是 Anthropic 推出的开放标准，用于把 AI 应用连接到外部系统，相当于"AI 世界的 USB 接口"：服务方按协议提供 Tool，AI 应用按协议对接，无需各自重复定义。本大类覆盖：核心概念、通信协议、LangChain 接入外部 MCP 服务、自定义 MCP Server。

## 核心概念
| 概念 | 说明 |
|---|---|
| MCP Server | 提供 MCP 服务的应用（远程或本地） |
| MCP Client | 连接 Server，读取 Tool 信息供 Host 使用 |
| MCP Host | 协调多个 Client 的 AI 应用（如 Agent） |

## 通信协议
- **stdio**：本地进程通信（Client 把服务脚本作为子进程运行），无网络延迟；
- **streamable_http（SSE）**：Client 通过 HTTP 与 Server 交互，存在网络延迟。

## 安装依赖
```bash
uv add langchain-mcp-adapters
```

## 接入外部 MCP 服务
标准代码：
```python
from langchain.agents import create_agent
from langchain.messages import HumanMessage
from langchain_mcp_adapters.client import MultiServerMCPClient

client = MultiServerMCPClient({
    "服务名": {
        "transport": "stdio",        # 通信方式：stdio / streamable_http
        "command": "npx",            # 启动方式：npx（node）或 uvx（python）
        "args": ["-y", "包名"],       # 启动参数
    },
})
tools = await client.get_tools()     # 拉取该服务提供的全部工具

agent = create_agent(model=model, tools=tools)
response = await agent.ainvoke(      # MCP 工具是异步的，必须异步调用
    {"messages": [HumanMessage("...")]},
)
```

### Windows / Notebook 事件循环注意
stdio 子进程在 Windows Jupyter 中需要 ProactorEventLoop，并重定向 stderr：
```python
import sys
import asyncio

if sys.platform == "win32":
    if not isinstance(asyncio.get_event_loop_policy(), asyncio.WindowsProactorEventLoopPolicy):
        asyncio.set_event_loop_policy(asyncio.WindowsProactorEventLoopPolicy())
    if "ipykernel" in sys.modules:
        sys.stderr = sys.__stderr__
```

## 自定义 MCP Server（FastMCP）
```bash
uv add fastmcp
```
标准代码：
```python
from fastmcp import FastMCP

mcp = FastMCP("服务名")

@mcp.tool          # 暴露为工具
def 工具函数(参数: str) -> str:
    """工具作用说明"""
    return "..."
```
- `@mcp.tool`：工具（最常用）；
- `@mcp.resources`：资源，类似扩展知识库（不常用）；
- `@mcp.prompt`：预定义提示词（不常用）。

## 相关大类
- [[LangChain Agent 开发]] —— 工具注册与 Agent 调用
- [[LangChain 基础与模型]] —— 模型初始化

## 参考
- [MCP 官方文档](https://modelcontextprotocol.io/)
- [MCP 传输规范](https://modelcontextprotocol.io/specification/2025-11-25/basic/transports)