# PostgreSQL 数据库开发规范

> 适用场景：`project.config.json → tech_stack.database = "postgres"` 或 `"postgresql"`
> ORM 默认为 SQLAlchemy，适配提示会注明 Django ORM 差异。

---

## PostgreSQL 特性约束（与 MySQL 的关键差异）

| 特性 | PostgreSQL 行为 | 常见坑 |
|------|----------------|--------|
| 主键自增 | 推荐用 `BIGSERIAL` 或 `GENERATED ALWAYS AS IDENTITY`，SQLAlchemy 用 `BigInteger` + `autoincrement=True` | 不需要手写序列，SQLAlchemy 自动处理 |
| 列注释 | 支持 `COMMENT ON COLUMN`，但 SQLAlchemy 的 `comment=` 参数在 PG 迁移中会生成对应语句 | 正常使用 `comment=` 即可 |
| `TEXT` 索引 | 直接建索引无长度限制，不需要 `mysql_length` | 从 MySQL 迁移时删除所有 `mysql_length` 参数 |
| 大小写敏感 | 标识符默认折叠为小写，引号包裹则区分大小写 | 避免使用驼峰表名/字段名，统一用 snake_case |
| `ENUM` 类型 | 原生支持，但修改 ENUM 值需要 `ALTER TYPE`，有迁移风险 | 仍推荐用 `SMALLINT` 替代，保持迁移灵活性 |
| 布尔类型 | 原生 `BOOLEAN`，不是 0/1 | SQLAlchemy `Boolean` 映射正确，直接用 |
| 日期时间 | 推荐 `TIMESTAMP WITH TIME ZONE`（`timestamptz`） | SQLAlchemy `DateTime(timezone=True)` 对应此类型 |
| `NULL` 默认值 | 不声明 `DEFAULT` 的 NOT NULL 列在 `ALTER TABLE ADD COLUMN` 时会要求现有行有值 | 新增 NOT NULL 列时必须提供 `server_default` |
| JSON 支持 | 原生 `JSONB`（二进制 JSON，支持索引） | 存储结构化数据优先用 `JSONB` 而非 `TEXT` |
| 全文搜索 | 内置 `tsvector` / `tsquery`，无需第三方 | 中文全文搜索需配合 `zhparser` 或 `pg_jieba` 扩展 |

---

## 核心规范 (必须严格遵守)

### 1. 建表与模型定义检查清单（SQLAlchemy）

1. **MUST** 主键使用 `BigInteger`，配合 `autoincrement=True`，映射为 `BIGSERIAL`。
2. **MUST** 必须包含 `created_at` 和 `updated_at` 审计时间字段，使用 `DateTime(timezone=True)`。
3. **MUST** 字段和表加 `comment=` 说明业务含义。
4. **MUST** 索引在 `__table_args__` 中用 `Index(...)` 定义，**不传 `mysql_length`**。
5. **MUST** 字符串字段使用 `String`（短文本）或 `Text`（长文本），不需要 `mysql_charset`。
6. **MUST** 避免使用 SQLAlchemy `Enum` 类型（迁移改值成本高），统一用 `SmallInteger`。
7. **MUST** 不需要声明 `mysql_engine`、`mysql_charset`，PostgreSQL 不支持这些参数。
8. **MUST** 使用 snake_case 命名所有表名和字段名，避免引号依赖。

### 2. 迁移操作规范（Alembic）

- **MUST** `ADD COLUMN NOT NULL` 时必须提供 `server_default`，否则非空表迁移失败。
- **MUST** 修改列类型使用 `op.alter_column`，PG 支持大多数类型转换（需 `USING` 子句时 Alembic 自动生成）。
- **MUST** 删除列前确认无任何应用层引用（全库搜索）。
- **SHOULD** 大表的索引变更使用 `CREATE INDEX CONCURRENTLY`（Alembic 支持 `postgresql_concurrently=True`），避免锁表。

### 3. 查询规范

- **MUST** 使用 ORM 参数化查询，禁止字符串拼接 SQL（防注入）。
- **MUST** 批量操作使用 `INSERT ... ON CONFLICT DO UPDATE`（upsert）替代先查后写。
- **SHOULD** 高频查询字段建立索引，JSONB 字段使用 GIN 索引。
- **MUST** 避免 `SELECT *`，手写查询列。

---

## 模型生成模板参考（SQLAlchemy + PostgreSQL）

```python
from sqlalchemy import Column, BigInteger, String, Text, SmallInteger, Index
from sqlalchemy import DateTime, func, text
from sqlalchemy.dialects.postgresql import JSONB
from app.db.base_class import Base

class ExampleModel(Base):
    __tablename__ = "example_table"

    __table_args__ = (
        Index("idx_field_name", "field_name"),
        # 大表索引用 CONCURRENTLY（Alembic 迁移中指定）
        {"comment": "示例表"}
        # 不需要 mysql_engine / mysql_charset
    )

    id = Column(BigInteger, primary_key=True, autoincrement=True, comment="自增主键")
    field_name = Column(String(50), nullable=False, server_default=text("''"), comment="字段说明")
    content = Column(Text, nullable=True, comment="长文本内容")
    extra_data = Column(JSONB, nullable=True, comment="扩展数据（JSONB 支持索引）")
    status = Column(SmallInteger, nullable=False, server_default=text("0"), comment="状态 0=正常 1=禁用")

    # 带时区的时间字段
    created_at = Column(DateTime(timezone=True), server_default=func.now(), comment="创建时间")
    updated_at = Column(DateTime(timezone=True), server_default=func.now(),
                        onupdate=func.now(), comment="更新时间")
```

---

## 开发环境配置

```python
# SQLAlchemy 连接字符串
SQLALCHEMY_DATABASE_URL = "postgresql+psycopg2://user:password@localhost:5432/dbname"
# 或使用 asyncpg（异步）
SQLALCHEMY_DATABASE_URL = "postgresql+asyncpg://user:password@localhost:5432/dbname"

# 推荐连接池配置（生产环境）
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    pool_size=10,
    max_overflow=20,
    pool_pre_ping=True,   # 自动检测断开的连接
)
```
