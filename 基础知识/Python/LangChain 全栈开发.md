---
title: LangChain 全栈开发
tags: [LangChain, 大类, 模型, 消息, Agent, 工具, 记忆, Checkpointer, 会话, AI]
created: 2026-08-14
---

## 概述
LangChain 是开发 Agent（智能体）的平台：LangChain 快速构建 Agent、LangGraph 底层控制与记忆、LangSmith 测试评估部署。本大类覆盖全栈开发流程：依赖安装、模型初始化（init_chat_model）、消息类型、结构化输出 → Agent 创建、工具定义、调用模式、Context 注入 → 短期/长期记忆、Checkpointer、PostgreSQL 持久化、会话状态读取/删除、上下文超限处理。

---

# 基础与模型

## 平台架构
- **LLM = 大脑，Agent = 大脑 + 工具（手脚）**：Agent 是"用 LLM 决定应用控制流"的系统，能主动规划任务、调用工具、感知结果、动态调整。
- **LangChain**：快速构建 Agent，兼容任何模型提供商。
- **LangGraph**：从底层控制构建（记忆、人机协同 HITL 等）。
- **Deep Agents**：构建复杂的多步骤任务 Agent。
- **LangSmith**：测试、观察、评估、部署 Agent。

## 安装依赖
```bash
uv add langchain langchain-deepseek   # langchain 本体 + 对应模型支持库
uv add langchain-ollama               # 本地 Ollama 模型（按需）
uv add python-dotenv                  # 读取 .env 到系统环境变量（按需）
```
注意：LangChain 默认从**系统环境变量**读取 api_key；`.env` 文件需要用 `load_dotenv()` 加载后才进入系统环境变量（Pydantic Settings 只生成配置对象，不会回写系统环境变量）。

## 模型初始化

### 自动识别（推荐）
标准代码：
```python
# Step: 导入 init_chat_model —— LangChain 提供的统一模型初始化函数
from langchain.chat_models import init_chat_model

# Step: 初始化模型 —— 按名称自动推断类型，无需手动指定 provider
model = init_chat_model(
    "模型名称",                                          # 模型名，LangChain 按名称自动推断类型
    extra_body={"thinking": {"type": "disabled"}},       # 关闭思考模式（DeepSeek 等可选）
)
```

### OpenAI 兼容服务（自定义 base_url / api_key）
标准代码：
```python
# Step: 导入所需模块
import os                                              # 读取环境变量
from langchain.chat_models import init_chat_model      # 统一模型初始化函数

# Step: 初始化模型 —— LangChain 不支持的模型走 OpenAI 规范
model = init_chat_model(
    model="模型名称",                    # 模型名
    model_provider="openai",            # LangChain 不支持的模型走 OpenAI 规范
    base_url=os.getenv("BASE_URL"),     # 服务商兼容接口地址
    api_key=os.getenv("API_KEY"),       # 密钥；必要时显式传入（Pydantic Settings 不回写环境变量）
)
```

### 专用模型类（不兼容 OpenAI 规范）
标准代码：
```python
# Step: 导入专用模型类 —— 适用于 Ollama 等非 OpenAI 兼容的本地模型
from langchain_ollama import ChatOllama

# Step: 初始化模型 —— 直接指定模型名与参数
model = ChatOllama(
    model="本地模型名",        # 如 qwen3.5:0.8b
    temperature=1.0,          # 随机性：越高越发散
)
```

## 消息（Messages）
LangChain 把消息统一封装为 BaseMessage 的子类：
- **SystemMessage**：设定角色与交互背景（系统提示词）
- **HumanMessage**：用户输入
- **AIMessage**：模型响应（含文本、工具调用、元数据）
- **ToolMessage**：工具调用产生的结果

标准代码：
```python
# Step: 导入消息类型
from langchain.messages import HumanMessage, SystemMessage

# Step: 调用模型 —— 传入消息列表，包含系统提示与用户输入
response = model.invoke([
    SystemMessage(content="设定角色与规则"),   # 系统消息：设定模型行为
    HumanMessage(content="用户输入"),          # 用户消息：实际输入内容
])
```

## 直接调用模型
- `invoke`：阻塞式调用，传 `str` 或消息列表，返回 AIMessage。
- `stream`：流式调用。

标准代码：
```python
# Step: 直接调用模型 —— 两种传参方式
response = model.invoke("你是谁？")                                # 方式一：传字符串
response = model.invoke([{"role": "user", "content": "hi"}])       # 方式二：传消息 dict 列表
```

