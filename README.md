# Jettisonize

<p align="left">
  <img src="./.github/assets/jettisonize-logo-horizontal.png" alt="Jettisonize" width="960">
</p>

Jettisonize is a development method for AI-agent work that keeps story-scoped context disposable.

The method uses a short lifecycle:

1. `fuel`: define a bounded story with explicit deliverables, `done when`, and guardrails
2. `ready`: expand the accepted story into an execution bundle
3. `propel`: do the work inside that bundle until project state changes
4. `jettison`: promote durable outcomes, then retire the local bundle

The goal is simple: preserve what must survive, and discard the rest before it turns into project memory you have to carry forever.

## Start Here

- Read [`manifesto.md`](./manifesto.md) for the method thesis and operating model.
- Read [`AGENTS.md`](./AGENTS.md) for the durable repo rules.
- Read [`codex-bootstrap.md`](./codex-bootstrap.md) if you want the operator-facing install contract.
- Read [`docs/codex.md`](./docs/codex.md) for the shortest Codex install entrypoint.
- Read [`status-rules.md`](./status-rules.md) if you want the durable rules for updating `status.md`.

## Install For Codex

Fetch and follow:

`https://raw.githubusercontent.com/ktrmnm/jettisonize/refs/heads/main/.codex/INSTALL.md`

The install flow uses a temporary clone of `ktrmnm/jettisonize`, then runs the repo-local installer against your current repository.

If you want the optional example config as well, use the `--with-config` install path described in [`codex-bootstrap.md`](./codex-bootstrap.md).

## Public Surface

The first public release treats these as the main entrypoints:

- `README.md`
- `manifesto.md`
- `AGENTS.md`
- `codex-bootstrap.md`
- `docs/codex.md`
- `status-rules.md`
- `templates/booster/`
- `scripts/`
- `skills/`
- optional `.jettison.toml`

This repo also contains source records, research summaries, archived boosters, and working material used to develop the method itself. Those files may still be useful, but they are not the first-use public onboarding path.

## What Ships As Durable Method Contract

- story-first boosters under `boosters/<story-id>/`
- the execution bundle shape: `story.md`, `spec.md`, `plan.md`, `status.md`
- repo-authoritative templates under `templates/booster/`
- operator workflow scripts under `scripts/`
- repo-local skills under `skills/`
- explicit lifecycle and acceptance rules in `AGENTS.md`

## Example Config

Jettisonize can also ship an optional root `.jettison.toml` with small v1 defaults:

- `defaults.epic`
- `defaults.switch_active`
- `documents.language`
- `identity.provider`
- `identity.local.prefix`
- `identity.local.width`

The config surface stays intentionally small. Story-level values such as acceptance mode, slug, and external reference remain per-story input rather than repo-wide defaults.
