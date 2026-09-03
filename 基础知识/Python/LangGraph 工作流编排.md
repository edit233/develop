---
title: LangGraph 工作流编排
tags: [LangGraph, LangChain, Agent, 工作流, State, Edge, Node, Checkpointer, Sub-graph, Workflow]
created: 2026-08-20
---

## 一、LangGraph 概述与定位

### 1.1 AI 应用发展历程

AI 应用从简单到复杂经历了三个阶段：

**简单 LLM 应用**：直接调用 LLM，能力有限——无法调用工具、无法访问外部数据、无法实现复杂多步骤任务。

**链式应用（Chain）**：在 LLM 调用前后加入额外步骤（知识检索 retrieval、工具调用 tool calls），形成由程序控制的工作流链条。早期 LangChain 就是基于这种理念设计。特点是**稳定可靠**（Reliable），执行多少次流程都一样，但**缺乏自主智能**（Agentic）。

**智能体（Agent）**：执行工作流由 LLM 自主决定，应用更智能。但 Agent 的自主控制能力与稳定程度是对立的两端——LLM 控制得越多，应用稳定性越差。

### 1.2 LangGraph 的作用

LangGraph 在保持 Agent 自主控制程度不变的同时，提高稳定程度。方法是允许开发者自定义工作流中的每个节点：

- 需要稳定性的节点 → 用传统编程控制
- 需要 LLM 自主控制的 → 交给 LLM

工作流从直线运行的链（Chain）变为有分支、有循环的**图（Graph）**，由三个基本要素组成：

- **节点（Node）**：工作流中的关键工作代码，加工处理 State 中的数据
- **边（Edge）**：连接各个节点的路径，控制工作流走向
- **状态（State）**：整个工作流中流转的数据

为提高稳定性，LangGraph 为节点运行提供了 Checkpointer 功能，每个节点运行后形成检查点（Checkpoint），从而支持三大能力：

- **故障恢复**：程序异常中止后，可恢复到失败节点继续执行
- **人机交互（HITL）**：在关键节点暂停，允许人工介入后恢复
- **持久记忆**：持久化存储历史信息，应用具备记忆功能

### 1.3 LangGraph 与 LangChain 的关系

LangChain 1.0+ 版本后，底层 Chain 模式已废弃，Agent 底层实现全部替换为 LangGraph。

| | LangChain | LangGraph |
|---|---|---|
| **定位** | AI 应用开发框架，提供统一 API | 工作流编排框架，提供完善的编排工具 |
| **关注** | 统一 LLM 调用、Embedding、Vector Store | Node + Edge 工作流编排、State 数据传输、Checkpointer 持久化 |
| **优势** | 简化开发、上手快 | 自由度高、可完全控制每个细节 |
| **场景** | 简单 LLM 调用、快速 Agent 开发 | 复杂 Agent 工作流、需要精细控制 |

---

## 二、核心概念：Node、State、Edge、Graph

### 2.1 节点（Node）

节点是图的执行单元，多数情况下就是一个 Python 函数。格式：

```python
def my_node(state: State) -> dict:
    # 从状态中读取数据
    # 执行计算逻辑（调用模型、工具、数据库等）
    # 返回要更新到状态的字段（字典，部分更新）
    return {"age": new_value}
```

- **输入**：State 对象
- **输出**：dict，只包含要更新的字段（部分更新，未提及的字段不变）
- **能力**：调用 LLM、执行工具、读数据库、文件操作等

LangGraph 有两个默认节点无需定义：
- `START`：开始节点，入口
- `END`：结束节点，出口

**创建 Graph 的一般流程**：
1. 定义 State → 定义数据结构
2. 定义 Node → 定义数据处理逻辑
3. 创建 Graph → 注册 State → 注册 Node → 注册 Edge → 编译
4. 执行 Graph → 调用 `invoke` 或 `stream`

