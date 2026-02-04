# jade-ide

VS Code fork with integrated AI assistance and jade-index semantic search.

## ASCII Structure

```
jade-ide/
├── .build/
│   └── vscode-src/                # Cloned VS Code source
├── patches/                       # JADE customizations
│   ├── branding.patch             # Icons, names, colors
│   └── product.patch              # product.json changes
├── extensions/
│   ├── jade-task-panel/           # Task management extension
│   │   └── src/
│   │       └── extension.ts
│   └── jade-ai/                   # AI chat extension
│       └── src/
│           ├── extension.ts
│           ├── ai/
│           │   ├── providers/     # Anthropic, Ollama
│           │   ├── indexing/      # searchBridge, contextEnricher
│           │   └── checkpoints/   # Git-based state snapshots
│           └── ui/
│               ├── chatPanel.ts
│               └── inlineEdit.ts
├── resources/                     # JADE icons, branding
└── scripts/
    ├── build.sh
    └── verify-patches.sh
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────────────────┐
│                           jade-ide                               │
│                    (Electron + VS Code base)                     │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐              ┌──────────────────┐         │
│  │  jade-task-panel │              │     jade-ai      │         │
│  │    (extension)   │              │   (extension)    │         │
│  └────────┬─────────┘              └────────┬─────────┘         │
│           │                                  │                   │
└───────────┼──────────────────────────────────┼───────────────────┘
            │                                  │
            ▼                                  ▼
     ┌─────────────┐                    ┌─────────────┐
     │tasks.json   │                    │ jade-index  │
     │(per-project)│                    │ (via CLI)   │
     └─────────────┘                    └──────┬──────┘
                                               │
                                               ▼
                                        ┌─────────────┐
                                        │  pgvector   │
                                        │ (embeddings)│
                                        └─────────────┘
```

## Dependencies

```
REQUIRES:
├── jade-index        # Semantic search for AI context
├── jadecli-infra     # pgvector, Dragonfly (via jade-index)
└── VS Code upstream  # Base editor source

REQUIRED BY:
├── Developer         # Primary IDE
└── jade-task-panel   # Visual task management
```

## Build Process

```
1. Clone VS Code     → .build/vscode-src/
2. Apply patches     → patches/*.patch
3. Build extensions  → extensions/jade-*/
4. Package           → jade-ide binary (185MB)
```
