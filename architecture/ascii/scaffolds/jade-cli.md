---
entity_id: scaffold-jade-cli
entity_name: jade-cli
entity_type: project_scaffold
entity_language: typescript
entity_status: buildable
entity_path: modules/jade-cli
entity_dependencies:
  core: [ink, react, zustand]
  testing: [vitest]
  dev: [typescript, tsx]
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jade-cli && npm test"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---

# jade-cli

React Ink terminal UI for task management and orchestrator visualization.

## ASCII Structure

```
jade-cli/
├── src/
│   ├── commands/              # CLI command handlers
│   │   ├── orchestrate.tsx    # Task orchestration view
│   │   ├── tasks.tsx          # Task list/status
│   │   └── index.tsx          # jade index subcommands
│   ├── components/            # React Ink UI components
│   │   ├── TaskList.tsx
│   │   ├── TaskCard.tsx
│   │   └── StatusBar.tsx
│   ├── lib/
│   │   ├── scheduler.ts       # Task scheduling
│   │   └── jade-dev-assist.ts # Orchestrator integration
│   └── index.tsx              # Entry point
├── tests/                     # vitest test suite
├── package.json
└── tsconfig.json
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────┐
│                     Terminal                         │
│                        │                             │
│                        ▼                             │
│  ┌─────────────────────────────────────────────┐   │
│  │                  jade-cli                    │   │
│  │           (React Ink + TypeScript)           │   │
│  └──────────────────┬──────────────────────────┘   │
└─────────────────────┼───────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        │             │             │
        ▼             ▼             ▼
  ┌──────────┐  ┌──────────┐  ┌──────────────┐
  │jade-dev- │  │jade-index│  │ tasks.json   │
  │ assist   │  │  (MCP)   │  │ (per-project)│
  │(scorer)  │  │          │  │              │
  └──────────┘  └──────────┘  └──────────────┘
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| ink | ^5.0.0 | React for CLI |
| react | ^18.0.0 | UI framework |
| zustand | ^4.5.0 | State management |
| vitest | ^2.0.0 | Test framework |

```
REQUIRES:
├── jade-dev-assist   # Scorer for task prioritization
├── jade-index        # Semantic search (via MCP)
└── tasks.json files  # Per-project task definitions

REQUIRED BY:
├── Developer         # Terminal-based workflow
└── jade-start        # Launches jade-cli views
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `jade orchestrate` | Show prioritized task view |
| `jade tasks` | List all tasks across projects |
| `jade index search <query>` | Semantic code search (Phase 3) |
