---
title: Milvus 全栈操作
tags: [RAG, 向量数据库, Milvus, pymilvus, 混合检索, RRF, Cross-Encoder, 大类, AI]
created: 2026-08-17
---

## 概述
Milvus 是 Zilliz 开发的开源高性能向量数据库（Apache 2.0），用于存储和检索大规模向量数据，是生产环境 RAG 的主流选择。本文覆盖 Milvus 的部署模式、核心概念与 Schema、数据类型与索引、pymilvus 客户端操作（Collection / Entity 增删改查）、稠密/稀疏向量检索，以及混合检索融合重排（加权、RRF、Cross-Encoder）。

---

# 基础概念

## 为什么需要 Milvus
测试阶段常用 `InMemoryVectorStore`（内存向量库），但生产环境需要企业级高性能向量库：支持大规模向量、分布式部署、混合检索（稠密+稀疏）与重排。

### 三种部署模式
| 模式 | 说明 | 适用场景 |
|---|---|---|
| Milvus Lite | Python 库，轻量版 | Jupyter Notebook 原型、边缘设备 |
| Milvus Standalone | 单服务器，组件打包进单个 Docker 镜像 | 中小规模生产环境 |
| Milvus Distributed | Kubernetes 云原生架构，组件冗余 | 数十亿向量级别 |

## 核心概念（与 MySQL 类比）
| Milvus | MySQL | 含义 |
|---|---|---|
| Collection | Table | 一组结构相同的数据集合 |
| Field | Column | 描述数据的某个属性（标题、文本、向量） |
| Entity | Row | Collection 中的一条完整数据 |
| Schema | 建表 DDL | 定义 Field 的名称、数据类型和属性 |
| Index | 字段索引 | 提高检索速度 |

使用 Milvus 与 MySQL 类似：定义 Schema（约束）→ 配置 Index（索引）→ 创建 Collection（建表）。

## Schema 字段属性
| 适用场景 | 属性 | 说明 |
|---|---|---|
| 通用 | `field_name` | 字段名称 |
| 通用 | `datatype` | 数据类型 |
| 通用 | `description` | 字段说明 |
| 主键 | `is_primary` | 是否为主键 |
| 主键 | `auto_id` | 是否自动生成主键 |
| 字符串 | `max_length` | 字符串最大长度 |
| 向量 | `dim` | 向量维度 |
| 数组 | `element_type` / `max_capacity` | 元素类型 / 最多元素数量 |

### 常用数据类型
- `VARCHAR`：字符串，必须设置 `max_length`
- `INT32` / `INT64`：数字，通用属性即可
- `ARRAY`：数组，需设置 `element_type` 和 `max_capacity`
- `FLOAT_VECTOR`：稠密向量，需设置 `dim`
- `SPARSE_FLOAT_VECTOR`：稀疏向量，无需 `dim`

## 稠密向量与稀疏向量
### 稠密向量
- 由 Embedding 模型生成（如 `qwen3-embedding:0.6b` → 1024 维），大部分位置有值
- 基于语义检索：意思相近即可命中，即使措辞不同、有错别字也可能匹配
- 弱点：产品名、疾病名、条款编号等专有名词需要精确匹配时不稳定（一字之差意思完全不同）

### 稀疏向量
- 基于词表：词表有几万~几十万词，文档中出现的词在对应位置给权重，其余位置为 0
- 维度极高但绝大多数位置是 0，因此只存非零位置与权重，如 `{3: 0.9, 4: 0.6, 5: 0.7}`
- 擅长关键词精确匹配（人名、地名、专有名词、编号）

### 词条权重获取方式
| 方式 | 算法 | 特点 |
|---|---|---|
| 统计式 | BM25、TF/IDF | 计算资源少、速度快，Milvus 内置 BM25 实现 |
| 学习式 | BGE-M3、SPLADE | 需 GPU 训练，带一定语义分析，理解更强 |

## 索引类型
| 数据类型 | 常见索引 | 用途 |
|---|---|---|
| 稠密向量 | `AUTOINDEX`、`HNSW`、`IVF_FLAT` | 加速向量相似度检索 |
| 稀疏向量 | `SPARSE_INVERTED_INDEX` | 加速稀疏向量检索 |
| 标量字段 | `INVERTED`、`BITMAP` | 条件过滤，缩小检索范围 |

三类索引配合使用：先用普通字段索引过滤缩小范围，再用稠密向量索引匹配语义、稀疏向量索引匹配关键词。稠密与稀疏是互补关系，常同时使用（混合检索）。

---

# 数据操作与检索

## 环境准备
### 安装依赖
```bash
uv add pymilvus
```

