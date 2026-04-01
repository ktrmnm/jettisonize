#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/update_status.sh <story-id> --label "<short label>" --next-action "<next action>" [options]
  bash scripts/update_status.sh --dry-run <story-id> --label "<short label>" --next-action "<next action>" [options]

Appends one structured log entry to boosters/<story-id>/status.md and optionally updates
Current State and Checkpoint fields.

Options:
  --label <text>                    Required. Short label used in the log heading.
  --decision <text>                 Optional. May be passed multiple times.
  --finding <text>                  Optional. May be passed multiple times.
  --blockers <text>                 Optional. Defaults to "none".
  --next-action <text>              Required. Written into the log entry and Current State by default.
  --current-next-action <text>      Optional. Override the Current State next action separately.
  --owner <text>                    Optional. Rewrite Current State owner.
  --propel-status <value>           Optional. Rewrite Current State Propel Status.
  --booster-lifecycle <value>       Optional. Rewrite Current State Booster Lifecycle.
  --done-when-focus <text>          Optional. Rewrite Checkpoint done-when focus.
  --unfinished-work <text>          Optional. Rewrite Checkpoint unfinished work.
  --checkpoint-blockers <text>      Optional. Rewrite Checkpoint blockers.
  --pending-decisions <text>        Optional. Rewrite Checkpoint pending decisions.
  --scope-guardrail-check <text>    Optional. Rewrite Checkpoint scope / guardrail check.
  --help                            Show this help.
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

label=""
log_next_action=""
current_next_action=""
owner=""
propel_status=""
booster_lifecycle=""
done_when_focus=""
unfinished_work=""
checkpoint_blockers=""
pending_decisions=""
scope_guardrail_check=""
blockers="none"
blockers_explicit=0
root_dir=$(cd "$(dirname "$0")/.." && pwd)
status_file="$root_dir/boosters/$story_id/status.md"
today=$(date +%F)
tmp_dir=""

declare -a decisions=()
declare -a findings=()

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

trap cleanup EXIT

