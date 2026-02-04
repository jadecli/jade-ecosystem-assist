---
entity_id: scaffold-jade-index
entity_name: jade-index
entity_type: project_scaffold
entity_language: python
entity_status: buildable
entity_path: modules/jade-index
entity_dependencies:
  core: [sentence-transformers, pgvector, tree-sitter, click]
  infrastructure: ["psycopg[binary]", redis]
  testing: [pytest]
  dev: [ruff, ty]
entity_services:
  - indexer
  - api
entity_ports: [8000]
entity_health_check: "cd modules/jade-index && uv run pytest tests/"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---

# jade-index

Semantic search engine with Merkle tree indexing, AST chunking, and GPU embeddings.

## ASCII Structure

```
jade-index/
├── src/jade_index/
│   ├── merkle.py              # Change detection via file hashing
│   ├── chunker.py             # AST parsing → L1-L4 chunks
│   ├── embedder.py            # GPU embedding (sentence-transformers)
│   ├── store.py               # Dual backend (JSON + pgvector)
│   ├── cache.py               # Two-layer Dragonfly cache
│   ├── db.py                  # Connection pooling with retry
│   ├── incremental.py         # Smart re-indexing
│   └── cli.py                 # Click CLI (4 commands)
├── tests/                     # pytest (247 tests, 98.6% coverage)
├── pyproject.toml
└── README.md
```

## Ecosystem Connections

```
                         SOURCE CODE
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                         jade-index                               │
│                                                                  │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐  │
│  │  MERKLE  │───▶│ CHUNKER  │───▶│ EMBEDDER │───▶│  STORE   │  │
│  │  (hash)  │    │  (AST)   │    │  (GPU)   │    │(pgvector)│  │
│  └──────────┘    └──────────┘    └──────────┘    └──────────┘  │
│       │                                               │         │
│       │              ┌──────────┐                     │         │
│       └─────────────▶│  CACHE   │◀────────────────────┘         │
│                      │(Dragonfly)│                              │
│                      └──────────┘                               │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              │               │               │
              ▼               ▼               ▼
       ┌──────────┐    ┌──────────┐    ┌──────────┐
       │jade-ide  │    │claude-   │    │jade-cli  │
       │(jade-ai) │    │objects   │    │(search)  │
       └──────────┘    └──────────┘    └──────────┘
```

## AST Chunking Levels

```
┌─────────────────────────────────────────────────────┐
│ L1: ENTIRE FILE                                      │
│ ┌─────────────────────────────────────────────────┐ │
│ │ L2: CLASS / INTERFACE                           │ │
│ │ ┌─────────────────────────────────────────────┐ │ │
│ │ │ L3: FUNCTION / METHOD                       │ │ │
│ │ │ ┌─────────────────────────────────────────┐ │ │ │
│ │ │ │ L4: BLOCK (for/if/try)                  │ │ │ │
│ │ │ └─────────────────────────────────────────┘ │ │ │
│ │ └─────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────┘
```

## Dependencies

### Core
| Package | Version | Purpose |
|---------|---------|---------|
| sentence-transformers | ^3.0.0 | GPU embeddings |
| pgvector | ^0.3.0 | Vector storage |
| tree-sitter | ^0.22.0 | AST parsing |
| click | ^8.0.0 | CLI framework |

### Infrastructure
| Package | Version | Purpose |
|---------|---------|---------|
| psycopg[binary] | ^3.0.0 | PostgreSQL driver |
| redis | ^5.0.0 | Dragonfly client |

```
REQUIRES:
├── jadecli-infra     # PostgreSQL + pgvector, Dragonfly
├── RTX 2080 Ti       # GPU for embeddings (fallback: CPU)
└── tree-sitter       # AST parsing

REQUIRED BY:
├── jade-ide          # Context enrichment for AI
├── claude-objects    # jade_index_mcp server
└── jade-cli          # `jade index search` command
```
