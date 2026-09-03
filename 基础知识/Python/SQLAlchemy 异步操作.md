---
title: SQLAlchemy 异步操作
tags: [SQLAlchemy, 大类, ORM, CRUD, 查询, 分页, 异步, 数据库]
created: 2026-08-09
---

> 前置知识：[[MySQL 基础操作]]（DDL/DML/DQL 基础、约束、数据类型）

## 概述
SQLAlchemy 2.0 完整参考：引擎与会话（同步/异步）、模型声明、增删改查、条件/排序/分页查询、连接池配置、FastAPI 依赖注入、ORM 时间戳混入、通用分页与归属校验。全部为可复用标准代码，参数处中文注明。

---

# 基础操作

## 引擎与会话工厂（同步）
标准完整代码：
```python
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

engine = create_engine(
    "mysql+pymysql://用户名:密码@主机:端口/数据库名",  # 数据库+驱动://用户名:密码@主机:端口/数据库名
    echo=True,  # 控制台打印 SQL（调试 True，生产 False）
)

session_factory = sessionmaker(engine)
```

## 模型声明
标准完整代码：
```python
from sqlalchemy import Integer, String
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class 模型名(Base):
    __tablename__ = "表名"  # 指定数据库表名

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True, comment="主键")
    名称: Mapped[str] = mapped_column(String(50), nullable=False, comment="字段注释")
    价格: Mapped[int] = mapped_column(Integer, nullable=False, comment="字段注释")

    def __repr__(self) -> str:
        return f"模型名(id={self.id}, 名称={self.名称})"


Base.metadata.create_all(engine)
```

- `Mapped[...]`：类型注解，`[]` 内写 Python 类型
- `mapped_column(...)`：描述数据库字段信息（类型、主键、自增、可空、注释等）
- 属性名 = 数据库列名

## 新增
标准完整代码：

说明：手动提交，需手动管理事务和连接释放。

```python
session = session_factory()
session.add(模型名(名称="值", 价格=100))  # 添加记录
session.commit()   # 提交事务
session.close()    # 释放连接
```

说明：上下文管理器（推荐），自动管理事务和连接。

```python
with session_factory() as session:          # 结束自动 close()
    with session.begin():                   # 正常自动 commit()，异常自动 rollback()
        session.add(模型名(名称="值", 价格=100))
```

## 查询三步
查询固定三步：**生成 SQL → 执行 → 收集结果**。
```python
from sqlalchemy import select

with session_factory() as session:
    sql = select(模型名)                # select(模型名) = SELECT * FROM 表
    result = session.execute(sql)  # 执行，sql 是生成器对象
    items = result.scalars().all()  # 收集结果
```

结果收集方法：
- `scalars().all()`：收集第一列，返回 list（查询模型对象时返回对象列表）
- `scalars().first()`：收集第 1 个结果，返回单个值
- `scalar_one()`：要求恰好 1 条，多条或 0 条会报错（适合按主键查）
- `mappings().all()`：每行转成 dict（RowMapping），查询部分字段时用

## session.execute() 统一执行入口
`session.execute()` 是 SQLAlchemy 2.0 执行 SQL 语句的统一入口：传入 statement 对象（select / insert / update / delete / text 原生 SQL），返回 Result 对象；写语句返回 CursorResult。
```python
from sqlalchemy import text

# 查询：Result 用 scalars() / mappings() 收集（见上方"查询三步"）
result = session.execute(select(模型名).where(模型名.id == 1))
item = result.scalar_one()   # 或 scalars().all() / mappings().all()

result = session.execute(delete(模型名).where(模型名.id == 1))
print(result.rowcount)  # 受影响行数

session.execute(text("UPDATE 表名 SET 价格 = 价格 - 100 WHERE id = 1"))
```
与 ORM 对象级操作（session.add / session.delete）的本质区别：execute() 直接执行 SQL 语句，**不经过 ORM 对象映射**，因此不触发 before_delete / after_delete 等 ORM 事件、不支持级联、不更新会话缓存（已缓存对象与数据库可能不一致）。

## 条件查询

按主键查单个：select + scalar_one()，简化写法 session.get(模型名, 1)。

批量 id 过滤：使用 in_() 匹配 id 列表中的任意值（等价 SQL IN)。

模糊匹配：使用 like() 配合 % 通配符进行模糊搜索。

多条件 AND：where 直接传多个条件默认 AND，也可用 and_() 显式连接。

多条件 OR：使用 or_() 连接多个条件，满足任一即匹配。