while [[ $# -gt 0 ]]; do
  case "$1" in
    --label)
      label=${2:-}
      shift 2
      ;;
    --decision)
      decisions+=("${2:-}")
      shift 2
      ;;
    --finding)
      findings+=("${2:-}")
      shift 2
      ;;
    --blockers)
      blockers=${2:-}
      blockers_explicit=1
      shift 2
      ;;
    --next-action)
      log_next_action=${2:-}
      shift 2
      ;;
    --current-next-action)
      current_next_action=${2:-}
      shift 2
      ;;
    --owner)
      owner=${2:-}
      shift 2
      ;;
    --propel-status)
      propel_status=${2:-}
      shift 2
      ;;
    --booster-lifecycle)
      booster_lifecycle=${2:-}
      shift 2
      ;;
    --done-when-focus)
      done_when_focus=${2:-}
      shift 2
      ;;
    --unfinished-work)
      unfinished_work=${2:-}
      shift 2
      ;;
    --checkpoint-blockers)
      checkpoint_blockers=${2:-}
      shift 2
      ;;
    --pending-decisions)
      pending_decisions=${2:-}
      shift 2
      ;;
    --scope-guardrail-check)
      scope_guardrail_check=${2:-}
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
  local label_name=$1
  local value=$2
  if [[ -z ${value// } ]]; then
    echo "$label_name is required" >&2
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

rewrite_section_line() {
  local file=$1
  local heading=$2
  local prefix=$3
  local value=$4
  local tmp_file=$5
  awk -v heading="$heading" -v prefix="$prefix" -v value="$value" '
    $0 == "## " heading { in_section=1; print; next }
    /^## / && in_section { in_section=0 }
    in_section && index($0, prefix) == 1 {
      print prefix value
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

replace_section_line() {
  local file=$1
  local heading=$2
  local prefix=$3
  local value=$4
  local safe_name
  safe_name=$(printf '%s' "$heading-$prefix" | tr ' /:.' '_____')
  local tmp_file="$tmp_dir/$safe_name.tmp"
  rewrite_section_line "$file" "$heading" "$prefix" "$value" "$tmp_file" || {
    echo "Could not find line starting with '$prefix' under '$heading' in $file" >&2
    exit 1
  }
  mv "$tmp_file" "$file"
}

insert_log_after_heading() {
  local file=$1
  local block_file=$2
  local tmp_file="$tmp_dir/log.tmp"
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

require_nonempty "--label" "$label"
require_nonempty "--next-action" "$log_next_action"
ensure_file "$status_file"

if [[ ${#decisions[@]} -eq 0 && ${#findings[@]} -eq 0 && $blockers_explicit -eq 0 ]]; then
  echo "Provide at least one --decision, --finding, or explicit --blockers entry" >&2
  exit 1
fi

if [[ -z "$current_next_action" ]]; then
  current_next_action=$log_next_action
fi

tmp_dir=$(mktemp -d)
log_block="$tmp_dir/log-entry.md"

{
  printf '### %s - %s\n\n' "$today" "$label"
  for item in "${decisions[@]}"; do
    printf -- '- Decision: %s\n' "$item"
  done
  for item in "${findings[@]}"; do
    printf -- '- Findings: %s\n' "$item"
  done
  printf -- '- Blockers: %s\n' "$blockers"
  printf -- '- Next action: %s\n' "$log_next_action"
  printf '\n'
} > "$log_block"

if [[ $dry_run -eq 1 ]]; then
  echo "[dry-run] would append the following log entry to $status_file:"
  cat "$log_block"
  if [[ -n "$propel_status" ]]; then
    echo "[dry-run] would set Current State Propel Status to \`$propel_status\`"
  fi
  if [[ -n "$booster_lifecycle" ]]; then
    echo "[dry-run] would set Current State Booster Lifecycle to \`$booster_lifecycle\`"
  fi
  if [[ -n "$owner" ]]; then
    echo "[dry-run] would set Current State Owner to \`$owner\`"
  fi
  echo "[dry-run] would set Current State Next action to: $current_next_action"
  if [[ -n "$done_when_focus" ]]; then
    echo "[dry-run] would update Checkpoint Done-when focus"
  fi
  if [[ -n "$unfinished_work" ]]; then
    echo "[dry-run] would update Checkpoint Unfinished work"
  fi
  if [[ -n "$checkpoint_blockers" ]]; then
    echo "[dry-run] would update Checkpoint Blockers"
  fi
  if [[ -n "$pending_decisions" ]]; then
    echo "[dry-run] would update Checkpoint Pending decisions"
  fi
  if [[ -n "$scope_guardrail_check" ]]; then
    echo "[dry-run] would update Checkpoint Scope / guardrail check"
  fi
  exit 0
fi

if [[ -n "$propel_status" ]]; then
  replace_section_line "$status_file" "Current State" "- Propel Status: " "\`$propel_status\`"
fi
if [[ -n "$booster_lifecycle" ]]; then
  replace_section_line "$status_file" "Current State" "- Booster Lifecycle: " "\`$booster_lifecycle\`"
fi
if [[ -n "$owner" ]]; then
  replace_section_line "$status_file" "Current State" "- Owner: " "\`$owner\`"
fi
replace_section_line "$status_file" "Current State" "- Next action: " "$current_next_action"

if [[ -n "$done_when_focus" ]]; then
  replace_section_line "$status_file" "Checkpoint" "- Done-when focus: " "$done_when_focus"
fi
if [[ -n "$unfinished_work" ]]; then
  replace_section_line "$status_file" "Checkpoint" "- Unfinished work: " "$unfinished_work"
fi
if [[ -n "$checkpoint_blockers" ]]; then
  replace_section_line "$status_file" "Checkpoint" "- Blockers: " "$checkpoint_blockers"
fi
if [[ -n "$pending_decisions" ]]; then
  replace_section_line "$status_file" "Checkpoint" "- Pending decisions: " "$pending_decisions"
fi
if [[ -n "$scope_guardrail_check" ]]; then
  replace_section_line "$status_file" "Checkpoint" "- Scope / guardrail check: " "$scope_guardrail_check"
fi

insert_log_after_heading "$status_file" "$log_block"
echo "Updated status for $story_id: $status_file"
