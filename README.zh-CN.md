[English](README.md) | **中文**

# CCClaude

**可复用的 Claude Code 框架，采用角色-配置文件组合架构。**

CCClaude 为跨软件项目使用 Claude Code 提供了结构化框架。它定义了角色、配置文件、技能、规则和钩子，在运行时组合生成专业化的 AI 开发智能体。

## 特性

- **5 个角色**：Planner、Worker、Reviewer、Releaser、Harden
- **10 个配置文件**：架构师、后端、前端、数据库、DevOps、安全、性能、测试、评审、文档
- **护栏规则**：编码风格、Git 工作流、测试、安全和性能规则在每次交互中强制执行
- **上下文技能**：根据对话上下文自动加载领域知识
- **可扩展**：无需修改框架即可添加项目特定的配置文件、技能和规则

## 快速开始

### 1. 克隆框架

```bash
git clone https://github.com/anthropics/CCClaude.git
```

### 2. 在你的项目中初始化

```bash
# Unix/macOS
/path/to/CCClaude/init.sh /path/to/your-project

# Windows PowerShell
/path/to/CCClaude/init.ps1 -ProjectDir /path/to/your-project
```

### 3. 开始使用

```
/plan 添加基于 OAuth 2.0 的用户认证
/work T1
/review
/harden all    # 对照 Iron Rules 标准审计所有角色定义
```

## 架构

```
┌─────────────────────────────────────────────────┐
│                  CCClaude Harness                │
│                                                  │
│  ┌──────────┐   ┌──────────┐   ┌──────────┐    │
│  │  Planner  │   │  Worker   │   │ Reviewer  │    │
│  │   角色    │   │   角色    │   │   角色    │    │
│  └────┬─────┘   └────┬─────┘   └────┬─────┘    │
│       │              │              │            │
│       ▼              ▼              ▼            │
│  ┌──────────────────────────────────────────┐   │
│  │            配置文件组合层                  │   │
│  │  backend | frontend | devops | testing    │   │
│  │  security | database | api | docs | perf  │   │
│  └──────────────────┬───────────────────────┘   │
│                     │                            │
│       ┌─────────────┼─────────────┐              │
│       ▼             ▼             ▼              │
│  ┌─────────┐  ┌──────────┐  ┌─────────┐        │
│  │  规则    │  │   技能    │  │  钩子    │        │
│  │(始终加载)│  │(按上下文) │  │(事件触发)│        │
│  └─────────┘  └──────────┘  └─────────┘        │
│                                                  │
│       角色 + 配置文件 + 规则 + 技能              │
│                    =                             │
│              运行时智能体                         │
└─────────────────────────────────────────────────┘
```

## 目录结构

```
CCClaude/
├── CLAUDE.md                    # 框架自身文档
├── README.md                    # 英文说明
├── README.zh-CN.md              # 本文件
├── LICENSE                      # MIT 许可证
├── init.sh                      # Unix/macOS 项目初始化脚本
├── init.ps1                     # Windows 项目初始化脚本
├── rules/
│   ├── common/                  # 通用规则（始终加载）
│   │   ├── coding-style.md
│   │   ├── git-workflow.md
│   │   ├── testing.md
│   │   ├── security.md
│   │   └── performance.md
│   └── _project/                # 项目特定规则
├── skills/
│   ├── common/                  # 共享技能（按上下文加载）
│   │   ├── git-workflow/
│   │   ├── code-review-checklist/
│   │   └── tdd-workflow/
│   └── _project/                # 项目特定技能
├── profiles/
│   ├── common/                  # 内置配置文件
│   └── _project/                # 项目特定配置文件
├── templates/                   # 文件模板
│   ├── Plans.md.template
│   └── CLAUDE.md.template
└── commands/                    # 斜杠命令定义
```

## 配置文件

