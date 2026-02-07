---
entity_id: scaffold-claude-objects
entity_name: claude-objects
entity_type: project_scaffold
entity_language: python
entity_status: buildable
entity_path: modules/claude-objects
entity_dependencies:
  core: [fastmcp, httpx, pydantic, asyncio]
  testing: [pytest, pytest-asyncio]
  dev: [ruff, ty]
entity_services:
  - mcp-server-claude-tools
  - mcp-server-jade-tool-agent
  - mcp-server-jade-swarm
  - mcp-server-tdd-agent-workflow
entity_ports: []
entity_health_check: "cd modules/claude-objects && uv run pytest tests/"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---

# claude-objects

FastMCP servers exposing jadecli functionality to Claude Code.

## ASCII Structure

```
claude-objects/
├── mcps/                          # FastMCP server implementations
│   ├── jade_index_mcp.py          # Semantic search (5 tools)
│   ├── jade_dev_assist_mcp.py     # Orchestrator tools
│   ├── jade_metrics_mcp.py        # Project metrics
│   ├── llms_txt_mcp.py            # LLMs.txt serving
│   ├── parallel_ai_mcp.py         # Parallel AI dispatch
│   └── swarm_cache_mcp.py         # Dragonfly cache access
├── agents/                        # Agent configurations
│   └── test_harness.py            # Agent testing framework
├── tests/                         # pytest test suite
└── pyproject.toml                 # uv/Python config
```

## Ecosystem Connections

```
                    ┌─────────────────┐
                    │  Claude Code    │
                    │    (client)     │
                    └────────┬────────┘
                             │ MCP protocol
                             ▼
┌────────────────────────────────────────────────────┐
│                  claude-objects                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────┐ │
│  │jade_index_mcp│  │jade_dev_mcp  │  │swarm_mcp │ │
│  └──────┬───────┘  └──────┬───────┘  └────┬─────┘ │
└─────────┼─────────────────┼───────────────┼───────┘
          │                 │               │
          ▼                 ▼               ▼
    ┌──────────┐     ┌────────────┐   ┌──────────┐
    │jade-index│     │jade-dev-   │   │Dragonfly │
    │ (Python) │     │  assist    │   │ (cache)  │
    └──────────┘     └────────────┘   └──────────┘
```

## Dependencies

### Core
| Package | Version | Purpose |
|---------|---------|---------|
| fastmcp | ^0.2.0 | MCP server framework |
| httpx | ^0.27.0 | HTTP client |
| pydantic | ^2.0.0 | Data validation |

### Testing
| Package | Version | Purpose |
|---------|---------|---------|
| pytest | ^8.0.0 | Test framework |
| pytest-asyncio | ^0.23.0 | Async test support |

```
REQUIRES:
├── jade-index        # For semantic search
├── jadecli-infra     # PostgreSQL, Dragonfly, MongoDB
└── jade-dev-assist   # For orchestrator tools

REQUIRED BY:
├── jade-ide          # AI chat uses MCP servers
├── jade-cli          # Terminal UI queries MCP
└── jade-swarm        # Swarm workers use cache MCP
```

## Key Files

| File | Purpose |
|------|---------|
| `mcps/jade_index_mcp.py` | search, index_project, get_status, invalidate_cache, health_check |
| `mcps/swarm_cache_mcp.py` | get, set, delete for worker state sharing |
| `tests/test_mcp_*.py` | Integration tests against live services |
