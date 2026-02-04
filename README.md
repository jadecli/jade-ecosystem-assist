# jade-ecosystem-assist

Meta-repository providing ecosystem context, architecture documentation, and session initialization for the jadecli ecosystem.

## Quick Start

```bash
# Clone with submodules (read-only references to all 10 projects)
git clone --recurse-submodules https://github.com/jadecli/jade-ecosystem-assist.git

# Or initialize submodules after cloning
git submodule update --init --recursive

# Use for Claude Code session initialization
cat architecture/ascii/scaffolds/*.md | claude
```

## Structure

```
jade-ecosystem-assist/
├── origin/                        # Git submodules (read-only)
│   ├── claude-objects/
│   ├── dotfiles/
│   ├── jade-claude-settings/
│   ├── jade-cli/
│   ├── jade-dev-assist/
│   ├── jade-ide/
│   ├── jade-index/
│   ├── jade-swarm/
│   ├── jadecli-infra/
│   └── jadecli-roadmap-and-architecture/
├── local/                         # Platform-specific setup
│   ├── linux/                     # WSL2/Ubuntu scripts
│   ├── macos/                     # macOS setup
│   └── windows/                   # Windows setup
└── architecture/
    └── ascii/
        └── scaffolds/             # Per-project ASCII architecture docs
            ├── claude-objects.md
            ├── dotfiles.md
            ├── jade-cli.md
            ├── jade-dev-assist.md
            ├── jade-ide.md
            ├── jade-index.md
            ├── jade-swarm.md
            ├── jadecli-infra.md
            ├── jadecli-roadmap.md
            └── jade-claude-settings.md
```

## 10 Projects

| Project | Purpose | Branch |
|---------|---------|--------|
| claude-objects | FastMCP servers | main |
| dotfiles | Developer environment (chezmoi) | main |
| jade-claude-settings | Plugins & research | main |
| jade-cli | Terminal UI (React Ink) | main |
| jade-dev-assist | Task orchestrator | main |
| jade-ide | VS Code fork | jadecli-main |
| jade-index | Semantic search (GPU) | main |
| jade-swarm | Skills/superpowers | jadecli-main |
| jadecli-infra | Docker infrastructure | main |
| jadecli-roadmap | Architecture docs | main |

## Session Initialization

When starting a Claude Code session, load ecosystem context:

```bash
# Option 1: Use jade-start (from dotfiles)
jade-start --context
cat ~/.jade/context.md | claude

# Option 2: Load architecture scaffolds
cat ~/projects/jade-ecosystem-assist/architecture/ascii/scaffolds/*.md | claude

# Option 3: Inside Claude Code
/jade-context
```

## Updating Submodules

```bash
# Update all submodules to latest
git submodule update --remote --merge

# Update specific submodule
git submodule update --remote origin/jade-index
```

## Patterns & Anti-Patterns

See `architecture/ascii/scaffolds/<project>.md` for:
- ASCII structure diagrams
- Ecosystem connection graphs
- Dependency trees
- Key files and commands

## Visual Architecture

ASCII scaffolds: `architecture/ascii/scaffolds/<project>.md`
Mermaid diagrams: `architecture/mermaid/<project>.mmd`

Both provide project structure views - ASCII for quick reference, Mermaid for visual exploration.