## 结构化输出
定义 Pydantic 模型约束输出，用 `with_structured_output()` 绑定后直接得到对象：
```python
# Step: 导入所需模块
from langchain.chat_models import init_chat_model     # 统一模型初始化
from langchain.messages import HumanMessage           # 用户消息类型
from pydantic import BaseModel, Field                 # 数据模型定义

# Step: 定义输出模型 —— 用 Pydantic 约束模型输出结构
class 输出模型(BaseModel):
    字段名: str = Field(description="字段说明")       # 描述帮助模型理解
    数字字段: int = Field(description="数字说明")

# Step: 初始化模型并绑定结构约束
model = init_chat_model("模型名称")
model_with_output = model.with_structured_output(schema=输出模型)   # 绑定结构约束

# Step: 调用并获取结构化结果
result = model_with_output.invoke([HumanMessage("生成内容的要求")])
print(result.字段名)      # 返回的是 输出模型 实例，可直接取字段
```


---

# LangGraph 编排进阶

本章覆盖多 Agent 编排、子图嵌套、意图路由等生产级 LangGraph 模式，全部来自实际项目实践。

## StateGraph + Command + 条件路由

多 Agent 系统的核心模式：主图根据意图识别结果，用 Command 对象跳转到不同子工作流。

标准完整代码：
```python
# =================== Step 1: 定义状态（继承 MessagesState） ===================
from typing import Literal                                         # 类型约束
from langgraph.graph import MessagesState                          # LangGraph 内置状态基类，自带 messages 字段

# Intent: 用 Literal 约束所有可能的工作流名称，类型安全
Intent = Literal["chitchat", "recommendation_plan", "claim", "human_handoff", "fallback"]

class OrchestratorState(MessagesState):
    """主图状态 —— 继承 MessagesState 自带 messages 字段，扩展工作流跟踪字段"""
    previous_workflow: Intent   # 上一轮所处的工作流（用于判断连续闲聊等）
    active_workflow: Intent     # 本轮进入的工作流

# =================== Step 2: 定义路由节点（返回 Command 对象） ===================
from langchain_core.messages import AIMessage                      # AI 消息类型
from langgraph.types import Command                                # LangGraph 跳转指令

async def route_node(state: OrchestratorState) -> Command[Intent]:
    """意图识别节点：根据用户消息决定跳转到哪个子工作流"""
    # Command 是 LangGraph 的跳转指令：
    #   - update: 更新状态（写入新的 messages / active_workflow 等）
    #   - goto: 目标节点名（必须与 add_node 注册的名称一致，或 END）
    result = await intent_router.route(state["messages"][-1].content)
    
    return Command(
        update={
            "messages": [AIMessage(content=result)],  # 写入固定回复（寒暄场景）
            "active_workflow": "chitchat",             # 记录本轮工作流
        },
        goto=END,  # 跳转到结束节点
    )

# =================== Step 3: 构建图（StateGraph + add_node + add_edge） ===================
from langgraph.graph import StateGraph, END, START                 # 图构建核心类

builder = StateGraph(OrchestratorState)                            # 传入自定义状态类
builder.add_node("route", route_node)                              # 意图路由节点
builder.add_node("chitchat", chitchat_agent)                       # 闲聊子图节点
builder.add_node("recommendation_plan", advisor_agent)              # 保险推荐子图节点
builder.add_node("claim", claim_agent)                             # 理赔子图节点
builder.add_node("fallback", fallback_node)                        # 兜底节点

builder.add_edge(START, "route")                                   # 入口 → 路由节点
builder.add_edge("chitchat", END)                                  # 闲聊结束
builder.add_edge("recommendation_plan", END)                       # 推荐结束
builder.add_edge("claim", END)                                     # 理赔结束
builder.add_edge("fallback", END)                                  # 兜底结束

graph = builder.compile(checkpointer=checkpointer)                 # 编译时注入 Checkpointer
```

## 子图模式（嵌套 StateGraph）

每个子 Agent 是独立的 StateGraph，编译后作为节点嵌入主图。子图继承父图的 Checkpointer，可拥有私有状态字段。

