---
title: 知识库总导航
tags: [导航, 知识库, MOC]
created: 2026-09-11
---

# 知识库总导航

按**内容分类**组织的开发知识库，所有笔记跨项目复用。

## 目录结构

```
develop/
├── 00-知识库总导航.md      # 本文件
├── 01-项目模板/           # Python / Java 项目构建整体模板（从零搭项目从这里开始）
├── 02-Python语言基础/     # 语法、容器、函数、面向对象
├── 03-Python全栈开发/     # FastAPI + Pydantic + SQLAlchemy + 认证 + 日志
├── 04-AI与LLM/            # LangChain / LangGraph / MCP / RAG / Milvus
├── 05-Java/               # JavaSE 基础 + Maven + SpringBoot + MyBatis-Plus
├── 06-数据库/             # SQL 语言
└── 07-运维与部署/         # Docker / Git / Nginx / Linux / HTTP
```

## 项目模板（先看这里）

- [[Python 项目构建整体模板]] —— uv + FastAPI 分层骨架：初始化 → 目录结构 → 配置 → 数据库 → 认证 → Agent → 部署
- [[Java 项目构建整体模板]] —— Maven + SpringBoot 三层架构骨架：环境 → 创建 → 分包 → 配置 → MyBatis-Plus → 多模块 → 部署

## 02-Python语言基础

- [[Python基础-数据类型与运算]] —— 变量、数据类型、输入输出、运算符
- [[Python基础-流程控制]] —— if/elif/else、while/for、break/continue、match-case
- [[Python基础-数据容器]] —— list、tuple、str、set、dict，切片、推导式
- [[Python基础-函数与模块]] —— 参数、作用域、lambda、模块导入、包结构
- [[Python基础-面向对象]] —— 类、封装、继承、多态、鸭子类型

## 03-Python全栈开发

- [[FastAPI 应用与路由]] —— 应用入口、lifespan、CORS、APIRouter、依赖注入
- [[Pydantic 配置与模型]] —— .env 分层配置、请求/响应模型、字段校验、泛型分页
- [[SQLAlchemy 异步操作]] —— 异步引擎、会话工厂、ORM 基类、CRUD、分页、归属校验
- [[日志与异常处理]] —— structlog 结构化日志、ApplicationError 业务异常体系
- [[业务模块标准写法]] —— Router→Service→Repository 六文件标准模板
- [[用户认证与鉴权]] —— JWT、密码哈希、Bearer 认证依赖
- [[SSE 流式响应]] —— EventSourceResponse 流式输出

## 04-AI与LLM

- [[AI 接口集成]] —— OpenAI 兼容接口、流式对话、Prompt 设计
- [[LangChain 全栈开发]] —— 模型初始化、消息、结构化输出、Agent、工具、记忆
- [[LangGraph 工作流编排]] —— State、Node、Edge、Sub-graph、Workflow
- [[MCP 集成]] —— MCP 协议、MultiServerMCPClient、FastMCP 自定义服务
- [[标准智能体可复用模板]] —— Agent + 工具 + Context + Checkpointer + SSE 完整模板
- [[RAG 全流程]] —— 检索增强生成、离线建库、在线问答、Agentic RAG
- [[文档加载与切分]] —— PyPDF/MinerU 加载、文本切分策略
- [[向量化与向量库]] —— Embeddings、VectorStore 统一接口
- [[Milvus 全栈操作]] —— 基础概念、Schema、数据操作、混合检索、重排
- [[LangChain-Milvus 集成]] —— VectorStore 封装、混合检索参数

## 05-Java

- [[Java基础 - 基础语法、流程控制与方法]] —— 变量、数据类型、运算符、流程控制、方法
- [[Java面向对象全解 - 从基础到接口]] —— 封装、继承、多态、抽象类、接口、内存划分
- [[JavaSE-容器与常用集合整理]] —— Array、String、StringBuilder、List/Set/Map
- [[JavaSE-匿名内部类-Lambda-Stream-异常整理]] —— Lambda、Stream API、异常处理
- [[Maven-依赖管理与多模块构建]] —— 坐标、依赖传递/冲突、聚合/继承
- [[SpringBoot-全栈开发笔记]] —— 三层架构、IOC/DI、参数接收、Result、Logback、全局异常、事务
- [[MyBatisPlus-数据库操作与动态SQL]] —— CRUD、Wrapper、分页、动态 SQL、IService、自动填充
- [[SpringBoot-AOP-面向切面编程与操作日志]] —— AOP 概念、五种通知、切点表达式、操作日志落库

## 06-数据库

- [[SQL 语言全解]] —— DDL/DML/DQL/DCL、约束、连接查询、事务
- [[SQL 常用函数与统计技巧]] —— 字符串/日期/条件函数、单行多状态计数、首页概览实战

## 07-运维与部署

- [[Docker 基础操作]] —— 镜像/容器、数据卷、Compose、多阶段构建
- [[Git与GitHub-版本控制与远程同步]] —— 版本控制、SSH 认证、GitHub Actions
- [[Nginx 部署实战]] —— 反向代理、静态资源、Docker 内 Nginx
- [[Linux 运维操作]] —— 常用命令、vim、systemctl、systemd 脚本
- [[HTTP 基础]] —— 请求/响应结构、方法、状态码、头部

## 使用方式

1. **从零搭项目** → [[Python 项目构建整体模板]] / [[Java 项目构建整体模板]]
2. **查某个知识点** → 按上面分类找，或用 Obsidian 关系图谱/反向链接
3. **新增笔记** → 放入对应分类目录，并在本导航登记一行；新笔记末尾加"相关笔记"链接
