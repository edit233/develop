---
title: LangChain-Milvus 集成
tags: [RAG, LangChain, Milvus, VectorStore, AI]
created: 2026-08-17
---

## 概述
LangChain 对 Milvus 做了 VectorStore 封装（`langchain_milvus.Milvus`），把向量模型、Milvus 连接、Schema/Index/Collection 创建、文档向量化与写入封装成统一接口。适合大多数 RAG 场景；需要深度定制（多模态、普通字段索引等）时用 pymilvus 官方客户端。

## 与官方客户端对比
LangChain 封装限制：混合检索仅支持稀疏+稠密两种模式、不支持多模态向量检索、不支持对普通字段加索引。对多数场景已够用。

## 环境准备
```bash
uv add langchain-milvus
```

## 初始化 VectorStore
初始化时 LangChain 自动完成：根据 Document 生成 Schema（`pk` 主键、`text` 原文、向量字段、metadata 展开为普通字段）、自动给向量字段加索引、创建 Collection。

```python
from langchain_milvus import Milvus, BM25BuiltInFunction
from langchain_ollama import OllamaEmbeddings

embeddings = OllamaEmbeddings(
    model="qwen3-embedding:0.6b",  # 性价比高的向量模型
    dimensions=1024,               # 向量维度
)

vectorstore = Milvus(
    embeddings,                                  # 向量模型
    collection_name="langchain_collection",       # collection 名称
    builtin_function=BM25BuiltInFunction(
        analyzer_params={"type": "chinese"}       # 中文分词，生成稀疏向量
    ),
    vector_field=["dense", "sparse"],            # 稠密+稀疏两个向量字段
    connection_args={"uri": "http://127.0.0.1:19530"},
    drop_old=True,                                # 删除旧 collection，避免重复创建
)
```

## 添加 / 删除文档
```python
# 新增：自动完成向量化 + 写入
vectorstore.add_documents(docs)

# 删除：按 id 集合
vectorstore.delete([468439912009399490])
```

注意：
- 自定义 id 必须是**字符串**类型（LangChain 要求）
- 不指定 id 时由 Milvus 自动生成（INT64 类型，`auto_id=True`）

## 检索
用法与普通 VectorStore 一致，额外支持混合检索和融合策略。`similarity_search_with_score` 返回 `list[tuple[Document, float]]`。

### 参数
- `query`：查询条件
- `k`：返回文档数量
- `ranker_type`：重排策略，仅 `weighted`、`rrf`
- `ranker_params`：重排参数
  - `weighted` → `{"weights": [0.4, 0.6]}`
  - `rrf` → `{"k": 60}`

⚠️ Collection 一旦设定稀疏向量，LangChain 默认自动开启**加权混合检索**，必须传入混合检索参数，否则报错。

### 加权混合检索
```python
result = vectorstore.similarity_search_with_score(
    query,
    ranker_type="weighted",
    ranker_params={"weights": [0.4, 0.6]},
)
```

### RRF 混合检索
```python
result = vectorstore.similarity_search_with_score(
    query,
    ranker_type="rrf",
    ranker_params={"k": 60},
)
```

### 过滤检索（expr 与 Milvus 表达式一致）
```python
result = vectorstore.similarity_search_with_score(
    query,
    ranker_type="rrf",
    ranker_params={"k": 60},
    expr='h3 like "%代表人物%"',
)
```

### Cross-Encoder 重排（自定义 reranker）
LangChain 不支持用 `ranker_type` 指定 Cross-Encoder，改为直接传 `reranker`：
```python
from pymilvus import Function, FunctionType

def create_cross_encoder_ranker(queries: list[str]):
    return Function(
        name="dashscope_semantic_ranker",  # ranker 名称，唯一即可
        input_field_names=["text"],         # 原始文档字段
        function_type=FunctionType.RERANK,
        params={
            "reranker": "model",            # cross-encoder 模式
            "provider": "ali",
            "model_name": "gte-rerank-v2",
            "queries": queries,
            "max_client_batch_size": 5,
        },
    )

result = vectorstore.similarity_search_with_score(
    query,
    k=3,
    fetch_k=5,                               # 先召回更多再做精排
    expr='h2 like "%教育的功能%"',
    reranker=create_cross_encoder_ranker([query]),
)
```

## 参考
- [LangChain Milvus 集成](https://docs.langchain.com/oss/python/integrations/vectorstores/milvus)
- [Milvus 官方文档](https://milvus.io/docs/zh/home)
