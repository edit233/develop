---
title: AI 接口集成
tags: [AI, 大类, OpenAI, SDK, 对话]
created: 2026-08-09
---

## 概述
OpenAI 兼容接口的标准调用方式（适用于 OpenAI、DeepSeek、小米 MiMo 等所有兼容 OpenAI 格式的服务）。参数处中文注明。

## 客户端初始化
标准完整代码：
```python
from openai import OpenAI

client = OpenAI(
    api_key="你的API密钥",     # 从环境变量/配置读取，不要硬编码进代码
    base_url="https://api.服务商.com/v1",  # 兼容接口地址（默认 OpenAI 官方，可省略）
)
```

## 对话调用（非流式）
标准完整代码：
```python
response = client.chat.completions.create(
    model="模型名称",  # 模型名，如 gpt-4o-mini / deepseek-chat / 各服务商模型 ID
    messages=[
        {"role": "system", "content": "系统提示词：设定角色与规则"},
        {"role": "user", "content": "用户输入"},
        {"role": "assistant", "content": "AI 上一条回复（多轮历史按顺序追加）"},
    ],
    stream=False,      # 非流式：等待完整回复后返回
    temperature=0.7,   # 随机性：0 最确定，越高越发散（可选）
    max_tokens=1024,   # 最大输出 token 数（可选）
)
answer = response.choices[0].message.content  # 提取回复文本
```

消息组装要点：
- `system` 放最前，设定角色与全局规则；
- 历史消息按时间顺序排列（user/assistant 交替）；
- 当前用户输入放最后。

## 对话调用（流式）
标准完整代码：
```python
stream = client.chat.completions.create(
    model="模型名称",
    messages=[...],  # 同上 messages 组装
    stream=True,     # 流式：逐块返回
)

for chunk in stream:
    piece = chunk.choices[0].delta.content  # 当前块的增量内容
    if piece:
        print(piece, end="")                # 逐块转发给前端 / 累积拼接
```

## System Prompt 模板设计
标准模板（按需填入角色信息）：
```text
你叫{角色名称}，请完全代入{角色设定}。
规则：
1. 每次只回 1 条消息
2. 禁止任何场景或状态描述性文字
3. 匹配用户的语言
4. 回复简短，像聊天一样
5. 可以用 emoji 表情
6. 用符合角色设定的方式对话
```

设计要点：明确角色身份 → 定义行为规则 → 限定回复风格 → 控制输出长度。

## 参考
- [OpenAI Python SDK](https://github.com/openai/openai-python)
- [Chat Completions API](https://platform.openai.com/docs/api-reference/chat)
