#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/fuel_booster.sh --title "<story-title>" --preset <story-preset> [options]
  bash scripts/fuel_booster.sh --dry-run --title "<story-title>" --preset <story-preset> [options]
  bash scripts/fuel_booster.sh <story-id> <story-title> [epic-id] [story-preset] [acceptance-mode]

Creates a new story-first booster draft under boosters/<story-id>/ with `story.md` only.

Options:
  --title <title>                 Story title. Required in flag mode.
  --preset <preset>               Story preset. Required in flag mode.
  --acceptance <mode>             Acceptance mode. Defaults from preset, not config.
  --epic <epic-id>                Epic label or linkage. Falls back to config.
  --story-id <canonical-id>       Explicit canonical story ID. Optional in flag mode.
  --slug <slug>                   Human-readable slug metadata. Optional.
  --external-ref <ref>            External tracker reference metadata. Optional.
  --switch-active <prompt|yes|no> Override config behavior for active-booster switching.
  --config <path>                 Config file. Defaults to .jettison.toml in repo root.

v1 config surface:
  - .jettison.toml provides defaults for epic, switch_active, agent-authored draft language, and local canonical ID generation.
  - Acceptance mode comes from the preset unless explicitly overridden on the command line.
  - Slug and external-ref remain per-story metadata, not config defaults.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

dry_run=0
root_dir=$(cd "$(dirname "$0")/.." && pwd)
template_dir="$root_dir/templates/booster"
config_path="$root_dir/.jettison.toml"
created_date=$(date +%F)
arg_mode="flags"
story_id=""
story_title=""
epic_id=""
story_preset=""
acceptance_mode=""
story_slug=""
external_ref=""
switch_active=""

if [[ ! -d "$template_dir" ]]; then
  echo "Template directory not found: $template_dir" >&2
  exit 1
fi

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\&|]/\\&/g'
}

trim() {
  printf '%s' "$1" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//'
}

toml_get() {
  local section=$1
  local key=$2
  awk -v section="$section" -v key="$key" '
    BEGIN { in_section = 0 }
    /^[[:space:]]*\[/ {
      in_section = ($0 == "[" section "]")
      next
    }
    in_section && $0 ~ "^[[:space:]]*" key "[[:space:]]*=" {
      sub("^[[:space:]]*" key "[[:space:]]*=[[:space:]]*", "", $0)
      gsub(/^"/, "", $0)
      gsub(/"$/, "", $0)
      gsub(/[[:space:]]+$/, "", $0)
      print $0
      exit
    }
  ' "$config_path"
}

default_acceptance_for_preset() {
  case "$1" in
    feature|enablement|validation) printf '%s\n' "mixed" ;;
    research|decision|draft) printf '%s\n' "human" ;;
    *) printf '%s\n' "unspecified" ;;
  esac
}

slugify() {
  local raw=$1
  local out
  out=$(printf '%s' "$raw" \
    | tr '[:upper:]' '[:lower:]' \
    | sed -e 's/[^a-z0-9]/-/g' -e 's/-\{2,\}/-/g' -e 's/^-//' -e 's/-$//')
  printf '%s\n' "$out"
}

