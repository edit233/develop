---
title: FastAPI 应用与路由
tags: [FastAPI, 大类, 应用入口, 路由, 依赖注入, CORS]
created: 2026-08-09
---

## 概述
FastAPI 应用骨架标准写法：应用入口与生命周期、路由组织、跨域配置、依赖注入。本大类全部为可复用标准代码，需要按项目填写的参数均用中文注释标明。

## 应用入口与 Lifespan
标准完整代码（`main.py`）：
```python
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


@asynccontextmanager
async def lifespan(app: FastAPI):
    """应用生命周期：yield 之前=启动逻辑，yield 之后=关闭逻辑"""
    # 启动时执行：验证数据库连接、加载模型、初始化缓存等
    # 示例：await check_database()
    yield
    # 关闭时执行：释放连接池、关闭客户端等
    # 示例：await close_database()


app = FastAPI(
    title="应用名称",        # 应用名称，显示在 Swagger 文档标题
    description="应用描述",  # 应用描述（可选）
    version="0.1.0",        # 版本号（可选）
    debug=False,            # 是否开启调试模式（生产环境必须 False）
    lifespan=lifespan,      # 绑定生命周期管理器
)

# 注册各业务模块路由（每个模块一个 APIRouter，见下方小节）
app.include_router(业务模块.router)
app.include_router(用户模块.router)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",      # 应用导入路径：模块名:app（按需替换）
        host="0.0.0.0",  # 监听地址，0.0.0.0 表示监听所有网卡
        port=8000,       # 监听端口
        reload=True,     # 开发时热重载；生产环境必须 False
    )
```

## CORS 跨域配置
标准完整代码：
```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:5173"],  # 允许访问的来源列表（前端地址），"*" 表示全部
    allow_credentials=True,                   # 是否允许携带 Cookie；与 "*" 不能同时使用
    allow_methods=["*"],                      # 允许的 HTTP 方法，"*" 表示全部（GET/POST/PUT/DELETE...）
    allow_headers=["*"],                      # 允许的请求头，"*" 表示全部
)
```

## APIRouter 路由组织
标准完整代码（业务模块 `router.py`）：
```python
from fastapi import APIRouter

router = APIRouter(
    prefix="/api/v1/资源名",  # URL 统一前缀，例如 /api/v1/products
    tags=["分组标签"],        # Swagger 文档中的分组名
)


@router.get("")               # 完整路径 = prefix + "" → GET /api/v1/资源名
async def 列表接口():
    ...


@router.get("/{资源_id}")     # 路径参数：完整路径 → GET /api/v1/资源名/1
async def 详情接口(资源_id: int):
    ...


@router.post("")              # 创建接口
async def 创建接口():
    ...
```

> **`@router.get("")` 路径为空的原因**
> `APIRouter` 通过 `prefix` 已经定义了完整前缀（如 `/api/v1/claims`），路由装饰器里的路径是相对路径，拼在 prefix 后面。所以 `@router.get("")` 的完整路径就是 `/api/v1/claims`，不需要重复写前缀。

主入口注册（`main.py`）：
```python
from 业务模块 import router as 业务模块_router

app.include_router(业务模块_router)  # 挂载该模块全部接口
```

## 依赖注入与参数注入
标准完整代码：
```python
from typing import Annotated, Optional
from uuid import UUID

from fastapi import Depends, Header, Path, Query

# 1. 依赖工厂：供接口函数注入（组装 Service、连接等）
async def get_service(基础依赖: 类型 = Depends(...)):
    return 组装好的对象  # 例如 Service(session)


# 2. 接口中声明依赖与参数
@router.get("/example/{资源_id}")
async def example(
    资源_id: Annotated[int, Path(ge=1)],                          # 路径参数，ge=最小值校验
    用户_id: Annotated[int, Header(alias="x-user-id")],           # 从请求头取值，alias 指定头名
    page: Annotated[int, Query(default=1, ge=1)],                 # 查询参数，default=默认值
    service: 类型 = Depends(get_service),                         # 依赖注入
):
    ...
```

> **`Query(None, ...)` 的含义**
> `Query(None, ...)` 表示该查询参数**可选**，默认值为 `None`。不传该参数时值为 `None`，在业务逻辑中可用于跳过该筛选条件。示例：
> ```python
> 分类: Annotated[Optional[str], Query(None, description="按分类筛选")]
> ```
> 对应过滤逻辑：
> ```python
> if 分类 is not None:
>     conditions.append(Model.分类 == 分类)
> ```

## 参考
- [FastAPI 生命周期事件](https://fastapi.tiangolo.com/zh/advanced/events/)
- [FastAPI CORS](https://fastapi.tiangolo.com/zh/tutorial/cors/)
- [FastAPI 依赖注入](https://fastapi.tiangolo.com/zh/tutorial/dependencies/)
- [FastAPI 更大应用结构](https://fastapi.tiangolo.com/zh/tutorial/bigger-applications/)