### 配置
`.env` 配置连接地址，config 中组合 URL：
```env
MILVUS_HOST=192.168.150.101
MILVUS_PORT=19530
```
```python
class RAGSettings(EnvSettings):
    milvus_host: str = Field(alias="MILVUS_HOST", default="127.0.0.1")
    milvus_port: int = Field(alias="MILVUS_PORT", default=19530)

    @computed_field
    @property
    def milvus_url(self) -> str:
        return f"http://{self.milvus_host}:{self.milvus_port}"
```

### 连接客户端
```python
from pymilvus import MilvusClient

client = MilvusClient(uri="http://192.168.150.101:19530")
```

## Collection 操作
创建 Collection 分 3 步：定义 Schema → 定义 Index → `create_collection`。

### 定义 Schema
文档切片常见字段：
- `id`：INT64 主键
- `dense`：FLOAT_VECTOR，dim=1024（稠密向量）
- `sparse`：SPARSE_FLOAT_VECTOR（稀疏向量，由 BM25 函数自动生成）
- `h2`：VARCHAR(128)（过滤用元数据）
- `content`：VARCHAR(2048)，开启中文分词

关键点：稀疏向量不手动生成，而是配置 Milvus 内置 BM25 Function，存储和检索阶段自动转换：
- `input_field_names`：原始文档字段（如 `content`）
- `output_field_names`：稀疏向量字段（如 `sparse`）
- 输入字段必须配置 `enable_analyzer=True` 与 `analyzer_params={"type": "chinese"}`

```python
from pymilvus import Function, FunctionType, DataType

schema = client.create_schema(
    auto_id=False,               # 不自动生成 id
    enable_dynamic_field=False,  # 不允许动态字段
)
schema.add_field(field_name="id", datatype=DataType.INT64, is_primary=True)
schema.add_field(field_name="dense", datatype=DataType.FLOAT_VECTOR, dim=1024)
schema.add_field(field_name="sparse", datatype=DataType.SPARSE_FLOAT_VECTOR)
schema.add_field(field_name="h2", datatype=DataType.VARCHAR, max_length=128)
schema.add_field(
    field_name="content",
    datatype=DataType.VARCHAR,
    max_length=2048,
    enable_analyzer=True,                # 允许分词，转 BM25 稀疏向量
    analyzer_params={"type": "chinese"}, # 中文分词
)
bm25_function = Function(
    name="text_bm25_emb",
    input_field_names=["content"],
    output_field_names=["sparse"],
    function_type=FunctionType.BM25,
)
schema.add_function(bm25_function)
```

### 定义索引 + 创建 Collection
```python
index_params = client.prepare_index_params()
# 稠密向量索引
index_params.add_index(
    field_name="dense",
    index_type="AUTOINDEX",
    metric_type="COSINE",  # COSINE / IP
)
# 稀疏向量索引
index_params.add_index(
    field_name="sparse",
    index_type="SPARSE_INVERTED_INDEX",
    metric_type="BM25",  # BM25 / IP
)
# 普通字段索引（过滤加速）
index_params.add_index(field_name="h2", index_type="AUTOINDEX")

client.create_collection(
    collection_name="my_collection_1",
    schema=schema,
    index_params=index_params,
)
```

### 查看 / 删除 Collection
```python
res = client.list_collections()  # ['my_collection_1']
client.drop_collection(collection_name="my_collection_1")
```

## Entity 操作
Entity 是 dict，可单个或 list 批量。

### insert
先向量化文档（只生成稠密向量，稀疏由 BM25 函数自动生成）：
```python
from langchain_ollama import OllamaEmbeddings

embeddings = OllamaEmbeddings(model="qwen3-embedding:0.6b", dimensions=1024)
vectors = embeddings.embed_documents([doc.page_content for doc in docs])

data = [
    {
        "id": i + 1,
        "content": doc.page_content,
        "h2": doc.metadata.get("h2", ""),
        "dense": vectors[i],
    }
    for i, doc in enumerate(docs)
]
res = client.insert(collection_name, data)
# {'insert_count': 21, 'ids': [1, 2, ..., 21]}
```

### upsert（更新或新增）
先按 id 删除旧的再插入：id 存在=更新，id 不存在=新增。
```python
data1 = data[0]
data1['h2'] = "测试一下"  # 模拟更新
data2 = data[1]
data2['id'] = 88           # 模拟新增
res = client.upsert(collection_name, [data1, data2])
# {'upsert_count': 2, 'ids': [1, 88]}
```

### delete
```python
res = client.delete(collection_name, ids=[88])
# {'delete_count': 1, 'cost': 0}
```

## 检索 Search
`client.search` 是向量相似性检索核心接口，使用 ANN（近似近邻）算法：
- kNN：与向量空间中所有向量逐一比较，耗时耗资源
- ANN：借助索引文件快速定位可能相似的子组，再在子组内按度量类型排序取 Top-K

