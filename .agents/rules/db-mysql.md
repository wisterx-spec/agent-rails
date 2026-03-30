# 数据库开发规范 (Database Rules)

## 角色定位
严格遵守数据库规范的 AI 编程助手。在处理任何数据库相关操作时，必须遵循以下铁律。

> 适配提示：本文件默认面向 MySQL + SQLAlchemy 技术栈。
> 使用其他数据库时，在 `project.config.json` 中声明 `tech_stack.database`，并相应调整本文件中的方言约束。

---

## 核心规范 (必须严格死守)

### 1. 建表与模型定义检查清单
1. **MUST** 必须存在自增主键（`BigInteger` 类型，命名遵循项目约定）。
2. **MUST** 必须包含 `created_at` 和 `updated_at` 审计时间字段。
3. **MUST** 所有表和字段必须带上 `comment` 说明其业务含义。
4. **MUST** 对 `Text` 类型建立索引时，必须显式指定前缀长度，**严禁直接在 Column 定义中使用 `index=True` 或 `unique=True`**（MySQL 方言限制）。
5. **MUST** 使用 InnoDB 引擎，字符集为 utf8mb4。
6. **MUST** 所有 varchar 字段默认设置 NOT NULL DEFAULT ''。
7. **MUST** 禁止外键，表外键关联逻辑交由业务代码实现。
8. **MUST** 禁止 timestamp 类型，时间字段统一使用 datetime。
9. **MUST** 避免使用 ENUM 类型，统一用 tinyint 替代。

### 2. 分片表额外检查（仅涉及横向切分时）
- **MUST** 强制包含分片路由主键字段。
- 原主键改为业务逻辑主键（如 OrderId/UserId）。

### 3. SQL / Query 编写规范
- **MUST** 极度警惕并杜绝 `SELECT *`，必须手写查询列。
- **MUST** 分片表的任何 DML 或复杂查询必须带分片键，严防全片拉取。
- **MUST** 避免跨分区的事务。

---

## 模型生成模板参考（SQLAlchemy）

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

*(凡被检测出违背上述 MUST 准则的模型代码，在输出前直接阻断报错。)*
