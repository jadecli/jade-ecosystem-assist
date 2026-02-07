#!/bin/bash
# Export settings from Python to environment variables

set -euo pipefail

# Find python3
if command -v python3 &>/dev/null; then
    PYTHON=python3
else
    echo "Error: python3 not found" >&2
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
