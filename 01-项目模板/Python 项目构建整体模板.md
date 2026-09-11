---
title: Python 项目构建整体模板
tags: [项目模板, Python, FastAPI, uv, 后端, MOC]
created: 2026-09-11
category: 项目模板
---

# Python 项目构建整体模板

> 从零搭建一个 **FastAPI 异步后端项目** 的完整模板。综合 AgentService / FastAPIProject 两个项目的实战结构，涵盖：项目初始化 → 目录结构 → 核心骨架代码 → 业务模块 → Agent 能力 → 部署。每个环节的详细写法见对应知识笔记，本文只保留**最小可用的骨架**。

## 一、技术选型总览

| 领域 | 选型 | 说明 |
|------|------|------|
| 包管理 | **uv** | 替代 pip/poetry，极速且锁版本（清华源） |
| Web 框架 | **FastAPI** + uvicorn | 异步、自动文档、依赖注入 |
| 数据校验/配置 | **Pydantic v2** + pydantic-settings | 分层 .env 配置 |
| ORM | **SQLAlchemy 2.0**（异步） | asyncpg（PostgreSQL）/ aiomysql（MySQL） |
| 日志 | **structlog** | 彩色结构化日志 |
| 异常 | ApplicationError 体系 | 基类 + 模块异常 + 全局处理器 |
| 认证 | **PyJWT + pwdlib** | JWT（HS256）+ Argon2 密码哈希 |
| Agent（可选） | **LangChain + LangGraph** | create_agent + Checkpointer 记忆 + SSE 流式 |
| Python 版本 | **>=3.11** | 使用 `X | None` 新语法 |

## 二、项目初始化（uv）

```bash
# 1. 初始化项目（生成 pyproject.toml）
uv init 项目名
cd 项目名

# 2. 核心依赖
uv add fastapi "uvicorn[standard]"
uv add sqlalchemy asyncpg            # PostgreSQL；MySQL 换 aiomysql
uv add pydantic-settings python-dotenv
uv add structlog
uv add pyjwt "pwdlib[argon2]"

# 3. 按需添加
uv add langchain langchain-deepseek   # Agent 能力
uv add langgraph-checkpoint-postgres "psycopg[binary,pool]"
uv add alem<|code_suffix|>-------------
1. 检查数据库连接（必须最先：连不上直接失败启动）
2. 初始化 Checkpointer 连接池（有 Agent 时）
3. 初始化 Agent，挂载 app.state.agent
yield（应用运行）
4. 关闭 Checkpointer → 5. 关闭数据库连接池
```

## 六、业务模块（六文件标准模板）

每个业务模块独立成包，复制即用：

```
modules/模块名/
├── models.py       # ORM 表模型
├── schemas.py      # 请求/响应 Pydantic 模型
├── repository.py   # 数据访问层（只写 SQLAlchemy 查询）
├── service.py      # 业务层（事务边界、业务规则、抛异常）
├── router.py       # HTTP 层（参数解析、依赖注入）
└── exceptions.py   # 业务异常（可选）
```

依赖注入链：`get_session`（基础设施）→ `get_模块_service`（router 工厂）→ 接口函数。

完整六文件模板见 → [[业务模块标准写法]]

## 七、Agent 能力（可选模块）

需要 AI 智能体时，在标准骨架上追加：

| 组件 | 说明 | 详细笔记 |
|------|------|----------|
| `agents/advisor.py` | `create_agent` 组装模型+工具+提示词+记忆 | [[标准智能体可复用模板]] |
| `agents/tools.py` | `@tool` 工具函数（同步纯逻辑 / async 数据库） | [[标准智能体可复用模板]] |
| `agents/schemas.py` | `AgentContext` 运行时上下文（后端注入 user_id） | [[标准智能体可复用模板]] |
| `infra/checkpointer.py` | AsyncPostgresSaver 会话记忆连接池 | [[标准智能体可复用模板]] |
| `modules/chat/` | SSE 流式对话接口（astream_events v3） | [[SSE 流式响应]] |
| 模型接入 | OpenAI 兼容接口 / DeepSeek / Ollama | [[AI 接口集成]]、[[LangChain 全栈开发]] |

> Agent 的完整可复用模板（含全部代码）已沉淀为独立笔记：[[标准智能体可复用模板]]，直接复制改造即可。

## 八、部署

### Docker 多阶段构建（推荐）

```dockerfile
# ---- 构建阶段 ----
FROM python:3.12-slim AS builder
WORKDIR /app
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev            # 按锁文件安装依赖

# ---- 运行阶段 ----
FROM python:3.12-slim
WORKDIR /app
COPY --from=builder /app/.venv .venv
COPY app ./app
ENV PATH="/app/.venv/bin:$PATH"
CMD ["python", "-m", "app.main"]
```

容器化细节（数据卷、环境变量注入、Compose）见 → [[Docker 基础操作]]

### systemd 后台运行（裸机）

```ini
[Unit]
Description=Python 应用

[Service]
WorkingDirectory=/opt/项目目录
ExecStart=/opt/项目目录/.venv/bin/python -m app.main
Restart=always
User=www-data

[Install]
WantedBy=multi-user.target
```

模板见 → [[Linux 运维操作]]（含 uv 安装、yum 换源、systemctl 管理）

### Nginx 反向代理

对外暴露 80/443、转发到 uvicorn 端口、托管前端静态资源 → [[Nginx 部署实战]]

## 九、构建检查清单

- [ ] `uv sync` 一键还原依赖，`.env` 已加入 `.gitignore`
- [ ] `pyproject.toml` 声明 `requires-python = ">=3.11"`
- [ ] 配置全部来自 `.env`（[[Pydantic 配置与模型]] 分层配置），无硬编码密钥
- [ ] `main.py` 用 lifespan 管理资源，启动失败快速退出
- [ ] 业务异常统一继承 ApplicationError，全局处理器已注册
- [ ] 每个模块六文件齐全，写操作包裹在事务中
- [ ] 涉及用户数据的接口都做了归属校验（防越权）
- [ ] Windows 本机开发用 `python -m app.main` 启动（SelectorEventLoop）
- [ ] 生产：`reload=False`、`debug=False`、CORS 只放行真实前端地址
- [ ] 数据库迁移（Alembic）已配置或建表脚本已备

## 相关笔记

**模板组成**（本模板的每块拼图）：
- [[FastAPI 应用与路由]] —— 应用入口、CORS、APIRouter、依赖注入
- [[Pydantic 配置与模型]] —— .env 分层配置、请求/响应模型、泛型分页
- [[SQLAlchemy 异步操作]] —— 异步引擎、会话工厂、ORM 基类、分页与归属校验
- [[日志与异常处理]] —— structlog 配置、业务异常体系
- [[业务模块标准写法]] —— Router → Service → Repository 六文件模板
- [[用户认证与鉴权]] —— JWT、密码哈希、Bearer 认证依赖
- [[SSE 流式响应]] —— 流式输出（AI 对话必需）
- [[标准智能体可复用模板]] —— Agent + 工具 + 记忆 + SSE 完整模板

**配套**：
- [[Java 项目构建整体模板]] —— Java 侧对照模板
- 实战来源项目：AgentService（保险 AI 智能体服务）与 FastAPIProject（AI 伴侣聊天应用）
- [[Docker 基础操作]] / [[Nginx 部署实战]] / [[Linux 运维操作]] —— 部署链路
- [[Git与GitHub-版本控制与远程同步]] —— 版本控制与自动部署
