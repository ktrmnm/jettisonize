#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/jettison_booster.sh <story-id> --acceptance-note "<note>" --promoted "<note>" --discarded "<note>" [options]
  bash scripts/jettison_booster.sh --dry-run <story-id> --acceptance-note "<note>" --promoted "<note>" --discarded "<note>" [options]

Closes a completed booster, records retirement notes, optionally appends an unblock note to another booster,
and archives the closed booster under archive/boosters/<story-id>/.

Options:
  --acceptance-note <text>       Required. Evidence or confirmation used to accept the story.
  --promoted <text>              Required. What durable findings were promoted before jettison.
  --discarded <text>             Required. What was intentionally discarded.
  --upstream-status <story-id>   Optional. Another booster whose status.md should receive a closure note.
  --unblock-note <text>          Optional. Closure note appended to the upstream booster. Required with --upstream-status.
  --archive-root <path>          Optional. Defaults to archive/boosters under the repo root.
  --help                         Show this help.
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

if [[ $# -lt 1 ]]; then
  usage >&2
  exit 1
fi

story_id=$1
shift

acceptance_note=""
promoted_note=""
discarded_note=""
upstream_status=""
unblock_note=""

root_dir=$(cd "$(dirname "$0")/.." && pwd)
archive_root="$root_dir/archive/boosters"
tank_dir="$root_dir/boosters/$story_id"
story_file="$tank_dir/story.md"
status_file="$tank_dir/status.md"
today=$(date +%F)
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --acceptance-note)
      acceptance_note=${2:-}
      shift 2
      ;;
    --promoted)
      promoted_note=${2:-}
      shift 2
      ;;
    --discarded)
      discarded_note=${2:-}
      shift 2
      ;;
    --upstream-status)
      upstream_status=${2:-}
      shift 2
      ;;
    --unblock-note)
      unblock_note=${2:-}
      shift 2
      ;;
    --archive-root)
      archive_root=${2:-}
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

require_nonempty() {
  local label=$1
  local value=$2
  if [[ -z ${value// } ]]; then
    echo "$label is required" >&2
    exit 1
  fi
}

ensure_file() {
  local path=$1
  if [[ ! -f "$path" ]]; then
    echo "Required file not found: $path" >&2
    exit 1
  fi
}

extract_state_value() {
  local label=$1
  local file=$2
  sed -n "s/^- ${label}: \`\\(.*\\)\`$/\\1/p" "$file" | head -n 1
}

story_title() {
  sed -n 's/^# Story: \(.*\)$/\1/p' "$1" | head -n 1
}

rewrite_state_line() {
  local file=$1
  local label=$2
  local value=$3
  local tmp_file=$4
  awk -v label="$label" -v value="$value" '
    /^## Current State$/ {
      in_current_state=1
      print
      next
    }
    /^## / && in_current_state {
      in_current_state=0
    }
    in_current_state && index($0, "- " label ": ") == 1 {
      print "- " label ": " value
      found=1
      next
    }
    { print }
    END {
      if (!found) {
        exit 1
      }
    }
  ' "$file" > "$tmp_file"
}

replace_state_line() {
  local file=$1
  local label=$2
  local value=$3
  local tmp_file="$tmp_dir/$(basename "$file").state"
  rewrite_state_line "$file" "$label" "$value" "$tmp_file" || {
    echo "Could not find state line for $label in $file" >&2
    exit 1
  }
  mv "$tmp_file" "$file"
}

insert_log_after_heading() {
  local file=$1
  local block_file=$2
  local tmp_file="$tmp_dir/$(basename "$file").log"
  awk -v block_file="$block_file" '
    {
      print
      if ($0 == "## Log" && !done) {
        print ""
        while ((getline line < block_file) > 0) {
          print line
        }
        close(block_file)
        done=1
      }
    }
    END {
      if (!done) {
        exit 1
      }
    }
  ' "$file" > "$tmp_file" || {
    echo "Could not find log heading in $file" >&2
    exit 1
  }
  mv "$tmp_file" "$file"
}

