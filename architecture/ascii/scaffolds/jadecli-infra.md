---
entity_id: scaffold-jadecli-infra
entity_name: jadecli-infra
entity_type: project_scaffold
entity_language: yaml
entity_status: buildable
entity_path: modules/jadecli-infra
entity_dependencies:
  core: [docker-compose]
  testing: []
  dev: []
entity_services:
  - postgresql
  - mongodb
  - dragonfly
  - ollama
entity_ports: [5432, 27017, 6379, 11434]
entity_health_check: "cd modules/jadecli-infra && docker compose ps"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---

# jadecli-infra

Docker Compose infrastructure stack for the jadecli ecosystem.

## ASCII Structure

```
jadecli-infra/
├── docker-compose.yml             # Main stack definition
├── docker-compose.gpu.yml         # GPU override (Ollama)
├── init-pgvector.sql              # Vector extension + schema
├── scripts/
│   ├── health-check.sh            # Full infrastructure check
│   ├── smoke-test.sh              # Quick connectivity test
│   ├── backup-mongo.sh            # MongoDB backup
│   └── restore-mongo.sh           # MongoDB restore
├── .env.example                   # Environment template
└── README.md
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────────────────┐
│                       jadecli-infra                              │
│                    (Docker Compose Stack)                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │  PostgreSQL  │  │   MongoDB    │  │  Dragonfly   │           │
│  │  + pgvector  │  │      7       │  │   (cache)    │           │
│  │    :5432     │  │    :27017    │  │    :6379     │           │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘           │
│         │                 │                 │                    │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                      Ollama (optional)                    │   │
│  │                    GPU profile :11434                     │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└──────────────────────────────┬───────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
  │ jade-index  │       │jade-dev-    │       │claude-      │
  │ (embeddings)│       │assist       │       │objects      │
  └─────────────┘       │(metrics)    │       │(MCP)        │
                        └─────────────┘       └─────────────┘
```

## Service Details

```
┌────────────────┬────────┬─────────────────────────────────────┐
│ Service        │ Port   │ Purpose                             │
├────────────────┼────────┼─────────────────────────────────────┤
│ PostgreSQL 16  │ 5432   │ Vector storage (pgvector + HNSW)    │
│ MongoDB 7      │ 27017  │ Document storage, metrics           │
│ Dragonfly      │ 6379   │ Redis-compatible cache              │
│ Ollama         │ 11434  │ Local LLM (GPU profile only)        │
└────────────────┴────────┴─────────────────────────────────────┘
```

## Dependencies

```
REQUIRES:
├── Docker + Compose   # Container runtime
├── NVIDIA drivers     # For GPU profile (optional)
└── ~10GB disk         # Data volumes

REQUIRED BY:
├── jade-index         # pgvector, Dragonfly
├── jade-dev-assist    # MongoDB (optional)
├── claude-objects     # All services via MCP
└── jade-ide           # Indirect via jade-index
```

## Quick Commands

```bash
jade-up      # docker compose up -d
jade-down    # docker compose down
jade-logs    # docker compose logs -f
```
