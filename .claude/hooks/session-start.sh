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
