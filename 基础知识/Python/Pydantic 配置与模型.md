---
title: Pydantic 配置与模型
tags: [Pydantic, 大类, 配置管理, 数据校验, 泛型]
created: 2026-08-09
---

## 概述
Pydantic v2 与 pydantic-settings 的标准用法：.env 分层配置、请求/响应模型、字段校验与清洗、泛型分页结构。全部为可复用标准代码，参数处中文注明。

## 分层配置管理（.env）
标准完整代码（`config.py`）：
```python
from pathlib import Path

from pydantic import Field, PostgresDsn, computed_field
from pydantic_settings import BaseSettings, SettingsConfigDict

# 项目根目录：当前文件在 app/core 下时向上 2 级，按项目结构调整
APP_ROOT = Path(__file__).resolve().parents[2]


class EnvSettings(BaseSettings):
    """公共基类：统一指定 .env 文件位置"""
    model_config = SettingsConfigDict(
        env_file=(APP_ROOT / ".env",),  # .env 文件路径
        env_file_encoding="utf-8",      # 文件编码
        extra="ignore",                 # .env 中未声明的字段直接忽略
    )


class DatabaseSettings(EnvSettings):
    """数据库配置示例"""
    host: str = Field(alias="DB_HOST", default="localhost")  # 数据库主机
    port: int = Field(alias="DB_PORT", default=5432)        # 端口
    name: str = Field(alias="DB_NAME", default="数据库名")   # 库名
    user: str = Field(alias="DB_USER", default="用户名")     # 用户名
    password: str = Field(alias="DB_PASSWORD", default="密码")  # 密码

    @computed_field
    @property
    def url(self) -> str:
        """自动拼接连接串（自动做 URL 编码）"""
        return PostgresDsn.build(
            scheme="postgresql+asyncpg",  # 驱动：PostgreSQL 用 asyncpg，MySQL 用 mysql+aiomysql
            host=self.host,
            port=self.port,
            username=self.user,
            password=self.password,
        ).encoded_string()


class Settings(BaseSettings):
    """组合所有配置域（每新增一个领域就加一个字段）"""
    db: DatabaseSettings = Field(default_factory=DatabaseSettings)  # 数据库配置
    # app: AppSettings = Field(default_factory=AppSettings)        # 应用配置
    # llm: LLMSettings = Field(default_factory=LLMSettings)        # 模型配置


settings = Settings()  # 全局单例：全项目 import 使用同一份配置
```

`.env` 文件示例：
```ini
DB_HOST=localhost
DB_PORT=5432
DB_NAME=数据库名
DB_USER=用户名
DB_PASSWORD=密码
```

## 请求与响应模型
标准完整代码：
```python
from typing import Optional
from uuid import UUID

from pydantic import BaseModel, ConfigDict, Field


class BaseSchema(BaseModel):
    """公共基类：开启 from_attributes，可直接从 ORM 对象转换"""
    model_config = ConfigDict(from_attributes=True)


class 创建请求(BaseSchema):
    名称: str = Field(min_length=1, max_length=100)  # 名称，必填，长度 1~100
    状态: str = Field(default="active")              # 状态，默认 active


class 响应模型(BaseSchema):
    id: int                      # 主键
    名称: str                     # 名称
    可选字段: str | None = None   # 可空字段（数据库可空时用）
```

> **`Optional[UUID]` 表示可选参数**
> `Optional[UUID]` 即 `UUID | None`，表示该字段可以传也可以不传。在接口参数中使用时，不传该参数值为 `None`，常与 `Query(None, ...)` 配合实现可选筛选：
> ```python
> claim_id: Annotated[Optional[UUID], Query(None, description="按 UUID 筛选")]
> ```

> **`model_validate(record)` —— Pydantic v2 ORM 转换**
> Pydantic v2 中用 `model_validate()` 替代了 v1 的 `.from_orm()`，用于将 SQLAlchemy ORM 对象直接转为响应 Schema。前提是响应模型的 `model_config` 中设置了 `from_attributes=True`：
> ```python
> response = 响应模型.model_validate(orm_record)
> # 等价于：从 ORM 对象读取所有同名属性，构造 Pydantic 实例
> ```

## 字段校验与清洗
标准完整代码：
```python
from pydantic import field_validator


class 请求模型(BaseModel):
    标题: str                    # 待清洗字段
    列表字段: list[str] | None   # 可空列表字段

    @field_validator("标题", mode="before")  # mode="before"：类型校验前先执行
    @classmethod
    def 清洗标题(cls, value):
        return value.strip()     # 去除首尾空格

    @field_validator("列表字段", mode="before")
    @classmethod
    def 归一化(cls, value):
        return value or []       # None 归一化为空列表，保证输出结构稳定
```

## 泛型与通用分页结构
标准完整代码：
```python
from typing import Generic, TypeVar

from pydantic import BaseModel

T = TypeVar("T")  # 泛型占位符，使用时再指定具体类型


class PageResult(BaseModel, Generic[T]):
    """通用分页结果：适用于所有列表接口"""
    items: list[T]    # 当前页数据列表（元素类型使用方指定）
    page: int         # 当前页码（从 1 开始）
    page_size: int    # 每页条数
    total: int        # 总条数


# 使用示例：PageResult[响应模型](items=[...], page=1, page_size=20, total=100)
```

## 参考
- [pydantic-settings 官方文档](https://docs.pydantic.dev/latest/concepts/pydantic_settings/)
- [Pydantic 模型配置](https://docs.pydantic.dev/latest/concepts/models/)
- [Pydantic 校验器](https://docs.pydantic.dev/latest/concepts/validators/)
- [Pydantic 泛型模型](https://docs.pydantic.dev/latest/concepts/generics/)