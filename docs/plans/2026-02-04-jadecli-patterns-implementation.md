# jadecli-codespaces Patterns Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Apply 3 proven patterns from jadecli-codespaces to reduce cognitive overhead in jade-ecosystem-assist

**Architecture:** Add frontmatter metadata to scaffolds for querying, centralize configuration in Pydantic settings, automate context loading via session hooks

**Tech Stack:** Python 3.10+, Pydantic, PyYAML, Bash

---

## Task 1: Frontmatter Template and Validation

**Files:**
- Create: `scripts/query-scaffolds.sh`
- Create: `scripts/validate-scaffolds.sh`
- Create: `.claude/rules/scaffold-metadata.md`
- Create: `tests/test_scaffold_metadata.py`

**Step 1: Write test for frontmatter validation**

```python
# tests/test_scaffold_metadata.py
import pytest
from pathlib import Path
import yaml

def test_scaffold_has_valid_frontmatter():
    """Verify scaffold files have required frontmatter fields."""
    scaffold_dir = Path("architecture/ascii/scaffolds")
    test_file = scaffold_dir / "claude-objects.md"

    content = test_file.read_text()

    # Check for YAML frontmatter
    assert content.startswith("---\n"), "Missing frontmatter start"
    assert "\n---\n" in content, "Missing frontmatter end"

    # Extract frontmatter
    parts = content.split("---\n", 2)
    frontmatter = yaml.safe_load(parts[1])

    # Required fields
    required = [
        "entity_id",
        "entity_name",
        "entity_type",
        "entity_language",
        "entity_status",
        "entity_path",
        "entity_dependencies",
        "entity_health_check",
    ]

    for field in required:
        assert field in frontmatter, f"Missing required field: {field}"
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_scaffold_metadata.py -v`
Expected: FAIL with "Missing frontmatter start" (file doesn't have frontmatter yet)

**Step 3: Add frontmatter to claude-objects.md**

```markdown
# architecture/ascii/scaffolds/claude-objects.md
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

[existing content remains unchanged]
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/test_scaffold_metadata.py -v`
Expected: PASS

**Step 5: Create scaffold query script**

```bash
# scripts/query-scaffolds.sh
#!/bin/bash
# ---
# entity_id: script-query-scaffolds
# entity_name: Query Scaffolds Script
# entity_type_id: config
# entity_path: scripts/query-scaffolds.sh
# entity_language: bash
# entity_state: active
# ---

set -euo pipefail

SCAFFOLDS_DIR="architecture/ascii/scaffolds"

usage() {
    cat <<EOF
Query scaffold metadata

Usage: $0 [OPTIONS]

Options:
    --language LANG    Filter by language (python, typescript, etc.)
    --status STATUS    Filter by status (buildable, scaffolding, etc.)
    --dependency DEP   Filter by dependency
    --format FORMAT    Output format (text, json) [default: text]
    -h, --help         Show this help

Examples:
    $0 --language python
    $0 --dependency pytest
    $0 --status buildable --format json
EOF
}

LANGUAGE=""
STATUS=""
DEPENDENCY=""
FORMAT="text"

while [[ $# -gt 0 ]]; do
    case $1 in
        --language) LANGUAGE="$2"; shift 2 ;;
        --status) STATUS="$2"; shift 2 ;;
        --dependency) DEPENDENCY="$2"; shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

# Use Python to parse YAML frontmatter
python3 -c "
import sys
import yaml
from pathlib import Path

scaffolds_dir = Path('$SCAFFOLDS_DIR')
results = []

for md_file in sorted(scaffolds_dir.glob('*.md')):
    content = md_file.read_text()
    if not content.startswith('---'):
        continue

    parts = content.split('---\n', 2)
    if len(parts) < 3:
        continue

    meta = yaml.safe_load(parts[1])

    # Apply filters
    if '$LANGUAGE' and meta.get('entity_language', '') != '$LANGUAGE':
        continue
    if '$STATUS' and meta.get('entity_status', '') != '$STATUS':
        continue
    if '$DEPENDENCY':
        deps = meta.get('entity_dependencies', {})
        all_deps = []
        for dep_list in deps.values():
            all_deps.extend(dep_list)
        if '$DEPENDENCY' not in all_deps:
            continue

    results.append(meta)

if '$FORMAT' == 'json':
    import json
    print(json.dumps(results, indent=2))
else:
    for meta in results:
        print(f\"{meta['entity_name']}\")
        print(f\"  Language: {meta['entity_language']}\")
        print(f\"  Status: {meta['entity_status']}\")
        print(f\"  Path: {meta['entity_path']}\")
        print()
"
```

**Step 6: Make script executable and test**

Run:
```bash
chmod +x scripts/query-scaffolds.sh
./scripts/query-scaffolds.sh --language python
```
Expected: Output shows "claude-objects" with metadata

**Step 7: Create validation script**

```bash
# scripts/validate-scaffolds.sh
#!/bin/bash
# Validate all scaffolds have required frontmatter

set -euo pipefail

SCAFFOLDS_DIR="architecture/ascii/scaffolds"
EXIT_CODE=0

for md_file in "$SCAFFOLDS_DIR"/*.md; do
    filename=$(basename "$md_file")

    if ! grep -q "^---$" "$md_file"; then
        echo "✗ $filename: Missing frontmatter"
        EXIT_CODE=1
        continue
    fi

    # Extract and validate frontmatter with Python
    python3 -c "
import sys
import yaml
from pathlib import Path

content = Path('$md_file').read_text()
if not content.startswith('---'):
    sys.exit(1)

parts = content.split('---\n', 2)
if len(parts) < 3:
    print('Invalid frontmatter format')
    sys.exit(1)

meta = yaml.safe_load(parts[1])

required = [
    'entity_id', 'entity_name', 'entity_type', 'entity_language',
    'entity_status', 'entity_path', 'entity_dependencies', 'entity_health_check'
]

missing = [f for f in required if f not in meta]
if missing:
    print(f'Missing fields: {', '.join(missing)}')
    sys.exit(1)
" && echo "✓ $filename: Valid frontmatter" || {
        echo "✗ $filename: Invalid frontmatter"
        EXIT_CODE=1
    }
done

exit $EXIT_CODE
```

**Step 8: Make validation script executable and test**

Run:
```bash
chmod +x scripts/validate-scaffolds.sh
./scripts/validate-scaffolds.sh
```
Expected: Shows "✓ claude-objects.md: Valid frontmatter", failures for others (expected)

**Step 9: Document the pattern**

```markdown
# .claude/rules/scaffold-metadata.md
# Scaffold Metadata Rule

All architecture scaffolds MUST have YAML frontmatter with structured metadata.

## Required Frontmatter

```yaml
---
entity_id: scaffold-<project-name>
entity_name: <project-name>
entity_type: project_scaffold
entity_language: python | typescript | markdown
entity_status: buildable | scaffolding | blocked
entity_path: modules/<project-name>
entity_dependencies:
  core: [list, of, dependencies]
  testing: [list, of, test, deps]
  dev: [list, of, dev, deps]
entity_services: [list, of, services]
entity_ports: [list, of, ports]
entity_health_check: "command to check health"
entity_created: YYYY-MM-DD
entity_last_validated: YYYY-MM-DD
---
```

## Benefits

1. **Queryable**: Use `query-scaffolds.sh` to find projects by language, status, or dependency
2. **Validation**: Pre-commit hooks ensure consistency
3. **Automation**: Scripts can extract metadata without parsing markdown

## Validation

Run `./scripts/validate-scaffolds.sh` before committing changes to scaffolds.

## Queries

```bash
# All Python projects
./scripts/query-scaffolds.sh --language python

# Projects using pytest
./scripts/query-scaffolds.sh --dependency pytest

# Buildable projects
./scripts/query-scaffolds.sh --status buildable

# JSON output for automation
./scripts/query-scaffolds.sh --format json
```
```

**Step 10: Commit**

```bash
git add tests/test_scaffold_metadata.py \
    architecture/ascii/scaffolds/claude-objects.md \
    scripts/query-scaffolds.sh \
    scripts/validate-scaffolds.sh \
    .claude/rules/scaffold-metadata.md
git commit -m "feat(scaffolds): add frontmatter metadata and query tools

- Add YAML frontmatter to claude-objects scaffold
- Implement query-scaffolds.sh for filtering
- Implement validate-scaffolds.sh for consistency
- Add scaffold-metadata.md rule documentation
- Add pytest test for validation

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 2: Add Frontmatter to Remaining Scaffolds

**Files:**
- Modify: `architecture/ascii/scaffolds/jade-cli.md`
- Modify: `architecture/ascii/scaffolds/jade-index.md`
- Modify: `architecture/ascii/scaffolds/jade-dev-assist.md`
- Modify: `architecture/ascii/scaffolds/jade-ide.md`
- Modify: `architecture/ascii/scaffolds/jade-swarm.md`
- Modify: `architecture/ascii/scaffolds/jadecli-infra.md`
- Modify: `architecture/ascii/scaffolds/jadecli-roadmap.md`
- Modify: `architecture/ascii/scaffolds/dotfiles.md`
- Modify: `architecture/ascii/scaffolds/jade-claude-settings.md`

**Step 1: Add frontmatter to jade-cli.md**

```yaml
---
entity_id: scaffold-jade-cli
entity_name: jade-cli
entity_type: project_scaffold
entity_language: typescript
entity_status: buildable
entity_path: modules/jade-cli
entity_dependencies:
  core: [ink, react, zustand]
  testing: [vitest]
  dev: [typescript, tsx]
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jade-cli && npm test"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 2: Add frontmatter to jade-index.md**

```yaml
---
entity_id: scaffold-jade-index
entity_name: jade-index
entity_type: project_scaffold
entity_language: python
entity_status: buildable
entity_path: modules/jade-index
entity_dependencies:
  core: [sentence-transformers, pgvector, tree-sitter, click]
  infrastructure: [psycopg[binary], redis]
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
```

**Step 3: Add frontmatter to jade-dev-assist.md**

```yaml
---
entity_id: scaffold-jade-dev-assist
entity_name: jade-dev-assist
entity_type: project_scaffold
entity_language: javascript
entity_status: scaffolding
entity_path: modules/jade-dev-assist
entity_dependencies:
  core: [@anthropic-ai/sdk]
  testing: [jest]
  dev: [eslint]
entity_services:
  - orchestrator
entity_ports: []
entity_health_check: "cd modules/jade-dev-assist && npm test"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 4: Add frontmatter to jade-ide.md**

```yaml
---
entity_id: scaffold-jade-ide
entity_name: jade-ide
entity_type: project_scaffold
entity_language: typescript
entity_status: blocked
entity_path: modules/jade-ide
entity_dependencies:
  core: [vscode-core]
  testing: []
  dev: [typescript]
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jade-ide && npm run compile"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 5: Add frontmatter to jade-swarm.md**

```yaml
---
entity_id: scaffold-jade-swarm
entity_name: jade-swarm-superpowers
entity_type: project_scaffold
entity_language: markdown
entity_status: scaffolding
entity_path: modules/jade-swarm-superpowers
entity_dependencies:
  core: []
  testing: []
  dev: []
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jade-swarm-superpowers && find skills -name '*.md' | wc -l"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 6: Add frontmatter to jadecli-infra.md**

```yaml
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
```

**Step 7: Add frontmatter to jadecli-roadmap.md**

```yaml
---
entity_id: scaffold-jadecli-roadmap
entity_name: jadecli-roadmap-and-architecture
entity_type: project_scaffold
entity_language: markdown
entity_status: scaffolding
entity_path: modules/jadecli-roadmap-and-architecture
entity_dependencies:
  core: []
  testing: []
  dev: []
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jadecli-roadmap-and-architecture && find docs -name '*.md' | wc -l"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 8: Add frontmatter to dotfiles.md**

```yaml
---
entity_id: scaffold-dotfiles
entity_name: dotfiles
entity_type: project_scaffold
entity_language: shell
entity_status: buildable
entity_path: modules/dotfiles
entity_dependencies:
  core: [chezmoi]
  testing: []
  dev: []
entity_services: []
entity_ports: []
entity_health_check: "cd modules/dotfiles && chezmoi verify"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 9: Add frontmatter to jade-claude-settings.md**

```yaml
---
entity_id: scaffold-jade-claude-settings
entity_name: jade-claude-settings
entity_type: project_scaffold
entity_language: markdown
entity_status: scaffolding
entity_path: modules/jade-claude-settings
entity_dependencies:
  core: []
  testing: []
  dev: []
entity_services: []
entity_ports: []
entity_health_check: "cd modules/jade-claude-settings && find plugins -name '*.md' | wc -l"
entity_created: 2026-02-04
entity_last_validated: 2026-02-04
---
```

**Step 10: Run validation**

Run: `./scripts/validate-scaffolds.sh`
Expected: All 10 scaffolds show "✓ Valid frontmatter"

**Step 11: Test queries**

Run:
```bash
./scripts/query-scaffolds.sh --language python
./scripts/query-scaffolds.sh --status buildable
./scripts/query-scaffolds.sh --dependency pytest
```
Expected: Correct filtering results

**Step 12: Commit**

```bash
git add architecture/ascii/scaffolds/*.md
git commit -m "feat(scaffolds): add frontmatter to all 9 remaining scaffolds

All 10 project scaffolds now have structured metadata for querying.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 3: Centralized Settings Module

**Files:**
- Create: `cli/__init__.py`
- Create: `cli/settings.py`
- Create: `.env.example`
- Create: `tests/test_settings.py`
- Modify: `.gitignore`
- Create: `.claude/rules/settings.md`

**Step 1: Write test for settings module**

```python
# tests/test_settings.py
import pytest
from pathlib import Path
import os

def test_settings_module_imports():
    """Verify settings module can be imported."""
    from cli.settings import Settings, settings

    assert Settings is not None
    assert settings is not None

def test_settings_has_required_fields():
    """Verify settings has all required fields."""
    from cli.settings import settings

    required_attrs = [
        'environment',
        'is_ci',
        'home_dir',
        'projects_base',
        'jade_context_file',
        'ecosystem_assist_root',
        'submodules_path',
        'health_reports_dir',
        'context_token_budget',
    ]

    for attr in required_attrs:
        assert hasattr(settings, attr), f"Missing attribute: {attr}"

def test_settings_paths_are_pathlib():
    """Verify path settings are Path objects."""
    from cli.settings import settings

    path_attrs = [
        'home_dir',
        'projects_base',
        'jade_context_file',
        'ecosystem_assist_root',
        'submodules_path',
        'health_reports_dir',
    ]

    for attr in path_attrs:
        value = getattr(settings, attr)
        assert isinstance(value, Path), f"{attr} should be Path, got {type(value)}"

def test_settings_defaults():
    """Verify settings have sensible defaults."""
    from cli.settings import settings

    assert settings.environment == "development"
    assert settings.context_token_budget == 15000
    assert settings.ecosystem_assist_root.name == "jade-ecosystem-assist"
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_settings.py -v`
Expected: FAIL with "ModuleNotFoundError: No module named 'cli'"

**Step 3: Create cli package**

```python
# cli/__init__.py
"""Centralized configuration and utilities for jade-ecosystem-assist."""

from .settings import settings, Settings

__all__ = ["settings", "Settings"]
```

**Step 4: Create settings module**

```python
# cli/settings.py
# ---
# entity_id: module-settings
# entity_name: Centralized Settings
# entity_type_id: module
# entity_path: cli/settings.py
# entity_language: python
# entity_state: active
# entity_exports: [Settings, settings]
# ---

from pathlib import Path
from typing import Optional
from pydantic import Field
from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Centralized configuration for jade-ecosystem-assist."""

    # Environment Detection
    environment: str = Field(
        default="development",
        description="development, staging, or production",
    )

    is_ci: bool = Field(
        default=False,
        description="True if running in CI/CD environment",
    )

    # Paths
    home_dir: Path = Field(
        default_factory=lambda: Path.home(),
        description="User home directory",
    )

    projects_base: Optional[Path] = Field(
        default=None,
        description="Base directory for all projects",
    )

    jade_context_file: Optional[Path] = Field(
        default=None,
        description="Path to generated context file",
    )

    ecosystem_assist_root: Path = Field(
        default_factory=lambda: Path(__file__).parent.parent,
        description="Root of jade-ecosystem-assist repository",
    )

    # Submodule Configuration
    submodules_path: Optional[Path] = Field(
        default=None,
        description="Path to submodules directory",
    )

    # Health Check Configuration
    health_reports_dir: Optional[Path] = Field(
        default=None,
        description="Directory for health check reports",
    )

    # Context Generation
    context_token_budget: int = Field(
        default=15000,
        description="Max tokens for generated context file",
    )

    # GitHub Integration
    github_token: Optional[str] = Field(
        default=None,
        description="GitHub API token for submodule sync",
    )

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"
        case_sensitive = False

    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # Set defaults based on environment
        if self.projects_base is None:
            self.projects_base = self.home_dir / "projects"

        if self.jade_context_file is None:
            self.jade_context_file = self.home_dir / ".jade" / "context.md"

        if self.submodules_path is None:
            self.submodules_path = self.ecosystem_assist_root / "modules"

        if self.health_reports_dir is None:
            self.health_reports_dir = (
                self.ecosystem_assist_root / "docs" / "health-reports"
            )


# Singleton instance
settings = Settings()
```

**Step 5: Create .env.example**

```dotenv
# .env.example
# jade-ecosystem-assist Configuration Template
#
# Copy this to .env and fill in your values
# DO NOT commit .env to git

# Environment (development, staging, production)
ENVIRONMENT=development

# CI Detection (set automatically by GitHub Actions)
IS_CI=false

# Base Paths (leave empty to use defaults)
# HOME_DIR=
# PROJECTS_BASE=
# JADE_CONTEXT_FILE=
# ECOSYSTEM_ASSIST_ROOT=

# GitHub Integration (optional)
# GITHUB_TOKEN=

# Context Generation
CONTEXT_TOKEN_BUDGET=15000
```

**Step 6: Update .gitignore**

Add to `.gitignore`:
```
# Environment files
.env
.env.local
```

**Step 7: Run test to verify it passes**

Run: `pytest tests/test_settings.py -v`
Expected: PASS (all 4 tests)

**Step 8: Create settings rule documentation**

```markdown
# .claude/rules/settings.md
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
cli/settings.py          # Pydantic Settings class (source of truth)
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
   new_setting: Optional[str] = Field(
       default=None,
       description="Description of new setting",
   )
   ```

3. Add to local `.env`:
   ```dotenv
   NEW_SETTING=actual-value
   ```

## Security

- `.env` is gitignored
- Never commit secrets
- Use GitHub Secrets for CI/CD
```

**Step 9: Commit**

```bash
git add cli/ tests/test_settings.py .env.example .gitignore .claude/rules/settings.md
git commit -m "feat(config): add centralized Pydantic settings

- Create cli/settings.py with Pydantic BaseSettings
- Add .env.example template
- Update .gitignore for .env files
- Add settings.md rule documentation
- Add pytest tests for settings module

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 4: Update Scripts to Use Settings

**Files:**
- Modify: `scripts/generate-context.sh`
- Modify: `scripts/health-check.sh`
- Create: `scripts/load-settings.sh`

**Step 1: Create settings loader for bash**

```bash
# scripts/load-settings.sh
#!/bin/bash
# Export settings from Pydantic to environment variables

set -euo pipefail

# Find python3 (prefer system, fallback to uv)
if command -v python3 &>/dev/null; then
    PYTHON=python3
elif command -v uv &>/dev/null; then
    PYTHON="uv run python"
else
    echo "Error: python3 or uv not found" >&2
    exit 1
fi

# Export settings
eval "$($PYTHON -c "
from cli.settings import settings

print(f'export JADE_CONTEXT_FILE=\"{settings.jade_context_file}\"')
print(f'export PROJECTS_BASE=\"{settings.projects_base}\"')
print(f'export ECOSYSTEM_ASSIST_ROOT=\"{settings.ecosystem_assist_root}\"')
print(f'export SUBMODULES_PATH=\"{settings.submodules_path}\"')
print(f'export HEALTH_REPORTS_DIR=\"{settings.health_reports_dir}\"')
print(f'export CONTEXT_TOKEN_BUDGET=\"{settings.context_token_budget}\"')
print(f'export IS_CI=\"{settings.is_ci}\"')
print(f'export ENVIRONMENT=\"{settings.environment}\"')
")"
```

**Step 2: Update generate-context.sh to use settings**

At the top of `scripts/generate-context.sh`, add:

```bash
#!/bin/bash
set -euo pipefail

# Load settings from Pydantic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-settings.sh"

# Now use settings instead of hardcoded values
# OLD: JADE_CONTEXT_FILE="$HOME/.jade/context.md"
# NEW: JADE_CONTEXT_FILE already set by load-settings.sh

# OLD: PROJECTS_BASE="$HOME/projects"
# NEW: PROJECTS_BASE already set by load-settings.sh
```

**Step 3: Update health-check.sh to use settings**

At the top of `scripts/health-check.sh`, add:

```bash
#!/bin/bash
set -euo pipefail

# Load settings from Pydantic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/load-settings.sh"

# Now use settings instead of hardcoded values
# OLD: REPORTS_DIR="docs/health-reports"
# NEW: Use $HEALTH_REPORTS_DIR from settings
```

**Step 4: Test settings loading**

Run:
```bash
source scripts/load-settings.sh
echo "Context file: $JADE_CONTEXT_FILE"
echo "Projects base: $PROJECTS_BASE"
```
Expected: Shows paths from settings

**Step 5: Test generate-context.sh**

Run: `./scripts/generate-context.sh --brief`
Expected: Works as before, uses settings-based paths

**Step 6: Test health-check.sh**

Run: `./scripts/health-check.sh --quick`
Expected: Works as before, uses settings-based paths

**Step 7: Commit**

```bash
git add scripts/load-settings.sh scripts/generate-context.sh scripts/health-check.sh
git commit -m "refactor(scripts): use centralized settings instead of hardcoded paths

- Create load-settings.sh to export Pydantic settings to bash
- Update generate-context.sh to use settings
- Update health-check.sh to use settings

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 5: Session Start Hook

**Files:**
- Create: `.claude/hooks/session-start.sh`
- Modify: `.claude/settings.json`
- Create: `tests/test_session_hook.py`
- Create: `.claude/rules/session-hooks.md`

**Step 1: Write test for session hook**

```python
# tests/test_session_hook.py
import pytest
from pathlib import Path
import subprocess

def test_session_hook_exists():
    """Verify session hook file exists and is executable."""
    hook_file = Path(".claude/hooks/session-start.sh")
    assert hook_file.exists(), "Session hook file missing"
    assert hook_file.stat().st_mode & 0o111, "Session hook not executable"

def test_session_hook_runs():
    """Verify session hook can execute without errors."""
    hook_file = Path(".claude/hooks/session-start.sh")

    result = subprocess.run(
        [str(hook_file)],
        capture_output=True,
        text=True,
    )

    # Hook should exit 0 (success or skip)
    assert result.returncode == 0, f"Hook failed: {result.stderr}"

def test_session_hook_sources_settings():
    """Verify hook loads settings correctly."""
    hook_file = Path(".claude/hooks/session-start.sh")
    content = hook_file.read_text()

    # Should source load-settings.sh
    assert "source" in content or "eval" in content, "Hook doesn't load settings"
    assert "cli.settings import settings" in content, "Hook doesn't use Pydantic settings"
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/test_session_hook.py -v`
Expected: FAIL with "Session hook file missing"

**Step 3: Create session hook script**

```bash
# .claude/hooks/session-start.sh
#!/bin/bash
# ---
# entity_id: hook-session-start
# entity_name: Session Start Hook
# entity_type_id: config
# entity_path: .claude/hooks/session-start.sh
# entity_language: bash
# entity_state: active
# ---

set -euo pipefail

# Load settings from Pydantic
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

eval "$(python3 -c "
import sys
sys.path.insert(0, '$SCRIPT_DIR')
from cli.settings import settings
print(f'export JADE_CONTEXT_FILE=\"{settings.jade_context_file}\"')
print(f'export ECOSYSTEM_ASSIST_ROOT=\"{settings.ecosystem_assist_root}\"')
print(f'export CONTEXT_TOKEN_BUDGET=\"{settings.context_token_budget}\"')
")"

CONTEXT_FILE="$JADE_CONTEXT_FILE"
GENERATE_SCRIPT="$ECOSYSTEM_ASSIST_ROOT/scripts/generate-context.sh"
MAX_AGE_SECONDS=3600  # 1 hour

# Ensure .jade directory exists
mkdir -p "$(dirname "$CONTEXT_FILE")"

# Check if context file exists and is recent
if [[ -f "$CONTEXT_FILE" ]]; then
    # Get file age (cross-platform)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        FILE_MTIME=$(stat -f %m "$CONTEXT_FILE")
    else
        FILE_MTIME=$(stat -c %Y "$CONTEXT_FILE")
    fi

    NOW=$(date +%s)
    AGE=$((NOW - FILE_MTIME))

    if (( AGE < MAX_AGE_SECONDS )); then
        echo "✓ Context is fresh (${AGE}s old)" >&2
        exit 0
    fi

    echo "⚠ Context is stale (${AGE}s old), regenerating..." >&2
else
    echo "⚠ No context file found, generating..." >&2
fi

# Regenerate context
if [[ -x "$GENERATE_SCRIPT" ]]; then
    "$GENERATE_SCRIPT" --brief >&2
    echo "✓ Context regenerated at $CONTEXT_FILE" >&2
else
    echo "✗ Generate script not found at $GENERATE_SCRIPT" >&2
    exit 1
fi
```

**Step 4: Make hook executable**

Run: `chmod +x .claude/hooks/session-start.sh`

**Step 5: Test hook manually**

Run: `./.claude/hooks/session-start.sh`
Expected: Either "Context is fresh" or "Context regenerated"

**Step 6: Run test to verify it passes**

Run: `pytest tests/test_session_hook.py -v`
Expected: PASS (all 3 tests)

**Step 7: Register hook in settings.json**

Create or modify `.claude/settings.json`:

```json
{
  "hooks": {
    "sessionStart": ".claude/hooks/session-start.sh"
  }
}
```

**Step 8: Document session hooks**

```markdown
# .claude/rules/session-hooks.md
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
```

**Step 9: Commit**

```bash
git add .claude/hooks/session-start.sh \
    .claude/settings.json \
    tests/test_session_hook.py \
    .claude/rules/session-hooks.md
git commit -m "feat(hooks): add session start hook for auto-context loading

- Create session-start.sh hook that auto-refreshes stale context
- Register hook in .claude/settings.json
- Add session-hooks.md rule documentation
- Add pytest tests for hook functionality
- Hook uses Pydantic settings for paths

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 6: Update Documentation

**Files:**
- Modify: `README.md`
- Modify: `CLAUDE.md`

**Step 1: Update README.md**

Add new sections after "Structure":

```markdown
## New Features

### Queryable Scaffolds

All architecture scaffolds now have structured YAML frontmatter:

```bash
# Find all Python projects
./scripts/query-scaffolds.sh --language python

# Find projects using pytest
./scripts/query-scaffolds.sh --dependency pytest

# Get buildable projects
./scripts/query-scaffolds.sh --status buildable

# Output JSON for automation
./scripts/query-scaffolds.sh --format json
```

See `.claude/rules/scaffold-metadata.md` for details.

### Centralized Settings

All scripts now use `cli/settings.py` for configuration:

```python
from cli.settings import settings

context_file = settings.jade_context_file
projects_base = settings.projects_base
```

Customize via `.env` file (copy `.env.example` to get started).

See `.claude/rules/settings.md` for details.

### Auto-Context Loading

Session start hooks automatically refresh context when stale:

- Context regenerates if > 1 hour old
- Skips regeneration if recent
- Configurable via settings

See `.claude/rules/session-hooks.md` for details.
```

**Step 2: Update CLAUDE.md**

Add after "Quick Start":

```markdown
## Automatic Context Loading

This repo has a session start hook that auto-loads context. When you start a Claude Code session:

1. Hook checks if `~/.jade/context.md` is stale (> 1 hour)
2. Regenerates if needed via `generate-context.sh --brief`
3. Context is automatically available in the session

**You don't need to manually run any commands** - context is always fresh.

### Manual Regeneration

Force regeneration:
```bash
./scripts/generate-context.sh
```

### Query Scaffolds

Find projects programmatically:

```bash
# All Python projects
./scripts/query-scaffolds.sh --language python

# Projects using specific dependency
./scripts/query-scaffolds.sh --dependency pytest

# Buildable projects
./scripts/query-scaffolds.sh --status buildable
```
```

**Step 3: Commit**

```bash
git add README.md CLAUDE.md
git commit -m "docs: update README and CLAUDE.md for new features

Document new queryable scaffolds, centralized settings, and
auto-context loading features.

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Task 7: Add Dependencies and Final Validation

**Files:**
- Create: `pyproject.toml`
- Create: `requirements.txt`
- Modify: `.gitignore`

**Step 1: Create pyproject.toml**

```toml
# pyproject.toml
[project]
name = "jade-ecosystem-assist"
version = "0.3.0"
description = "Meta-repository for jadecli ecosystem context and tooling"
readme = "README.md"
requires-python = ">=3.10"
dependencies = [
    "pydantic>=2.0.0",
    "pydantic-settings>=2.0.0",
    "pyyaml>=6.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=7.0.0",
    "pytest-cov>=4.0.0",
]

[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]

[tool.ruff]
line-length = 88
target-version = "py310"
```

**Step 2: Create requirements.txt**

```txt
# requirements.txt
pydantic>=2.0.0
pydantic-settings>=2.0.0
pyyaml>=6.0
```

**Step 3: Update .gitignore**

Add Python-specific entries:

```
# Python
__pycache__/
*.py[cod]
*$py.class
.pytest_cache/
*.egg-info/
dist/
build/
```

**Step 4: Run all tests**

Run: `pytest tests/ -v`
Expected: All tests pass

**Step 5: Run validation scripts**

Run:
```bash
./scripts/validate-scaffolds.sh
./scripts/query-scaffolds.sh --format json > /dev/null
```
Expected: All validations pass

**Step 6: Test session hook in clean environment**

Run:
```bash
rm -f ~/.jade/context.md
./.claude/hooks/session-start.sh
test -f ~/.jade/context.md && echo "✓ Context generated"
```
Expected: Context file is created

**Step 7: Commit**

```bash
git add pyproject.toml requirements.txt .gitignore
git commit -m "chore: add Python project configuration

- Add pyproject.toml with dependencies
- Add requirements.txt for pip users
- Update .gitignore for Python artifacts

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

---

## Completion Checklist

After all tasks are complete:

- [ ] All tests pass: `pytest tests/ -v`
- [ ] All scaffolds have frontmatter: `./scripts/validate-scaffolds.sh`
- [ ] Query scripts work: `./scripts/query-scaffolds.sh --language python`
- [ ] Settings module works: `python3 -c "from cli.settings import settings; print(settings.jade_context_file)"`
- [ ] Scripts use settings: `grep -r "load-settings.sh" scripts/`
- [ ] Session hook works: `./.claude/hooks/session-start.sh`
- [ ] Documentation updated: `README.md`, `CLAUDE.md` mention new features
- [ ] Git history is clean: conventional commits only

---

## Post-Implementation

After completing all tasks:

1. Tag release: `git tag v0.3.0 && git push --tags`
2. Update CHANGELOG.md with new features
3. Test in a fresh clone to verify everything works
4. Create GitHub issue to track future phases (entity store, file locking)