```python
from typing import TypedDict
from langgraph.constants import START, END
from langgraph.graph import StateGraph

# =================== 1. 定义 State：声明图中流转的数据结构 ===================
class SimpleState(TypedDict):
    name: str       # 记录用户输入的名字
    greeting: str   # 记录生成的问候语

# =================== 2. 定义 Node：数据处理逻辑 ===================
# Node 1：读取 state 中的 name，生成问候语写回 greeting
def greet_node(state: SimpleState):
    print(f"问候节点收到名字: {state['name']}")
    return {"greeting": f"Hello, {state['name']}!"}

# Node 2：读取 state 中的 greeting，转大写后覆盖写回 greeting
def uppercase_node(state: SimpleState):
    print(f"大写转换节点收到问候语: {state['greeting']}")
    return {"greeting": state["greeting"].upper()}

# =================== 3. 创建 Graph ===================
graph_builder = StateGraph(SimpleState)             # 注册 State，初始化图构建器
graph_builder.add_node("greet", greet_node)         # 注册 greet（问候）节点
graph_builder.add_node("uppercase", uppercase_node) # 注册 uppercase（大写转换）节点
graph_builder.add_edge(START, "greet")              # 开始 → greet
graph_builder.add_edge("greet", "uppercase")        # greet → uppercase
graph_builder.add_edge("uppercase", END)            # uppercase → 结束

graph = graph_builder.compile()                     # 编译成可执行的图

# =================== 4. 执行 Graph ===================
result = graph.invoke({"name": "World"})
print(result)
# {'name': 'World', 'greeting': 'HELLO, WORLD!'}
```

### 2.2 State（状态）

State 是图的共享内存数据，贯穿整个执行过程。每个 Node 都可以读取 State、更新 State（返回要更新的字段即可）。

Node 返回数据后，State 的更新方式取决于 **Reducer**——每个字段都有自己的 Reducer。

**Reducer 本质**：一个函数，接收旧数据和新数据，返回整合后的结果。

```python
greeting = 'hello, Jack'

def reducer(old, new):
    return new  # 直接用新值替换
```

**默认 Reducer — 覆盖**：如果字段没有指定 Reducer，多个 Node 都更新同一字段时，后执行的覆盖前面的结果：

```python
from typing import TypedDict
from langgraph.constants import START, END
from langgraph.graph import StateGraph

# =================== 1. 定义 State（val 字段无自定义 Reducer，使用默认覆盖） ===================
class DefaultReducerState(TypedDict):
    val: str

# =================== 2. 定义 Node ===================
# Node 1：将 val 覆盖为 "node_1"
def node_1(state: DefaultReducerState):
    print(f"节点1收到 val: {state['val']}")
    return {"val": "node_1"}

# Node 2：将 val 覆盖为 "node_2"
def node_2(state: DefaultReducerState):
    print(f"节点2收到 val: {state['val']}")
    return {"val": "node_2"}

# =================== 3. 创建 Graph ===================
graph = (
    StateGraph(DefaultReducerState)
    .add_node("node_1", node_1)
    .add_node("node_2", node_2)
    .add_edge(START, "node_1")
    .add_edge("node_1", "node_2")
    .add_edge("node_2", END)
    .compile()
)

result = graph.invoke({"val": "default"})
print(result)
# 节点1收到 val: default
# 节点2收到 val: node_1
# {'val': 'node_2'}  ← node_2 覆盖了 node_1 的结果
```

**自定义 Reducer**：通过 `Annotated[type, reducer]` 定义。例如用 `operator.add` 做列表拼接：

```python
from operator import add
from typing import Annotated, TypedDict
from langgraph.constants import START, END
from langgraph.graph import StateGraph

# =================== 1. 定义 State ===================
class CustomReducerState(TypedDict):
    count: int                            # 无 Reducer，默认覆盖
    nodes: Annotated[list[str], add]      # 使用 add 作为 Reducer，效果是拼接列表

# =================== 2. 定义 Node ===================
# Node 1：直接返回新值，无需自己做拼接，add Reducer 会自动处理
def node_1(state: CustomReducerState):
    print(f"节点1收到 count: {state['count']}")
    return {"count": 1, "nodes": ["node_1"]}

# Node 2：同理，add Reducer 会把 ["node_2"] 追加到已有列表
def node_2(state: CustomReducerState):
    print(f"节点2收到 count: {state['count']}")
    return {"count": 2, "nodes": ["node_2"]}

# =================== 3. 创建 Graph ===================
graph = (
    StateGraph(CustomReducerState)
    .add_node("node_1", node_1)
    .add_node("node_2", node_2)
    .add_edge(START, "node_1")
    .add_edge("node_1", "node_2")
    .add_edge("node_2", END)
    .compile()
)

result = graph.invoke({"count": 0, "nodes": []})
print(result)
# 节点1收到 count: 0
# 节点2收到 count: 1
# {'count': 2, 'nodes': ['node_1', 'node_2']}  ← nodes 被拼接，而非覆盖
```

