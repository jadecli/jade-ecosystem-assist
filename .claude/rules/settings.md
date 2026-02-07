# Settings Rule - Centralized Configuration

## Golden Rule

**NEVER hardcode paths or environment-specific values in scripts.**

All configuration MUST be accessed through `cli/settings.py`.

## How It Works

```python
# ✅ CORRECT - Use settings
from cli.settings import settings

context_file = settings.jade_context_file
projects_base = settings.projects_base

# ❌ WRONG - Never do this
context_file = "$HOME/.jade/context.md"  # Hardcoded
projects_base = os.path.expanduser("~/projects")  # Fragile
```

## Settings Structure

```
cli/settings.py          # Settings class (source of truth)
.env                      # Local overrides (gitignored)
.env.example              # Template (committed)
GitHub Secrets            # CI/CD (org or repo level)
```

## Available Settings

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `environment` | str | "development" | Environment name |
| `is_ci` | bool | False | CI environment detection |
| `home_dir` | Path | `Path.home()` | User home directory |
| `projects_base` | Path | `~/projects` | Base for all projects |
| `jade_context_file` | Path | `~/.jade/context.md` | Generated context |
| `ecosystem_assist_root` | Path | repo root | This repo's root |
| `submodules_path` | Path | `modules/` | Submodules directory |
| `health_reports_dir` | Path | `docs/health-reports/` | Health reports |
| `context_token_budget` | int | 15000 | Max context tokens |
| `github_token` | str | None | GitHub API token |

## Usage in Bash Scripts

Export settings to environment:

```bash
# Load settings into environment
eval "$(python3 -c "
from cli.settings import settings
print(f'export JADE_CONTEXT_FILE={settings.jade_context_file}')
print(f'export PROJECTS_BASE={settings.projects_base}')
")"

# Use in script
echo "Context file: $JADE_CONTEXT_FILE"
```

## Adding New Settings

1. Add to `.env.example`:
   ```dotenv
   NEW_SETTING=
   ```

2. Add to `cli/settings.py`:
   ```python
   self.new_setting: Optional[str] = os.getenv("NEW_SETTING")
   ```

3. Add to local `.env`:
   ```dotenv
   NEW_SETTING=actual-value
   ```

## Security

- `.env` is gitignored
- Never commit secrets
- Use GitHub Secrets for CI/CD