next_local_id() {
  local prefix=$1
  local width=$2
  local max_id=0
  local path base num
  while IFS= read -r path; do
    base=$(basename "$path")
    if [[ $base =~ ^${prefix}-([0-9]+)$ ]]; then
      num=${BASH_REMATCH[1]}
      num=$((10#$num))
      if (( num > max_id )); then
        max_id=$num
      fi
    fi
  done < <(find "$root_dir/boosters" "$root_dir/archive/boosters" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  printf '%s-%0*d\n' "$prefix" "$width" "$((max_id + 1))"
}

ensure_story_id_available() {
  local candidate=$1
  local active_path="$root_dir/boosters/$candidate"
  local archived_path="$root_dir/archive/boosters/$candidate"

  if [[ -e "$active_path" ]]; then
    echo "Canonical story ID already exists in active boosters: $active_path" >&2
    exit 1
  fi

  if [[ -e "$archived_path" ]]; then
    echo "Canonical story ID already exists in archived boosters: $archived_path" >&2
    exit 1
  fi
}

if [[ ${1:-} == "--dry-run" ]]; then
  dry_run=1
  shift
fi

if [[ $# -ge 1 && ${1:-} != --* ]]; then
  arg_mode="legacy"
fi

if [[ $arg_mode == "legacy" ]]; then
  if [[ $# -lt 2 || $# -gt 5 ]]; then
    usage >&2
    exit 1
  fi
  story_id=$1
  story_title=$2
  epic_id=${3:-unknown-epic}
  story_preset=${4:-unspecified}
  acceptance_mode=${5:-$(default_acceptance_for_preset "$story_preset")}
  story_slug=$story_id
  external_ref="none"
  switch_active="no"
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --title)
        story_title=${2:-}
        shift 2
        ;;
      --preset)
        story_preset=${2:-}
        shift 2
        ;;
      --acceptance)
        acceptance_mode=${2:-}
        shift 2
        ;;
      --epic)
        epic_id=${2:-}
        shift 2
        ;;
      --story-id)
        story_id=${2:-}
        shift 2
        ;;
      --slug)
        story_slug=${2:-}
        shift 2
        ;;
      --external-ref)
        external_ref=${2:-}
        shift 2
        ;;
      --switch-active)
        switch_active=${2:-}
        shift 2
        ;;
      --config)
        config_path=${2:-}
        shift 2
        ;;
      *)
        echo "Unknown argument: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  if [[ ! -f "$config_path" ]]; then
    echo "Config file not found: $config_path" >&2
    exit 1
  fi

  provider=$(toml_get "identity" "provider")
  if [[ -z "$provider" ]]; then
    provider="local"
  fi
  if [[ $provider != "local" ]]; then
    echo "Unsupported identity provider in v1: $provider" >&2
    exit 1
  fi

  if [[ -z "$story_title" || -z "$story_preset" ]]; then
    usage >&2
    exit 1
  fi

  if [[ -z "$epic_id" ]]; then
    epic_id=$(toml_get "defaults" "epic")
    epic_id=${epic_id:-unknown-epic}
  fi
  if [[ -z "$acceptance_mode" ]]; then
    acceptance_mode=$(default_acceptance_for_preset "$story_preset")
  fi
  if [[ -z "$switch_active" ]]; then
    switch_active=$(toml_get "defaults" "switch_active")
    switch_active=${switch_active:-prompt}
  fi
  if [[ -z "$story_slug" ]]; then
    story_slug=$(slugify "$story_title")
  fi
  if [[ -z "$external_ref" ]]; then
    external_ref="none"
  fi
  if [[ -z "$story_id" ]]; then
    prefix=$(toml_get "identity.local" "prefix")
    width=$(toml_get "identity.local" "width")
    prefix=${prefix:-JT}
    width=${width:-4}
    story_id=$(next_local_id "$prefix" "$width")
  fi
  if [[ -z "$story_slug" ]]; then
    story_slug="story-$(printf '%s' "$story_id" | tr '[:upper:]' '[:lower:]')"
  fi
fi

tank_dir="$root_dir/boosters/$story_id"
ensure_story_id_available "$story_id"

if [[ $story_id =~ [[:space:]] ]]; then
  echo "story-id must not contain whitespace" >&2
  exit 1
fi

if [[ ! $switch_active =~ ^(prompt|yes|no)$ ]]; then
  echo "switch-active must be one of: prompt, yes, no" >&2
  exit 1
fi

background_prompts=""
deliverable_prompts=""
done_when_prompts=""
boundary_hint=""

