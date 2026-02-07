# Session Hooks Rule

Session hooks automate context loading on Claude Code session start.

## How It Works

When you start a Claude Code session in this directory, the session hook:

1. Checks if `~/.jade/context.md` exists
2. Checks if context is stale (> 1 hour old)
3. Regenerates context if needed using `generate-context.sh --brief`
4. Silently succeeds if context is fresh

## Configuration

Hook is registered in `.claude/settings.json`:

```json
{
  "hooks": {
    "sessionStart": ".claude/hooks/session-start.sh"
  }
}
```

## Settings

Hook configuration is controlled via `cli/settings.py`:

| Setting | Default | Description |
|---------|---------|-------------|
| `jade_context_file` | `~/.jade/context.md` | Context output location |
| `context_token_budget` | 15000 | Max tokens for context |

You can override these in `.env`:

```dotenv
JADE_CONTEXT_FILE=/custom/path/context.md
CONTEXT_TOKEN_BUDGET=20000
```

## Manual Regeneration

To force regeneration:

```bash
./scripts/generate-context.sh
```

## Timeout Protection

Hook has 30-second timeout (configured in Claude Code settings).
If generation takes longer, session will continue without context.

## Benefits

- **Zero Manual Steps**: Context auto-refreshes on session start
- **Always Fresh**: Detects stale context (> 1 hour)
- **Fast Start**: Skips regeneration if recent
- **Configurable**: Tune via settings
