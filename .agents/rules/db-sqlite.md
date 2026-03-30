# SQLite 数据库开发规范

> 适用场景：`project.config.json → tech_stack.database = "sqlite"`
> ORM 默认为 SQLAlchemy，适配提示会注明差异。

---

## SQLite 特性约束（与 MySQL 的关键差异）

在套用任何 MySQL 规范前，必须先理解以下 SQLite 特性，否则极易写出无效或行为不符预期的代码：

| 特性 | SQLite 行为 | 常见坑 |
|------|------------|--------|
| 主键自增 | `INTEGER PRIMARY KEY` 自动获得 rowid 别名，是真正的自增。使用其他类型（如 `BigInteger`）不会自动自增 | 不要用 `BigInteger` 做自增主键，用 `Integer` |
| 列类型 | 动态类型系统（Type Affinity），声明类型只是建议 | `VARCHAR(255)` 和 `TEXT` 行为相同，不需要区分 |
| `ALTER TABLE` | 仅支持 `ADD COLUMN` 和 `RENAME`，不支持 `DROP COLUMN`（SQLite < 3.35）、`MODIFY COLUMN` | 改字段类型必须重建表 |
| 索引前缀长度 | 不支持 `mysql_length`，直接建索引即可 | 从 MySQL 迁移时必须删掉 `mysql_length` 参数 |
| 表/列注释 | 不支持 `COMMENT` 语法 | 注释写在 Python 代码或文档中，不写进 DDL |
| 并发写入 | WAL 模式下支持一写多读，但写入仍为串行 | 高并发写场景不适合 SQLite，需评估是否换库 |
| 布尔类型 | 无原生 BOOLEAN，存为 0/1 整数 | SQLAlchemy 的 `Boolean` 类型会自动处理 |
| 日期时间 | 无原生 DATETIME，存为 TEXT（ISO 8601）或 INTEGER（Unix timestamp） | SQLAlchemy 的 `DateTime` 类型存为 TEXT，查询时注意格式 |

---

## 核心规范 (必须严格遵守)

### 1. 建表与模型定义检查清单（SQLAlchemy）

1. **MUST** 主键使用 `Integer`（不是 `BigInteger`），配合 `autoincrement=True`，映射到 SQLite 的 `INTEGER PRIMARY KEY`。
2. **MUST** 必须包含 `created_at` 和 `updated_at` 审计时间字段，类型用 `DateTime`。
3. **MUST** 列注释写在 Python 字段的 docstring 或 `info={}` 参数中，不要试图写进 DDL。
4. **MUST** 索引直接在 `__table_args__` 中用 `Index(...)` 定义，**不传 `mysql_length` 参数**。
5. **MUST** 字符串字段使用 `String` 或 `Text`，不需要区分；`nullable=False` 时须提供 `server_default`。
6. **MUST** 避免使用 `Enum` 类型（SQLite 会存为 VARCHAR），统一用 `Integer`（tinyint 语义）替代。
7. **MUST** 不需要声明 `mysql_engine` 或 `mysql_charset`，SQLite 不支持这些参数。

### 2. 迁移操作规范（Alembic）

- **MUST** `ADD COLUMN` 时，新列必须允许 NULL 或有 `server_default`，否则迁移会在非空表上失败。
- **MUST** 需要修改列类型或删除列时，必须使用"重建表"方案（创建新表 → 迁移数据 → 删旧表 → 重命名）。
- **MUST** Alembic 配置中启用 `render_as_batch=True`，这是 SQLite 的迁移必需选项：
  ```python
  # env.py
  with connectable.connect() as connection:
      context.configure(connection=connection, render_as_batch=True, ...)
  ```

### 3. 查询规范

- **MUST** 使用 `func.strftime()` 处理日期格式，不能用 MySQL 的 `DATE_FORMAT()`。
- **MUST** 字符串拼接使用 `||` 操作符（SQLite 语法），不能用 MySQL 的 `CONCAT()`。
- **MUST** 不存在 `ONLY_FULL_GROUP_BY` 限制，但仍应避免 GROUP BY 中出现非聚合非分组字段（可移植性）。

---

## 模型生成模板参考（SQLAlchemy + SQLite）

```python
from sqlalchemy import Column, Integer, String, DateTime, Text, Index, text
from app.db.base_class import Base

class ExampleModel(Base):
    __tablename__ = "example_table"

    __table_args__ = (
        Index("idx_field_name", "field_name"),  # 不需要 mysql_length
        # 不需要 mysql_engine / mysql_charset
    )

    # SQLite 自增主键：必须用 Integer，不是 BigInteger
    id = Column(Integer, primary_key=True, autoincrement=True)

    # 字符串字段
    field_name = Column(String(50), nullable=False, server_default=text("''"))

    # 长文本字段（SQLite 中 String 和 Text 行为相同，Text 更语义化）
    content = Column(Text, nullable=True)

    # 时间字段（SQLite 存为 TEXT，ISO 8601 格式）
    created_at = Column(DateTime, nullable=False, server_default=text("CURRENT_TIMESTAMP"))
    updated_at = Column(DateTime, nullable=False, server_default=text("'1900-01-01 00:00:00'"))
```

---

## 开发环境配置提示

```python
# SQLAlchemy 连接字符串
SQLALCHEMY_DATABASE_URL = "sqlite:///./app.db"          # 相对路径
SQLALCHEMY_DATABASE_URL = "sqlite:////abs/path/app.db"  # 绝对路径
SQLALCHEMY_DATABASE_URL = "sqlite://"                   # 纯内存（测试用）

# 必须开启 check_same_thread=False（FastAPI 多线程环境）
engine = create_engine(
    SQLALCHEMY_DATABASE_URL,
    connect_args={"check_same_thread": False}
)
```

*(凡被检测出违背上述 MUST 准则的模型代码，在输出前直接阻断报错。)*