### search 参数速查
| 参数 | 作用 | 必填 |
|---|---|---|
| `collection_name` | 目标集合名 | 是 |
| `data` | 查询向量（单个或多个批量） | 是 |
| `anns_field` | 向量字段名 | 通常必填 |
| `limit` | Top-K 数量 | 是 |
| `search_params` | `metric_type`（必须与索引一致）、`offset`（分页）、`radius`/`range_filter`（范围搜索） | 否 |
| `filter` | 向量搜索前执行的标量过滤表达式 | 否 |
| `output_fields` | 需要返回的字段（默认只返回 id 和 score） | 否 |
| `order_by_fields` | 按标量字段排序覆盖相似度排序 | 否 |
| `ids` | 用主键 ID 替代 data（与 data 互斥） | 否 |

注意：`limit + offset <= 16384`；`ids` 与 `data` 互斥。

### 稠密向量检索
```python
def dense_search(query: str):
    query_vector = embeddings.embed_query(query)  # 先把问题向量化
    res = client.search(
        collection_name=collection_name,
        anns_field="dense",
        data=[query_vector],
        limit=3,
        search_params={"metric_type": "COSINE"},  # 必须和索引一致
        output_fields=["content", "h2"],
    )
    for hits in res:
        for hit in hits:
            print(hit)
```
擅长语义相似查询（模糊措辞也能命中），不擅长专有名词精确匹配。

### 稀疏向量检索
```python
def sparse_search(query: str):
    res = client.search(
        collection_name=collection_name,
        data=[query],        # 直接传原始文本，BM25 函数自动转向量
        anns_field="sparse",
        limit=3,
        output_fields=["content", "h2"],
    )
    for hits in res:
        for hit in hits:
            print(hit)
```
擅长专有名词/关键词精确匹配，不擅长语义分析。

