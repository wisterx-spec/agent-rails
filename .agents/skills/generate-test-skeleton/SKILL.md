---
name: generate-test-skeleton
description: 根据改动类型和接口契约，生成测试骨架文件（锁定接口契约、边界断言），Test-First 场景下人工确认后立即锁定基线
trigger: /generate-test-skeleton [--type=api|service|db|frontend]
inputs:
  - name: change_type
    source: "用户参数 --type / dev-flow 判断的改动类型"
    required: true
    description: "api=接口层, service=业务层, db=数据库迁移, frontend=前端组件"
  - name: interface_definition
    source: "相关代码文件（函数签名、ORM 模型、路由定义）"
    required: true
    description: "AI 通过读取文件获取，不猜测"
outputs:
  - name: test_skeleton_files
    destination: "{{TEST_PATH}} 下对应的测试文件"
    description: "包含 describe/it 骨架和关键断言，测试必然失败（红色）—— 这是正确状态"
standalone: true
called_by:
  - workflow/dev-flow (Step 4)
  - workflow/frontend-tdd (Step 1，前端组件类型)
---

# Generate Test Skeleton Skill

> **单独调用**：`/generate-test-skeleton --type=api`
> **在工作流中调用**：由 `dev-flow` Step 4 或 `frontend-tdd` Step 1 触发
> **可跳过条件**：纯样式微调 / 探索性 Prototype（dev-flow 表格中 Code-First 场景）

---

## 执行步骤

### Step 1：读取接口定义（强制，不猜测）
**MUST** 通过工具读取实际代码，获取：
- `--type=api`：路由函数签名、请求参数类型、响应结构
- `--type=service`：函数签名、参数、返回值、可能的副作用
- `--type=db`：ORM 模型字段、迁移操作类型
- `--type=frontend`：组件 props 类型、触发的用户交互

### Step 2：按类型生成骨架

**API 骨架（pytest）**：
```python
class TestXxxEndpoint:
    def test_正常请求返回200(self, client, db_session):
        response = client.post("/api/v1/xxx", json={...实际字段...})
        assert response.status_code == 200
        assert response.json()["field"] == expected_value  # 真实字段名

    def test_缺少必填字段返回422(self, client):
        response = client.post("/api/v1/xxx", json={})
        assert response.status_code == 422

    def test_无权限返回403(self, client, non_admin_user):
        ...
```

**前端组件骨架（Testing Library）**：
```typescript
describe('ComponentName', () => {
  it('正常渲染', () => { ... })
  it('loading 状态下按钮禁用', () => { ... })
  it('空数据时渲染 EmptyState', () => { ... })
  it('危险操作触发确认弹窗', async () => { ... })
})
```

**DB 迁移骨架（pytest）**：
```python
def test_迁移后字段存在():
    # 验证新增字段
    ...
def test_迁移后数据完整性():
    # 验证现有数据未丢失
    ...
```

### Step 3：人工确认后锁定基线
骨架生成后，提示用户：

```
测试骨架已生成。此时测试全部红色（FAIL）—— 这是正确状态。
请确认测试用例覆盖了你的验收标准，确认后执行：
  python .agents/scripts/test_lock.py lock
锁定后严禁修改测试断言，只允许修改实现代码。
```

---

## 约束

- **NEVER** 在未读接口定义的情况下生成骨架（防止幻觉字段名）
- **NEVER** 为了让骨架"看起来合理"而虚构字段或状态码
- **MUST** 生成的骨架覆盖：正常路径 + 至少 1 个异常路径 + 权限场景（如适用）
- 生成的测试此时必须全部失败（红色），如果通过说明骨架没有真正锁定契约