标准完整代码：
```python
# =================== Step 1: 子图状态（继承父图状态，扩展私有字段） ===================
from typing import NotRequired                                      # 标记可选字段
from langgraph.graph import StateGraph

class ChitchatState(InsuranceAgentState):
    """子图状态 —— 继承父图状态，可扩展子图私有字段"""
    chitchat_count: NotRequired[int]  # 子图私有状态：连续闲聊计数（NotRequired 表示可选）

# =================== Step 2: 子图构建器 ===================
class ChitchatAgent:
    def build(self):
        builder = StateGraph(ChitchatState)
        builder.add_node("handle", self.handle)
        builder.set_entry_point("handle")                          # 单节点图：入口即出口
        builder.set_finish_point("handle")
        # 关键：编译时传 checkpointer=True，子图复用父图的 Checkpointer 存储私有状态
        return builder.compile(checkpointer=True)

# =================== Step 3: 主图中注册子图节点 ===================
builder.add_node("chitchat", ChitchatAgent().build())              # 子图作为节点嵌入主图
```

> **checkpointer=True 的含义**
> 编译子图时传 checkpointer=True 表示子图使用父图提供的 Checkpointer 实例，子图的私有状态（如 chitchat_count）会独立存储到 Checkpoint 中，不会与父图状态混在一起。

## 意图识别：规则预筛 + LLM 结构化输出

生产级意图路由的常见模式：正则预处理简单意图（寒暄），复杂意图交给 LLM 结构化输出。

标准完整代码：
```python
# =================== Step 1: 定义输出结构约束 ===================
from langchain.messages import HumanMessage, SystemMessage         # 消息类型
from pydantic import BaseModel, Field                              # 数据模型定义

class RouteResult(BaseModel):
    """LLM 输出结构约束 —— with_structured_output 会要求模型严格按此格式输出"""
    intent: Intent = Field(description="本轮消息应该进入的工作流")
    reason: str = Field(description="判断该意图的理由")

# =================== Step 2: 初始化结构化路由模型 ===================
model = init_chat_model(model="deepseek-chat", model_provider="deepseek", api_key=api_key)
router_model = model.with_structured_output(RouteResult)           # 绑定输出结构

# =================== Step 3: 路由逻辑（规则预筛 + LLM 兜底） ===================
import re                                                          # 正则匹配

SOCIAL_PATTERNS = {
    "greeting": (r"(你|您)?好(呀|啊|哦)?", r"嗨", r"哈喽", r"hello", r"hi"),
    "goodbye": (r"再见", r"拜拜", r"先这样"),
}

def match_social_intent(message: str) -> str | None:
    """基于正则的简单意图匹配，减少不必要的 LLM 调用"""
    normalized = re.sub(r"[\s，。！？、,.!?~～]", "", message).lower()  # 去除标点空白
    for intent, patterns in SOCIAL_PATTERNS.items():
        if any(re.fullmatch(p, normalized) for p in patterns):
            return intent
    return None

async def route(message: str, context: str) -> RouteResult | str:
    # 1. 规则预筛：简单寒暄直接返回固定回复，不调用 LLM（节省成本和延迟）
    social_intent = match_social_intent(message)
    if social_intent:
        return SOCIAL_RESPONSES[social_intent]  # 返回 str 而非 RouteResult
    
    # 2. LLM 识别：非寒暄消息交给模型
    result = await router_model.ainvoke([
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=f"历史上下文：{context}\n当前消息：{message}"),
    ])
    return result  # 返回 RouteResult 对象
```

## astream_events v3 事件解析

LangGraph Agent 的流式调用标准模式：用 stream_events 获取中间过程事件，逐条包装为 SSE 推送给前端。

标准完整代码：
```python
# =================== Step 1: 构造输入与配置 ===================
from langchain_core.messages import HumanMessage, AIMessage        # 消息类型
from fastapi.sse import ServerSentEvent                            # SSE 事件对象

# 输入消息：LangGraph 标准格式为 messages 列表
_input = {"messages": [HumanMessage(content=request.message)]}

# 运行配置：thread_id 用于 Checkpointer 持久化（同一 thread_id 自动加载历史）
config = {"configurable": {"thread_id": str(request.thread_id)}}

# 业务上下文：传递 user_id 等信息供 Agent 工具函数使用
context = InsuranceAgentContext(user_id=user_id)

# =================== Step 2: 流式调用 Agent ===================
result = await agent.astream_events(
    _input,              # 输入消息
    config,              # LangGraph 配置（包含 thread_id）
    context=context,     # 业务上下文（user_id）
    version="v3"         # 事件流版本（v3 是最新格式）
)

# =================== Step 3: 解析事件流 ===================
async for event in result:
    method = event["method"]                                       # 事件类型：messages / interrupts 等
    if method == "messages":
        data = event["params"]["data"][0]                          # 取第一条消息
        if isinstance(data, AIMessage):
            yield ServerSentEvent(data=data.text, event="message")         # 完整回复
        elif data.get("delta", {}).get("text"):
            yield ServerSentEvent(data=data["delta"]["text"], event="message")  # 增量文本

# =================== Step 4: 发送结束标记 ===================
yield ServerSentEvent(data="[DONE]", event="done")                 # 客户端收到后关闭 SSE 连接
```

