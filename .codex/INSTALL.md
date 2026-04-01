# Install Jettisonize For Codex

Install the Codex-first Jettisonize bootstrap into the current repo by using a temporary clone of `ktrmnm/jettisonize`.

## Prerequisites

- Git
- A target repo that already exists and has `.git/`

## Steps

1. Remember the current repo path as the target repo.
2. Clone `https://github.com/ktrmnm/jettisonize.git` into a temporary directory under `/tmp`.
3. Change into that temporary clone.
4. Run:

```bash
bash scripts/install_codex_bootstrap.sh install <target-repo>
```

5. Return to the target repo.

Optional config install:

```bash
bash scripts/install_codex_bootstrap.sh install <target-repo> --with-config
```

## Important Rules

- Do not edit `~/.codex/config.toml`.
- Do not install Claude Code or Cursor-specific assets.
- If the target repo already has `AGENTS.md` without Jettison-managed markers, stop and report the refusal instead of forcing a merge.
- Treat `/tmp` as disposable source state. The durable result belongs only in the target repo.

## Update

Repeat the same flow, but run:

```bash
bash scripts/install_codex_bootstrap.sh update <target-repo>
```

## Uninstall

Repeat the same flow, but run:

```bash
bash scripts/install_codex_bootstrap.sh uninstall <target-repo>
```
