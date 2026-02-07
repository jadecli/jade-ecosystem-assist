#!/usr/bin/env bash
# generate-context.sh - Generate consolidated context.md from ecosystem state
# Reads ~/.jade/projects.json for project registry and combines:
#   - Project CLAUDE.md files
#   - Task summaries from .claude/tasks/tasks.json
#   - Architecture scaffold files
#
# Output: ~/.jade/context.md (default) or stdout with -o -
#
# Usage:
#   ./generate-context.sh              # Write to ~/.jade/context.md
#   ./generate-context.sh -o -         # Write to stdout
#   ./generate-context.sh -o /path     # Write to custom path
#   ./generate-context.sh --brief      # Shorter output (~8k tokens)
#   ./generate-context.sh --focus NAME # Single-project context

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SCAFFOLDS_DIR="$REPO_ROOT/architecture/ascii/scaffolds"
PROJECTS_JSON="$HOME/.jade/projects.json"
DEFAULT_OUTPUT="$HOME/.jade/context.md"
MAX_TOKENS=15000  # Target ~15k tokens (roughly 60k chars)
CHARS_PER_TOKEN=4

# Parse arguments
OUTPUT="$DEFAULT_OUTPUT"
BRIEF=false
FOCUS_PROJECT=""

while [[ $# -gt 0 ]]; do
  case $1 in
    -o|--output)
      OUTPUT="$2"
      shift 2
      ;;
    --brief)
      BRIEF=true
      MAX_TOKENS=8000
      shift
      ;;
    --focus)
      FOCUS_PROJECT="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [-o OUTPUT] [--brief] [--focus PROJECT]"
      echo ""
      echo "Options:"
      echo "  -o, --output PATH     Output file (default: ~/.jade/context.md, use '-' for stdout)"
      echo "  --brief               Generate shorter context (~8k tokens)"
      echo "  --focus PROJECT       Generate focused context for single project (name or alias)"
      echo "  -h, --help            Show this help"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

# Ensure output directory exists
if [[ "$OUTPUT" != "-" ]]; then
  mkdir -p "$(dirname "$OUTPUT")"
fi

# Verify dependencies
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  exit 1
fi

if [[ ! -f "$PROJECTS_JSON" ]]; then
  echo "Error: Project registry not found at $PROJECTS_JSON" >&2
  echo "Create it or run jade-start --init first." >&2
  exit 1
fi

# Read projects_dir from registry
PROJECTS_BASE="$(jq -r '.projects_dir // "~/projects"' "$PROJECTS_JSON" | sed "s|~|$HOME|")"

# Function to write output
write_output() {
  if [[ "$OUTPUT" == "-" ]]; then
    cat
  else
    cat > "$OUTPUT"
  fi
}

# Track total character count for token budget
TOTAL_CHARS=0
MAX_CHARS=$((MAX_TOKENS * CHARS_PER_TOKEN))
BUDGET_EXCEEDED=false