case "$story_preset" in
  feature)
    background_prompts=$'- User or system behavior being changed\n- Primary touched surface: API / UI / job / workflow / data model\n- Verification shape: tests, manual QA, rollout check\n- Compatibility or migration concerns'
    deliverable_prompts=$'- Implementation change\n- Test coverage or verification artifact\n- User- or operator-facing note when needed'
    done_when_prompts=$'- Behavior exists\n- Tests or checks pass\n- Human review confirms expected behavior'
    boundary_hint='Use `feature` when the end state is changed system behavior. If the end state is only a reviewable proposal, prefer `draft`.'
    ;;
  research)
    background_prompts=$'- Concrete question being answered\n- Evidence sources or research surface\n- Expected form of answer: memo / comparison / recommendation / annotated notes\n- Decision dependency, if any'
    deliverable_prompts=$'- Answer to the question\n- Evidence or source trail\n- Recommendation if relevant'
    done_when_prompts=$'- The question is answered clearly enough\n- Evidence is sufficient for human review\n- Open uncertainty is named explicitly'
    boundary_hint='Use `research` when the end state is an answered question. If the end state is a committed choice, prefer `decision`.'
    ;;
  decision)
    background_prompts=$'- Decision to be made\n- Options under consideration\n- Who or what is unblocked by the decision\n- Whether approval or sign-off is needed'
    deliverable_prompts=$'- Decision record\n- Rationale\n- Rejected or deferred options\n- Follow-up constraint or consequence list'
    done_when_prompts=$'- A choice is fixed or a decision-ready recommendation exists\n- Rationale is reviewable\n- Next constraints for future stories are explicit'
    boundary_hint='Use `decision` when the end state is a fixed choice. If the work only answers a question, prefer `research`.'
    ;;
  enablement)
    background_prompts=$'- What future work is blocked today\n- What exactly becomes possible after completion\n- Required access, setup, or environment surface\n- Verification method for readiness'
    deliverable_prompts=$'- Granted access, configured environment, or setup result\n- Runbook or setup note\n- Verification evidence that work is now unblocked'
    done_when_prompts=$'- The blocked next step can now be attempted\n- Setup or access is verifiable\n- The enabling state is documented enough to reuse'
    boundary_hint='Use `enablement` when the main result is that future work becomes possible. If the main result is changed behavior, prefer `feature`.'
    ;;
  draft)
    background_prompts=$'- Artifact being drafted\n- Intended audience or reviewer\n- Expected level of completeness: rough / reviewable / near-final\n- Constraints on tone, scope, or style'
    deliverable_prompts=$'- Draft artifact\n- Optional outline or structural note\n- Editorial constraints if they matter later'
    done_when_prompts=$'- A reviewable draft exists\n- Scope and tone are sufficiently coherent for review\n- Known weak sections are identified if not fixed yet'
    boundary_hint='Use `draft` when the end state is a reviewable first artifact. If the end state is shipped behavior, prefer `feature`.'
    ;;
  validation)
    background_prompts=$'- Hypothesis or configuration being tested\n- Method of validation\n- Output format: benchmark table / result memo / figure / go-no-go note\n- Confidence threshold or decision threshold if known'
    deliverable_prompts=$'- Test or experiment result\n- Measurement summary\n- Interpretation or recommendation'
    done_when_prompts=$'- The test has actually been run or otherwise completed\n- Results are captured in a reviewable form\n- Conclusion about confidence, viability, or next step is explicit'
    boundary_hint='Use `validation` when the main result is confidence gained by testing. If the work mainly answers a question by reading and synthesis, prefer `research`.'
    ;;
  *)
    background_prompts='- Add preset-specific background prompts here'
    deliverable_prompts='- Add preset-specific deliverables here'
    done_when_prompts='- Add preset-specific acceptance conditions here'
    boundary_hint='Preset boundary is unspecified. Confirm that the chosen preset matches the intended completion shape.'
    ;;
esac

