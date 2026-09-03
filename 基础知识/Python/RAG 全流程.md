---
title: RAG 全流程
tags: [RAG, 大类, 检索增强生成, Agent, 检索, AI]
created: 2026-08-15
---

## 概述
RAG（Retrieval-Augmented Generation，检索增强生成）是解决 LLM 知识局限的核心技术：通过检索加载额外的知识片段作为上下文，增强 LLM 的生成回答。本大类覆盖完整 RAG 流程：为什么需要 RAG、外挂知识库与知识切分、语义检索与向量相似度、向量数据库选型、RAG 核心流程（离线/在线）、LangChain RAG 组件映射、RAG Agent 架构、三种 RAG 架构选型（2-Step RAG、Agentic RAG、Hybrid）。

---

## 一、为什么需要 RAG（LLM 的局限）
LLM 的能力全部来自训练数据，存在两个天然局限：
- **知识局限性**：对于训练数据未覆盖的专业领域（如某公司自家的保险条款），模型无法给出正确答案。
- **时间局限性**：训练数据是历史数据（例如 DeepSeek 训练数据截止于 2026 年），无法回答实时问题。

如果强行回答未知问题，模型只能"一本正经地胡说八道"，这就是**幻觉（Hallucination）**。

## 二、RAG 的核心思想
### 外挂知识库
把 LLM 不知道的知识作为提示词的一部分发送给它，模型就能基于提示词中的知识回答用户问题：
- 例如 AI 保险客服不知道保险合同条款，提问时把公司全部保险条款 + 用户问题一起作为提示词发给模型。

### 知识切分（为什么不能把整个知识库塞进上下文）
把整个知识库直接塞进提示词有两个问题：
- **可能超出上下文限制**：最大上下文窗口约 1M token，而企业文档数据量可能达到 GB 级。
- **浪费 Token、成本高**：每次提问都携带全部内容，Token 越多收费越贵。

解决办法：**把知识库切分成一个个知识片段（chunk）**，用户提问时**只携带与问题相关的知识片段**。这样既不会超出上下文，Token 也少、成本低。

## 三、知识检索：语义检索
知识库切成大量片段后，难点变成：**如何找到与用户问题语义相关的片段**。

全文检索（如 Elasticsearch 关键字匹配）的局限：用户问"我得过肝炎，能买这款产品吗？"，语义是问**承保范围**，关键字检索很难命中对应条款。因此必须基于**语义分析**检索。

### 向量相似度
模型理解语言的方式是 Word Embedding：把词转为多维向量，映射到多维空间中，方向与大小代表不同语义。
- 检索时把**用户问题（一句话）转为向量**，把**知识片段（一段话）转为向量**，通过比较向量相似度判断语义是否接近。
- 好的向量模型会让**语义相近的文本在向量空间中距离更近**。

常见的向量距离度量：
- **余弦相似度（Cosine similarity）**：两个向量之间的夹角，最常用。
- **欧氏距离（Euclidean distance）**：两点之间的直线距离。
- **点积（Dot product）**：一个向量在另一个向量上的投影量。

距离越近，相似度越高（距离值越小，相似度越高）。

### 向量数据库
向量数据库的两个核心作用：
- **存储**向量数据（知识片段及其向量）。
- 基于**相似度检索**向量数据（知识片段）。

企业常用向量数据库分三类：

**新兴专用向量数据库**
| 数据库 | 核心特点 | 典型企业场景 |
|---|---|---|
| Pinecone | 全托管、无需运维、索引优化强 | 不想管理基础设施的 SaaS 公司、初创企业 |
| Milvus | 最流行的开源向量数据库，支持多种索引、混合查询 | 有数据安全要求、需要自建/私有化部署的中大型企业 |
| Qdrant | Rust 编写，性能极高，支持丰富的过滤条件（Payload） | 需要复杂元数据过滤的场景（电商、社交推荐） |
| Weaviate | 内置 ML 模型（可直接向量化），支持 GraphQL | 希望简化数据预处理、使用 GraphQL 的团队 |
| Chroma | 轻量级、嵌入式使用（类似 SQLite），与 LangChain 集成最紧密 | 原型验证、AI 应用快速开发、个人/小团队项目 |

