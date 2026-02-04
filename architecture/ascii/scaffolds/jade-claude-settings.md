# jade-claude-settings

Curated Claude Code plugins, research documentation, and development environment setup.

## ASCII Structure

```
jade-claude-settings/
├── plugins/                       # Curated plugin collection
│   ├── recommended/               # Vetted plugins for jadecli
│   └── experimental/              # Testing new plugins
├── research/                      # Claude Code research docs
│   ├── api-documentation/
│   ├── best-practices/
│   └── feature-requests/
├── environments/                  # Dev environment configs
│   ├── wsl2/
│   ├── macos/
│   └── windows/
├── templates/                     # Project templates
│   ├── python-uv/
│   ├── typescript-node/
│   └── claude-plugin/
└── .claude/
    └── tasks/tasks.json
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────────────────┐
│                    jade-claude-settings                          │
│              (Research & Configuration Hub)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐           │
│  │   Plugins    │  │   Research   │  │ Environments │           │
│  │  (curated)   │  │    (docs)    │  │  (configs)   │           │
│  └──────────────┘  └──────────────┘  └──────────────┘           │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │                     Templates                             │   │
│  │        (Project scaffolds for new repos)                  │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
                               │
         ┌─────────────────────┼─────────────────────┐
         │                     │                     │
         ▼                     ▼                     ▼
  ┌─────────────┐       ┌─────────────┐       ┌─────────────┐
  │  dotfiles   │       │ jade-swarm  │       │ New project │
  │ (installs)  │       │ (plugins)   │       │ (templates) │
  └─────────────┘       └─────────────┘       └─────────────┘
```

## Purpose

```
┌────────────────────────────────────────────────────────────────┐
│                                                                 │
│  1. RESEARCH       - Document Claude Code capabilities          │
│                    - Track API changes, new features            │
│                                                                 │
│  2. CURATE         - Vet third-party plugins                   │
│                    - Maintain recommended plugin list           │
│                                                                 │
│  3. CONFIGURE      - Platform-specific environment setup        │
│                    - IDE settings, shell configs                │
│                                                                 │
│  4. TEMPLATE       - Project scaffolds for common patterns      │
│                    - Quick-start for new repos                  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

## Dependencies

```
REQUIRES:
├── Claude Code       # Target platform
└── dotfiles          # Environment setup

REQUIRED BY:
├── New projects      # Use templates
├── Developer setup   # Environment configs
└── jade-swarm        # Plugin research
```

## Relationship to dotfiles

```
jade-claude-settings     dotfiles
       │                    │
       │  research &        │  actual installation
       │  curation          │  & management
       │                    │
       └────────┬───────────┘
                │
                ▼
         Developer Machine
```