### 2.3 Edge（边）

Edge 定义节点的执行顺序。LangGraph 提供两种边：

| 边类型 | 方法 | 说明 |
|---|---|---|
| 普通边（Normal Edge） | `add_edge(node_a, node_b)` | 固定流向：A 执行完一定到 B |
| 条件边（Conditional Edge） | `add_conditional_edges(node_a, router, mapping)` | router 返回值决定下一节点 |

**普通边 — 串行与并行**：

```python
from operator import add
from typing import Annotated, TypedDict
from langgraph.constants import START, END
from langgraph.graph import StateGraph

# =================== 1. 定义 State（使用 add Reducer 支持并行节点写入同一字段） ===================
class ParallelState(TypedDict):
    nodes: Annotated[list[str], add]

# =================== 2. 定义 Node ===================
def node_a(state: ParallelState):
    return {"nodes": ["a"]}

def node_b(state: ParallelState):
    return {"nodes": ["b"]}

def node_c(state: ParallelState):
    return {"nodes": ["c"]}

def node_d(state: ParallelState):
    return {"nodes": ["d"]}

# =================== 3. 创建 Graph：a → (b, c) 并行 → d ===================
#     ┌──> b ──┐
# a ──┤          ├──> d
#     └──> c ──┘
graph = (
    StateGraph(ParallelState)
    .add_node("a", node_a)
    .add_node("b", node_b)
    .add_node("c", node_c)
    .add_node("d", node_d)
    .add_edge(START, "a")      # 开始 → a
    .add_edge("a", "b")        # a → b
    .add_edge("a", "c")        # a → c（b 和 c 并行执行）
    .add_edge("b", "d")        # b → d
    .add_edge("c", "d")        # c → d（b 和 c 在 d 汇合）
    .add_edge("d", END)        # d → 结束
    .compile()
)

result = graph.invoke({})
print(result)
# 节点A运行中，已访问节点: []
# 节点B运行中，已访问节点: ['a']
# 节点C运行中，已访问节点: ['a']       ← b 和 c 接收到相同参数，证实并行
# 节点D运行中，已访问节点: ['a', 'b', 'c']
# {'nodes': ['a', 'b', 'c', 'd']}
```

> **注意**：并行节点同时修改 State 同一字段时，该字段**必须有自定义 Reducer**，否则冲突报错。

**条件边**：接收三个参数：
- `node_a`：当前节点（边的起点）
- `router`：路由函数，返回值决定下一节点名
- `mapping`（可选）：返回值与节点名不一致时的映射

```python
from typing import TypedDict, Literal
from langgraph.constants import START, END
from langgraph.graph import StateGraph

# =================== 1. 定义 State ===================
class RouteState(TypedDict):
    score: int
    result: str

# =================== 2. 定义 Node ===================
def scorer(state: RouteState):
    return {"score": state["score"]}  # 打分节点（此处简化，实际可从外部获取分数）

def pass_node(state: RouteState):
    return {"result": "通过！"}

def fail_node(state: RouteState):
    return {"result": "不通过"}

# =================== 3. 定义路由函数：根据 score 决定走 pass 还是 fail ===================
def router(state: RouteState) -> Literal["pass", "fail"]:
    if state["score"] >= 60:
        return "pass"   # 返回 "pass"，Graph 将跳转到 pass 节点
    return "fail"        # 返回 "fail"，Graph 将跳转到 fail 节点

# =================== 4. 创建 Graph ===================
graph = (
    StateGraph(RouteState)
    .add_node("scorer", scorer)
    .add_node("pass", pass_node)
    .add_node("fail", fail_node)
    .add_edge(START, "scorer")                       # 开始 → scorer
    .add_conditional_edges("scorer", router)          # scorer → 条件路由（返回值决定下一节点）
    .add_edge("pass", END)                            # 通过 → 结束
    .add_edge("fail", END)                            # 不通过 → 结束
    .compile()
)

result = graph.invoke({"score": 85, "result": ""})
print(result)  # {'score': 85, 'result': '通过！'}
```

**Command 实现条件分支**：不想写独立的条件边时，可以在 Node 内部通过 `Command` 同时指定状态更新和跳转目标：

