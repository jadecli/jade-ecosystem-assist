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