```python
from sqlalchemy import and_, or_, select

# 1. 按主键查单个
result = session.execute(select(模型名).where(模型名.id == 1)).scalar_one()
# 简化：session.get(模型名, 1)

# 2. 批量 id：in_()
ids = [1, 2, 3]
results = session.execute(
    select(模型名).where(模型名.id.in_(ids))
).scalars().all()

# 3. 模糊查询：like()
results = session.execute(
    select(模型名).where(模型名.名称.like("%关键词%"))
).scalars().all()

# 4. 多条件 AND
results = session.execute(
    select(模型名).where(模型名.名称.like("%AI%"), 模型名.价格 <= 20000)
).scalars().all()

# 5. 多条件 OR：or_()
results = session.execute(
    select(模型名).where(or_(模型名.名称.like("%AI%"), 模型名.价格 <= 12000))
).scalars().all()
```

## 排序查询
标准完整代码：
```python
results = session.execute(
    select(模型名)
    .where(条件)                                        # 可选过滤
    .order_by(模型名.价格.asc(), 模型名.id.desc())       # asc() 升序 / desc() 降序
).scalars().all()
```

## 分页查询
参数换算公式：`offset = (page - 1) * page_size`，`limit = page_size`
```python
def 分页查询(page: int, page_size: int):

    with session_factory() as session:
        results = session.execute(
            select(模型名)
            .order_by(模型名.id.asc())          # 排序保证顺序稳定
            .offset((page - 1) * page_size)     # 跳过条数
            .limit(page_size)                   # 每页条数
        ).scalars().all()
        return results
```

## 修改
标准完整代码：
```python
from sqlalchemy import update

# 方式一：条件更新（update 语句）
with session_factory() as session:
    with session.begin():
        session.execute(
            update(模型名).values(价格=21998).where(模型名.id == 1)  # 直接赋值
        )
        # 原字段基础上修改：values(价格=模型名.价格 - 200)

# 方式二（ORM）：先查对象再改属性，提交时自动 UPDATE
with session_factory() as session:
    with session.begin():
        对象 = session.get(模型名, 1)
        对象.价格 = 21996              # ORM 检测变更自动 UPDATE
```

⚠️ ORM 对象过期问题：默认事务提交后对象被标记过期，事务外访问会报 `DetachedInstanceError`。关闭过期：
```python
session_factory = sessionmaker(engine, expire_on_commit=False)  # 提交后对象属性不过期
```

## 删除
标准完整代码：
```python
from sqlalchemy import delete

with session_factory() as session:
    with session.begin():
        session.execute(
            delete(模型名).where(模型名.id == 1)
        )
```

---

# 从同步到异步

## 同步转异步切换
切换驱动 + 换引擎/会话工厂函数即可：
- 驱动：`pymysql`（同步）→ `aiomysql`（异步）
- 引擎：`create_engine` → `create_async_engine`
- 会话工厂：`sessionmaker` → `async_sessionmaker`
- 执行：`await session.execute(...)`

标准完整代码：
```python
import asyncio

from sqlalchemy import select
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine

engine = create_async_engine(
    "mysql+aiomysql://用户名:密码@主机:端口/数据库名",  # 异步驱动连接串（同步 pymysql → 异步 aiomysql）
    echo=True,
)
session_factory = async_sessionmaker(engine)


async def 查询():
    async with session_factory() as session:
        result = await session.execute(select(模型名))
        return result.scalars().all()


if __name__ == "__main__":
    asyncio.run(查询())  # 同步环境运行异步；FastAPI 中直接 await
```

---

# 异步进阶

## 异步引擎与连接池
标准完整代码：
```python
from sqlalchemy.ext.asyncio import AsyncEngine, create_async_engine

DATABASE_URL = "postgresql+asyncpg://用户:密码@主机:端口/库名"  # PostgreSQL: postgresql+asyncpg:// / MySQL: mysql+aiomysql://

engine: AsyncEngine = create_async_engine(
    DATABASE_URL,
    echo=False,        # 是否在控制台打印 SQL 语句（调试时设 True）
    pool_size=5,       # 连接池常驻连接数
    max_overflow=10,   # 连接池满后允许临时创建的额外连接数
    pool_timeout=30,   # 获取连接的最长等待秒数
    pool_recycle=1800, # 连接存活超过该秒数后重建（防止被数据库断开）
    pool_pre_ping=True,  # 取出连接前先 ping，自动剔除失效连接
)
```

