# jade-dev-assist

Central orchestrator for the jadecli ecosystem - scans, scores, and dispatches tasks.

## ASCII Structure

```
jade-dev-assist/
├── lib/                           # Core modules
│   ├── scanner.js                 # Reads tasks.json from all projects
│   ├── scorer.js                  # 5-factor priority algorithm
│   ├── presenter.js               # Terminal table display
│   ├── dispatcher.js              # Worker prompt construction
│   ├── executor.js                # Claude Code spawning
│   ├── status-updater.js          # Task completion tracking
│   └── github-sync.js             # GitHub Projects sync
├── commands/                      # Claude Code commands (14)
├── skills/                        # Workflow skills (6)
├── agents/                        # Agent configs (3)
├── hooks/                         # Session hooks
├── scripts/
│   ├── sync-github-projects.js
│   └── github-projects.sh
├── bin/
│   └── dashboard.py               # Rich terminal dashboard
└── tests/                         # TDD test suite
```

## Ecosystem Connections

```
                  ┌────────────────────────────────────┐
                  │         jade-dev-assist            │
                  │           (orchestrator)           │
                  └──────────────┬─────────────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
         ▼                       ▼                       ▼
  ┌─────────────┐        ┌─────────────┐        ┌─────────────┐
  │   SCANNER   │        │   SCORER    │        │ DISPATCHER  │
  │             │        │             │        │             │
  │ Read all    │───────▶│ 5-factor    │───────▶│ Construct   │
  │ tasks.json  │        │ priority    │        │ worker      │
  └─────────────┘        └─────────────┘        │ prompts     │
         │                                       └──────┬──────┘
         │                                              │
         ▼                                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        10 PROJECT REPOS                          │
│  ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐ ┌────────┐        │
│  │jade-ide│ │jade-   │ │claude- │ │jadecli-│ │jade-cli│  ...   │
│  │        │ │index   │ │objects │ │infra   │ │        │        │
│  └────────┘ └────────┘ └────────┘ └────────┘ └────────┘        │
└─────────────────────────────────────────────────────────────────┘
```

## Dependencies

```
REQUIRES:
├── All 10 projects   # Scans their tasks.json files
├── jadecli-infra     # MongoDB for metrics (optional)
└── jade-swarm        # Skill definitions

REQUIRED BY:
├── jade-cli          # Uses scorer for prioritization
├── claude-objects    # jade_dev_assist_mcp wraps this
└── jade-swarm        # Workers receive dispatched tasks
```

## Scoring Algorithm

```
SCORE = Σ (weight × factor)

┌────────────────┬────────┬─────────────────────────────┐
│ Factor         │ Weight │ Calculation                 │
├────────────────┼────────┼─────────────────────────────┤
│ Urgency        │ 0.30   │ Days until milestone        │
│ Dependencies   │ 0.25   │ Count of blocked tasks      │
│ Complexity     │ 0.20   │ S=1, M=2, L=3              │
│ Recency        │ 0.15   │ Days since created          │
│ Labels         │ 0.10   │ critical=+2, test=+1       │
└────────────────┴────────┴─────────────────────────────┘
```
