---
name: db-dev-guide
description: 数据库开发约束与规范。修改 ORM 模型、表结构或编写迁移前必读。
trigger: /db-dev-guide
standalone: true
---

# 数据库开发规范 (Database Rules)

> 读取 `project.config.json → tech_stack.database` 确定数据库类型。
> 先读通用规则，再只读匹配的数据库章节，跳过无关章节。

---

## 通用规则（所有数据库适用）

1. **MUST** 禁止外键约束，表关联逻辑交由业务代码实现。
2. **MUST** 所有表和字段必须有明确的业务含义说明（注释或文档）。
3. **MUST** 必须包含 `created_at` 和 `updated_at` 审计字段。
4. **MUST** 极度警惕并杜绝 `SELECT *`，必须手写查询列。
5. **MUST** 批量 DML（UPDATE/DELETE）必须有 WHERE 条件，严禁无条件全表操作。
6. **MUST** 任何 DDL 变更必须附带真实业务查询 SQL 注释，供 Review 使用。
7. **NEVER** 在无 Review 的情况下直接在生产数据库执行 DDL。

---

## MySQL（tech_stack.database = "mysql"）

> ORM 默认为 SQLAlchemy。

### 建表与模型定义

1. **MUST** 主键使用 `BigInteger`，`autoincrement=True`。
2. **MUST** `created_at` 和 `updated_at` 用 `DateTime` 类型。
3. **MUST** 所有表和字段带 `comment` 说明业务含义。
4. **MUST** 对 `Text` 类型建索引时，必须指定前缀长度，**严禁直接 `index=True` 或 `unique=True`**。
5. **MUST** 使用 InnoDB 引擎，字符集 utf8mb4。
6. **MUST** varchar 字段默认 `NOT NULL DEFAULT ''`。
7. **MUST** 禁止 `TIMESTAMP` 类型，统一用 `DATETIME`。
8. **MUST** 避免 `ENUM` 类型，用 `tinyint` 替代。

### 分片表额外检查
- **MUST** 强制包含分片路由主键字段。
- 分片表的任何 DML 或复杂查询必须带分片键，严防全片拉取。

### 模型模板

```python
from sqlalchemy import Column, BigInteger, String, DateTime, text, Index
from app.db.base_class import Base

class ExampleModel(Base):
    __tablename__ = "example_table"
    __table_args__ = (
        Index("idx_field_name", "field_name", mysql_length={"field_name": 50}),
        {"comment": "示例表", "mysql_engine": "InnoDB", "mysql_charset": "utf8mb4"}
    )
    id = Column("Id", BigInteger, primary_key=True, autoincrement=True, comment="自增主键")
    field_name = Column("field_name", String(50), nullable=False, server_default=text("''"), comment="字段说明")
    created_at = Column("created_at", DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"), comment="创建时间")
    updated_at = Column("updated_at", DateTime, nullable=False, server_default=text("'1900-01-01 00:00:00'"), comment="更新时间")
```

---

## SQLite（tech_stack.database = "sqlite"）

> ORM 默认为 SQLAlchemy。

### 与 MySQL 的关键差异

| 特性 | SQLite 行为 | 常见坑 |
|------|------------|--------|
| 主键自增 | `INTEGER PRIMARY KEY` 是真正的自增。其他类型不自增 | 用 `Integer` 不是 `BigInteger` |
| 列类型 | 动态类型系统，声明类型只是建议 | `VARCHAR(255)` 和 `TEXT` 行为相同 |
| `ALTER TABLE` | 仅支持 `ADD COLUMN` 和 `RENAME`，不支持 `DROP COLUMN`（< 3.35） | 改字段类型必须重建表 |
| 索引前缀长度 | 不支持 `mysql_length` | 迁移时必须删掉 `mysql_length` |
| 表/列注释 | 不支持 `COMMENT` 语法 | 注释写在 Python 代码中 |
| 并发写入 | WAL 模式下一写多读，写入串行 | 高并发写场景不适合 SQLite |
| 日期时间 | 存为 TEXT（ISO 8601）或 INTEGER | `DateTime` 类型存为 TEXT |

### 建表与模型定义

1. **MUST** 主键使用 `Integer`（不是 `BigInteger`），配合 `autoincrement=True`。
2. **MUST** `created_at` 和 `updated_at` 用 `DateTime` 类型。
3. **MUST** 列注释写在 Python 字段的 docstring 或 `info={}` 中，不写进 DDL。
4. **MUST** 索引不传 `mysql_length` 参数。
5. **MUST** 不需要声明 `mysql_engine` 或 `mysql_charset`。
6. **MUST** 避免 `Enum` 类型，用 `Integer` 替代。