## 会话工厂与依赖注入
标准完整代码：
```python
from collections.abc import AsyncGenerator

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

AsyncSessionFactory = async_sessionmaker(
    bind=engine,
    autoflush=False,        # 查询前不自动 flush
    expire_on_commit=False, # commit 后对象属性不过期


async def get_session() -> AsyncGenerator[AsyncSession, None]:
    """FastAPI 依赖注入：每请求一个独立会话，请求结束自动关闭/回滚"""
    async with AsyncSessionFactory() as session:
        yield session
```

## 连接检查与释放
标准完整代码：
```python
from sqlalchemy import text


async def check_database() -> None:
    """启动时连通性检查：执行 SELECT 1"""
    async with engine.connect() as connection:
        await connection.execute(text("SELECT 1"))


async def close_database() -> None:
    """关闭时释放连接池中的所有连接"""
    await engine.dispose()
```

## ORM 基类与时间戳混入
标准完整代码：
```python
from datetime import datetime

from sqlalchemy import DateTime, func
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column


class Base(DeclarativeBase):
    pass


class CreateAtMixin:
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),  # 插入时数据库自动填当前时间
    )


class UpdateAtMixin:
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        server_default=func.now(),  # 插入时默认值
        onupdate=func.now(),        # UPDATE 时自动刷新
    )


class 示例模型(Base, CreateAtMixin, UpdateAtMixin):
    __tablename__ = "表名"  # 数据库表名

    id: Mapped[int] = mapped_column(primary_key=True)

    名称: Mapped[str] = mapped_column(String(100))                     # 短文本
    描述: Mapped[str | None] = mapped_column(Text)                    # 长文本，可空
    金额: Mapped[Decimal | None] = mapped_column(Numeric(14, 2))      # 总精度14，小数2位
    状态: Mapped[str] = mapped_column(
        String(30),
        default="active",          # 应用层默认值
        server_default="active",   # 数据库层默认值
    )
```

## 通用分页查询
标准完整代码：
```python
from sqlalchemy import func, or_, select
from sqlalchemy.ext.asyncio import AsyncSession


async def find_page(
    session: AsyncSession,
    分类: str | None,
    关键词: str | None,
    page: int,
    page_size: int,
):
    # 1. 组装条件：默认 + 可选，count 与查询共用同一列表保证一致
    conditions = [示例模型.status == "active"]
    if 分类:
        conditions.append(示例模型.分类 == 分类)
    if 关键词:
        kw = f"%{关键词.strip()}%"  # ilike 需手加 %
        conditions.append(
            or_(示例模型.名称.ilike(kw), 示例模型.别名.ilike(kw))
        )

    total = await session.scalar(
        select(func.count(示例模型.id)).where(*conditions)
    ) or 0  # or 0 兜底 None

    items = await session.scalars(
        select(示例模型)
        .where(*conditions)
        .order_by(示例模型.id.asc())      # asc 升序 / desc 降序
        .offset((page - 1) * page_size)   # 跳过条数
        .limit(page_size)                 # 每页条数
    )
    return items.all(), total
```

> **`stmt.where(*filters)` 动态筛选条件展开**
> `*filters` 把一个列表展开为多个独立参数传给 `.where()`。SQLAlchemy 的 `.where()` 接受多个条件参数，内部用 `AND` 连接。
> ```python
> filters = [Model.status == "active"]
> if category:
>     filters.append(Model.category == category)
> # *filters 展开为：.where(Model.status == "active", Model.category == category)
> # 等价于：.where(Model.status == "active" AND Model.category == category)
> ```
> 这种模式避免了空列表时传空条件的问题（空列表 `*[]` 不传任何参数，where 无筛选）。

## 归属校验查询
标准完整代码：
```python
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession


async def find_owned(session: AsyncSession, 对象_id, 用户_id):
    # 存在性 + 归属校验同时完成，防止越权
    return await session.scalar(
        select(示例模型).where(
            示例模型.id == 对象_id,
            示例模型.user_id == 用户_id,
        )
    )
```

---

## 参考
- [SQLAlchemy 官方文档](https://docs.sqlalchemy.org/en/20/)
- [SQLAlchemy ORM 查询指南](https://docs.sqlalchemy.org/en/20/orm/queryguide/select.html)
- [SQLAlchemy 异步 I/O 文档](https://docs.sqlalchemy.org/en/20/orm/extensions/asyncio.html)
- [asyncpg 驱动](https://magicstack.github.io/asyncpg/current/)
