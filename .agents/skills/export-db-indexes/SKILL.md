---
name: export-db-indexes
description: 扫描 ORM 模型文件，对比线上表结构，生成增量 ALTER TABLE DDL 脚本，并附带真实业务查询 SQL 注释供 DBA Review。
---

# Export DB Indexes Skill

## 触发时机

- `dev-flow` Step 6：修改了 ORM 模型文件（如 `models.py`）后
- `production-release` 第四步：数据库差异化导出
- 用户手动触发：提及"导出数据库差异"、"生成 DDL"

---

## 执行步骤

### Step 1：扫描 ORM 模型
读取项目的 ORM 模型文件（路径来自 `project.config.json → tech_stack.backend_path`），提取：
- 所有表定义
- 字段类型、约束、注释
- 索引定义（包括复合索引、前缀索引）
- 表级元数据（引擎、字符集、表注释）

### Step 2：对比线上结构
通过以下方式获取线上（或 baseline）表结构：
```sql
SHOW CREATE TABLE {table_name};
-- 或
SELECT * FROM information_schema.COLUMNS WHERE TABLE_NAME = '{table_name}';
```

### Step 3：生成增量 DDL

对每个有差异的表，生成：
- `ALTER TABLE` 语句（新增字段、修改字段、新增索引）
- 每条 DDL 前附带 `-- 业务含义说明` 注释
- 每条 DDL 后附带对应的真实业务查询 SQL（Query SQL），说明该索引会被哪种查询用到

**输出格式示例**：
```sql
-- [新增字段] user_level: 用户等级，用于会员分层筛选
ALTER TABLE user_info ADD COLUMN user_level TINYINT NOT NULL DEFAULT 0 COMMENT '用户等级';

-- [新增索引] idx_user_level: 支持按用户等级的批量查询
-- Query SQL: SELECT id, name FROM user_info WHERE user_level = ? LIMIT 100;
ALTER TABLE user_info ADD INDEX idx_user_level (user_level);
```

### Step 4：输出报告

将生成的 DDL 写入临时文件：`tmp/db_migration_{YYYYMMDD}.sql`

并在对话中输出摘要：
```
## 数据库增量导出报告

| 表名 | 变更类型 | 详情 |
|------|---------|------|
| user_info | 新增字段 | user_level (tinyint) |
| order_record | 新增索引 | idx_status_created |

DDL 文件已生成：tmp/db_migration_{YYYYMMDD}.sql

⚠️ 请交由 DBA Review 后在对应环境执行，严禁直接在生产执行未经 Review 的 DDL。
```

---

## 强制约束

- **MUST** 输出的 DDL 必须是 `ALTER TABLE` 格式，禁止输出 `DROP TABLE` 或 `CREATE TABLE`（除非是全新表）
- **MUST** 每条 DDL 后必须附带真实 Query SQL 注释
- **MUST** 写入 `tmp/` 目录，不得放在项目根目录
- **NEVER** 在无 DBA Review 的情况下直接在生产数据库执行任何 DDL