```python
from typing import TypedDict, Literal
from langgraph.constants import START, END
from langgraph.graph import StateGraph
from langgraph.types import Command

class RouteState(TypedDict):
    score: int
    result: str

# scorer 节点自己负责路由，返回值类型声明为 Command[Literal["pass", "fail"]]
def scorer(state: RouteState) -> Command[Literal["pass", "fail"]]:
    score = state["score"]
    goto = "pass" if score >= 60 else "fail"
    return Command(
        update={"score": score},   # 更新 State 中的分数字段
        goto=goto                  # 指定跳转到的下一个节点
    )

def pass_node(state: RouteState):
    return {"result": "通过！"}

def fail_node(state: RouteState):
    return {"result": "不通过"}

# 注意：使用 Command 后，scorer 不需要 add_conditional_edges，直接 add_edge 即可
graph = (
    StateGraph(RouteState)
    .add_node("scorer", scorer)
    .add_node("pass", pass_node)
    .add_node("fail", fail_node)
    .add_edge(START, "scorer")   # 开始 → scorer（由 Command 控制跳转）
    .add_edge("pass", END)
    .add_edge("fail", END)
    .compile()
)
```

---

## 三、用 LangGraph 构建 Agent

### 3.1 基础 LLM 调用工作流

最简单的 Agent：一个 LLM 节点，接收用户输入，返回模型响应。

```python
from typing import TypedDict
from langchain.chat_models import init_chat_model
from langgraph.constants import START, END
from langgraph.graph import StateGraph
from dotenv import load_dotenv

load_dotenv()

# =================== 0. 初始化 LLM 模型 ===================
llm = init_chat_model(
    'deepseek-v4-flash',                              # 模型名称
    extra_body={'thinking': {'type': 'disabled'}}      # 关闭思考模式（deepseek 特有参数）
)

# =================== 1. 定义 State：记录用户输入和 LLM 返回结果 ===================
class SimpleAgentState(TypedDict):
    user_input: str    # 用户输入的问题
    result: str        # LLM 生成的回答

# =================== 2. 定义 Node：调用 LLM 并更新 State ===================
def call_llm(state: SimpleAgentState):
    response = llm.invoke(state['user_input'])         # 调用模型，传入用户输入
    return {'result': response.text}                    # 将模型回答写入 State 的 result 字段

# =================== 3. 创建 Graph ===================
builder = StateGraph(SimpleAgentState)
builder.add_node('llm', call_llm)                      # 注册 LLM 节点
builder.add_edge(START, 'llm')                         # 开始 → LLM 节点
builder.add_edge('llm', END)                           # LLM 节点 → 结束
graph = builder.compile()

# =================== 4. 执行 Graph ===================
result = graph.invoke({'user_input': '你好', 'result': ''})
print(result)
# {'user_input': '你好', 'result': '你好！很高兴见到你，有什么我可以帮你的吗？'}
```

### 3.2 消息历史（add_messages 与 MessagesState）

实际 Agent 需要记录多轮交互的完整消息列表。LangGraph 提供了 `add_messages` Reducer 和内置的 `MessagesState`。

**自定义消息 State**：用 `Annotated[list[BaseMessage], add_messages]` 实现消息追加而非覆盖：

```python
from typing import Annotated, TypedDict
from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages
from langchain.chat_models import init_chat_model
from langgraph.constants import START, END
from langgraph.graph import StateGraph

llm = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})

# =================== 1. 定义 State：messages 字段使用 add_messages Reducer，实现消息累积 ===================
class MessageAgentState(TypedDict):
    messages: Annotated[list[BaseMessage], add_messages]

# =================== 2. 定义 Node：将消息列表发给 LLM，AI 回复追加到 State ===================
def call_llm(state: MessageAgentState):
    response = llm.invoke(state['messages'])            # 传入完整消息历史给模型
    return {"messages": [response]}                      # 返回模型回复，add_messages Reducer 会自动追加到历史

# =================== 3. 创建并执行 ===================
graph = (
    StateGraph(MessageAgentState)
    .add_node('llm', call_llm)
    .add_edge(START, 'llm')
    .add_edge('llm', END)
    .compile()
)

from langchain_core.messages import SystemMessage, HumanMessage
result = graph.invoke({
    "messages": [
        SystemMessage(content="你扮演火箭队的武藏，以她的口吻回答问题"),  # 系统提示词
        HumanMessage(content="你是谁？")                                  # 用户消息
    ]
})
# 返回结果包含完整历史：[SystemMessage, HumanMessage, AIMessage]
```