### 迁移操作（Alembic）

- **MUST** `ADD COLUMN` 时，新列必须允许 NULL 或有 `server_default`。
- **MUST** 改列类型/删列 → 重建表方案（建新表 → 迁移数据 → 删旧表 → 重命名）。
- **MUST** Alembic 配置启用 `render_as_batch=True`。
- **MUST** 日期用 `func.strftime()`，不用 `DATE_FORMAT()`。字符串拼接用 `||`，不用 `CONCAT()`。

### 模型模板

```python
from sqlalchemy import Column, Integer, String, DateTime, Text, Index, text
from app.db.base_class import Base

class ExampleModel(Base):
    __tablename__ = "example_table"
    __table_args__ = (
        Index("idx_field_name", "field_name"),  # 不需要 mysql_length
    )
    id = Column(Integer, primary_key=True, autoincrement=True)
    field_name = Column(String(50), nullable=False, server_default=text("''"))
    content = Column(Text, nullable=True)
    created_at = Column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, nullable=False, server_default=text("'1900-01-01 00:00:00'"))
```

### 开发环境配置

```python
SQLALCHEMY_DATABASE_URL = "sqlite:///./app.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
```

---

## PostgreSQL（tech_stack.database = "postgres" / "postgresql"）

> ORM 默认为 SQLAlchemy。

### 与 MySQL 的关键差异

| 特性 | PostgreSQL 行为 | 常见坑 |
|------|----------------|--------|
| 主键自增 | `BIGSERIAL`，SQLAlchemy 用 `BigInteger` + `autoincrement=True` | 不需要手写序列 |
| 列注释 | 支持 `COMMENT ON COLUMN`，`comment=` 正常使用 | |
| TEXT 索引 | 直接建索引无长度限制 | 删除所有 `mysql_length` |
| 大小写 | 标识符默认折叠为小写 | 统一用 snake_case |
| ENUM | 原生支持但修改值需 `ALTER TYPE` | 推荐用 `SMALLINT` 替代 |
| 日期时间 | 推荐 `TIMESTAMP WITH TIME ZONE` | 用 `DateTime(timezone=True)` |
| JSON | 原生 `JSONB`，支持索引 | 优先用 JSONB 而非 TEXT |

### 建表与模型定义

1. **MUST** 主键使用 `BigInteger`，`autoincrement=True`，映射为 `BIGSERIAL`。
2. **MUST** 时间字段使用 `DateTime(timezone=True)`。
3. **MUST** 字段和表加 `comment=` 说明业务含义。
4. **MUST** 索引不传 `mysql_length`，不声明 `mysql_engine`/`mysql_charset`。
5. **MUST** 避免 SQLAlchemy `Enum` 类型，用 `SmallInteger`。
6. **MUST** 使用 snake_case 命名所有表名和字段名。

### 迁移操作（Alembic）

- **MUST** `ADD COLUMN NOT NULL` 时必须提供 `server_default`。
- **SHOULD** 大表索引变更使用 `postgresql_concurrently=True` 避免锁表。
- **MUST** 删除列前全库搜索确认无应用层引用。

### 查询规范

- **MUST** 使用 ORM 参数化查询，禁止字符串拼接 SQL。
- **MUST** 批量操作用 `INSERT ... ON CONFLICT DO UPDATE`（upsert）。
- **SHOULD** JSONB 高频查询字段使用 GIN 索引。

### 模型模板

```python
from sqlalchemy import Column, BigInteger, String, Text, SmallInteger, Index
from sqlalchemy import DateTime, func, text
from sqlalchemy.dialects.postgresql import JSONB
from app.db.base_class import Base

class ExampleModel(Base):
    __tablename__ = "example_table"
    __table_args__ = (
        Index("idx_field_name", "field_name"),
        {"comment": "示例表"}
    )
    id = Column(BigInteger, primary_key=True, autoincrement=True, comment="自增主键")
    field_name = Column(String(50), nullable=False, server_default=text("''"), comment="字段说明")
    content = Column(Text, nullable=True, comment="长文本内容")
    extra_data = Column(JSONB, nullable=True, comment="扩展数据")
    status = Column(SmallInteger, nullable=False, server_default=text("0"), comment="状态 0=正常 1=禁用")
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="创建时间")
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), comment="更新时间")
```

### 开发环境配置

```python
SQLALCHEMY_DATABASE_URL = "postgresql+psycopg2://user:password@localhost:5432/dbname"
engine = create_engine(SQLALCHEMY_DATABASE_URL, pool_size=10, max_overflow=20, pool_pre_ping=True)
```
