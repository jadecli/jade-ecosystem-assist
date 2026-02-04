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