## 过滤
过滤表达式是普通字符串，语法接近 MySQL where：
```python
filter = 'id == 1'
filter = 'id >= 1'
filter = 'title like "%重疾险%"'
filter = 'id in [11, 20, 30]'
```
- [Milvus 基础操作符](https://milvus.io/docs/zh/basic-operators.md)
- 数组字段过滤语法特殊：[数组数据类型](https://milvus.io/docs/zh/array_data_type.md)

---

# 混合检索与重排

## 为什么需要混合检索
| 检索方式 | 擅长 | 弱点 |
|---|---|---|
| 稠密检索 | 语义接近的内容 | 可能错过专业名词、关键词 |
| 稀疏检索 | 专有名词、关键词 | 语义分析弱，措辞不同就检索不到 |

## 混合检索流程
1. **多路召回**：用稀疏、稠密等方式分别查询，得到多个结果集
2. **融合重排**：把所有结果融合为一个列表，重新打分排序

## 三种融合重排方式对比
| 方式 | 原理 | 特点 |
|---|---|---|
| 加权求和 | 分数归一化后按权重合并 | 依赖分数归一化，权重可调 |
| RRF | 倒数排名求和，只与排名有关 | 无需归一化，计算简单 |
| Cross-Encoder | 神经网络对 query-document 对精确打分 | 精度最高，成本最高 |

## 加权融合
给各路召回分配权重，文档最终得分 = Σ(各路得分 × 各路权重)。例：稠密权重 0.6、稀疏权重 0.4，则 `0.5*0.6 + 0.8*0.4 = 0.62`。

**必须归一化分数**：不同检索体系打分尺度不同（BM25 通常 0~10+，余弦相似度 0~1），直接加权会被大尺度检索器主导。常见归一化方法：
| 方法 | 公式 | 特点 |
|---|---|---|
| Min-Max | (score - min) / (max - min) | 值固定 [0,1]，计算简单 |
| Z-Score | (score - avg) / std | 转为均值 0、标准差 1 的正态分布 |
| Softmax | e^s / Σe^s | 转为概率分布，总和为 1 |

## RRF（Reciprocal Rank Fusion，倒数排名融合）
核心公式：`RRF(d) = Σ 1 / (k + rank_r(d))`
- `d`：某个文档；`k`：常量（通常 60）；`rank_r(d)`：文档在第 r 路结果中的排名（从 1 开始）

特点：无需归一化（与分数无关）、对离群值不敏感、计算简单、可融合任意数量检索列表；缺点：对排名靠后的文档不敏感、无法利用得分/置信度、所有检索源权重相同。

## Cross-Encoder（交叉编码）
### Bi-Encoder vs Cross-Encoder
| | Bi-Encoder | Cross-Encoder |
|---|---|---|
| 处理方式 | 问题、文档分别编码为向量再比较 | 问题和文档一起输入模型精确打分 |
| 速度 | 快（文档离线向量化，可处理百万级） | 慢（需实时逐对计算） |
| 精度 | 略差 | 高 |
| 用途 | 初筛 | 精排 |

稀疏/稠密检索都属于 Bi-Encoder（初筛），筛选结果再交给 Cross-Encoder 模型精排。常用 Reranker 模型：Qwen3-Reranker-4B、mxbai-rerank-large-v2、bge-reranker-v2-m3、jina-reranker-v3、ms-marco-MiniLM-L6-v2、ColBERT v2。

### Milvus 重排流程
应用发送查询 → Milvus 混合检索召回候选 → Rerank 模型评估（query, document）对 → 按语义相关性分数重排 → 返回结果。

### 模型提供商
vLLM / TEI（自部署）、Cohere / Voyage AI / SiliconFlow / DashScope / Hugging Face（云服务）。DashScope 方案需要 Milvus 3.x。

### DashScope 配置
在 Milvus 部署中配置 API Key（如 `deploy/milvus/user.yaml`）：
```yaml
credential:
  dashscope_apikey:
    apikey: sk-xxxxxxx
```
然后 `docker compose restart milvus`。

## Milvus 实现：混合检索
基本步骤：创建多路请求（AnnSearchRequest）→ 配置融合策略（ranker）→ `hybrid_search`。

### 通用混合检索函数
```python
from pymilvus import AnnSearchRequest

def hybrid_search(query: str, ranker, filter_query: str = None):
    # 1.稠密请求
    query_dense_vector = embeddings.embed_query(query)
    dense_request = AnnSearchRequest(
        data=[query_dense_vector],
        anns_field="dense",
        param={"metric_type": "COSINE"},
        limit=3,
        filter=filter_query,
    )
    # 2.稀疏请求（直接传文本，BM25 自动转向量）
    sparse_request = AnnSearchRequest(
        data=[query],
        anns_field="sparse",
        param={"metric_type": "BM25"},
        limit=3,
        filter=filter_query,
    )
    reqs = [dense_request, sparse_request]

    # 3.融合重排
    res = client.hybrid_search(
        collection_name=collection_name,
        reqs=reqs,
        ranker=ranker,
        limit=2,
        output_fields=['content', 'h2'],
    )
    for hits in res:
        print("TopK results:")
        for hit in hits:
            print(hit)
```

### 加权融合
```python
from pymilvus import WeightedRanker

ranker = WeightedRanker(0.5, 0.5)
hybrid_search("教育的负面作用是什么", ranker)
```

### RRF 融合
```python
from pymilvus import RRFRanker

ranker = RRFRanker(k=60)
hybrid_search("教育的负面作用是什么", ranker)
```

### Cross-Encoder 重排（RERANK Function）
Function 定义是固定代码，变化的只有 provider / model_name：
```python
from pymilvus import Function, FunctionType

def create_cross_encoder_ranker(queries: list[str]):
    return Function(
        name="dashscope_semantic_ranker",  # ranker 名称，唯一即可
        input_field_names=["content"],      # 原始文档字段
        function_type=FunctionType.RERANK,  # 固定值
        params={
            "reranker": "model",            # model = cross-encoder 模式
            "provider": "ali",              # 模型提供商
            "model_name": "gte-rerank-v2",  # rerank 模型名称
            "queries": queries,             # 查询条件
            "max_client_batch_size": 5,     # 单批次最大文档数
        },
    )

def cross_encoder_hybrid_search(query: str):
    ranker = create_cross_encoder_ranker([query])
    hybrid_search(query, ranker)
```

---

## 参考
- [Milvus 官方文档](https://milvus.io/docs/zh/home)
- [Milvus Lite](https://milvus.io/docs/zh/milvus_lite.md)
- [Milvus Standalone 安装](https://milvus.io/docs/zh/install_standalone-docker.md)
- [Milvus Distributed](https://milvus.io/docs/zh/install_cluster-milvusoperator.md)
- [Index Explained](https://milvus.io/docs/zh/index-explained.md)
- [稀疏向量](https://milvus.io/docs/zh/v2.6.x/sparse_vector.md)
- [Milvus 基础操作符](https://milvus.io/docs/zh/basic-operators.md)
- [数组数据类型](https://milvus.io/docs/zh/array_data_type.md)
- [vLLM Ranker](https://milvus.io/docs/zh/vllm-ranker.md)
- [Cohere Ranker](https://milvus.io/docs/zh/cohere-ranker.md)
- [DashScope Ranker](https://milvus.io/docs/zh/dashscope-ranker.md)
- [SiliconFlow Ranker](https://milvus.io/docs/zh/siliconflow-ranker.md)
