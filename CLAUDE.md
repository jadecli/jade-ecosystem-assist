# jade-ecosystem-assist

Meta-repository providing ecosystem context, architecture documentation, and session initialization for the jadecli ecosystem.

## Purpose

This repo serves as the "ecosystem brain" - providing:
1. **Read-only references** to all 10 jadecli projects via git submodules
2. **ASCII architecture diagrams** showing project structures and connections
3. **Session initialization** context for Claude Code sessions

## Quick Start

```bash
# Load ecosystem context for a Claude Code session
cat architecture/ascii/scaffolds/*.md | claude

# Or use jade-start from dotfiles
jade-start --context
```

## Structure

```
jade-ecosystem-assist/
├── origin/                     # Git submodules (read-only)
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
├── local/                      # Platform-specific setup
│   ├── linux/
│   ├── macos/
│   └── windows/
└── architecture/
    └── ascii/
        └── scaffolds/          # Per-project ASCII architecture docs
```

## 10 Projects

| Project | Purpose | Role |
|---------|---------|------|
| claude-objects | FastMCP servers | Infrastructure |
| dotfiles | Developer environment (chezmoi) | Setup |
| jade-claude-settings | Plugins & research | Configuration |
| jade-cli | Terminal UI (React Ink) | Frontend |
| jade-dev-assist | Task orchestrator | Core |
| jade-ide | VS Code fork | Frontend |
| jade-index | Semantic search (GPU) | Backend |
| jade-swarm | Skills/superpowers | Claude Code plugin |
| jadecli-infra | Docker infrastructure | Infrastructure |
| jadecli-roadmap | Architecture docs | Documentation |

## Submodules

Initialize after cloning:
```bash
git submodule update --init --recursive
```

Update to latest:
```bash
git submodule update --remote --merge
```

## Key Files

- `architecture/ascii/scaffolds/*.md` - ASCII diagrams for each project
- `.gitmodules` - Submodule definitions
- `local/<platform>/` - Platform-specific setup scripts

## Commands

From dotfiles:
- `jade-start` - Ecosystem launcher
- `jade-start --context` - Generate context from this repo
- `/jade-context` - Load context inside active Claude Code session

## Dependencies

This repo has no runtime dependencies. It's pure documentation and references.

## Relationship to Other Repos

```
jade-ecosystem-assist (this repo)
         │
         │ provides context to
         ▼
┌─────────────────────────┐
│   Claude Code Session   │
│                         │
│  Uses architecture docs │
│  to understand projects │
└─────────────────────────┘
         │
         │ works on
         ▼
┌─────────────────────────┐
│   Any of 10 Projects    │
└─────────────────────────┘
```