> **astream_events v3 vs stream**
> - stream：只返回最终消息，无中间过程
> - stream_events：返回所有中间事件（工具调用、节点切换等），适合需要细粒度控制的场景
> - ersion="v3"：使用最新的事件格式，事件结构为 {method, params}


# Agent 开发

## ToolCalling 原理（ReAct）
工具的本质是函数，但模型在云端无法直接执行本地函数，流程如下：
1. 把工具的函数名、参数、作用描述给模型（tools 列表）；
2. 模型返回想调用的工具名与参数（tool_calls）；
3. 程序在本地执行函数，把结果以 `role=tool` 回传；
4. 模型根据工具结果生成最终回答，信息不足则重复调用。

该"推理（Reasoning）→ 行动（Action）→ 观察（Observation）"循环称为 **ReAct**，是最基础的 Agent 工作模型。

## 创建 Agent
标准代码：
```python
# Step: 导入所需模块
from langchain.agents import create_agent              # Agent 创建函数
from langchain.messages import HumanMessage             # 用户消息类型

# Step: 创建 Agent —— 组装模型、工具、提示词、记忆
agent = create_agent(
    model=model,                # 初始化好的模型（见上方「模型初始化」）
    tools=[工具函数...],         # 工具列表，可省略（省略则只有对话能力）
    system_prompt="系统提示词",   # 设定角色与规则，创建后不必每次发送消息时指定
    checkpointer=checkpointer,  # 会话记忆保存器（见下方「记忆与持久化」）
)

# Step: 调用 Agent —— 注意输入是 dict，key 为 messages
response = agent.invoke({
    "messages": [HumanMessage("用户输入")],   # Agent 输入格式：{"messages": [...]}
})
print(response["messages"][-1].content)       # 返回也是 dict，AI 回答在 messages 最后一条
```
调用差异小结：
- **Model 调用**：传 `str` / 消息列表，返回 AIMessage。
- **Agent 调用**：传 `{"messages": [...]}`，返回 dict（含全部历史消息）。

## 定义工具

### 方式一：装饰器 + 名称/描述
```python
# Step: 导入 tool 装饰器
from langchain.tools import tool

# Step: 定义工具 —— 显式指定工具名和描述
@tool("工具名", description="工具作用说明")
def 工具函数(x: float) -> float:
    return x ** 0.5                                  # 返回计算结果
```

### 方式二：装饰器 + 文档注释（推荐）
```python
# Step: 导入 tool 装饰器
from langchain.tools import tool

# Step: 定义工具 —— 用文档注释描述，工具名 = 函数名
@tool
def 工具函数(location: str, units: str = "celsius") -> str:
    """工具作用说明。

    Args:
        location: 参数作用
        units: 参数作用（默认 celsius）
    """
    return "工具执行结果"                             # 返回结果给模型阅读
```
默认情况下：工具名 = 函数名，参数 = 函数入参，作用 = 文档注释（必须有，否则报错）。

### 方式三：Pydantic 约束参数
```python
# Step: 导入所需模块
from langchain.tools import tool                      # tool 装饰器
from pydantic import BaseModel, Field                 # 参数模型定义

# Step: 定义输入参数模型
class 输入模型(BaseModel):
    """输入参数说明"""
    参数1: str = Field(description="参数作用")

# Step: 定义工具 —— 用 args_schema 绑定参数约束
@tool(args_schema=输入模型)
def 工具函数(参数1: str) -> str:
    return "工具执行结果"
```

### 异步工具（调用数据库 / 外部服务）
```python
# Step: 导入所需模块
from fastapi.encoders import jsonable_encoder          # 转 JSON 兼容格式
from langchain.tools import tool                      # tool 装饰器

# Step: 定义异步工具 —— Agent 调用时必须用 ainvoke / astream_events
@tool
async def 查询工具(条件: str) -> list[dict]:
    """查询数据。当用户咨询具体数据时使用。"""
    async with 会话工厂() as session:                  # 异步会话（如 SQLAlchemy AsyncSession）
        result = await 查询(session, 条件)             # 执行异步查询
    return jsonable_encoder(result)                    # 转 JSON 返回给模型阅读
```
注意：Agent 调用异步工具时必须用 `ainvoke` / `astream_events`（异步调用）。

