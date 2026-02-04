# jadecli-codespaces Pattern Integration Design

**Date:** 2026-02-04
**Status:** Design
**Goal:** Apply proven patterns from jadecli-codespaces to reduce cognitive overhead in jade-ecosystem-assist

---

## Executive Summary

jade-ecosystem-assist currently provides excellent documentation and tooling for the 10-project ecosystem. However, jadecli-codespaces demonstrates 5 advanced patterns that could significantly enhance our automation and queryability:

1. **Frontmatter-based metadata** - Fast querying without full file parsing
2. **Centralized Pydantic settings** - Eliminate hardcoded paths and enable environment detection
3. **Session hooks** - Automate context loading on session start
4. **Entity store** - AST-based change tracking (future phase)
5. **File locking** - Multi-agent collaboration safety (future phase)

This design focuses on **implementing patterns 1-3** in the next iteration, as they directly support jade-ecosystem-assist's mission: **reduce cognitive overhead for multi-repo development**.

---

## Part 1: Frontmatter Metadata for Architecture Scaffolds

### Problem Statement

Currently, ASCII scaffolds in `architecture/ascii/scaffolds/*.md` are excellent documentation but difficult to query programmatically. Questions like "Which projects use pytest?" or "Show me all TypeScript projects" require manual reading or fragile text parsing.

### Solution: Frontmatter Metadata

Add YAML frontmatter to each scaffold with structured metadata:

```yaml
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

[existing content follows]
```

### Benefits

1. **Fast Queries**: `scripts/query-scaffolds.sh --language python` returns matching projects
2. **Dependency Tracking**: Build dependency graphs without parsing ASCII tables
3. **Health Integration**: Each scaffold declares its health check command
4. **Version Tracking**: `entity_last_validated` shows staleness
5. **Automation**: Generate reports, validate consistency, detect drift

### Implementation Files

- `architecture/ascii/scaffolds/*.md` - Add frontmatter to all 10 scaffolds
- `scripts/query-scaffolds.sh` - New script for querying scaffold metadata
- `scripts/validate-scaffolds.sh` - New script to ensure frontmatter consistency
- `.claude/rules/scaffold-metadata.md` - Documentation for the pattern

### Example Queries

```bash
# All Python projects
./scripts/query-scaffolds.sh --language python

# Projects with pytest
./scripts/query-scaffolds.sh --dependency pytest

# Projects in BUILDABLE status
./scripts/query-scaffolds.sh --status buildable

# Output JSON for programmatic use
./scripts/query-scaffolds.sh --language typescript --format json
```

### Migration Strategy

1. Create frontmatter template
2. Add frontmatter to 1 scaffold as proof-of-concept
3. Implement `query-scaffolds.sh` with basic parsing
4. Add frontmatter to remaining 9 scaffolds
5. Implement `validate-scaffolds.sh` for consistency checks
6. Update documentation in README.md

---

## Part 2: Centralized Settings via Pydantic

### Problem Statement

Currently, bash scripts hardcode paths and make assumptions about environment:

```bash
# scripts/generate-context.sh
JADE_CONTEXT_FILE="$HOME/.jade/context.md"
PROJECTS_BASE="$HOME/projects"
```

This breaks when:
- Different users have different home directories
- CI/CD environments have different paths
- Development vs production environments need different settings

### Solution: Settings Module

Create `cli/settings.py` following jadecli-codespaces pattern:

```python
# cli/settings.py
# ---
# entity_id: module-settings
# entity_name: Settings Module
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

    projects_base: Path = Field(
        default=None,
        description="Base directory for all projects",
    )

    jade_context_file: Path = Field(
        default=None,
        description="Path to generated context file",
    )

    ecosystem_assist_root: Path = Field(
        default_factory=lambda: Path(__file__).parent.parent,
        description="Root of jade-ecosystem-assist repository",
    )

    # Submodule Configuration
    submodules_path: Path = Field(
        default=None,
        description="Path to submodules directory",
    )

    # Health Check Configuration
    health_reports_dir: Path = Field(
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
            self.health_reports_dir = self.ecosystem_assist_root / "docs" / "health-reports"

# Singleton instance
settings = Settings()
```

### Usage in Scripts

Convert bash scripts to Python or use environment variable pattern:

```python
# scripts/generate_context.py
from cli.settings import settings

def generate_context():
    output_file = settings.jade_context_file
    projects_base = settings.projects_base
    token_budget = settings.context_token_budget

    # ... rest of logic
```

Or export to environment for bash scripts:

```bash
# scripts/load-settings.sh
source <(python -c "from cli.settings import settings; print(f'export JADE_CONTEXT_FILE={settings.jade_context_file}')")
```

### Environment File

Create `.env.example` template:

```dotenv
# jade-ecosystem-assist Configuration

# Environment (development, staging, production)
ENVIRONMENT=development

# CI Detection (set by GitHub Actions)
IS_CI=false

# Base Paths (leave empty to use defaults)
HOME_DIR=
PROJECTS_BASE=
JADE_CONTEXT_FILE=
ECOSYSTEM_ASSIST_ROOT=

# GitHub Integration
GITHUB_TOKEN=

# Context Generation
CONTEXT_TOKEN_BUDGET=15000
```

### Benefits

1. **Environment Portability**: Works across different user environments
2. **CI/CD Ready**: Detects CI environment, adjusts behavior
3. **Type Safety**: Pydantic validates all settings
4. **Documentation**: Field descriptions serve as inline docs
5. **No Secrets in Git**: `.env` is gitignored, `.env.example` is template

### Implementation Files

- `cli/settings.py` - New Pydantic settings module
- `.env.example` - Template for environment variables
- `.gitignore` - Add `.env` if not already present
- `scripts/generate-context.sh` - Update to use settings
- `scripts/health-check.sh` - Update to use settings
- `.claude/rules/settings.md` - Document the pattern

### Migration Strategy

1. Create `cli/settings.py` with initial fields
2. Create `.env.example` template
3. Update one script (`generate-context.sh`) as proof-of-concept
4. Validate it works in different environments
5. Update remaining scripts
6. Add validation in pre-commit hooks

---

## Part 3: Session Hooks for Auto-Context Loading

### Problem Statement

Currently, users must manually run:

```bash
cd ~/projects/jade-ecosystem-assist
./scripts/generate-context.sh
claude --context ~/.jade/context.md
```

This is error-prone and adds friction to starting a session.

### Solution: Session Start Hook

Create `.claude/hooks/session-start.sh` that automatically:
1. Detects if context is stale (last run > 1 hour ago)
2. Regenerates context if needed
3. Loads it into the session

```bash
#!/bin/bash
# .claude/hooks/session-start.sh
# ---
# entity_id: hook-session-start
# entity_name: Session Start Hook
# entity_type_id: config
# entity_path: .claude/hooks/session-start.sh
# entity_language: bash
# entity_state: active
# ---

set -euo pipefail

# Source settings (use Python to export env vars)
eval "$(python3 -c "
from cli.settings import settings
print(f'export JADE_CONTEXT_FILE={settings.jade_context_file}')
print(f'export ECOSYSTEM_ASSIST_ROOT={settings.ecosystem_assist_root}')
")"

CONTEXT_FILE="$JADE_CONTEXT_FILE"
GENERATE_SCRIPT="$ECOSYSTEM_ASSIST_ROOT/scripts/generate-context.sh"
MAX_AGE_SECONDS=3600  # 1 hour

# Check if context file exists and is recent
if [[ -f "$CONTEXT_FILE" ]]; then
    AGE=$(($(date +%s) - $(stat -c %Y "$CONTEXT_FILE" 2>/dev/null || stat -f %m "$CONTEXT_FILE")))

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
    "$GENERATE_SCRIPT" --brief
    echo "✓ Context regenerated" >&2
else
    echo "✗ Generate script not found at $GENERATE_SCRIPT" >&2
    exit 1
fi
```

### Settings Integration

Add hook configuration to `cli/settings.py`:

```python
class Settings(BaseSettings):
    # ... existing fields ...

    # Session Hook Configuration
    enable_session_hooks: bool = Field(
        default=True,
        description="Enable automatic session hooks",
    )

    context_max_age_seconds: int = Field(
        default=3600,
        description="Regenerate context if older than this (seconds)",
    )

    session_hook_timeout: int = Field(
        default=30,
        description="Max seconds for hook execution",
    )
```

### Hook Registration

Update `.claude/settings.json`:

```json
{
  "hooks": {
    "sessionStart": ".claude/hooks/session-start.sh"
  }
}
```

### Benefits

