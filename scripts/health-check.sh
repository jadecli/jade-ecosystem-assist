#!/usr/bin/env bash
# health-check.sh - Aggregate health checks across all jadecli projects
#
# Usage:
#   ./health-check.sh              # Run all health checks
#   ./health-check.sh --quick      # Skip slow checks (tests)
#   ./health-check.sh --json       # Output as JSON
#   ./health-check.sh <project>    # Check specific project only

set -euo pipefail

# Colors (disabled if not TTY)
if [[ -t 1 ]]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  NC='\033[0m' # No Color
else
  RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

# Configuration
PROJECTS_ROOT="$HOME/projects"
QUICK_MODE=false
JSON_OUTPUT=false
SINGLE_PROJECT=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --quick|-q)
      QUICK_MODE=true
      shift
      ;;
    --json|-j)
      JSON_OUTPUT=true
      shift
      ;;
    -h|--help)
      echo "Usage: $(basename "$0") [OPTIONS] [PROJECT]"
      echo ""
      echo "Options:"
      echo "  --quick, -q    Skip slow checks (tests, full builds)"
      echo "  --json, -j     Output results as JSON"
      echo "  -h, --help     Show this help"
      echo ""
      echo "Projects:"
      echo "  claude-objects, dotfiles, jade-claude-settings, jade-cli,"
      echo "  jade-dev-assist, jade-ide, jade-index, jade-swarm-superpowers,"
      echo "  jadecli-infra, jadecli-roadmap"
      exit 0
      ;;
    -*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      SINGLE_PROJECT="$1"
      shift
      ;;
  esac
done

# Project definitions with health check commands
# Format: project_name|directory_name|check_command|check_type
declare -a PROJECTS=(
  "claude-objects|claude-objects|uv run pytest --co -q|python"
  "dotfiles|dotfiles|chezmoi verify 2>/dev/null || true|dotfiles"
  "jade-claude-settings|jade-claude-settings|test -f CLAUDE.md|docs"
  "jade-cli|jade-cli|npm run build --if-present 2>/dev/null|node"
  "jade-dev-assist|jade-dev-assist|npm run build --if-present 2>/dev/null|node"
  "jade-ide|jade-ide|test -f product.json|vscode"
  "jade-index|jade-index|uv run pytest --co -q|python"
  "jade-swarm-superpowers|jade-swarm-superpowers|test -f README.md|docs"
  "jadecli-infra|jadecli-infra|docker compose config -q 2>/dev/null|docker"
  "jadecli-roadmap|jadecli-roadmap-and-architecture|test -f README.md|docs"
)

# Results storage
declare -A RESULTS
declare -A MESSAGES
HEALTHY_COUNT=0
TOTAL_COUNT=0

# Function to check a single project
check_project() {
  local name="$1"
  local dir="$2"
  local cmd="$3"
  local check_type="$4"
  local project_path="$PROJECTS_ROOT/$dir"

  if [[ ! -d "$project_path" ]]; then
    RESULTS["$name"]="missing"
    MESSAGES["$name"]="Directory not found"
    return
  fi

  cd "$project_path"

  # Type-specific checks
  case "$check_type" in
    python)
      # Check pyproject.toml and venv
      if [[ ! -f "pyproject.toml" ]]; then
        RESULTS["$name"]="warn"
        MESSAGES["$name"]="No pyproject.toml"
        return
      fi
      if [[ ! -d ".venv" ]]; then
        RESULTS["$name"]="warn"
        MESSAGES["$name"]="No .venv (run: uv sync)"
        return
      fi
      if [[ "$QUICK_MODE" == "false" ]]; then
        if eval "$cmd" >/dev/null 2>&1; then
          RESULTS["$name"]="pass"
          MESSAGES["$name"]="Tests discoverable"
        else
          RESULTS["$name"]="fail"
          MESSAGES["$name"]="Test discovery failed"
        fi
      else
        RESULTS["$name"]="pass"
        MESSAGES["$name"]="Venv ready (quick mode)"
      fi
      ;;

    node)
      if [[ ! -f "package.json" ]]; then
        RESULTS["$name"]="warn"
        MESSAGES["$name"]="No package.json"
        return
      fi
      if [[ ! -d "node_modules" ]]; then
        RESULTS["$name"]="warn"
        MESSAGES["$name"]="No node_modules (run: npm install)"
        return
      fi
      if [[ "$QUICK_MODE" == "false" ]]; then
        if eval "$cmd" >/dev/null 2>&1; then
          RESULTS["$name"]="pass"
          MESSAGES["$name"]="Build successful"
        else
          # Build might not exist, check if lint passes instead
          if npm run lint --if-present >/dev/null 2>&1; then
            RESULTS["$name"]="pass"
            MESSAGES["$name"]="Lint passes"
          else
            RESULTS["$name"]="warn"
            MESSAGES["$name"]="Build/lint issues"
          fi
        fi
      else
        RESULTS["$name"]="pass"
        MESSAGES["$name"]="Dependencies installed (quick mode)"
      fi
      ;;

    docker)
      if [[ ! -f "docker-compose.yml" ]] && [[ ! -f "compose.yml" ]]; then
        RESULTS["$name"]="warn"
        MESSAGES["$name"]="No compose file"
        return
      fi
      if eval "$cmd" 2>/dev/null; then
        # Check if services are running
        local running=$(docker compose ps --status running -q 2>/dev/null | wc -l)
        if [[ $running -gt 0 ]]; then
          RESULTS["$name"]="pass"
          MESSAGES["$name"]="$running services running"
        else
          RESULTS["$name"]="warn"
          MESSAGES["$name"]="Config valid, no services running"
        fi
      else
        RESULTS["$name"]="fail"
        MESSAGES["$name"]="Invalid compose config"
      fi
      ;;

    vscode)
      if eval "$cmd" 2>/dev/null; then
        RESULTS["$name"]="pass"
        MESSAGES["$name"]="Product config present"
      else
        RESULTS["$name"]="fail"
        MESSAGES["$name"]="Missing product.json"
      fi
      ;;

    dotfiles)
      if command -v chezmoi >/dev/null 2>&1; then
        RESULTS["$name"]="pass"
        MESSAGES["$name"]="chezmoi available"
      else
        RESULTS["$name"]="warn"
        MESSAGES["$name"]="chezmoi not installed"
      fi
      ;;

    docs)
      if eval "$cmd" 2>/dev/null; then
        RESULTS["$name"]="pass"
        MESSAGES["$name"]="Documentation present"
      else
        RESULTS["$name"]="fail"
        MESSAGES["$name"]="Missing documentation"
      fi
      ;;

    *)
      if eval "$cmd" >/dev/null 2>&1; then
        RESULTS["$name"]="pass"
        MESSAGES["$name"]="Check passed"
      else
        RESULTS["$name"]="fail"
        MESSAGES["$name"]="Check failed"
      fi
      ;;
  esac
}