**使用内置 MessagesState**：LangGraph 预定义了 `MessagesState`，等价于 `TypedDict + Annotated[list[AnyMessage], add_messages]`，无需自定义：

```python
from langgraph.graph import StateGraph, MessagesState
from langchain_core.messages import HumanMessage, SystemMessage

# 直接使用 MessagesState，无需自定义 State 类
def call_llm(state: MessagesState):
    response = llm.invoke(state['messages'])
    return {"messages": [response]}

graph = (
    StateGraph(MessagesState)       # 使用内置 MessagesState
    .add_node('llm', call_llm)
    .add_edge(START, 'llm')
    .add_edge('llm', END)
    .compile()
)

result = graph.invoke({
    "messages": [
        SystemMessage(content="你扮演火箭队的武藏，以她的口吻回答问题"),
        HumanMessage(content="你是谁？")
    ]
})
```

### 3.3 会话记忆（Checkpointer）

有了历史不等于有记忆。记忆必须基于 **会话 id**（`thread_id`）分别管理会话历史，靠 LangGraph 的 `Checkpointer` 实现。

```python
from langchain_core.messages import HumanMessage
from langchain.chat_models import init_chat_model
from langgraph.constants import START, END
from langgraph.graph import StateGraph, MessagesState
from langgraph.checkpoint.memory import InMemorySaver

llm = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})

def call_llm(state: MessagesState):
    response = llm.invoke(state['messages'])
    return {"messages": [response]}

# =================== 创建 Graph 时传入 Checkpointer ===================
graph = (
    StateGraph(MessagesState)
    .add_node('llm', call_llm)
    .add_edge(START, 'llm')
    .add_edge('llm', END)
    .compile(checkpointer=InMemorySaver())   # 指定 InMemorySaver 作为 Checkpointer
)

# =================== 通过 config 传递 thread_id 实现会话隔离 ===================
config = {"configurable": {"thread_id": "1"}}   # 通过 thread_id 隔离不同会话

# 第一轮对话
result = graph.invoke(
    {"messages": [HumanMessage("你好，我是虎哥")]},
    config
)

# 第二轮对话（LLM 记得之前的上下文）
result = graph.invoke(
    {"messages": [HumanMessage("记得我是谁吗?")]},
    config
)

for message in result['messages']:
    message.pretty_print()
# LLM 回答：当然记得，你是虎哥！
```

### 3.4 Streaming（流式输出）

LangGraph 的 streaming 方式与 LangChain Agent 一致，使用 `stream_events` 逐 token 输出：

```python
from langchain.chat_models import init_chat_model
from langchain_core.messages import HumanMessage
from langgraph.constants import START, END
from langgraph.graph import MessagesState, StateGraph

llm = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})

def call_llm(state: MessagesState):
    response = llm.invoke(state['messages'])
    return {'messages': [response]}

graph = (
    StateGraph(MessagesState)
    .add_node('llm', call_llm)
    .add_edge(START, 'llm')
    .add_edge('llm', END)
    .compile()
)

# =================== 使用 stream_events 代替 invoke，实现流式输出 ===================
stream = graph.stream_events(
    {'messages': [HumanMessage(content='你是谁？')]},
    version='v3'       # 流式事件的 API 版本
)

for message in stream.messages:
    for chunk in message.text:
        print(chunk, end='', flush=True)    # 逐 token 打印，flush=True 确保即时输出
```

### 3.5 带工具调用的 Agent 工作流

Agent = 绑定工具的 LLM，采用 ReAct 模式：推理（Reasoning）→ 行动（Action）→ 观察（Observation）循环。

**手动实现完整版**：