**传统数据库集成向量功能**
| 产品 | 向量功能特点 | 常见用途 |
|---|---|---|
| Elasticsearch | `dense_vector` 字段 + `knn` 查询支持向量搜索 | 已有 ES 集群、日志+向量混合搜索 |
| Pgvector（PostgreSQL 扩展） | 最流行的关系型向量扩展，支持精确/近似搜索 | 以 PostgreSQL 为主、不想引入新组件 |
| Redis | RediSearch 模块提供向量相似度搜索 | 超低延迟（缓存级）、实时推荐 |
| ClickHouse | 余弦/欧氏距离函数支持向量检索 | OLAP 大规模数据分析+向量检索 |

**选型建议**：企业开发首推 **Milvus**（性能最好且开源免费）；个人测试用 **Milvus lite**（不支持 Windows）或 **Chroma**（都支持本地嵌入）。

## 四、RAG 核心流程（离线阶段）
RAG 名字的含义：**检索**（利用向量相似度检索知识片段）+ **增强**（用检索到的知识片段增强模型、减少幻觉）+ **生成**（模型基于知识片段生成答案）。

### 离线阶段（构建知识库）
1. **知识加载**：读取各种来源的知识数据，解析、清洗，形成文档（Documents）。
2. **知识切分**：把清洗后的文档切分成知识片段（Chunks）。
3. **向量化**：用向量模型把知识片段转为向量，使语义相近的文本在向量空间中彼此邻近。
4. **存储向量**：把向量及对应知识片段存入向量数据库。

### LangChain 组件映射
| RAG 步骤 | LangChain 组件 |
|---|---|
| 文档加载 | Document Loaders |
| 知识切分 | Text Splitters |
| 向量化 | Embeddings 接口（兼容各类向量模型） |
| 存储/检索 | VectorStore 接口（兼容各类向量数据库） |

## 五、RAG 代码预览（最小闭环）
先安装依赖：
```bash
uv add langchain-ollama langchain-text-splitters langchain-community pypdf
```

完整流程代码：
```python
from langchain_text_splitters import CharacterTextSplitter
from langchain_core.vectorstores import InMemoryVectorStore
from langchain.chat_models import init_chat_model
from langchain_ollama import OllamaEmbeddings
from langchain_community.document_loaders import PyPDFLoader
from dotenv import load_dotenv

load_dotenv()

# ===============一、构建知识库阶段====================
# 1.加载文档：mode="single" 表示整个 PDF 作为一个 Document
loader = PyPDFLoader(file_path="resources/贵州茅台研报.pdf", mode="single")
docs = loader.load()

# 2.切分文档：按换行符切分，每块最大 800 字符，块间重叠 150 字符
splitter = CharacterTextSplitter(separator="\n", chunk_size=800, chunk_overlap=150)
chunks = splitter.split_documents(docs)
print(f"分块数量：{len(chunks)}")

# 3.向量化：本地 Ollama 向量模型
embeddings = OllamaEmbeddings(model="qwen3-embedding:0.6b", dimensions=1024)

# 4.存入向量库：from_documents 会自动调用向量模型完成向量化
vectorstore = InMemoryVectorStore.from_documents(chunks, embeddings)

# ===============二、在线问答阶段================
model = init_chat_model(
    "deepseek-v4-flash",
    extra_body={"thinking": {"type": "disabled"}},
)

def try_rag(query: str):
    # 1.检索文档（VectorStore 会自动把问题向量化，召回相关知识片段）
    retrieved_docs = vectorstore.similarity_search(query, k=2)
    # 2.拼接上下文提示词
    content = "\n\n".join(doc.page_content for doc in retrieved_docs)
    prompt = f"""你基于我提供的报告回答用户问题，报告中没提及的就说不知道，不要自己编造答案.
    report: ```{content}```
    query: {query}"""
    # 3.调用模型，生成答案
    response = model.invoke(prompt)
    return response.content

# ===============三、测试=================
print(try_rag("茅台收盘价多少"))
print('=' * 100)
print(try_rag("茅台2025年的市盈率和市净率是多少"))
```

**局限**：LangChain 组件能快速搭建 RAG 系统，但简单问题能答对、复杂问题（如报告里有数据却检索不到）说明检索质量仍需优化。想开发稳定可靠的 RAG 系统，需要逐一优化每个组件（见 [[文档加载与切分]]、[[向量化与向量库]]）。

---

