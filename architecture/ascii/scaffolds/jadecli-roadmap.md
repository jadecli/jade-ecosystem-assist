---
entity_id: scaffold-jadecli-roadmap
entity_name: jadecli-roadmap-and-architecture
entity_type: project_scaffold
entity_language: markdown
entity_status: scaffolding
entity_path: modules/jadecli-roadmap-and-architecture
entity_dependencies:
  core: []
  testing: []
  dev: []
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jadecli-roadmap-and-architecture && find docs -name '*.md' | wc -l"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---

# jadecli-roadmap-and-architecture

Architecture decisions, diagrams, and roadmap for the jadecli ecosystem.

## ASCII Structure

```
jadecli-roadmap-and-architecture/
├── ARCHITECTURE.md                # System context, links to diagrams
├── decisions/                     # ADRs (Architecture Decision Records)
│   ├── 0001-use-dragonfly-over-redis.md
│   ├── 0002-neon-local-proxy-for-branching.md
│   ├── 0003-merkle-tree-l1-l4-ast-chunking.md
│   ├── 0004-local-embeddings-on-gpu.md
│   ├── 0005-fastmcp-for-custom-mcps.md
│   ├── 0006-conventional-commits-and-graphite.md
│   ├── 0007-fork-superpowers-as-jade-swarm.md
│   ├── 0008-hybrid-orchestrator-architecture.md
│   └── template.md
├── diagrams/                      # Mermaid syntax files
│   ├── context.md                 # C4 context diagram
│   ├── containers.md              # C4 container diagram
│   ├── data-flow.md
│   ├── sequences/                 # Sequence diagrams
│   │   ├── orchestrator-dispatch.md
│   │   ├── jade-index-*.md
│   │   └── ...
│   └── er/                        # Entity relationship diagrams
├── roadmap/
│   ├── current.md                 # Active phase goals
│   ├── completed.md               # Done items
│   └── vision.md                  # 5-phase long-term vision
├── docs/
│   ├── architecture/              # Deep-dive docs
│   │   ├── health-check-report-*.md
│   │   └── jade-index-ecosystem.md
│   └── plans/                     # Design documents
└── .github/
    └── workflows/
        └── ci.yml                 # ADR + link validation
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────────────────┐
│              jadecli-roadmap-and-architecture                    │
│                    (Documentation Hub)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │    ADRs      │  │   Diagrams   │  │   Roadmap    │           │
│  │  (decisions) │  │  (Mermaid)   │  │   (phases)   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                   Health Check Reports                    │   │
│  │            (Ecosystem status snapshots)                   │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                               │
                               │ References
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ALL 10 PROJECTS                             │
│   Documents architecture decisions affecting each project        │
└─────────────────────────────────────────────────────────────────┘
```

## Phase Roadmap

```
┌────────┬─────────────────────┬─────────────────────────────────┐
│ Phase  │ Name                │ Status                          │
├────────┼─────────────────────┼─────────────────────────────────┤
│   1    │ Foundation          │ ✅ COMPLETE                     │
│   2    │ Integration         │ ✅ COMPLETE                     │
│   3    │ Release             │ 🔄 IN PROGRESS (6 tasks)        │
│   4    │ Scale               │ ⏳ PLANNED                      │
│   5    │ Ecosystem           │ ⏳ PLANNED                      │
└────────┴─────────────────────┴─────────────────────────────────┘
```

## Dependencies

```
REQUIRES:
├── Nothing           # Pure documentation

REQUIRED BY:
├── All 10 projects   # Architecture reference
├── New contributors  # Onboarding docs
└── jade-dev-assist   # Health check baseline
```
