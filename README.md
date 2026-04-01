# Jettisonize

<p align="left">
  <img src="./.github/assets/jettisonize-logo-horizontal.png" alt="Jettisonize" width="960">
</p>

Jettisonize is a development method for AI-agent work that keeps story-scoped context disposable.

It is designed for teams that want to keep durable project memory small, explicit, and intentional instead of letting working context accumulate by default.

## Why

AI-agent work often breaks down because too much temporary context stays alive for too long: long sessions, local notes, partial plans, and residue that no longer changes anything.

Jettisonize addresses that problem by treating story-local context as short-lived support for one bounded move. Keep what must survive. Jettison the rest.

## Core Loop

1. `fuel`: define a bounded story with explicit deliverables, `done when`, and guardrails
2. `ready`: expand the accepted story into an execution bundle
3. `propel`: do the work and keep the handoff state current
4. `jettison`: promote durable outcomes, then retire the local bundle

A story normally works through a small handoff bundle:

- `story.md`
- `spec.md`
- `plan.md`
- `status.md`

## Start Here

- Read [`manifesto.md`](./manifesto.md) for the method thesis and operating model.
- Read [`AGENTS.md`](./AGENTS.md) for the durable operating rules.
- Read [`status-rules.md`](./status-rules.md) for the durable rules for updating `status.md`.
- Read [`docs/codex.md`](./docs/codex.md) for the shortest Codex install entrypoint.
- Read [`codex-bootstrap.md`](./codex-bootstrap.md) for the operator-facing bootstrap contract.

## Install For Codex

For the shortest install path, follow [`/.codex/INSTALL.md`](./.codex/INSTALL.md).

The installer uses a temporary clone of `ktrmnm/jettisonize` and applies the bootstrap assets to your current repository.

If you want the optional example config as well, use the `--with-config` install path described in [`codex-bootstrap.md`](./codex-bootstrap.md).

## Example Config

Jettisonize can also ship an optional root `.jettison.toml` with small v1 defaults:

- `defaults.epic`
- `defaults.switch_active`
- `documents.language`
- `identity.provider`
- `identity.local.prefix`
- `identity.local.width`

The config surface stays intentionally small. Story-level values such as acceptance mode, slug, and external reference remain per-story input rather than repo-wide defaults.