## 六、RAG 在线阶段：Agent 架构
有了知识库之后，进入 RAG 的**在线阶段**：找出与用户问题最相关的知识片段，发送给模型生成增强答案。RAG 对话本质上就是**在每次调用模型前多了知识检索这一步**：
1. 用户提问
2. 根据问题检索知识片段
3. 把知识片段与问题拼接，形成提示词
4. 调用模型，生成答案

标准代码（检索 + 拼接提示词 + 生成）：
```python
from dotenv import load_dotenv
from langchain.chat_models import init_chat_model

load_dotenv()

# 1.用户提问
query = "论语中教育的目的"

# 2.根据问题检索知识片段
documents = vector_store.similarity_search(query)

# 3.把知识片段与问题拼接，形成提示词
# 3.1.获取知识片段上下文
context = "\n".join([doc.page_content for doc in documents])
# 3.2.拼接提示词
prompt = f"""
你是一个教资考试专家，你需要根据提供的上下文回答用户的问题，不能自己编造答案。答案要简短，直接引用原文。
context: ```{context}```
query: ```{query}```
"""

# 4.调用模型，生成答案
model = init_chat_model(
    "deepseek-v4-flash",
    extra_body={"thinking": {"type": "disabled"}},
)
response = model.invoke(prompt)
print(response.content)
```

### 三种 RAG 架构选型
| 架构 | 介绍 | 可控性 | 扩展性 | 延迟 | 场景 |
|---|---|---|---|---|---|
| **2-Step RAG** | 每次调用模型前都做知识检索，流程简单、可控 | 高 | 低 | 快 | FAQs、文档问答机器人 |
| **Agentic RAG** | 由 LLM 思考何时进行知识检索 | 低 | 高 | 不定 | 绑定了很多工具的研究助手 |
| **Hybrid** | 结合两者特点，并加入答案验证环节 | 中 | 中 | 不定 | 回答质量要求高的特殊领域 |

## 七、2-Step RAG（了解）
严格遵循 RAG 流程，固化为两步：
1. **Retrieve**：检索知识库，返回知识片段。
2. **Generate**：基于知识片段增强 Prompt，调用模型生成答案。

简单说：**每次发送请求给 LLM 之前，都修改提示词，拼接检索到的知识片段**。

标准代码：
```python
from langchain.chat_models import init_chat_model
from app.core.config import settings

# 1.初始化模型
model = init_chat_model(
    "deepseek-v4-flash",
    api_key=settings.llm.api_key,
    extra_body={'thinking': {'type': 'disabled'}},
)

# 2.定义RAG函数
def rag_chat(user_input: str):
    # 1.拿到用户问题
    print("================User Message================")
    print(user_input, "\n")

    # 2.检索知识片段，返回 list[Document]
    docs = vector_store.similarity_search(user_input, k=2)
    context = "\n\n".join(doc.page_content for doc in docs)
    print('=============== Context ====================')
    print(context, "\n")

    # 3.拼接新提示词
    prompt = f'''
    你是一个教资考试专家，你根据文档回答用户问题，文档中没有的不要编造，直接说不知道。
    回答直接引用文档中原文，不要自己发挥！
    context: {context}
    query: {user_input}
    '''

    # 4.调用模型
    result = model.invoke(prompt)
    print("=================AI Message================")
    print(result.content)

# 测试
rag_chat("论语中教育的目的是什么？")
```

**缺点**：即使只是发送"你好"这样的问候，完整 RAG 流程也会照常执行、检索大量文档回来，浪费时间和资源。示例中问候"你好"也会检索出"经济与教育的关系"等无关文档。

## 八、Agentic RAG
**Agent 自主决定何时检索、检索什么、用不用其他工具**。实现方式：把检索器包装为 Tool，Agent 自主判断何时调用工具获取文档，甚至多次检索、多轮迭代。

**适用**：研究助手、复杂多步问答 —— 需要灵活组合多种能力的场景。

**优缺点**
| ✅ 好处 | ⚠️ 缺点 |
|---|---|
| 只在需要时搜索——问候、跟进、简单查询不触发不必要的搜索 | 两次 LLM 调用——搜索时一次生成查询、一次生成最终响应 |
| 上下文搜索查询——检索作为工具，LLM 可根据会话上下文自定义查询 | 可能失控——LLM 可能在需要时跳过搜索，或在不必要时额外搜索 |
| 允许多次搜索——LLM 可执行多个搜索寻找答案 | |