1. **Zero Manual Steps**: Context auto-refreshes on session start
2. **Always Fresh**: Detects stale context and regenerates
3. **Fast Start**: Skips regeneration if context is recent
4. **Configurable**: Max age tunable via settings
5. **Timeout Protection**: Won't hang session start if slow

### Implementation Files

- `.claude/hooks/session-start.sh` - New session start hook
- `.claude/settings.json` - Register the hook
- `cli/settings.py` - Add hook configuration fields
- `.claude/rules/session-hooks.md` - Document the pattern

### Migration Strategy

1. Create basic hook script
2. Test manually: `.claude/hooks/session-start.sh`
3. Register in `.claude/settings.json`
4. Test in fresh session
5. Add settings integration for configurability
6. Document in README.md

---

## Part 4: Integration Plan

### Phase 1: Frontmatter (Week 1)
- [ ] Create frontmatter template for scaffolds
- [ ] Add frontmatter to `claude-objects.md` as proof-of-concept
- [ ] Implement `query-scaffolds.sh` basic version
- [ ] Add frontmatter to remaining 9 scaffolds
- [ ] Implement `validate-scaffolds.sh`
- [ ] Update documentation

### Phase 2: Settings (Week 2)
- [ ] Create `cli/settings.py` module
- [ ] Create `.env.example` template
- [ ] Update `.gitignore` for `.env`
- [ ] Convert `generate-context.sh` to use settings
- [ ] Convert `health-check.sh` to use settings
- [ ] Add pre-commit validation

### Phase 3: Hooks (Week 3)
- [ ] Create `.claude/hooks/session-start.sh`
- [ ] Test hook manually
- [ ] Register hook in `.claude/settings.json`
- [ ] Add hook configuration to settings
- [ ] Test in fresh sessions
- [ ] Document usage in README.md

### Phase 4: Validation (Week 4)
- [ ] Run full health check with new patterns
- [ ] Test in CI/CD environment
- [ ] Validate across multiple user environments
- [ ] Document lessons learned
- [ ] Plan future phases (entity store, file locking)

---

## Part 5: Future Phases (Not In Scope)

### Entity Store Integration

**When:** After proving value of frontmatter metadata
**What:** Full AST-based parsing for code files
**Why:** Track changes at function/class level, not just file level

### File Locking

**When:** If multi-agent collaboration becomes common
**What:** Frontmatter-based file locking like jadecli-codespaces
**Why:** Prevent conflicts when multiple Claude sessions edit scaffolds

### Platform-Claude Documentation

**When:** After building significant user-facing features
**What:** Adopt platform-claude's llms.txt pattern for API documentation
**Why:** Make jade-ecosystem-assist features discoverable via AI

---

## Part 6: Success Metrics

### Quantitative
- **Context Generation Speed**: Baseline 5-10 minutes manual → Target 30 seconds automated
- **Query Response Time**: Baseline N/A (manual search) → Target <1 second for scaffold queries
- **Session Start Overhead**: Baseline 0s (no automation) → Target <5s (with auto-refresh)

### Qualitative
- **Developer Experience**: "I don't think about context loading anymore"
- **Onboarding**: "New contributors find projects faster with query-scaffolds.sh"
- **Confidence**: "I trust the context is always up-to-date"

---

## Part 7: Risks and Mitigations

### Risk: Frontmatter Maintenance Burden
**Mitigation:** `validate-scaffolds.sh` in pre-commit hooks prevents drift

### Risk: Settings Complexity
**Mitigation:** Sensible defaults mean `.env` is optional for standard setups

### Risk: Hook Failures Block Sessions
**Mitigation:** Timeout + graceful degradation (warn but continue if hook fails)

### Risk: Over-Engineering
**Mitigation:** YAGNI ruthlessly - only implement features 1-3, defer entity store and file locking

---

## Conclusion

Implementing **frontmatter metadata**, **centralized settings**, and **session hooks** from jadecli-codespaces will:

1. **Reduce cognitive overhead** by automating context loading
2. **Enable programmatic queries** for ecosystem navigation
3. **Improve portability** across different environments
4. **Maintain simplicity** by deferring advanced features to future phases

**Estimated Effort:** 3-4 weeks for full implementation
**Expected ROI:** Hours saved per week for developers working across the 10-project ecosystem

**Next Step:** Create implementation plan with detailed tasks using `superpowers:writing-plans` skill.
