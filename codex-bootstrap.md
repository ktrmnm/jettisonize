# Codex Bootstrap

## Scope

This document describes the operator-facing Codex-first bootstrap path for Jettisonize.

The public contract of this bootstrap path is:

- repo-local canonical assets
- managed-block `AGENTS.md`
- no automatic `~/.codex/config.toml` mutation
- no plugin packaging requirement

## Command Surface

Run the installer from a checked-out `ktrmnm/jettisonize` source repo against an existing git repo.

```bash
bash scripts/install_codex_bootstrap.sh install /path/to/target-repo
bash scripts/install_codex_bootstrap.sh update /path/to/target-repo
bash scripts/install_codex_bootstrap.sh uninstall /path/to/target-repo
```

Optional config install:

```bash
bash scripts/install_codex_bootstrap.sh install /path/to/target-repo --with-config
```

By default, `.jettison.toml` is not installed. Use `--with-config` if you want the shipped example config in the target repo.

## Remote Instruction Path

If the operator starts inside a target repo and wants the flow to feel local, Codex can follow a remote install instruction such as:

`https://raw.githubusercontent.com/ktrmnm/jettisonize/refs/heads/main/.codex/INSTALL.md`

The intended behavior is:

1. remember the current repo as the target repo
2. clone the `ktrmnm/jettisonize` source repo into `/tmp` or another disposable location
3. run the installer from that temporary clone against the target repo
4. return to the target repo

This does not change installer authority. The durable result still lives only in the target repo, and the temporary clone is disposable source state.

## Managed `AGENTS.md` Semantics

The installer owns only a marked region inside root `AGENTS.md`.

Markers:

```html
<!-- BEGIN JETTISON MANAGED BLOCK -->
<!-- END JETTISON MANAGED BLOCK -->
```

Rules:

- If `AGENTS.md` is absent, install creates it with the managed block.
- If `AGENTS.md` already has the managed block, install is safe to rerun and behaves like update for that block.
- If `AGENTS.md` exists without the managed block, install refuses and asks for manual adoption.
- Update requires the managed block and rewrites only that block.
- Uninstall removes only the managed block. If nothing remains in `AGENTS.md`, the file is removed.

## Canonical Asset Semantics

The installer manages these repo-local assets:

- `AGENTS.md`
- `skills/jettison-fuel/SKILL.md`
- `skills/jettison-ready/SKILL.md`
- `skills/jettison-hydrate/SKILL.md`
- `skills/jettison/SKILL.md`
- `templates/booster/story.md`
- `templates/booster/spec.md`
- `templates/booster/plan.md`
- `templates/booster/status.md`
- `scripts/fuel_booster.sh`
- `scripts/ready_booster.sh`
- `scripts/hydrate_booster.sh`
- `scripts/jettison_booster.sh`
- optional `.jettison.toml`

Rules:

- First install refuses if a managed target path already exists before Jettisonize is installed.
- After a managed install exists, update rewrites the managed files from the source repo.
- Uninstall removes only the known Jettisonize-managed paths and leaves unrelated files untouched.

## Prerequisites

- The target directory already exists and is a git repo.
- Codex can discover repo-root `AGENTS.md` and repo-local `skills/`.
- The operator runs the installer from a checked-out `ktrmnm/jettisonize` source repo.

## Rollback Expectation

- If install refuses, no partial overwrite should occur.
- If uninstall succeeds, the managed block and known Jettisonize-managed files are removed.
- The installer does not mutate user-global Codex configuration, so rollback stays repo-local.