标准代码（检索器包装为 Tool + create_agent）：
```python
from langchain.agents import create_agent
from langchain.chat_models import init_chat_model
from langchain_core.messages import HumanMessage
from langchain_core.tools import tool
from app.core.config import settings

# 1.初始化模型
model = init_chat_model(
    "deepseek-v4-flash",
    api_key=settings.llm.api_key,
    extra_body={'thinking': {'type': 'disabled'}},
)

# 2.定义工具：把知识检索包装为 Tool
@tool
def retrieve_docs(query: str):
    """检索知识库，获取知识片段"""
    # 检索知识片段，返回 list[Document]
    docs = vector_store.similarity_search(query, k=2)
    # 拼接返回，不需要我们组织提示词，tool 结果会直接给模型
    return "\n\n".join(doc.page_content for doc in docs)

# 3.初始化 Agent，绑定模型和工具
agent = create_agent(
    model=model,
    tools=[retrieve_docs],
    system_prompt='''
    你是一个教资考试专家，你调用工具检索文档回答用户问题，文档中没有的不要编造，直接说不知道。
    回答直接引用文档中原文，不要自己发挥！
    ''',
)

# 4.调用 Agent
query = "论语中教育的目的是什么？"
response = agent.invoke({'messages': [HumanMessage(content=query)]})

for message in response['messages']:
    message.pretty_print()
```

调用过程：模型先发出 `retrieve_docs` 工具调用（参数为优化后的查询词，如"论语 教育目的"），拿到检索结果后生成最终答案。

流式调用（问候语不触发检索）：
```python
from langchain_core.messages import AIMessage

# 流式调用，stream_mode="messages"
response = agent.stream(
    {"messages": [{"role": "user", "content": "你好"}]},
    stream_mode="messages",
)

for chunk, metadata in response:
    if isinstance(chunk, AIMessage) and chunk.content:
        print(chunk.content, end="")
```

输出：`你好！有什么可以帮助你的吗？` —— Agent 判断"你好"无需检索，直接回答，节省了不必要的检索成本。

---

## 相关大类
- [[文档加载与切分]] —— 知识库构建第 1、2 步：加载与切分
- [[向量化与向量库]] —— 知识库构建第 3、4 步：向量化与存储检索
- [[LangChain 全栈开发]] —— create_agent、@tool 工具定义、astream_events 的完整用法
- [[Milvus 全栈操作]] —— BM25 稀疏向量、混合检索、重排序
- [[LangChain-Milvus 集成]] —— LangChain 的 Milvus VectorStore 封装

