# 数据库规则路由器 (DB Rules Router)

读取 `project.config.json → tech_stack.database`，加载对应的数据库规范文件：

| 配置值 | 加载文件 |
|--------|---------|
| `mysql` | `.agents/rules/db-mysql.md` |
| `sqlite` | `.agents/rules/db-sqlite.md` |
| `postgres` / `postgresql` | `.agents/rules/db-postgres.md`（暂未提供，使用通用原则） |
| 其他 / 未配置 | 使用下方通用原则 |

**强制要求**：读到数据库类型后，必须通过工具物理读取对应规范文件，不允许凭记忆执行。

---

## 通用数据库原则（所有数据库适用）

以下规则不依赖数据库类型，任何情况下都必须遵守：

1. **MUST** 禁止外键约束，表关联逻辑交由业务代码实现。
2. **MUST** 所有表和字段必须有明确的业务含义说明（注释或文档）。
3. **MUST** 必须包含创建时间和更新时间审计字段。
4. **MUST** 极度警惕并杜绝 `SELECT *`，必须手写查询列。
5. **MUST** 批量 DML（UPDATE/DELETE）必须有 WHERE 条件，严禁无条件全表操作。
6. **MUST** 任何 DDL 变更必须附带真实业务查询 SQL 注释，供 Review 使用。
7. **NEVER** 在无 Review 的情况下直接在生产数据库执行 DDL。