| 配置文件 | 说明 |
|---------|------|
| `architect` | 系统设计、组件边界、API 契约、ADR 文档、DDD |
| `backend` | 服务端开发：API、DDD、整洁架构、错误处理、日志 |
| `frontend` | UI 组件、状态管理、无障碍访问（WCAG 2.1 AA）、性能 |
| `database` | Schema 设计、数据库迁移、查询优化、索引、多数据库支持 |
| `devops` | CI/CD 流水线、Docker/K8s、部署策略、监控、基础设施 |
| `security` | 漏洞检测、OWASP Top 10、供应链安全、失败安全模式 |
| `performance` | 性能分析、基准测试、回归检测、N+1 查询、Core Web Vitals |
| `testing` | TDD 工作流、差异感知测试、回归检测、边界用例覆盖 |
| `reviewer` | 多轮代码评审、置信度评分、反模式检测、AI 残留检测 |
| `documentation` | 差异驱动文档更新、API 文档、跨文档一致性、CHANGELOG 管理 |

## 命令

| 命令 | 角色 | 说明 |
|------|------|------|
| `/plan <feature>` | Planner | 将功能分解为任务，生成 Plans.md |
| `/work <task-id>` | Worker | 执行 Plans.md 中的指定任务 |
| `/review` | Reviewer | 对照所有规则评审当前代码变更 |
| `/release [patch\|minor\|major]` | Releaser | 准备发布：变更日志、版本号、标签 |
| `/orchestrate <pipeline>` | 全部 | 运行流水线：feature、bugfix、refactor 或 security |
| `/harden [role\|all]` | Harden | 审计并加固角色/配置文件/规则定义 |

## Iron Rule 体系

CCClaude 的核心创新是一套结构化的 Iron Rule 体系，用于防止 AI 智能体犯常见错误。每个角色定义都包含：

- **工具禁令** — 明确列出允许和禁止的工具，并说明原因
- **编号 Iron Rules（铁律）** — NEVER/DO NOT/CRITICAL 声明，每条都附带违规后果说明
- **禁令格式标准** — 不使用软性措辞，不留逃逸口，每条禁令必须可验证且具体

`rules/common/` 中有三条适用于所有角色的通用规则：
- `iron-rule-standard.md` — 禁令格式和结构要求
- `honesty.md` — 禁止猜测、禁止编造，必须显式标注不确定性
- `anti-overreach.md` — 保持在职责范围内，禁止过度设计

**Harden 角色**（`/harden`）对照这些标准审计所有角色和配置文件定义，实现双重约束。

## 自定义

### 添加项目特定规则

在 `rules/_project/` 中创建 Markdown 文件：

```markdown
<!-- rules/_project/api-conventions.md -->
# API 约定

- 所有接口返回 JSON 信封格式：{ data, error, meta }
- JSON 字段名使用 snake_case
- 版本前缀：/api/v1/
```

### 添加项目特定技能

在 `skills/_project/` 中创建目录并包含 `SKILL.md`：

```markdown
<!-- skills/_project/domain-model/SKILL.md -->
---
name: domain-model
description: "项目领域模型和业务规则"
---

# 领域模型
...
```

### 添加项目特定配置文件

在 `profiles/_project/` 中创建配置文件定义，用于项目独有的角色。

## 贡献

1. Fork 本仓库
2. 创建功能分支：`git checkout -b feature/your-feature`
3. 遵循 `rules/common/` 中的规则进行开发
4. 为新功能编写测试
5. 提交 Pull Request

## 许可证

MIT 许可证。详见 [LICENSE](LICENSE)。

## 致谢

CCClaude 从以下开源项目和资源中获得灵感：

- [Anthropic Claude Code](https://docs.anthropic.com/en/docs/claude-code) — 本框架所扩展的基础
- [everything-claude-code](https://github.com/affaan-m/everything-claude-code) — 136+ 技能、30+ 智能体、全面的框架
- [claude-code-harness](https://github.com/Chachamaru127/claude-code-harness) — Plan→Work→Review 循环、TypeScript 护栏引擎
- [garrytan/gstack](https://github.com/garrytan/gstack) — 一流的评审、测试和基准测试技能
- [trailofbits/skills](https://github.com/trailofbits/skills) — 来自顶级审计公司的安全技能
- [VoltAgent/awesome-claude-code-subagents](https://github.com/VoltAgent/awesome-claude-code-subagents) — 子智能体目录
- [alirezarezvani/claude-skills](https://github.com/alirezarezvani/claude-skills) — 数据库和后端配置文件
- [OpenSSF Security Guide](https://best.openssf.org/Security-Focused-Guide-for-AI-Code-Assistant-Instructions.html) — AI 安全最佳实践
