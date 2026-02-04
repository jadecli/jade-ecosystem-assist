#!/usr/bin/env bash
# generate-context.sh - Generate consolidated context.md from ecosystem scaffolds
# Output: ~/.jade/context.md (default) or stdout with -o -
#
# Usage:
#   ./generate-context.sh              # Write to ~/.jade/context.md
#   ./generate-context.sh -o -         # Write to stdout
#   ./generate-context.sh -o /path     # Write to custom path
#   ./generate-context.sh --brief      # Shorter output (~8k tokens)

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
SCAFFOLDS_DIR="$REPO_ROOT/architecture/ascii/scaffolds"
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
      echo "  --focus PROJECT       Generate focused context for single project"
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

# Function to write output
write_output() {
  if [[ "$OUTPUT" == "-" ]]; then
    cat
  else
    cat > "$OUTPUT"
  fi
}

# Function to get project status from tasks.json
get_project_status() {
  local project_dir="$1"
  local tasks_file="$project_dir/.claude/tasks/tasks.json"

  if [[ -f "$tasks_file" ]]; then
    local total=$(jq '.tasks | length' "$tasks_file" 2>/dev/null || echo 0)
    local completed=$(jq '[.tasks[] | select(.status == "completed")] | length' "$tasks_file" 2>/dev/null || echo 0)
    local pending=$(jq '[.tasks[] | select(.status == "pending")] | length' "$tasks_file" 2>/dev/null || echo 0)
    local in_progress=$(jq '[.tasks[] | select(.status == "in_progress" or .status == "in-progress")] | length' "$tasks_file" 2>/dev/null || echo 0)
    echo "$completed/$total done, $pending pending, $in_progress active"
  else
    echo "no tasks.json"
  fi
}