```python
from typing import Literal
from langchain.chat_models import init_chat_model
from langchain.tools import tool
from langchain_core.messages import HumanMessage, ToolMessage
from langgraph.constants import START, END
from langgraph.graph import StateGraph, MessagesState
from dotenv import load_dotenv

load_dotenv()

# =================== Step 1: 定义工具 ===================
@tool
def get_weather(city: str) -> str:
    """获取城市天气信息"""
    weather_data = {
        "北京": "晴天 25度",
        "上海": "多云 28度",
        "杭州": "小雨 22度",
    }
    return weather_data.get(city, f"未找到{city}的天气信息")

# 工具列表和工具名→工具函数的映射（用于根据 AI 返回的 tool_calls 找到对应工具）
tools = [get_weather]
tools_by_name = {t.name: t for t in tools}

# =================== Step 2: 准备模型，绑定工具 ===================
model = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})
# bind_tools 让框架自动将工具描述拼接到请求中发给模型
model_with_tools = model.bind_tools(tools)

# =================== Step 3: 定义 Node ===================
def tool_node(state: MessagesState):
    """工具节点：解析 AI 返回的 tool_calls，逐个执行工具，封装为工具消息 返回"""
    message = state['messages'][-1]                   # 最后一条消息是模型返回的带工具调用的消息
    messages = []
    for tool_call in message.tool_calls:              # 遍历所有工具调用（可能有多个）
        _name = tool_call['name']                     # 工具名称
        _args = tool_call['args']                     # 工具参数
        _id = tool_call['id']                         # 调用编号（用于关联返回结果）
        result = tools_by_name[_name].invoke(_args)  # 通过名称映射找到工具并执行
        messages.append(ToolMessage(content=result, tool_call_id=_id))  # 封装为工具消息
    return {'messages': messages}

def llm_node(state: MessagesState):
    """LLM 节点：调用模型，模型可选择调用工具或直接回答"""
    response = model_with_tools.invoke(state["messages"])
    return {"messages": [response]}

# 路由函数：检查 AI 回复中是否有 tool_calls，有则去工具节点，没有则结束
def should_continue(state: MessagesState) -> Literal["tools", "END"]:
    last_message = state["messages"][-1]
    if hasattr(last_message, 'tool_calls') and last_message.tool_calls:
        return 'tools'    # 有工具调用 → 跳转到工具节点执行
    return END             # 无工具调用 → 结束，返回模型最终回答

# =================== Step 4: 构建 Graph ===================
# 核心结构：LLM → 条件路由 → (工具 → LLM) 循环
graph = (
    StateGraph(MessagesState)
    .add_node("llm", llm_node)                        # 注册 LLM 节点
    .add_node("tools", tool_node)                     # 注册工具节点
    .add_edge(START, "llm")                           # START → llm
    .add_conditional_edges("llm", should_continue)    # llm → 条件路由（判断是否需要工具）
    .add_edge("tools", "llm")                         # tools → llm（工具执行后回到 LLM 继续判断）
    .compile()
)

# =================== Step 5: 调用 ===================
result = graph.invoke({
    "messages": [HumanMessage(content="北京和杭州今天天气怎么样？")]
})
for m in result['messages']:
    m.pretty_print()
```

**使用预定义节点简化**：LangGraph 提供 `ToolNode`（内置工具执行逻辑）和 `tools_condition`（内置路由判断），可以大幅简化代码：

```python
from langgraph.prebuilt import ToolNode, tools_condition

# ToolNode(tools) 替代手写的 tool_node
# tools_condition 替代手写的 should_continue
graph = (
    StateGraph(MessagesState)
    .add_node("llm", llm_node)
    .add_node("tools", ToolNode(tools))               # 预定义工具执行节点
    .add_edge(START, "llm")
    .add_conditional_edges("llm", tools_condition)     # 预定义路由：有 tool_calls → tools，否则 → END
    .add_edge("tools", "llm")                          # 工具执行后回到 LLM
    .compile()
)
```

### 3.6 Runtime Context（运行时上下文）

Runtime Context 是一次请求中可共享的上下文信息，通常用来传递配置信息、用户敏感信息。Node 函数通过 `runtime` 参数访问。

```python
from langchain.chat_models import init_chat_model
from langchain_core.messages import HumanMessage
from langgraph.constants import START, END
from langgraph.graph import MessagesState, StateGraph
from langgraph.runtime import Runtime
from pydantic.dataclasses import dataclass

# =================== Step 1: 定义运行上下文 Schema ===================
@dataclass
class ContextSchema:
    thinking: str = "enabled"   # 控制是否开启思考模式

# =================== Step 2: 初始化模型（不在这里指定思考参数，交给 Context 控制） ===================
llm = init_chat_model("deepseek-v4-flash")

# =================== Step 3: 定义 Node，通过 runtime.context 读取上下文 ===================
def call_llm(state: MessagesState, runtime: Runtime[ContextSchema]):
    # 通过运行时上下文动态控制思考模式开关
    response = llm.invoke(
        state['messages'],
        extra_body={"thinking": {"type": runtime.context.thinking}}
    )
    return {"messages": [response]}

# =================== Step 4: 创建图时指定上下文结构 ===================
builder = StateGraph(MessagesState, context_schema=ContextSchema)
builder.add_node('llm', call_llm)
builder.add_edge(START, 'llm')
builder.add_edge('llm', END)
graph = builder.compile()

# =================== Step 5: 调用时传递上下文 ===================
result = graph.invoke(
    {"messages": [HumanMessage(content="你是谁？")]},
    context=ContextSchema(thinking='enabled')   # 传入上下文配置，控制思考模式
)
print(result)
```

