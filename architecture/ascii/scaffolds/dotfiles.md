# dotfiles

Chezmoi-managed developer environment for jadecli ecosystem.

## ASCII Structure

```
dotfiles/
├── dot_bashrc                     # Bash shell config
├── dot_zshrc                      # Zsh with jade-* functions
├── dot_jade/                      # → ~/.jade/
│   ├── bin/jade-start             # Ecosystem launcher
│   ├── shell-hook.sh              # cd ~/projects hook
│   ├── ghostty-keybinds.conf      # Super+1-8 shortcuts
│   ├── projects.json              # 10-project registry
│   └── resume-template.md         # Session resume
├── dot_claude/                    # → ~/.claude/
│   ├── commands/jade-context.md   # /jade-context
│   └── settings.json              # Env + permissions
├── dot_config/                    # → ~/.config/
│   ├── ghostty/config
│   └── starship.toml
├── ecosystem/                     # Symlinked to ~/projects/
│   ├── CLAUDE.md
│   ├── DEVELOPER.md
│   └── setup-jade.sh
└── private_dot_ssh/               # age-encrypted keys
```

## Ecosystem Connections

```
┌─────────────────────────────────────────────────────┐
│                     dotfiles                         │
│  (chezmoi managed, age encrypted)                   │
└─────────────────────┬───────────────────────────────┘
                      │ chezmoi apply
                      ▼
┌─────────────────────────────────────────────────────┐
│                  Developer Machine                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────┐  │
│  │ ~/.jade/ │  │~/.claude/│  │ ~/.config/       │  │
│  │  bin/    │  │ commands/│  │  ghostty/        │  │
│  │  *.sh    │  │ settings │  │  starship.toml   │  │
│  └────┬─────┘  └────┬─────┘  └────────┬─────────┘  │
│       │             │                  │            │
│       ▼             ▼                  ▼            │
│  jade-start    Claude Code        Terminal          │
└─────────────────────────────────────────────────────┘
```

## Dependencies

```
REQUIRES:
├── chezmoi           # Dotfile manager
├── age               # Encryption for secrets
└── ghostty           # Terminal (optional)

REQUIRED BY:
├── All 10 projects   # Developer environment setup
└── New machine setup # First thing to apply
```

## Key Commands

| Command | Purpose |
|---------|---------|
| `jade-start` | Ecosystem dashboard |
| `jade-start <alias>` | Open project in Claude Code |
| `jade-start --resume` | Resume with context |
| `/jade-context` | Load context in active session |