# Function to check if project is healthy
check_project_health() {
  local project_dir="$1"
  local name="$2"

  # Check if directory exists and has content
  if [[ ! -d "$project_dir" ]]; then
    echo "missing"
    return
  fi

  # Check for common health indicators
  if [[ -f "$project_dir/package.json" ]]; then
    if [[ -d "$project_dir/node_modules" ]]; then
      echo "ready"
    else
      echo "needs npm install"
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

# Function to get recent commit activity
get_recent_commits() {
  local project_dir="$1"
  local limit="${2:-3}"

  if [[ ! -d "$project_dir/.git" ]]; then
    echo "not a git repo"
    return
  fi

  cd "$project_dir"
  git log -n "$limit" --pretty=format:"%h %ar: %s" 2>/dev/null || echo "no commits"
  cd - &>/dev/null
}

# Function to check if submodule is stale
check_submodule_staleness() {
  local submodule_path="$1"

  if [[ ! -d "$submodule_path/.git" ]]; then
    echo "not-initialized"
    return
  fi

  cd "$submodule_path"

  # Fetch remote to get latest info (quietly)
  git fetch origin --quiet 2>/dev/null || {
    echo "fetch-failed"
    cd - &>/dev/null
    return
  }

  # Get current commit and remote head
  local current=$(git rev-parse HEAD 2>/dev/null)
  local remote=$(git rev-parse origin/HEAD 2>/dev/null || git rev-parse origin/main 2>/dev/null || git rev-parse origin/master 2>/dev/null)

  if [[ "$current" == "$remote" ]]; then
    echo "up-to-date"
  else
    local behind=$(git rev-list --count HEAD..origin/HEAD 2>/dev/null || git rev-list --count HEAD..origin/main 2>/dev/null || echo "0")
    local ahead=$(git rev-list --count origin/HEAD..HEAD 2>/dev/null || git rev-list --count origin/main..HEAD 2>/dev/null || echo "0")

    if [[ $behind -gt 0 ]] && [[ $ahead -eq 0 ]]; then
      echo "behind-$behind"
    elif [[ $ahead -gt 0 ]] && [[ $behind -eq 0 ]]; then
      echo "ahead-$ahead"
    else
      echo "diverged"
    fi
  fi

  cd - &>/dev/null
}

# Generate the context document
generate_context() {
  local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  cat << 'HEADER'
# jadecli Ecosystem Context

Auto-generated context for Claude Code sessions.

HEADER

  echo "Generated: $timestamp"
  echo ""

  # Project summary table
  echo "## Projects Overview"
  echo ""
  echo "| Project | Path | Status | Tasks |"
  echo "|---------|------|--------|-------|"

  # List of projects with their local paths
  declare -A projects=(
    ["claude-objects"]="$HOME/projects/claude-objects"
    ["dotfiles"]="$HOME/projects/dotfiles"
    ["jade-claude-settings"]="$HOME/projects/jade-claude-settings"
    ["jade-cli"]="$HOME/projects/jade-cli"
    ["jade-dev-assist"]="$HOME/projects/jade-dev-assist"
    ["jade-ide"]="$HOME/projects/jade-ide"
    ["jade-index"]="$HOME/projects/jade-index"
    ["jade-swarm-superpowers"]="$HOME/projects/jade-swarm-superpowers"
    ["jadecli-infra"]="$HOME/projects/jadecli-infra"
    ["jadecli-roadmap"]="$HOME/projects/jadecli-roadmap-and-architecture"
  )

  for name in $(echo "${!projects[@]}" | tr ' ' '\n' | sort); do
    # Skip if focus mode and doesn't match
    if [[ -n "$FOCUS_PROJECT" ]] && [[ "$name" != "$FOCUS_PROJECT" ]]; then
      continue
    fi

    local path="${projects[$name]}"
    local health=$(check_project_health "$path" "$name")
    local tasks=$(get_project_status "$path")
    echo "| $name | ${path#$HOME/} | $health | $tasks |"
  done

  echo ""

  # Recent commit activity
  if [[ "$BRIEF" != "true" ]]; then
    echo "## Recent Activity"
    echo ""

    for name in $(echo "${!projects[@]}" | tr ' ' '\n' | sort); do
      # Skip if focus mode and doesn't match
      if [[ -n "$FOCUS_PROJECT" ]] && [[ "$name" != "$FOCUS_PROJECT" ]]; then
        continue
      fi

      local path="${projects[$name]}"
      if [[ -d "$path" ]]; then
        echo "### $name"
        echo ""
        echo '```'
        get_recent_commits "$path" 3
        echo '```'
        echo ""
      fi
    done
  fi

  # Architecture scaffolds (the main content)
  echo "## Architecture Scaffolds"
  echo ""

  if [[ -d "$SCAFFOLDS_DIR" ]]; then
    local total_chars=0
    local max_chars=$((MAX_TOKENS * CHARS_PER_TOKEN))

    for scaffold in "$SCAFFOLDS_DIR"/*.md; do
      if [[ -f "$scaffold" ]]; then
        local name=$(basename "$scaffold" .md)

        # Skip if focus mode and doesn't match
        if [[ -n "$FOCUS_PROJECT" ]] && [[ "$name" != "$FOCUS_PROJECT" ]]; then
          continue
        fi

        local content=$(cat "$scaffold")
        local content_chars=${#content}

        # Check if adding this would exceed budget
        if [[ $((total_chars + content_chars)) -gt $max_chars ]]; then
          if [[ "$BRIEF" == "true" ]]; then
            echo "### $name"
            echo ""
            echo "_[Truncated for token budget. Run without --brief for full content.]_"
            echo ""
          else
            echo "### $name"
            echo ""
            echo "$content"
            echo ""
          fi
        else
          echo "### $name"
          echo ""
          echo "$content"
          echo ""
          total_chars=$((total_chars + content_chars))
        fi
      fi
    done
  else
    echo "_No scaffolds directory found at $SCAFFOLDS_DIR_"
    echo ""
  fi

  # Submodule status
  echo "## Submodule Status"
  echo ""

  if [[ -f "$REPO_ROOT/.gitmodules" ]]; then
    echo "| Submodule | Status |"
    echo "|-----------|--------|"

    # Parse .gitmodules for submodule paths
    grep -E "^\[submodule" "$REPO_ROOT/.gitmodules" | sed 's/\[submodule "\(.*\)"\]/\1/' | while read -r name; do
      local path=$(grep -A 2 "^\[submodule \"$name\"\]" "$REPO_ROOT/.gitmodules" | grep "path = " | cut -d'=' -f2 | xargs)
      if [[ -n "$path" ]]; then
        local status=$(check_submodule_staleness "$REPO_ROOT/$path")

        case "$status" in
          up-to-date)
            echo "| $name | ✅ Up to date |"
            ;;
          behind-*)
            local count=$(echo "$status" | cut -d'-' -f2)
            echo "| $name | ⚠️ Behind by $count commits |"
            ;;
          ahead-*)
            local count=$(echo "$status" | cut -d'-' -f2)
            echo "| $name | ⚠️ Ahead by $count commits |"
            ;;
          diverged)
            echo "| $name | ❌ Diverged from remote |"
            ;;
          not-initialized)
            echo "| $name | ❌ Not initialized |"
            ;;
          fetch-failed)
            echo "| $name | ⚠️ Fetch failed |"
            ;;
        esac
      fi
    done
  else
    echo "_No .gitmodules file found_"
  fi
  echo ""

  # Infrastructure status
  echo "## Infrastructure"
  echo ""
  echo "Docker services (jadecli-infra):"
  echo "- PostgreSQL 16 + pgvector (5432)"
  echo "- MongoDB 7 (27017)"
  echo "- Dragonfly cache (6379)"
  echo "- Ollama (11434, optional)"
  echo ""

  # Quick commands
  echo "## Quick Commands"
  echo ""
  echo '```bash'
  echo "jade-start              # Ecosystem dashboard"
  echo "jade-start <alias>      # Open project in Claude Code"
  echo "jade-start --health     # Run health checks"
  echo "jade-start --context    # Regenerate this file"
  echo '```'
  echo ""

  # Footer
  echo "---"
  echo "_Context generated by jade-ecosystem-assist/scripts/generate-context.sh_"
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
