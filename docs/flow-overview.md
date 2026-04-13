# 完整开发流程图：从需求到上线

```mermaid
flowchart TD
    START([用户提出需求]) --> RC

    %% ──────────────── 需求阶段 ────────────────
    subgraph REQ["Phase: 需求对齐"]
        RC["/requirement-clarification<br/>结构化问答（最多 6 问）"]
        RC --> SPEC["输出《需求规格确认书》"]
        SPEC --> GATE_SPEC{{"🔴 人工卡点<br/>确认需求规格"}}
    end

    GATE_SPEC -->|确认| CHOOSE
    GATE_SPEC -->|有问题| RC

    %% ──────────────── 路径选择 ────────────────
    CHOOSE{{"选择开发模式"}}
    CHOOSE -->|"需求明确，交给 AI 全程执行"| AUTODEV
    CHOOSE -->|"边做边决策，人工推进"| DEVFLOW

    %% ──────────────── AUTO-DEV ────────────────
    subgraph AUTODEV["auto-dev（AI 自驱模式）"]
        direction TB

        subgraph P0["Phase 0: 规范预加载"]
            A0_1["读取 project.config.json"]
            A0_2["读取 conventions.md 速查区"]
            A0_3["按需加载 skill<br/>（frontend-dev-guide / db-dev-guide）"]
            A0_4["预读 decisions 索引"]
            A0_5["生成《规范快照》≤30 行"]
            A0_1 --> A0_2 --> A0_3 --> A0_4 --> A0_5
        end

        subgraph P1["Phase 1: 立项"]
            A1_1["切换 feature/ 分支"]
            A1_2["生成《问题全量清单》<br/>P0/P1/P2 分级"]
            A1_1 --> A1_2
        end

        subgraph P2["Phase 2: 方案设计"]
            A2_CHECK{"轻量任务？<br/>（≤2 文件 bug fix / 纯样式）"}
            A2_CHECK -->|否| A2_PR["/proposal-review<br/>生成方案评审文档"]
            A2_CHECK -->|是| A2_SIMPLE["出具简化技术方案"]
            A2_PR --> A2_TECH["追加技术补充项<br/>组件复用检查 + 决策草稿"]
            A2_SIMPLE --> GATE_PLAN
            A2_TECH --> GATE_PLAN{{"🔴 人工卡点<br/>确认方案"}}
        end

        subgraph P3["Phase 3: 编码执行（Ralph-loop）"]
            direction TB
            FS_CHECK{"全栈任务？"}
            FS_CHECK -->|是| FE_FIRST["第一轮：前端 Component-TDD"]
            FS_CHECK -->|否| RALPH

            subgraph FE_TDD["Frontend-First"]
                FE_FIRST --> FE_TEST["写行为测试 → 锁定基线"]
                FE_TEST --> FE_IMPL["实现组件"]
                FE_IMPL --> FE_UX["/frontend-ux-evaluator"]
                FE_UX --> GATE_FE{{"🔴 人工卡点<br/>确认 UX"}}
                GATE_FE -->|"🔴 必须修复"| FE_IMPL
                GATE_FE -->|通过| FE_NEXT{"还有组件？"}
                FE_NEXT -->|是| FE_TEST
                FE_NEXT -->|否| BE_START["第二轮：后端<br/>从已确认 UI 反推 API 契约"]
            end

            BE_START --> RALPH

            subgraph LOOP["Ralph-loop 自循环"]
                RALPH["Assess: 取 P0/P1 问题"]
                RALPH --> ACT["Act: 执行改动<br/>自动挂载领域防线"]
                ACT --> VERIFY["Verify: 三层验证<br/>①目标 ②范围 ③新问题"]
                VERIFY --> LOG["Log: 记录 + 持久化<br/>tmp/.agent-session.md"]
                LOG --> EXIT_CHECK{"P0 全部解决？<br/>无新增 P0？"}
                EXIT_CHECK -->|否| RALPH
            end
        end

        subgraph P4["Phase 4: 人工核验"]
            A4_REPORT["输出核验报告<br/>改动资产 / 规范符合性 / 遗留问题"]
            A4_REPORT --> GATE_VERIFY{{"🔴 人工卡点<br/>确认改动"}}
        end

        subgraph P5["Phase 5: 合规入库"]
            A5_COMMIT["/commit-with-affects<br/>带影响面的标准化提交"]
            A5_DECISION{"有未记录的决策？"}
            A5_COMMIT --> A5_DECISION
            A5_DECISION -->|是| A5_ADR["/record-decision"]
            A5_DECISION -->|否| A5_CLEAN["删除 session 存档"]
            A5_ADR --> A5_CLEAN
        end

        P0 --> P1 --> P2
        GATE_PLAN -->|确认| P3
        GATE_PLAN -->|有问题| A2_PR
        EXIT_CHECK -->|是| P4
        GATE_VERIFY -->|确认| P5
        GATE_VERIFY -->|有问题| RALPH
    end

    %% ──────────────── DEV-FLOW ────────────────
    subgraph DEVFLOW["dev-flow（人工驱动模式）"]
        direction TB
        D1["Step 1: 探测与预研<br/>（条件：新路由/大重构）"]
        D2["Step 2: 脑部钢印读取<br/>加载 conventions + 领域 skill"]
        D3_CHECK{"轻量任务？"}
        D3["Step 3: /proposal-review<br/>方案评审"]
        D3_GATE{{"🔴 人工卡点<br/>确认方案"}}
        D4["Step 4: /impact-analysis<br/>（条件：API/DB/跨组件）"]
        D5["Step 5: 测试骨架<br/>（按改动类型路由策略）"]
        D6["Step 6: 编码开发"]
        D7["Step 7: DB 审计<br/>（条件：修改了 ORM）"]
        D8["Step 8: 测试门禁<br/>run-tests --mode fast"]
        D9["Step 9: /commit-with-affects"]

        D1 --> D2 --> D3_CHECK
        D3_CHECK -->|否| D3 --> D3_GATE
        D3_CHECK -->|是| D4
        D3_GATE -->|确认| D4
        D3_GATE -->|有问题| D3
        D4 --> D5 --> D6 --> D7 --> D8
        D8 -->|"❌ FAIL"| D6
        D8 -->|"✅ PASS"| D9
    end

    %% ──────────────── PR & 发布 ────────────────
    subgraph RELEASE["Phase: PR & 发布"]
        PR["/pr-review<br/>PR 描述 + 四维自检"]
        PROD["/production-release<br/>卫生扫描 → 测试 → DDL Review → 部署"]
        GATE_PROD{{"🔴 人工卡点<br/>发布确认"}}
        PR --> PROD --> GATE_PROD
    end

    A5_CLEAN --> PR
    D9 --> PR
    GATE_PROD -->|确认| DONE([上线完成])

    %% ──────────────── 样式 ────────────────
    classDef gate fill:#ff6b6b,stroke:#c0392b,color:#fff,font-weight:bold
    classDef skill fill:#4ecdc4,stroke:#1a535c,color:#fff
    classDef phase fill:#f7f1e3,stroke:#aaa

    class GATE_SPEC,GATE_PLAN,GATE_FE,GATE_VERIFY,GATE_PROD,D3_GATE gate
    class RC,A2_PR,FE_UX,A5_COMMIT,A5_ADR,PR,PROD,D3,D4,D8,D9 skill
```

## 人工卡点汇总

| 卡点 | 位置 | 触发条件 | 通过条件 |
|------|------|----------|----------|
| 需求确认 | requirement-clarification 输出后 | 始终 | 用户确认规格书 |
| 方案评审 | auto-dev Phase 2 / dev-flow Step 3 | 非轻量任务 | 用户回复"确认，继续执行" |
| UX 评估 | frontend-tdd 每个组件完成后 | 涉及前端 UX | 用户确认所有 🔴 已修复 |
| 改动核验 | auto-dev Phase 4 | 始终 | 用户确认核验报告 |
| 发布确认 | production-release | 始终 | QA + DBA + 部署审批 |

## 轻量路径（跳过 proposal-review）

以下场景自动跳过方案评审卡点，减少确认疲劳：
- Bug fix 且预计改动文件 ≤ 2 个
- 纯样式 / 纯文案调整
- 单文件局部修改
