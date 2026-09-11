# 开发知识库 · Dev Knowledge Base

> 一份按**内容**分类整理、相互交叉链接的开发学习知识库，基于 [Obsidian](https://obsidian.md) 构建，覆盖 **Python 全栈**、**Java 后端** 与 **AI / LLM 应用开发**。

![Notes](https://img.shields.io/badge/notes-40-4f46e5)
![Obsidian](https://img.shields.io/badge/Obsidian-vault-7c3aed)
![Python](https://img.shields.io/badge/Python-3.14-3776ab)
![Java](https://img.shields.io/badge/Java-SpringBoot%203.x-ed8b00)
![AI](https://img.shields.io/badge/AI-LangChain%20%7C%20LangGraph-10a37f)
![Links](https://img.shields.io/badge/dead%20links-0-22c55e)

---

## 📖 简介

这不是按语言目录或教材章节堆放的笔记，而是一套**按内容分类、互相引用**的知识体系：

- **40 篇笔记**，统一放在 `00-总导航 + 7 个分类目录` 下，找知识点不靠记忆靠导航；
- **每篇笔记**都有统一 frontmatter（`category`）与「相关笔记」交叉链接，顺着链接就能把一条技术链路走通；
- **两份项目构建整体模板**（Python / Java），从依赖管理到分层骨架再到部署，可直接作为新项目起点；
- 全库 wikilink 经过审计，**0 死链**。

## 📂 目录结构

```text
develop/
├── 00-知识库总导航.md      # 入口：全库索引 + 使用方式
├── 01-项目模板/           # Python / Java 项目构建整体模板
├── 02-Python语言基础/     # 语法、容器、函数、面向对象
├── 03-Python全栈开发/     # FastAPI + Pydantic + SQLAlchemy + 认证 + 日志
├── 04-AI与LLM/            # LangChain / LangGraph / MCP / RAG / Milvus
├── 05-Java/               # JavaSE + Maven + SpringBoot + MyBatis-Plus + AOP
├── 06-数据库/             # SQL 语言与常用函数统计技巧
└── 07-运维与部署/         # Docker / Git / Nginx / Linux / HTTP
```

## 🧭 内容概览

<details>
<summary><b>01-项目模板</b>（2 篇）—— 从零搭项目从这里开始</summary>

- **Python 项目构建整体模板** —— uv + FastAPI 分层骨架：初始化 → 目录结构 → 配置 → 数据库 → 认证 → Agent → 部署
- **Java 项目构建整体模板** —— Maven + SpringBoot 三层架构骨架：环境 → 创建 → 分包 → 配置 → MyBatis-Plus → 多模块 → 部署

</details>

<details>
<summary><b>02-Python语言基础</b>（5 篇）</summary>

- Python基础-数据类型与运算 —— 变量、数据类型、输入输出、运算符
- Python基础-流程控制 —— if/elif/else、while/for、break/continue、match-case
- Python基础-数据容器 —— list、tuple、str、set、dict，切片、推导式
- Python基础-函数与模块 —— 参数、作用域、lambda、模块导入、包结构
- Python基础-面向对象 —— 类、封装、继承、多态、鸭子类型

</details>

<details>
<summary><b>03-Python全栈开发</b>（7 篇）</summary>

- FastAPI 应用与路由 —— 应用入口、lifespan、CORS、APIRouter、依赖注入
- Pydantic 配置与模型 —— .env 分层配置、请求/响应模型、字段校验、泛型分页
- SQLAlchemy 异步操作 —— 异步引擎、会话工厂、ORM 基类、CRUD、分页、归属校验
- 日志与异常处理 —— structlog 结构化日志、ApplicationError 业务异常体系
- 业务模块标准写法 —— Router → Service → Repository 六文件标准模板
- 用户认证与鉴权 —— JWT、密码哈希（Argon2）、Bearer 认证依赖
- SSE 流式响应 —— EventSourceResponse 流式输出

</details>

<details>
<summary><b>04-AI与LLM</b>（10 篇）</summary>

- AI 接口集成 —— OpenAI 兼容接口、流式对话、Prompt 设计
- LangChain 全栈开发 —— 模型初始化、消息、结构化输出、Agent、工具、记忆
- LangGraph 工作流编排 —— State、Node、Edge、Sub-graph、Workflow
- MCP 集成 —— MCP 协议、MultiServerMCPClient、FastMCP 自定义服务
- 标准智能体可复用模板 —— Agent + 工具 + Context + Checkpointer + SSE 完整模板
- RAG 全流程 —— 检索增强生成、离线建库、在线问答、Agentic RAG
- 文档加载与切分 —— PyPDF / MinerU 加载、文本切分策略
- 向量化与向量库 —— Embeddings、VectorStore 统一接口
- Milvus 全栈操作 —— 基础概念、Schema、数据操作、混合检索、重排
- LangChain-Milvus 集成 —— VectorStore 封装、混合检索参数

</details>

<details>
<summary><b>05-Java</b>（8 篇）</summary>

- Java基础 - 基础语法、流程控制与方法
- Java面向对象全解 - 从基础到接口 —— 封装、继承、多态、抽象类、接口、内存划分
- JavaSE-容器与常用集合整理 —— Array、String、StringBuilder、List/Set/Map
- JavaSE-匿名内部类-Lambda-Stream-异常整理
- Maven-依赖管理与多模块构建 —— 坐标、依赖传递/冲突、聚合/继承
- SpringBoot-全栈开发笔记 —— 三层架构、IOC/DI、参数接收、Result、Logback、全局异常、事务
- MyBatisPlus-数据库操作与动态SQL —— CRUD、Wrapper、分页、动态 SQL、IService
- SpringBoot-AOP-面向切面编程与操作日志 —— 五种通知、切点表达式、操作日志落库

</details>

<details>
<summary><b>06-数据库</b>（2 篇）</summary>

- SQL 语言全解 —— DDL/DML/DQL/DCL、约束、连接查询、事务
- SQL 常用函数与统计技巧 —— 字符串/日期/条件函数、单行多状态计数、首页概览实战

</details>

<details>
<summary><b>07-运维与部署</b>（5 篇）</summary>

- Docker 基础操作 —— 镜像/容器、数据卷、Compose、多阶段构建
- Git与GitHub-版本控制与远程同步 —— 版本控制、SSH 认证、GitHub Actions
- Nginx 部署实战 —— 反向代理、静态资源、Docker 内 Nginx
- Linux 运维操作 —— 常用命令、vim、systemctl、systemd 脚本
- HTTP 基础 —— 请求/响应结构、方法、状态码、头部

</details>

## 🛠 技术栈

| 领域 | 技术 |
| --- | --- |
| **Python 语言** | Python 3.14、asyncio、uv |
| **Python 后端** | FastAPI、Pydantic v2 / pydantic-settings、SQLAlchemy 2.0（异步）、structlog、PyJWT、pwdlib（Argon2） |
| **AI / LLM** | LangChain、LangGraph、MCP、RAG、Milvus、Embeddings、SSE 流式输出 |
| **Java 后端** | JavaSE、Maven（聚合/继承）、SpringBoot 3.x、MyBatis-Plus、Lombok、Logback、AOP |
| **数据库** | MySQL、PostgreSQL、SQL 函数与统计技巧 |
| **运维部署** | Docker / Compose、Nginx、Linux（systemd）、Git / GitHub Actions、HTTP |

## 🚀 使用方式

```bash
git clone <repo-url>
```

用 **Obsidian** 打开该目录（Open folder as vault），然后：

1. 从 **`00-知识库总导航.md`** 开始 —— 全库索引与使用约定都在这里；
2. **从零搭项目** → `01-项目模板/` 下的 Python / Java 整体模板；
3. **查知识点** → 按分类目录进入，或用 Obsidian 的**关系图谱 / 反向链接 / 全局搜索**；
4. 直接用 GitHub / 任意 Markdown 编辑器阅读也可以，链接会以文本形式呈现。

## ✨ 整理特点

- ✅ **统一分类体系**：`00-总导航` + `01 ~ 07` 七个内容分类，新增笔记只需登记一行；
- ✅ **统一笔记规范**：frontmatter 带 `category`，文末统一「相关笔记」区块；
- ✅ **交叉链接网络**：相关知识点之间用 wikilink 互相引用，形成可漫游的知识图谱；
- ✅ **零死链**：全库链接定期审计，确保 40 篇笔记、240+ 链接全部可达；
- ✅ **可复用模板**：两份项目构建整体模板，把「踩过的坑」沉淀成标准骨架。

## 📝 说明

- 笔记为个人学习整理，内容会持续更新。

---

<p align="center"><i>Keep learning, keep shipping.</i></p>