## 调用模式

### invoke（阻塞）
```python
# Step: 同步调用 —— 阻塞直到完成
response = agent.invoke({"messages": [HumanMessage("你是谁？")]})
```

### stream_events（流式，V3 协议）
```python
# Step: 同步流式调用
stream = agent.stream_events(
    {"messages": [HumanMessage("你是谁？")]},
    version="v3",                 # 推荐 V3
)
for message in stream.messages:   # 遍历模型调用的消息流
    for text in message.text:     # 消息文本片段（持续生成）
        print(text, end="", flush=True)
```

异步版本（对接 SSE 用）：
```python
# Step: 异步流式调用 —— 用于 SSE 或 FastAPI StreamingResponse
stream = await agent.astream_events(
    {"messages": [HumanMessage("...")]},
    version="v3",
)
async for message in stream.messages:      # 异步遍历消息流
    async for text in message.text:         # 异步遍历文本片段
        yield text                          # 逐片段产出
```

## Context 注入（进阶）
需要向工具传外部信息（如当前用户 ID）且不能让模型自行生成时，用 Context：
```python
# Step: 导入所需模块
from dataclasses import dataclass                       # 不可变数据类
from langchain.tools import ToolRuntime, tool           # 运行时上下文与工具装饰器

# Step: 定义运行上下文 —— 创建后不可修改（frozen=True）
@dataclass(frozen=True)
class 运行上下文:
    """运行时上下文，创建后不可修改"""
    user_id: int                                        # 由后端注入的用户 ID

# Step: 定义工具 —— 通过 runtime.context 获取后端注入的信息
@tool
async def 保存工具(数据: 数据模型, runtime: ToolRuntime[运行上下文]) -> dict:
    """保存业务数据。"""
    user_id = runtime.context.user_id                   # 后端注入，不出现在模型可见的参数里
    ...
```
Agent 创建时声明 `context_schema=运行上下文`，调用时传 `context=运行上下文(user_id=...)`。用户身份由后端控制、业务数据由模型生成，两类来源不混在一起。

---

# 记忆与持久化

## 记忆分类
| 维度 | 短期记忆 | 长期记忆 |
|---|---|---|
| 生命周期 | 当前会话 | 跨任务、跨会话 |
| 内容 | 对话历史、查询结果、任务状态 | 知识、经验、用户偏好 |
| 存储 | Redis / 内存 / DB | DB / Vector DB |

## 会话记忆机制
- 每一次与 AI 交互生成一个 **AgentStateSnapshot**（状态快照），同一会话的所有快照组成会话历史；
- 快照由 **Checkpointer** 对象保存，有多种实现；
- 用 **thread_id** 区分会话：相同 thread_id = 同一会话，调用时自动携带历史消息。

## 内存版 Checkpointer（学习 / 测试）
```python
# Step: 导入内存版 Checkpointer
from langgraph.checkpoint.memory import InMemorySaver  # 基于内存的 Checkpointer
from langchain.agents import create_agent              # Agent 创建函数

# Step: 创建 Agent —— 绑定内存版 Checkpointer（重启即丢失）
agent = create_agent(
    model=model,
    checkpointer=InMemorySaver(),                      # 基于内存，重启即丢失
)

# Step: 调用 Agent —— 通过 thread_id 唤起对应会话记忆
config = {"configurable": {"thread_id": "会话ID"}}     # 相同 thread_id = 同一会话
response = agent.invoke({"messages": [HumanMessage("...")]}, config)
```

## PostgreSQL Checkpointer（生产持久化）

### 安装依赖
```bash
uv add langgraph-checkpoint-postgres "psycopg[binary,pool]"
```
- `langgraph-checkpoint-postgres`：提供 PostgresSaver / AsyncPostgresSaver；
- `psycopg[binary,pool]`：连接 PostgreSQL，并提供异步连接池。