# Run health checks
for project_def in "${PROJECTS[@]}"; do
  IFS='|' read -r name dir cmd check_type <<< "$project_def"

  # Skip if single project specified and doesn't match
  if [[ -n "$SINGLE_PROJECT" ]] && [[ "$name" != "$SINGLE_PROJECT" ]]; then
    continue
  fi

  check_project "$name" "$dir" "$cmd" "$check_type"
  TOTAL_COUNT=$((TOTAL_COUNT + 1))

  if [[ "${RESULTS[$name]}" == "pass" ]]; then
    HEALTHY_COUNT=$((HEALTHY_COUNT + 1))
  fi
done

# Output results
if [[ "$JSON_OUTPUT" == "true" ]]; then
  echo "{"
  echo "  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\","
  echo "  \"summary\": {"
  echo "    \"healthy\": $HEALTHY_COUNT,"
  echo "    \"total\": $TOTAL_COUNT"
  echo "  },"
  echo "  \"projects\": {"

  first=true
  for name in $(echo "${!RESULTS[@]}" | tr ' ' '\n' | sort); do
    if [[ "$first" == "true" ]]; then
      first=false
    else
      echo ","
    fi
    printf '    "%s": {"status": "%s", "message": "%s"}' "$name" "${RESULTS[$name]}" "${MESSAGES[$name]}"
  done
  echo ""
  echo "  }"
  echo "}"
else
  # Human-readable output
  echo ""
  echo "jadecli Ecosystem Health Check"
  echo "=============================="
  echo ""

  if [[ "$QUICK_MODE" == "true" ]]; then
    echo -e "${BLUE}Mode: Quick (skipping tests)${NC}"
    echo ""
  fi

  for name in $(echo "${!RESULTS[@]}" | tr ' ' '\n' | sort); do
    status="${RESULTS[$name]}"
    message="${MESSAGES[$name]}"

    case "$status" in
      pass)
        echo -e "${GREEN}[PASS]${NC} $name - $message"
        ;;
      warn)
        echo -e "${YELLOW}[WARN]${NC} $name - $message"
        ;;
      fail)
        echo -e "${RED}[FAIL]${NC} $name - $message"
        ;;
      missing)
        echo -e "${RED}[MISS]${NC} $name - $message"
        ;;
    esac
  done

  echo ""
  echo "=============================="
  if [[ $HEALTHY_COUNT -eq $TOTAL_COUNT ]]; then
    echo -e "${GREEN}Summary: $HEALTHY_COUNT/$TOTAL_COUNT healthy${NC}"
  elif [[ $HEALTHY_COUNT -gt $((TOTAL_COUNT / 2)) ]]; then
    echo -e "${YELLOW}Summary: $HEALTHY_COUNT/$TOTAL_COUNT healthy${NC}"
  else
    echo -e "${RED}Summary: $HEALTHY_COUNT/$TOTAL_COUNT healthy${NC}"
  fi
  echo ""
fi
