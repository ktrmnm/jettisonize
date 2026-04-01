# Jettison Operating Rules

This repository uses the Jettison method.

Jettison treats story-scoped working context as disposable. Durable project memory must stay small, explicit, and intentional.

## Core Rules

- Every substantial story gets a booster under `boosters/<story-id>/`.
- A new booster starts with `story.md` only.
- `spec.md`, `plan.md`, `status.md`, and optional support files are added only after the story draft has been reviewed and accepted for execution.
- A booster may include `notes.md` or `artifacts/` when the story needs them.
- A booster contains only handoff-critical documents.
- Temporary working files, scratch notebooks, one-off exports, and exploratory artifacts do not need to live in the booster.
- If temporary files matter for recovery or traceability, record their paths in `status.md` or another story-local support file.
- No story begins without explicit deliverables, `done when`, and guardrails.
- No story is complete until it changes project state or stakeholder decisions.
- No booster survives by default after acceptance. Promote durable knowledge first, then archive or delete the booster.
- Durable outputs must not depend on booster-local assets by reference. Boosters may point outward to durable docs, but durable docs must remain valid after the booster is archived or deleted.

## Document Roles

`story.md`
- problem statement, deliverables, `done when`, guardrails
- draft review surface before execution begins

`spec.md`
- local constraints, interfaces, acceptance notes, non-goals

`plan.md`
- ordered steps, dependencies, verification approach

`status.md`
- dated progress notes, decisions, blockers, next action, checkpoint
- includes `Propel Status`, the review / execution readiness state for the story
- includes `Booster Lifecycle`, the lifecycle state for the booster
- `Checkpoint` stays distinct from `Current State`
- `Log` is reverse chronological: newest entries are added at the top
- each `Log` entry should use a short dated heading plus structured `Decision`, `Findings`, `Blockers`, and `Next action` lines

## State Model

Jettison v1 uses a 2-layer visible state model.

- `Propel Status` lives in `status.md` and describes review / execution readiness
- `Booster Lifecycle` lives in `status.md` and describes where the booster is in the lifecycle

### Allowed `Propel Status` values

- `draft`
- `story-reviewed`
- `plan-draft`
- `plan-reviewed`
- `done`
- `closed`

### Allowed `Booster Lifecycle` values

- `fuel`
- `ready`
- `propel`
- `jettison`

## Asset Boundary

- `AGENTS.md` holds repo-global durable operating rules only.
- repo-root durable docs and canonical assets define the reviewed contract for this repository.
- `skills/` holds operator workflow and skill-private supporting context.

Canonical repo-root assets in this repo include:

- `templates/booster/`
- `scripts/`
- durable decision records and method docs in the repo root

## Context Discipline

- Keep global rules in `AGENTS.md` or other durable docs.
- Keep story-local execution context in the booster.
- Keep the booster minimal. Prefer the core handoff bundle over ad hoc parallel documents.
- Temporary files may live outside the booster. The booster should point to them, not necessarily contain them.
- If a work product becomes broadly reusable or durable, promote it out of the booster into the persistent layer.
- When promoting a durable output, rewrite any booster-local dependency into durable form before promotion. A durable doc must not require `boosters/<story-id>/...` to stay interpretable.
- Do not turn `AGENTS.md` into a backlog or diary.
- Do not turn boosters into long-lived project memory.
