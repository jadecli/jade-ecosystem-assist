# jade-swarm

Fork of obra/superpowers with swarm orchestration skills for multi-agent coordination.

## ASCII Structure

```
jade-swarm/
├── skills/                        # 21 skill directories
│   ├── [inherited - 14]           # From upstream superpowers
│   │   ├── brainstorming/
│   │   ├── test-driven-development/
│   │   ├── systematic-debugging/
│   │   ├── writing-plans/
│   │   ├── executing-plans/
│   │   └── ...
│   └── [new swarm - 7]            # jadecli additions
│       ├── swarm-orchestration/
│       ├── swarm-worker/
│       ├── swarm-quality-gate/
│       ├── swarm-context-management/
│       ├── swarm-aggregation/
│       ├── swarm-init-generator/
│       └── github-projects/
├── agents/
│   └── code-reviewer.md
├── commands/
│   ├── brainstorm.md
│   ├── write-plan.md
│   └── execute-plan.md
├── hooks/
│   └── session-start.sh
└── .claude-plugin/
    └── plugin.json
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────────────────┐
│                         jade-swarm                               │
│                   (Claude Code Plugin)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                    SKILLS (21)                           │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │ brainstorming│  │   TDD        │  │  debugging   │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │    │
│  │  │swarm-        │  │swarm-worker  │  │swarm-quality │   │    │
│  │  │orchestration │  │              │  │    -gate     │   │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │    │
│  └─────────────────────────────────────────────────────────┘    │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
  │jade-dev-    │       │ Dragonfly   │       │All projects │
  │assist       │       │ (state)     │       │(skill users)│
  └─────────────┘       └─────────────┘       └─────────────┘
```

## Context Overflow Mitigations

```
┌────────────────────────────────────────────────────────────┐
│                   TOKEN BUDGETS                             │
├────────────────┬───────────────────────────────────────────┤
│ Per-agent cap  │ 40,000 tokens                             │
│ Core context   │ 15,000 tokens                             │
│ Wrap-up        │ 30,000 tokens (agent should finish)       │
│ Retry summary  │ 500 tokens                                │
└────────────────┴───────────────────────────────────────────┘
```

## Fork Strategy

```
main          ← syncs with obra/superpowers upstream
                     │
                     ▼
jadecli-main  ← jadecli customizations (swarm skills, agents)
```