render_template() {
  local src=$1
  local dst=$2
  JT_STORY_ID="$story_id" \
  JT_STORY_SLUG="$story_slug" \
  JT_EXTERNAL_REF="$external_ref" \
  JT_STORY_TITLE="$story_title" \
  JT_EPIC_ID="$epic_id" \
  JT_STORY_PRESET="$story_preset" \
  JT_ACCEPTANCE_MODE="$acceptance_mode" \
  JT_CREATED_DATE="$created_date" \
  JT_PRESET_BACKGROUND_PROMPTS="$background_prompts" \
  JT_PRESET_DELIVERABLE_PROMPTS="$deliverable_prompts" \
  JT_PRESET_DONE_WHEN_PROMPTS="$done_when_prompts" \
  JT_PRESET_BOUNDARY_HINT="$boundary_hint" \
  perl -0pe '
    s/\{\{STORY_ID\}\}/$ENV{JT_STORY_ID}/g;
    s/\{\{STORY_SLUG\}\}/$ENV{JT_STORY_SLUG}/g;
    s/\{\{EXTERNAL_REF\}\}/$ENV{JT_EXTERNAL_REF}/g;
    s/\{\{STORY_TITLE\}\}/$ENV{JT_STORY_TITLE}/g;
    s/\{\{EPIC_ID\}\}/$ENV{JT_EPIC_ID}/g;
    s/\{\{STORY_PRESET\}\}/$ENV{JT_STORY_PRESET}/g;
    s/\{\{ACCEPTANCE_MODE\}\}/$ENV{JT_ACCEPTANCE_MODE}/g;
    s/\{\{CREATED_DATE\}\}/$ENV{JT_CREATED_DATE}/g;
    s/\{\{PRESET_BACKGROUND_PROMPTS\}\}/$ENV{JT_PRESET_BACKGROUND_PROMPTS}/g;
    s/\{\{PRESET_DELIVERABLE_PROMPTS\}\}/$ENV{JT_PRESET_DELIVERABLE_PROMPTS}/g;
    s/\{\{PRESET_DONE_WHEN_PROMPTS\}\}/$ENV{JT_PRESET_DONE_WHEN_PROMPTS}/g;
    s/\{\{PRESET_BOUNDARY_HINT\}\}/$ENV{JT_PRESET_BOUNDARY_HINT}/g;
  ' "$src" > "$dst"
}

if [[ $dry_run -eq 1 ]]; then
  echo "[dry-run] would create: $tank_dir"
  printf '%s\n' \
    "[dry-run] canonical-id: $story_id" \
    "[dry-run] slug: $story_slug" \
    "[dry-run] external-ref: $external_ref" \
    "[dry-run] preset: $story_preset" \
    "[dry-run] acceptance: $acceptance_mode" \
    "[dry-run] would render: story.md"
  if [[ $switch_active == "prompt" ]]; then
    echo "[dry-run] would ask whether to switch the active booster"
  else
    echo "[dry-run] switch-active behavior: $switch_active"
  fi
  exit 0
fi

mkdir -p "$tank_dir"
render_template "$template_dir/story.md" "$tank_dir/story.md"

echo "Created booster: $tank_dir"
echo "Canonical ID: $story_id"
echo "Slug: $story_slug"
echo "External Ref: $external_ref"

switch_message() {
  local answer=$1
  case "$answer" in
    yes)
      echo "Active booster switch acknowledged for this session only. No durable state was written."
      ;;
    no)
      echo "Active booster unchanged."
      ;;
  esac
}

if [[ $switch_active == "yes" ]]; then
  switch_message yes
elif [[ $switch_active == "prompt" && -t 0 ]]; then
  printf "Switch active booster to %s? [y/N] " "$story_id" >&2
  read -r reply
  case "$reply" in
    [yY]|[yY][eE][sS]) switch_message yes ;;
    *) switch_message no ;;
  esac
else
  switch_message no
fi

echo "Required next step: review and refine story.md before moving the booster into the ready phase."