## 参考
- [LangChain 向量数据库集成文档](https://docs.langchain.com/oss/python/integrations/vectorstores)
- [阿里云百炼向量模型](https://bailian.console.aliyun.com/cn-beijing?tab=doc#/doc/?type=model&url=2842587)
- [MinerU PDF 解析](https://github.com/opendatalab/MinerU)
- [Milvus 重排序文档](https://milvus.io/docs/reranking.md)
- [LangChain Agent 官方文档](https://docs.langchain.com/oss/python/langchain/agents)
## 九、生产级 RAG 实践（父子块策略 + 混合检索 + 重排）

以上是最小闭环的 RAG 实现。生产环境需要更精细的策略来提升检索质量和上下文完整性。以下是一个完整的生产级 RAG 管道设计。

### 9.1 父子块策略（Parent-Child Chunk）

**核心思想**：子块小（~500字符），适合向量检索（精准匹配）；父块大（完整章节），适合 LLM 阅读（完整上下文）。检索时用子块定位，返回父块给 LLM。

```python
# =================== Step 1: PDF 解析为 Markdown ===================
from mineru import MinerU                                         # MinerU: PDF 文档解析工具，保留表格/公式/图片

mineru = MinerU()                                                # 初始化解析器
raw_markdown = await mineru.parse(file_path)                     # PDF → 原始 Markdown（保留结构）

# =================== Step 2: LLM 优化 Markdown ===================
from langchain.chat_models import init_chat_model                 # 模型初始化

model = init_chat_model(model="deepseek-chat", model_provider="deepseek", api_key=api_key)
response = await model.ainvoke(f"修正表格错乱、标题编号：\n{raw_markdown}")  # 修正格式问题

# =================== Step 3: 按标题切分为父块 ===================
from langchain_text_splitters import MarkdownHeaderTextSplitter    # 按 Markdown 标题层级切分

# 定义标题层级：哪些标题级别作为切分边界
headers_to_split = [
    ("#", 1), ("##", 2), ("###", 3)                              # 一级/二级/三级标题
]
splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split)
parent_chunks = splitter.split_text(markdown_text)               # 每个标题章节为一个父块

# =================== Step 4: 父块进一步切分为子块 ===================
from langchain_text_splitters import RecursiveCharacterTextSplitter  # 递归字符切分

child_splitter = RecursiveCharacterTextSplitter(
    chunk_size=500,                                               # 子块最大字符数
    chunk_overlap=100,                                            # 块间重叠字符数
)
child_chunks = []
for parent in parent_chunks:
    children = child_splitter.split_text(parent.page_content)
    for child in children:
        child_chunks.append({
            "content": child,
            "metadata": {"parent_id": parent.metadata["parent_id"]},  # 子块记录父块 ID
        })

# =================== Step 5: 双库存储 ===================
# 子块 → Milvus（含向量索引，用于检索）
# 父块 → PostgreSQL（含完整文本，用于回查）
```

### 9.2 BM25 稀疏向量（关键词检索）

纯向量检索对关键词匹配不敏感（如产品编号、专业术语）。BM25 作为稀疏向量补充关键词检索能力：

```python
from langchain_milvus import BM25BuiltInFunction, Milvus        # BM25 内置函数 + Milvus 客户端

# 初始化 Milvus —— 双字段混合检索：dense（语义向量）+ sparse（BM25 关键词向量）
_vector_store = Milvus(
    embedding_function=_embeddings,                               # 用于生成 dense 向量的 Embedding 模型
    collection_name="insurance_collection",                       # Milvus 集合名称
    builtin_function=BM25BuiltInFunction(
        analyzer_params={"type": "chinese"}                       # 中文分词器
    ),
    vector_field=["dense", "sparse"],                             # 双字段：dense + sparse
    connection_args={"uri": milvus_url},                          # Milvus 服务地址
    auto_id=True,                                                 # 由 Milvus 自动生成行 ID
)
```

### 9.3 Milvus 重排序函数（Function + RERANK）

混合检索召回大量候选后，用重排序模型二次筛选最相关的结果：

```python
from pymilvus import Function, FunctionType                       # Milvus 自定义函数

def create_reranker(query: str) -> Function:
    """创建 Milvus 重排序函数 —— 使用阿里云 gte-rerank-v2 模型"""
    return Function(
        name="dashscope_semantic_ranker",                         # 函数名称（Milvus 内部标识）
        input_field_names=["text"],                               # 输入字段：子块文本内容
        function_type=FunctionType.RERANK,                        # 函数类型：重排序
        params={
            "reranker": "model",                                  # 使用模型进行重排
            "provider": "ali",                                    # 提供商：阿里云 DashScope
            "model_name": "gte-rerank-v2",                        # 重排序模型名称
            "queries": [query],                                   # 查询文本（一条）
            "max_client_batch_size": 5,                           # 每批最多 5 个候选
        },
    )

# 使用：混合检索 + 重排
results = await vector_store.asimilarity_search(
    query=query,
    k=5,                                                          # 最终返回 5 个子块
    fetch_k=10,                                                   # 先召回 10 个候选，重排后取 top-5
    expr=f"product_id == {product_id}",                           # Milvus 过滤表达式（限定产品范围）
    reranker=create_reranker(query),                              # 重排序函数
)
```

### 9.4 父块回查（子块检索 → 父块获取）

```python
# 提取子块的 parent_id 并去重（多个子块可能属于同一父块）
parent_ids = list(dict.fromkeys(
    child.metadata["parent_id"] for child in results              # dict.fromkeys 保持顺序 + 去重
))

# 根据 parent_id 批量查询 PostgreSQL 获取父块完整内容
async with AsyncSessionFactory() as session:
    repository = ParentChunkRepository(session)
    parent_chunks = await repository.list_by_ids(parent_ids)      # SELECT * FROM parent_chunks WHERE id IN (...)

# 按子块召回顺序排列父块（SQL 不保证顺序，需手动排列）
parent_map = {str(p.id): p for p in parent_chunks}               # 构建 {id: chunk} 映射
ordered_parents = [
    parent_map[pid] for pid in parent_ids if pid in parent_map     # 按召回顺序 + 防止 KeyError
]
```
