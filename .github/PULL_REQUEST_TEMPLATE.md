## Summary

<!-- What changed and why. Link to issue if applicable. -->

**Issue:** <!-- #123 or N/A -->
**Type:** <!-- feat | fix | refactor | docs | infra | test | chore -->

## Changes

<!-- Bullet list of what this PR does -->

-

## Ecosystem Architecture Impact

<!-- Mark [*] on the project(s) this PR changes. Edit arrows if data flow changes. -->

```
jadecli Ecosystem -- PR Impact Map
===================================

+------------------+     +------------------+     +------------------+
|   jade-ide       |     | jade-dev-assist  |     |  jade-swarm      |
|   (TS/Electron)  |---->| (orchestrator)   |---->|  (skills)        |
+------------------+     +------------------+     +------------------+
        |                        |                        |
        v                        v                        v
+------------------+     +------------------+     +------------------+
|   jade-cli       |     | claude-objects   |     | jadecli-roadmap  |
|   (TS/React Ink) |     | (Python/FastMCP) |     | (docs/ADRs)      |
+------------------+     +------------------+     +------------------+
        |                        |
        v                        v
+------------------+     +------------------+     +------------------+
|   jade-index     |     | jadecli-infra    |     | jade-ecosystem-  |
|   (Python/GPU)   |     | (Docker Compose) |     | assist [*]       |
+------------------+     +------------------+     +------------------+

Data flow: IDE -> orchestrator -> swarm skills
           CLI -> jade-index -> infra (Postgres/pgvector, MongoDB, Dragonfly)
           jade-ecosystem-assist provides context to all projects
```

### Cross-Project Impact

<!-- Check all that apply -->

- [ ] Self-contained (no cross-project impact)
- [ ] jade-ide (extension/build changes)
- [ ] jade-dev-assist (orchestrator/plugin changes)
- [ ] jade-cli (terminal UI changes)
- [ ] jade-index (semantic search changes)
- [ ] claude-objects (MCP server changes)
- [ ] jade-swarm (skill/superpower changes)
- [ ] jadecli-infra (Docker/infrastructure changes)
- [ ] jadecli-roadmap (architecture/ADR changes)
- [ ] dotfiles (developer environment changes)
- [ ] jade-claude-settings (plugin/config changes)

### Companion PRs

<!-- List PRs in other repos that should be merged together -->

| Repo | PR | Status |
|------|-----|--------|
| <!-- jade-index --> | <!-- #123 --> | <!-- Draft/Ready --> |

## Verification Checklist

<!-- Check all that apply -->

- [ ] Submodules updated to latest (`git submodule update --remote`)
- [ ] Architecture scaffolds match project reality
- [ ] README accurate
- [ ] Pre-commit hooks pass
- [ ] CI passes

## Testing Evidence

<details>
<summary>Submodule Status</summary>

```
# Paste output of: git submodule status
```

</details>

## Reviewer Notes

<!-- Anything reviewers should know -->
