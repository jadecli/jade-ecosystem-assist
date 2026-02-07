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