---

## 四、Workflow 编排模式

### 4.1 七种核心编排模式

LangGraph 的核心能力是用图的方式灵活编排任意复杂的工作流，常见的七种模式：

| 模式 | 说明 | 分类 |
|---|---|---|
| Prompt Chaining | 顺序链式，前一步输出作为后一步输入 | LLM 嵌入预定义工作流 |
| Parallelization | 并行执行多个任务 | LLM 嵌入预定义工作流 |
| Orchestrator-Worker | 编排器分配任务给 worker | LLM 控制工作流 |
| Evaluator-Optimizer | 评估器评估结果并优化 | LLM 控制工作流 |
| **Routing** | 根据输入动态路由到不同处理节点 | LLM 控制工作流 |
| Agent | LLM 自主控制工作流 | LLM 控制工作流 |
| Human-in-the-Loop | 人工介入关键节点 | 辅助模式 |

### 4.2 Routing 路由模式

路由本质是条件分支，让 Graph 根据输入动态选择下一节点。典型场景：
- 智能客服：识别问题类型 → 路由到售前/退款/退货
- 知识问答：识别知识领域 → 路由到对应专业节点

```python
from typing import Literal, TypedDict
from langchain.chat_models import init_chat_model
from langchain_core.messages import HumanMessage, AIMessage
from langgraph.graph import StateGraph, MessagesState, START, END

llm = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})

# =================== 1. 定义 State（继承 MessagesState，额外记录意图） ===================
class IntentState(MessagesState):
    intent: str    # 存储意图识别结果：weather / translate / chat

# =================== 2. 定义工作节点 ===================
def intent_node(state: IntentState):
    """意图识别节点：让模型判断用户意图"""
    intent = llm.invoke(f'''
    根据用户的请求判断用户意图，可选意图：weather、translate或chat。
    user_query: {state['messages'][-1].content}
    ''')
    return {'intent': intent.content}                   # 将识别到的意图写入状态

def weather_node(state: IntentState):
    """天气查询节点（此处简化为固定返回）"""
    return {'messages': [AIMessage(content='晴 25度')]}

def translate_node(state: IntentState):
    """翻译节点：调用模型翻译用户输入"""
    result = llm.invoke(f'''
    按照用户要求翻译，只输出翻译结果，不要任何解释。
    user_query:{state['messages'][-1].content}
    ''')
    return {'messages': [result]}

def chat_node(state: IntentState):
    """闲聊节点：直接把消息历史发给模型"""
    result = llm.invoke(state['messages'])
    return {'messages': [result]}

# =================== 3. 路由函数：根据 intent 决定跳转哪个工作节点 ===================
def intent_router(state: IntentState) -> Literal['weather', 'translate', 'chat']:
    return state['intent']    # 返回意图名称，图自动跳转到对应节点

# =================== 4. 创建 Graph ===================
builder = StateGraph(IntentState)
builder.add_node('intent', intent_node)
builder.add_node('weather', weather_node)
builder.add_node('chat', chat_node)
builder.add_node('translate', translate_node)

builder.add_edge(START, 'intent')                              # START → intent（先做意图识别）
builder.add_conditional_edges('intent', intent_router)         # 意图识别 → 条件路由
builder.add_edge('weather', END)
builder.add_edge('chat', END)
builder.add_edge('translate', END)
routing_graph = builder.compile()

# =================== 5. 测试 ===================
for q in ['今天北京天气如何？', '倍儿爽用英文怎么说', '你好']:
    r = routing_graph.invoke({'messages': [HumanMessage(content=q)]})
    print(f"'{q}' -> intent={r['intent']} -> {r['messages'][-1].content}")
```

### 4.3 Sub-graph 子图嵌套

复杂工作流可拆分为多层子图。LangGraph 支持将已编译的子图作为父图的一个 Node 使用。

**两种方式**：