### 连接池 + Checkpointer
```python
# Step: 导入所需模块
from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver  # 异步 PostgreSQL Checkpointer
from psycopg.rows import dict_row                                  # 查询结果以 dict 返回
from psycopg_pool import AsyncConnectionPool                       # psycopg 异步连接池

# Step: 创建连接池 —— psycopg 协议，与 SQLAlchemy 的 asyncpg 不同
checkpoint_pool = AsyncConnectionPool(
    conninfo="postgresql://用户:密码@主机:端口/库名",   # psycopg 协议；注意与 SQLAlchemy 的 postgresql+asyncpg 不同
    min_size=1,                      # 池最小连接数
    max_size=5,                      # 池最大连接数
    kwargs={
        "autocommit": True,          # 自动提交事务
        "prepare_threshold": 0,      # 不做预准备 SQL
        "row_factory": dict_row,     # 查询结果以 dict 返回
    },
    open=False,                      # 不自动创建连接，由 init 显式打开
)

# Step: 初始化 Checkpointer —— 应用启动时执行
async def init_checkpointer() -> AsyncPostgresSaver:
    """初始化 Checkpointer（应用启动时执行）"""
    await checkpoint_pool.open()     # 初始化连接
    await checkpoint_pool.wait()     # 等待连接池就绪
    checkpointer = AsyncPostgresSaver(checkpoint_pool)
    await checkpointer.setup()       # 自动创建 Checkpointer 相关表
    return checkpointer

# Step: 关闭连接池 —— 应用关闭前执行
async def close_checkpointer() -> None:
    """关闭连接池（应用关闭前执行）"""
    await checkpoint_pool.close()
```
说明：`AsyncPostgresSaver` 底层用 psycopg 驱动，与 SQLAlchemy 的 asyncpg 不同，需要**独立连接池**；同一数据库两种驱动连接地址协议分别为 `postgresql` 与 `postgresql+asyncpg`。

### Windows 事件循环
psycopg 异步连接不能运行在 ProactorEventLoop 上，Windows 下启动 uvicorn 时指定 SelectorEventLoop：
```python
# Step: 启动 uvicorn —— Windows 下必须用 SelectorEventLoop
uvicorn.run(
    "app.main:app",
    loop="asyncio:SelectorEventLoop" if sys.platform == "win32" else "auto",   # Windows 用 SelectorEventLoop
)
```
注意：因此必须用 `python -m app.main` 启动（入口内设置了 loop），不能直接 `uvicorn app.main:app`。

## 读取 / 删除会话状态

### 读取最新状态快照
```python
# Step: 读取会话最新状态
config = {"configurable": {"thread_id": "会话ID"}}
snapshot = await agent.aget_state(config)               # 获取最新 StateSnapshot
messages = snapshot.values.get("messages", [])          # 历史消息列表
for message in messages:
    message.pretty_print()                              # 格式化打印每条消息
```

### 删除会话全部快照
```python
# Step: 删除会话 —— 同时需要删除业务表记录
await checkpointer.adelete_thread("会话ID")              # 删除该 thread 的全部 Checkpoint
```
删除后 `aget_state` 返回空 values，说明历史已清理。业务上删除会话时，需要**同时**删除业务表记录与 Checkpointer 状态。

## 上下文超限处理
会话历史超过模型上下文窗口会丢失记忆、降低质量。三种策略：
- **修剪（trim）**：发送前只保留部分消息，State 仍完整；
- **删除（delete）**：直接从 State 删除消息（谨慎使用）；
- **总结（summarize）**：用模型把历史总结成摘要替换，保留记忆且不超限。

标准代码：
```python
# Step: 导入摘要中间件
from langchain.agents.middleware import SummarizationMiddleware

# Step: 创建摘要中间件 —— 消息数超过阈值时自动总结
middleware = SummarizationMiddleware(
    model=model,                    # 做摘要的模型
    trigger=("messages", 6),        # 触发时机：消息数超过 6 时总结（也支持 fraction/tokens）
    keep=("messages", 1),           # 摘要后保留的消息数量
)

# Step: 创建 Agent —— 绑定摘要中间件
agent = create_agent(
    model=model,
    checkpointer=checkpointer,
    middleware=[middleware],
)
```


---

# LangGraph 编排进阶

本章覆盖多 Agent 编排、子图嵌套、意图路由等生产级 LangGraph 模式，全部来自实际项目实践。

## StateGraph + Command + 条件路由

多 Agent 系统的核心模式：主图根据意图识别结果，用 Command 对象跳转到不同子工作流。

