#!/usr/bin/env bash
# generate-dependency-matrix.sh - Extract dependency versions from projects
#
# Usage:
#   ./generate-dependency-matrix.sh              # All projects
#   ./generate-dependency-matrix.sh jade-index   # Single project

set -euo pipefail

PROJECTS_ROOT="$HOME/projects"
SINGLE_PROJECT="${1:-}"

# Function to extract Python dependencies
extract_python_deps() {
    local project_path="$1"
    local pyproject="$project_path/pyproject.toml"

    if [[ ! -f "$pyproject" ]]; then
        return
    fi

    echo "#### Python Dependencies"
    echo ""
    echo "| Package | Version |"
    echo "|---------|---------|"

    # Extract from [project.dependencies]
    sed -n '/^\[project\.dependencies\]/,/^\[/p' "$pyproject" | \
        grep -E '^\s*"' | \
        sed 's/^[[:space:]]*"//; s/".*$//' | \
        while IFS='=' read -r pkg version; do
            pkg=$(echo "$pkg" | xargs)
            version=$(echo "$version" | xargs | tr -d '"' | sed 's/[<>=~^]//g')
            [[ -n "$pkg" ]] && echo "| $pkg | $version |"
        done
}

# Function to extract Node.js dependencies
extract_node_deps() {
    local project_path="$1"
    local package_json="$project_path/package.json"

    if [[ ! -f "$package_json" ]] || ! command -v jq &>/dev/null; then
        return
    fi

    echo "#### Node.js Dependencies"
    echo ""
    echo "| Package | Version |"
    echo "|---------|---------|"

    jq -r '.dependencies // {} | to_entries[] | "| \(.key) | \(.value) |"' "$package_json" 2>/dev/null
}

# Main logic
if [[ -n "$SINGLE_PROJECT" ]]; then
    project_path="$PROJECTS_ROOT/$SINGLE_PROJECT"
    if [[ -d "$project_path" ]]; then
        echo "## $SINGLE_PROJECT Dependencies"
        echo ""
        extract_python_deps "$project_path"
        extract_node_deps "$project_path"
    else
        echo "Project not found: $SINGLE_PROJECT" >&2
        exit 1
    fi
else
    # Generate for all known projects
    declare -a projects=(
        "claude-objects"
        "jade-cli"
        "jade-dev-assist"
        "jade-index"
    )

    for project in "${projects[@]}"; do
        project_path="$PROJECTS_ROOT/$project"
        if [[ -d "$project_path" ]]; then
            echo "## $project"
            echo ""
            extract_python_deps "$project_path"
            extract_node_deps "$project_path"
            echo ""
        fi
    done
fi
