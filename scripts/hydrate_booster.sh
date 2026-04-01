#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/hydrate_booster.sh <story-id>

Prints a compact handoff summary from boosters/<story-id>/.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

story_id=$1
root_dir=$(cd "$(dirname "$0")/.." && pwd)
tank_dir="$root_dir/boosters/$story_id"

if [[ ! -d "$tank_dir" ]]; then
  echo "Booster not found: $tank_dir" >&2
  exit 1
fi

extract_section() {
  local file=$1
  local heading=$2
  awk -v heading="$heading" '
    $0 == "## " heading { in_section=1; next }
    /^## / && in_section { exit }
    in_section { print }
  ' "$file"
}

extract_first_section() {
  local file=$1
  shift
  local heading
  local content

  for heading in "$@"; do
    content=$(extract_section "$file" "$heading")
    if [[ -n "$content" ]]; then
      printf '%s' "$content"
      return 0
    fi
  done

  return 1
}

print_section() {
  local label=$1
  local file=$2
  local heading=$3
  local content
  content=$(extract_section "$file" "$heading")
  if [[ -n "$content" ]]; then
    echo "## $label"
    printf '%s\n' "$content"
    echo
  fi
}

print_first_section() {
  local label=$1
  local file=$2
  shift 2
  local content

  if content=$(extract_first_section "$file" "$@"); then
    echo "## $label"
    printf '%s\n' "$content"
    echo
  fi
}

story_file="$tank_dir/story.md"
spec_file="$tank_dir/spec.md"
plan_file="$tank_dir/plan.md"
status_file="$tank_dir/status.md"

echo "# Handoff: $story_id"
echo
print_section "Background" "$story_file" "Background"
print_section "Deliverables" "$story_file" "Deliverables"
print_section "Done When" "$story_file" "Done When"
print_section "Guardrails" "$story_file" "Guardrails"
if [[ -f "$plan_file" ]]; then
  print_section "Current Plan" "$plan_file" "Steps"
  print_section "Dependencies" "$plan_file" "Dependencies"
fi
if [[ -f "$status_file" ]]; then
  print_section "Current State" "$status_file" "Current State"
  print_first_section "Checkpoint" "$status_file" "Checkpoint" "Latest Checkpoint"
  echo "## Recent Log"
  awk 'f{print} /^## Log$/{f=1; next}' "$status_file"
else
  echo "## Current Mode"
  echo "Story-first draft only. Execution bundle has not been prepared yet."
fi