标准完整代码：
```python
# =================== Step 1: 定义状态（继承 MessagesState） ===================
from typing import Literal                                         # 类型约束
from langgraph.graph import MessagesState                          # LangGraph 内置状态基类，自带 messages 字段

# Intent: 用 Literal 约束所有可能的工作流名称，类型安全
Intent = Literal["chitchat", "recommendation_plan", "claim", "human_handoff", "fallback"]

class OrchestratorState(MessagesState):
    """主图状态 —— 继承 MessagesState 自带 messages 字段，扩展工作流跟踪字段"""
    previous_workflow: Intent   # 上一轮所处的工作流（用于判断连续闲聊等）
    active_workflow: Intent     # 本轮进入的工作流

# =================== Step 2: 定义路由节点（返回 Command 对象） ===================
from langchain_core.messages import AIMessage                      # AI 消息类型
from langgraph.types import Command                                # LangGraph 跳转指令

async def route_node(state: OrchestratorState) -> Command[Intent]:
    """意图识别节点：根据用户消息决定跳转到哪个子工作流"""
    # Command 是 LangGraph 的跳转指令：
    #   - update: 更新状态（写入新的 messages / active_workflow 等）
    #   - goto: 目标节点名（必须与 add_node 注册的名称一致，或 END）
    result = await intent_router.route(state["messages"][-1].content)
    
    return Command(
        update={
            "messages": [AIMessage(content=result)],  # 写入固定回复（寒暄场景）
            "active_workflow": "chitchat",             # 记录本轮工作流
        },
        goto=END,  # 跳转到结束节点
    )

# =================== Step 3: 构建图（StateGraph + add_node + add_edge） ===================
from langgraph.graph import StateGraph, END, START                 # 图构建核心类

builder = StateGraph(OrchestratorState)                            # 传入自定义状态类
builder.add_node("route", route_node)                              # 意图路由节点
builder.add_node("chitchat", chitchat_agent)                       # 闲聊子图节点
builder.add_node("recommendation_plan", advisor_agent)              # 保险推荐子图节点
builder.add_node("claim", claim_agent)                             # 理赔子图节点
builder.add_node("fallback", fallback_node)                        # 兜底节点

builder.add_edge(START, "route")                                   # 入口 → 路由节点
builder.add_edge("chitchat", END)                                  # 闲聊结束
builder.add_edge("recommendation_plan", END)                       # 推荐结束
builder.add_edge("claim", END)                                     # 理赔结束
builder.add_edge("fallback", END)                                  # 兜底结束

graph = builder.compile(checkpointer=checkpointer)                 # 编译时注入 Checkpointer
```

## 子图模式（嵌套 StateGraph）

每个子 Agent 是独立的 StateGraph，编译后作为节点嵌入主图。子图继承父图的 Checkpointer，可拥有私有状态字段。

标准完整代码：
```python
# =================== Step 1: 子图状态（继承父图状态，扩展私有字段） ===================
from typing import NotRequired                                      # 标记可选字段
from langgraph.graph import StateGraph

class ChitchatState(InsuranceAgentState):
    """子图状态 —— 继承父图状态，可扩展子图私有字段"""
    chitchat_count: NotRequired[int]  # 子图私有状态：连续闲聊计数（NotRequired 表示可选）

# =================== Step 2: 子图构建器 ===================
class ChitchatAgent:
    def build(self):
        builder = StateGraph(ChitchatState)
        builder.add_node("handle", self.handle)
        builder.set_entry_point("handle")                          # 单节点图：入口即出口
        builder.set_finish_point("handle")
        # 关键：编译时传 checkpointer=True，子图复用父图的 Checkpointer 存储私有状态
        return builder.compile(checkpointer=True)

# =================== Step 3: 主图中注册子图节点 ===================
builder.add_node("chitchat", ChitchatAgent().build())              # 子图作为节点嵌入主图
```

> **checkpointer=True 的含义**
> 编译子图时传 checkpointer=True 表示子图使用父图提供的 Checkpointer 实例，子图的私有状态（如 chitchat_count）会独立存储到 Checkpoint 中，不会与父图状态混在一起。

## 意图识别：规则预筛 + LLM 结构化输出

生产级意图路由的常见模式：正则预处理简单意图（寒暄），复杂意图交给 LLM 结构化输出。

