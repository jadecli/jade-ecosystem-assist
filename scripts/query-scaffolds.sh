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