| 方式 | API | 特点 |
|---|---|---|
| 直接嵌入 | `add_node("name", compiled_subgraph)` | 子图作为节点，checkpoint 与父图集成，interrupt 自动冒泡，共享 State |
| 包装调用 | 普通 node 函数内 `subgraph.invoke()` | 灵活的状态映射，需手动传递数据，父子不共享 State |

**直接嵌入 — 状态共享规则**：
- **父→子**：父图自动将共享 key 的值传给子图（input projection）
- **子→父**：子图返回的 key 如果父图也有，按**父图的 reducer** 写回
- 父子图 State 完全不同时，必须用包装调用

**直接嵌入示例**（在 Routing 基础上将天气查询改为子图）：

```python
from typing import Literal, TypedDict
from langchain.chat_models import init_chat_model
from langchain_core.messages import HumanMessage, AIMessage
from langgraph.graph import StateGraph, START, END, MessagesState
from langchain.tools import tool
from langgraph.prebuilt import ToolNode, tools_condition

llm = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})

# =================== 子图部分：天气 Agent ===================
# 子图 State：继承 MessagesState，额外有 foo 字段（演示与父图不同的字段）
class WeatherState(MessagesState):
    foo: str

@tool
def get_weather(city: str) -> str:
    """获取城市天气"""
    weather_data = {"北京": "晴天 25度", "上海": "多云 28度", "杭州": "小雨 22度"}
    return weather_data.get(city, f"未找到{city}的天气信息")

model = init_chat_model('deepseek-v4-flash', extra_body={'thinking': {'type': 'disabled'}})
model_with_tools = model.bind_tools([get_weather])

def llm_node(state: WeatherState):
    response = model_with_tools.invoke(state["messages"])
    return {"messages": [response], 'foo': 'foo'}    # 写入 foo 字段

# 构建子图
weather_agent = (
    StateGraph(WeatherState)
    .add_node("llm", llm_node)
    .add_node("tools", ToolNode([get_weather]))
    .add_edge(START, "llm")
    .add_conditional_edges("llm", tools_condition)
    .add_edge("tools", "llm")
    .compile()
)

# =================== 父图部分：意图路由 ===================
class IntentState(MessagesState):
    intent: str     # 父图独有字段

def intent_node(state: IntentState):
    intent = llm.invoke(f'''
    根据用户的请求判断用户意图，可选意图：weather、translate或chat。
    user_query: {state['messages'][-1].content}
    ''')
    return {'intent': intent.content}

def translate_node(state: IntentState):
    result = llm.invoke(f'翻译：{state["messages"][-1].content}')
    return {'messages': [result]}

def chat_node(state: IntentState):
    result = llm.invoke(state['messages'])
    return {'messages': [result]}

def intent_router(state: IntentState) -> Literal['weather', 'translate', 'chat']:
    return state['intent']

# 构建父图，子图 weather_agent 作为父图的 "weather" 节点
graph = (
    StateGraph(IntentState)
    .add_node('intent', intent_node)
    .add_node('weather', weather_agent)     # 子图直接作为节点
    .add_node('chat', chat_node)
    .add_node('translate', translate_node)
    .add_edge(START, 'intent')
    .add_conditional_edges('intent', intent_router)
    .add_edge('weather', END)
    .add_edge('chat', END)
    .add_edge('translate', END)
    .compile()
)

# 子图共享 messages 字段，子图内的工具调用消息也会出现在父图历史中
result = graph.invoke({'messages': [HumanMessage(content='杭州天气如何？')]})
```

**包装调用示例**（父子 State 不共享，手动传递）：

```python
# 在父图 Node 函数内手动调用子图，手动提取结果
def handle_weather(state: IntentState):
    human_message = state['messages'][-1]                      # 从父图状态取出用户消息
    result = weather_agent.invoke({'messages': [human_message]})  # 手动调用子图
    ai_message = result['messages'][-1]                         # 手动从子图结果提取模型回复
    return {'messages': [ai_message]}                           # 手动写回父图状态

# 包装调用作为普通节点注册
builder = StateGraph(IntentState)
builder.add_node('classify', classify_intent)
builder.add_node('weather', handle_weather)   # 注意：这里传的是函数，不是 compiled_subgraph
```

> **关键区别**：直接嵌入时，子图的完整消息历史（包括工具调用）会自动合并到父图；包装调用时，只传回最后一条 AI 消息，子图历史不进入父图。

可用 `graph.get_graph(xray=True)` 查看子图内部结构。





