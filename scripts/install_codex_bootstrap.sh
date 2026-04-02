#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  bash scripts/install_codex_bootstrap.sh install <target-repo> [--with-config]
  bash scripts/install_codex_bootstrap.sh update <target-repo> [--with-config]
  bash scripts/install_codex_bootstrap.sh uninstall <target-repo>

Installs the Codex-first Jettisonize bootstrap into an existing target repo using
repo-local canonical assets from this Jettisonize source repo.
USAGE
}

if [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage >&2
  exit 1
fi

command_name=$1
target_repo=$2
shift 2

include_config=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --with-config)
      include_config=1
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$command_name" in
  install|update|uninstall)
    ;;
  *)
    echo "Unknown command: $command_name" >&2
    usage >&2
    exit 1
    ;;
esac

source_root=$(cd "$(dirname "$0")/.." && pwd)
target_repo=$(cd "$target_repo" && pwd)

if [[ ! -d "$target_repo/.git" ]]; then
  echo "Target repo must already exist and contain .git: $target_repo" >&2
  exit 1
fi

begin_marker="<!-- BEGIN JETTISON MANAGED BLOCK -->"
end_marker="<!-- END JETTISON MANAGED BLOCK -->"
agents_template="$source_root/templates/bootstrap/AGENTS.md"
target_agents="$target_repo/AGENTS.md"
tmp_dir=""

cleanup() {
  if [[ -n "$tmp_dir" && -d "$tmp_dir" ]]; then
    rm -rf "$tmp_dir"
  fi
}

trap cleanup EXIT

managed_files=(
  "status-rules.md"
  "skills/jettison-fuel/SKILL.md"
  "skills/jettison-ready/SKILL.md"
  "skills/jettison-hydrate/SKILL.md"
  "skills/jettison/SKILL.md"
  "templates/booster/story.md"
  "templates/booster/spec.md"
  "templates/booster/plan.md"
  "templates/booster/status.md"
  "scripts/fuel_booster.sh"
  "scripts/ready_booster.sh"
  "scripts/hydrate_booster.sh"
  "scripts/jettison_booster.sh"
  "scripts/update_status.sh"
)

if [[ $include_config -eq 1 ]]; then
  managed_files+=(".jettison.toml")
fi

refuse() {
  echo "$1" >&2
  exit 1
}

has_managed_block() {
  [[ -f "$target_agents" ]] || return 1
  grep -Fq "$begin_marker" "$target_agents" && grep -Fq "$end_marker" "$target_agents"
}

render_managed_block() {
  {
    printf '%s\n' "$begin_marker"
    printf '%s\n' "<!-- Managed by scripts/install_codex_bootstrap.sh. Edit outside this block. -->"
    printf '%s\n' "<!-- Bootstrap source: https://github.com/ktrmnm/jettisonize -->"
    cat "$agents_template"
    printf '%s\n' "$end_marker"
  }
}

write_agents_when_absent() {
  render_managed_block > "$target_agents"
}

replace_managed_block() {
  tmp_dir=${tmp_dir:-$(mktemp -d)}
  local rendered_block="$tmp_dir/managed-block.md"
  local updated_agents="$tmp_dir/AGENTS.md"
  render_managed_block > "$rendered_block"
  awk -v begin="$begin_marker" -v end="$end_marker" -v replacement="$rendered_block" '
    {
      if ($0 == begin) {
        in_block=1
        while ((getline line < replacement) > 0) {
          print line
        }
        close(replacement)
        next
      }
      if (in_block) {
        if ($0 == end) {
          in_block=0
        }
        next
      }
      print
    }
  ' "$target_agents" > "$updated_agents"
  mv "$updated_agents" "$target_agents"
}

remove_managed_block() {
  tmp_dir=${tmp_dir:-$(mktemp -d)}
  local updated_agents="$tmp_dir/AGENTS.md"
  awk -v begin="$begin_marker" -v end="$end_marker" '
    {
      if ($0 == begin) {
        in_block=1
        next
      }
      if (in_block) {
        if ($0 == end) {
          in_block=0
        }
        next
      }
      print
    }
  ' "$target_agents" > "$updated_agents"

  if [[ -s "$updated_agents" ]]; then
    mv "$updated_agents" "$target_agents"
  else
    rm -f "$target_agents"
  fi
}

copy_managed_files() {
  local relative_path source_path target_path
  for relative_path in "${managed_files[@]}"; do
    source_path="$source_root/$relative_path"
    target_path="$target_repo/$relative_path"
    mkdir -p "$(dirname "$target_path")"
    cp "$source_path" "$target_path"
  done
}

remove_managed_files() {
  local relative_path target_path parent_dir
  for relative_path in "${managed_files[@]}"; do
    target_path="$target_repo/$relative_path"
    rm -f "$target_path"
    parent_dir=$(dirname "$target_path")
    while [[ "$parent_dir" != "$target_repo" ]]; do
      rmdir "$parent_dir" 2>/dev/null || break
      parent_dir=$(dirname "$parent_dir")
    done
  done
}

find_conflicting_paths() {
  local relative_path
  for relative_path in "${managed_files[@]}"; do
    if [[ -e "$target_repo/$relative_path" ]]; then
      printf '%s\n' "$relative_path"
      return 0
    fi
  done
  return 1
}

ensure_installable() {
  local conflicting_path
  if has_managed_block; then
    return 0
  fi
  if [[ -f "$target_agents" ]]; then
    refuse "Refusing install: target AGENTS.md exists without managed block markers. Add the managed block manually or move existing guidance outside the block."
  fi
  conflicting_path=$(find_conflicting_paths || true)
  if [[ -n "$conflicting_path" ]]; then
    refuse "Refusing install: target path already exists without a managed installation: $conflicting_path"
  fi
}

ensure_updatable() {
  has_managed_block || refuse "Refusing update: target AGENTS.md does not contain the managed block markers."
}

ensure_uninstallable() {
  has_managed_block || refuse "Refusing uninstall: target AGENTS.md does not contain the managed block markers."
}

case "$command_name" in
  install)
    ensure_installable
    if has_managed_block; then
      replace_managed_block
    else
      write_agents_when_absent
    fi
    copy_managed_files
    ;;
  update)
    ensure_updatable
    replace_managed_block
    copy_managed_files
    ;;
  uninstall)
    ensure_uninstallable
    remove_managed_block
    remove_managed_files
    ;;
esac

echo "Completed $command_name for Codex-first bootstrap in $target_repo"
