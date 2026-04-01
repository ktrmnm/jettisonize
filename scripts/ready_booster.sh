#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/ready_booster.sh <story-id>
  bash scripts/ready_booster.sh --dry-run <story-id>

Creates the execution bundle for an existing story-first booster.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

dry_run=0
if [[ ${1:-} == "--dry-run" ]]; then
  dry_run=1
  shift
fi

if [[ $# -ne 1 ]]; then
  usage >&2
  exit 1
fi

story_id=$1
root_dir=$(cd "$(dirname "$0")/.." && pwd)
template_dir="$root_dir/templates/booster"
tank_dir="$root_dir/boosters/$story_id"
story_file="$tank_dir/story.md"

if [[ ! -d "$tank_dir" ]]; then
  echo "Booster not found: $tank_dir" >&2
  exit 1
fi

if [[ ! -f "$story_file" ]]; then
  echo "story.md not found: $story_file" >&2
  exit 1
fi

extract_meta() {
  local label=$1
  sed -n "s/^- ${label}: \`\\(.*\\)\`$/\\1/p" "$story_file" | head -n 1
}

story_title=$(sed -n 's/^# Story: \(.*\)$/\1/p' "$story_file" | head -n 1)
epic_id=$(extract_meta "Epic")
created_date=$(extract_meta "Created")
story_preset=$(extract_meta "Story Preset")
acceptance_mode=$(extract_meta "Acceptance Mode")

if [[ -z "$story_title" ]]; then
  echo "Could not parse story title from $story_file" >&2
  exit 1
fi

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

render_template() {
  local src=$1
  local dst=$2
  if [[ -e "$dst" ]]; then
    echo "Refusing to overwrite existing file: $dst" >&2
    exit 1
  fi
  sed \
    -e "s|{{STORY_ID}}|$(escape_sed "$story_id")|g" \
    -e "s|{{STORY_TITLE}}|$(escape_sed "$story_title")|g" \
    -e "s|{{EPIC_ID}}|$(escape_sed "${epic_id:-unknown-epic}")|g" \
    -e "s|{{STORY_PRESET}}|$(escape_sed "${story_preset:-unspecified}")|g" \
    -e "s|{{ACCEPTANCE_MODE}}|$(escape_sed "${acceptance_mode:-unspecified}")|g" \
    -e "s|{{CREATED_DATE}}|$(escape_sed "${created_date:-$(date +%F)}")|g" \
    "$src" > "$dst"
}

if [[ $dry_run -eq 1 ]]; then
  echo "[dry-run] would create ready-phase execution bundle in: $tank_dir"
  printf '%s\n' \
    "[dry-run] would render: spec.md" \
    "[dry-run] would render: plan.md" \
    "[dry-run] would render: status.md"
  exit 0
fi

render_template "$template_dir/spec.md" "$tank_dir/spec.md"
render_template "$template_dir/plan.md" "$tank_dir/plan.md"
render_template "$template_dir/status.md" "$tank_dir/status.md"

echo "Created ready-phase execution bundle: $tank_dir"
echo "Required next step: refine spec.md, plan.md, and status.md before propel."
