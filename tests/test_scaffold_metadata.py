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