标准完整代码：
```python
# =================== Step 1: 定义输出结构约束 ===================
from langchain.messages import HumanMessage, SystemMessage         # 消息类型
from pydantic import BaseModel, Field                              # 数据模型定义

class RouteResult(BaseModel):
    """LLM 输出结构约束 —— with_structured_output 会要求模型严格按此格式输出"""
    intent: Intent = Field(description="本轮消息应该进入的工作流")
    reason: str = Field(description="判断该意图的理由")

# =================== Step 2: 初始化结构化路由模型 ===================
model = init_chat_model(model="deepseek-chat", model_provider="deepseek", api_key=api_key)
router_model = model.with_structured_output(RouteResult)           # 绑定输出结构

# =================== Step 3: 路由逻辑（规则预筛 + LLM 兜底） ===================
import re                                                          # 正则匹配

SOCIAL_PATTERNS = {
    "greeting": (r"(你|您)?好(呀|啊|哦)?", r"嗨", r"哈喽", r"hello", r"hi"),
    "goodbye": (r"再见", r"拜拜", r"先这样"),
}

def match_social_intent(message: str) -> str | None:
    """基于正则的简单意图匹配，减少不必要的 LLM 调用"""
    normalized = re.sub(r"[\s，。！？、,.!?~～]", "", message).lower()  # 去除标点空白
    for intent, patterns in SOCIAL_PATTERNS.items():
        if any(re.fullmatch(p, normalized) for p in patterns):
            return intent
    return None

async def route(message: str, context: str) -> RouteResult | str:
    # 1. 规则预筛：简单寒暄直接返回固定回复，不调用 LLM（节省成本和延迟）
    social_intent = match_social_intent(message)
    if social_intent:
        return SOCIAL_RESPONSES[social_intent]  # 返回 str 而非 RouteResult
    
    # 2. LLM 识别：非寒暄消息交给模型
    result = await router_model.ainvoke([
        SystemMessage(content=SYSTEM_PROMPT),
        HumanMessage(content=f"历史上下文：{context}\n当前消息：{message}"),
    ])
    return result  # 返回 RouteResult 对象
```

## astream_events v3 事件解析

LangGraph Agent 的流式调用标准模式：用 stream_events 获取中间过程事件，逐条包装为 SSE 推送给前端。

标准完整代码：
```python
# =================== Step 1: 构造输入与配置 ===================
from langchain_core.messages import HumanMessage, AIMessage        # 消息类型
from fastapi.sse import ServerSentEvent                            # SSE 事件对象

# 输入消息：LangGraph 标准格式为 messages 列表
_input = {"messages": [HumanMessage(content=request.message)]}

# 运行配置：thread_id 用于 Checkpointer 持久化（同一 thread_id 自动加载历史）
config = {"configurable": {"thread_id": str(request.thread_id)}}

# 业务上下文：传递 user_id 等信息供 Agent 工具函数使用
context = InsuranceAgentContext(user_id=user_id)

# =================== Step 2: 流式调用 Agent ===================
result = await agent.astream_events(
    _input,              # 输入消息
    config,              # LangGraph 配置（包含 thread_id）
    context=context,     # 业务上下文（user_id）
    version="v3"         # 事件流版本（v3 是最新格式）
)

# =================== Step 3: 解析事件流 ===================
async for event in result:
    method = event["method"]                                       # 事件类型：messages / interrupts 等
    if method == "messages":
        data = event["params"]["data"][0]                          # 取第一条消息
        if isinstance(data, AIMessage):
            yield ServerSentEvent(data=data.text, event="message")         # 完整回复
        elif data.get("delta", {}).get("text"):
            yield ServerSentEvent(data=data["delta"]["text"], event="message")  # 增量文本

# =================== Step 4: 发送结束标记 ===================
yield ServerSentEvent(data="[DONE]", event="done")                 # 客户端收到后关闭 SSE 连接
```

> **astream_events v3 vs stream**
> - stream：只返回最终消息，无中间过程
> - stream_events：返回所有中间事件（工具调用、节点切换等），适合需要细粒度控制的场景
> - ersion="v3"：使用最新的事件格式，事件结构为 {method, params}


## 相关大类
- [[AI 接口集成]] —— OpenAI 兼容接口的原始调用方式（不经 LangChain）
- [[MCP 集成]] —— 通过 MCP 复用外部工具
- [[SSE 流式响应]] —— 把流式输出接到前端
- [[SQLAlchemy 数据访问]] —— 业务库异步连接池（与 Checkpointer 连接池的差异）

## 参考
- [LangChain 官方文档](https://docs.langchain.com/)
- [LangChain Python 文档](https://docs.langchain.com/oss/python/langchain)
- [LangChain Short-term Memory](https://docs.langchain.com/oss/python/langchain/short-term-memory)
- [LangGraph Checkpointer](https://docs.langchain.com/oss/python/langgraph/persistence)
- [LangChain Agents 文档](https://docs.langchain.com/oss/python/langchain/agents)
- [LangChain Tools 文档](https://docs.langchain.com/oss/python/langchain/tools)