# Append text with budget tracking
emit() {
  local text="$1"
  local text_len=${#text}

  if [[ "$BUDGET_EXCEEDED" == "true" ]]; then
    return
  fi

  if [[ $((TOTAL_CHARS + text_len)) -gt $MAX_CHARS ]]; then
    # Emit truncation notice and stop
    echo ""
    echo "_[Context truncated at ~$((TOTAL_CHARS / CHARS_PER_TOKEN)) tokens to stay within ${MAX_TOKENS}-token budget.]_"
    BUDGET_EXCEEDED=true
    return
  fi

  echo "$text"
  TOTAL_CHARS=$((TOTAL_CHARS + text_len))
}

# Get the resolved path for a project
resolve_project_path() {
  local name="$1"
  echo "${PROJECTS_BASE}/${name}"
}

# Get task counts and pending task titles from tasks.json
get_task_summary() {
  local project_dir="$1"
  local tasks_file="$project_dir/.claude/tasks/tasks.json"

  if [[ ! -f "$tasks_file" ]]; then
    echo "COUNTS:no tasks file"
    return
  fi

  local total completed pending in_progress
  total=$(jq '.tasks | length' "$tasks_file" 2>/dev/null || echo 0)
  completed=$(jq '[.tasks[] | select(.status == "completed")] | length' "$tasks_file" 2>/dev/null || echo 0)
  pending=$(jq '[.tasks[] | select(.status == "pending")] | length' "$tasks_file" 2>/dev/null || echo 0)
  in_progress=$(jq '[.tasks[] | select(.status == "in_progress" or .status == "in-progress")] | length' "$tasks_file" 2>/dev/null || echo 0)

  echo "COUNTS:${completed}/${total} done, ${pending} pending, ${in_progress} active"

  # Output pending/active task titles (up to 5)
  jq -r '
    [.tasks[] | select(.status == "pending" or .status == "in_progress" or .status == "in-progress")]
    | sort_by(if .status == "in_progress" or .status == "in-progress" then 0 else 1 end)
    | .[0:5][]
    | "TASK:" + .status + ":" + .title
  ' "$tasks_file" 2>/dev/null || true
}

# Extract first meaningful description line from CLAUDE.md
get_project_description() {
  local claude_md="$1/CLAUDE.md"

  if [[ ! -f "$claude_md" ]]; then
    echo ""
    return
  fi

  # Get the first non-empty, non-heading line as a brief description
  local desc
  desc=$(sed -n '/^[^#\[]/{/^$/d; s/^[[:space:]]*//; p; q;}' "$claude_md" 2>/dev/null || echo "")
  # Truncate to 80 chars
  if [[ ${#desc} -gt 80 ]]; then
    desc="${desc:0:77}..."
  fi
  echo "$desc"
}

# Check project health
check_project_health() {
  local project_dir="$1"

  if [[ ! -d "$project_dir" ]]; then
    echo "missing"
    return
  fi

  if [[ -f "$project_dir/package.json" ]]; then
    if [[ -d "$project_dir/node_modules" ]]; then
      echo "ready"
    else
      echo "needs install"
    fi
  elif [[ -f "$project_dir/pyproject.toml" ]]; then
    if [[ -d "$project_dir/.venv" ]]; then
      echo "ready"
    else
      echo "needs uv sync"
    fi
  elif [[ -f "$project_dir/docker-compose.yml" ]] || [[ -f "$project_dir/compose.yml" ]]; then
    echo "docker"
  else
    echo "ok"
  fi
}

# Generate the context document
generate_context() {
  local timestamp
  timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  emit "# jadecli Ecosystem Context"
  emit ""
  emit "Auto-generated context for Claude Code sessions."
  emit ""
  emit "Generated: $timestamp"
  emit ""

  # --- Project Summary Table ---
  emit "## Projects Overview"
  emit ""
  emit "| Project | Alias | Language | Status | Tasks |"
  emit "|---------|-------|----------|--------|-------|"

  # Read projects from registry
  local project_count
  project_count=$(jq '.projects | length' "$PROJECTS_JSON")

  for i in $(seq 0 $((project_count - 1))); do
    local name alias language
    name=$(jq -r ".projects[$i].name" "$PROJECTS_JSON")
    alias=$(jq -r ".projects[$i].alias // \"-\"" "$PROJECTS_JSON")
    language=$(jq -r ".projects[$i].language // \"unknown\"" "$PROJECTS_JSON")

    # Skip if focus mode and doesn't match name or alias
    if [[ -n "$FOCUS_PROJECT" ]] && [[ "$name" != "$FOCUS_PROJECT" ]] && [[ "$alias" != "$FOCUS_PROJECT" ]]; then
      continue
    fi

    local path
    path=$(resolve_project_path "$name")
    local health
    health=$(check_project_health "$path")

    # Get task counts only (first line of summary)
    local task_counts="n/a"
    if [[ -d "$path" ]]; then
      local summary_output
      summary_output=$(get_task_summary "$path")
      task_counts=$(echo "$summary_output" | grep "^COUNTS:" | head -1 | sed 's/^COUNTS://')
    fi

    emit "| $name | $alias | $language | $health | $task_counts |"
  done

  emit ""

  # --- Key Tasks Summary ---
  emit "## Key Tasks"
  emit ""

  local has_tasks=false

  for i in $(seq 0 $((project_count - 1))); do
    local name alias
    name=$(jq -r ".projects[$i].name" "$PROJECTS_JSON")
    alias=$(jq -r ".projects[$i].alias // \"-\"" "$PROJECTS_JSON")

    if [[ -n "$FOCUS_PROJECT" ]] && [[ "$name" != "$FOCUS_PROJECT" ]] && [[ "$alias" != "$FOCUS_PROJECT" ]]; then
      continue
    fi

    local path
    path=$(resolve_project_path "$name")

    if [[ ! -d "$path" ]]; then
      continue
    fi

    local summary_output
    summary_output=$(get_task_summary "$path")
    local task_lines
    task_lines=$(echo "$summary_output" | grep "^TASK:" || true)

    if [[ -n "$task_lines" ]]; then
      has_tasks=true
      emit "### $name"
      emit ""

      while IFS= read -r line; do
        local status title
        status=$(echo "$line" | cut -d: -f2)
        title=$(echo "$line" | cut -d: -f3-)

        local marker="[ ]"
        if [[ "$status" == "in_progress" ]] || [[ "$status" == "in-progress" ]]; then
          marker="[>]"
        fi

        emit "- ${marker} ${title}"
      done <<< "$task_lines"

      emit ""
    fi
  done

  if [[ "$has_tasks" == "false" ]]; then
    emit "_No pending or active tasks found._"
    emit ""
  fi

  # --- CLAUDE.md Summaries (non-brief only) ---
  if [[ "$BRIEF" != "true" ]]; then
    emit "## Project Descriptions"
    emit ""

    for i in $(seq 0 $((project_count - 1))); do
      local name alias
      name=$(jq -r ".projects[$i].name" "$PROJECTS_JSON")
      alias=$(jq -r ".projects[$i].alias // \"-\"" "$PROJECTS_JSON")

      if [[ -n "$FOCUS_PROJECT" ]] && [[ "$name" != "$FOCUS_PROJECT" ]] && [[ "$alias" != "$FOCUS_PROJECT" ]]; then
        continue
      fi

      local path
      path=$(resolve_project_path "$name")
      local claude_md="$path/CLAUDE.md"

      if [[ -f "$claude_md" ]]; then
        # Extract the title (first # heading) and first paragraph
        local heading
        heading=$(head -5 "$claude_md" | grep "^# " | head -1 || echo "# $name")
        local desc
        desc=$(get_project_description "$path")

        emit "### ${heading#\# }"
        if [[ -n "$desc" ]]; then
          emit "$desc"
        fi
        emit ""
      fi
    done
  fi

  # --- Architecture Scaffolds ---
  if [[ -d "$SCAFFOLDS_DIR" ]]; then
    local scaffold_files
    scaffold_files=$(ls "$SCAFFOLDS_DIR"/*.md 2>/dev/null || true)

    if [[ -n "$scaffold_files" ]]; then
      emit "## Architecture Scaffolds"
      emit ""

      for scaffold in $scaffold_files; do
        if [[ "$BUDGET_EXCEEDED" == "true" ]]; then
          break
        fi

        local sname
        sname=$(basename "$scaffold" .md)

        # Skip if focus mode and doesn't match
        if [[ -n "$FOCUS_PROJECT" ]] && [[ "$sname" != "$FOCUS_PROJECT" ]]; then
          continue
        fi

        local content
        content=$(cat "$scaffold")
        local content_chars=${#content}

        # Check if adding this would exceed budget
        if [[ $((TOTAL_CHARS + content_chars + 50)) -gt $MAX_CHARS ]]; then
          emit "### $sname"
          emit ""
          emit "_[Scaffold truncated for token budget. Use --focus $sname for full content.]_"
          emit ""
          break  # Remaining scaffolds won't fit either
        else
          emit "### $sname"
          emit ""
          emit "$content"
          emit ""
        fi
      done
    fi
  fi

  # --- Infrastructure (compact) ---
  emit "## Infrastructure"
  emit ""
  emit "Docker services (jadecli-infra): PostgreSQL 16+pgvector (5432), MongoDB 7 (27017), Dragonfly (6379), Ollama (11434)"
  emit ""

  # --- Quick Commands ---
  emit "## Quick Commands"
  emit ""
  emit '```bash'
  emit "jade-start              # Ecosystem dashboard"
  emit "jade-start <alias>      # Open project in Claude Code"
  emit "jade-start --health     # Run health checks"
  emit "jade-start --context    # Regenerate this file"
  emit '```'
  emit ""

  # --- Footer ---
  emit "---"
  emit "_Context generated by jade-ecosystem-assist/scripts/generate-context.sh_"
}

# Run
generate_context | write_output

# Report if not stdout
if [[ "$OUTPUT" != "-" ]]; then
  size=$(wc -c < "$OUTPUT")
  estimated_tokens=$((size / CHARS_PER_TOKEN))
  echo "Generated: $OUTPUT"
  echo "Size: $size bytes (~$estimated_tokens tokens)"
fi