require_nonempty "--acceptance-note" "$acceptance_note"
require_nonempty "--promoted" "$promoted_note"
require_nonempty "--discarded" "$discarded_note"

if [[ -n "$upstream_status" && -z "$unblock_note" ]]; then
  echo "--unblock-note is required when --upstream-status is supplied" >&2
  exit 1
fi

if [[ -z "$upstream_status" && -n "$unblock_note" ]]; then
  echo "--upstream-status is required when --unblock-note is supplied" >&2
  exit 1
fi

if [[ ! -d "$tank_dir" ]]; then
  echo "Booster not found: $tank_dir" >&2
  exit 1
fi

ensure_file "$story_file"
ensure_file "$status_file"

current_move_status=$(extract_state_value "Propel Status" "$status_file")
current_lifecycle=$(extract_state_value "Booster Lifecycle" "$status_file")
title=$(story_title "$story_file")

if [[ "$current_move_status" != "done" ]]; then
  echo "Refusing to jettison $story_id: Propel Status must be \`done\`, got \`$current_move_status\`" >&2
  exit 1
fi

if [[ "$current_lifecycle" != "propel" && "$current_lifecycle" != "jettison" ]]; then
  echo "Refusing to jettison $story_id: Booster Lifecycle must be \`propel\` or \`jettison\`, got \`$current_lifecycle\`" >&2
  exit 1
fi

dest_dir="$archive_root/$story_id"
if [[ -e "$dest_dir" ]]; then
  echo "Archive destination already exists: $dest_dir" >&2
  exit 1
fi

upstream_file=""
if [[ -n "$upstream_status" ]]; then
  upstream_file="$root_dir/boosters/$upstream_status/status.md"
  ensure_file "$upstream_file"
fi

if [[ $dry_run -eq 1 ]]; then
  echo "[dry-run] would set Booster Lifecycle to \`jettison\` in $status_file"
  echo "[dry-run] would add retirement log entry to $status_file"
  if [[ -n "$upstream_file" ]]; then
    echo "[dry-run] would append closure note to $upstream_file"
  fi
  echo "[dry-run] would move $tank_dir to $dest_dir"
  echo "[dry-run] would set Propel Status to \`closed\` in $dest_dir/status.md"
  exit 0
fi

mkdir -p "$archive_root"
tmp_dir=$(mktemp -d)
retirement_block="$tmp_dir/retirement.md"
upstream_block="$tmp_dir/upstream.md"

cat > "$retirement_block" <<EOF
### $today - Booster jettisoned

- Decision: closed the booster and archived it under \`archive/boosters/$story_id/\`
- Acceptance evidence: $acceptance_note
- Durable promotion: $promoted_note
- Discarded context: $discarded_note
$(if [[ -n "$upstream_status" ]]; then printf '%s\n' "- Upstream unblock update: appended a closure note to \`boosters/$upstream_status/status.md\`"; fi)
- Next action: none; this booster is closed

EOF

replace_state_line "$status_file" "Booster Lifecycle" "\`jettison\`"
replace_state_line "$status_file" "Next action" "booster is being archived and closed"
insert_log_after_heading "$status_file" "$retirement_block"

if [[ -n "$upstream_file" ]]; then
  cat > "$upstream_block" <<EOF
### $today - Blocker closed: $story_id

- Findings: blocker booster \`$story_id\` was closed
- Next action: $unblock_note

EOF
  insert_log_after_heading "$upstream_file" "$upstream_block"
fi

mv "$tank_dir" "$dest_dir"

archived_status="$dest_dir/status.md"
replace_state_line "$archived_status" "Propel Status" "\`closed\`"
replace_state_line "$archived_status" "Booster Lifecycle" "\`jettison\`"
replace_state_line "$archived_status" "Next action" "none; booster is archived"

echo "Jettisoned $story_id: archived to $dest_dir"
if [[ -n "$upstream_status" ]]; then
  echo "Updated upstream booster status: $upstream_status"
fi
if [[ -n "$title" ]]; then
  echo "Closed story: $title"
fi
