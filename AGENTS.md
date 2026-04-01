# Jettison Operating Rules

## Purpose

This repository develops and documents the Jettison method.

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

## Story Eligibility

A story is valid only if all of the following are true.

- It has clear background and purpose.
- It defines concrete deliverables.
- It defines `done when` in a way that a human or audit rule can evaluate.
- Completion changes implementation, understanding, or stakeholder decisions.
- The story is expected to complete within two weeks.

If these conditions are not met, split the work or redefine the story before fueling it.

## Booster Lifecycle

### 1. Fuel

Create a story-first booster draft from the template.

Required fields:

- story ID
- title
- epic linkage or epic label
- story preset
- acceptance mode
- deliverables
- `done when`
- guardrails

At this stage, create `story.md` only. Human review happens before execution documents exist.

### 2. Ready

After the story draft is reviewed and accepted, expand the booster into an execution bundle.

Ready normally creates:

- `spec.md`
- `plan.md`
- `status.md`

`ready` creates the execution bundle, but it does not imply that `spec.md` or `plan.md` have been human-reviewed. In v1, `ready` should normally move the story into `Propel Status: plan-draft`.

### 3. Propel

Work happens inside the booster.

During active work:

- update `status.md` at every meaningful decision boundary
- keep `plan.md` aligned with current intent
- move stable conclusions into durable project docs when they stop being story-local
- if an active booster fuels a second booster that blocks its next propel step, record that dependency in the first booster's `status.md` and name the immediate task that should resume after the blocker is closed
- when the blocking booster is closed, append that closure fact to the blocked booster's `status.md`; do not reconstruct the resumed task at close time

### 4. Jettison

Before retirement:

- confirm the declared deliverables exist
- confirm acceptance evidence exists
- copy durable findings to the persistent layer
- record what was intentionally discarded
- if the booster was blocking another booster, append the unblock note to the parent booster's `status.md`
- archive the booster by default in this repo

Default policy in this repo: archive completed boosters before considering deletion.

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
- if another booster is acting as a blocker, the dependency, the future resumed task, and the later unblock note belong here
- includes `Propel Status`, the review / execution readiness state for the story
- includes `Booster Lifecycle`, the lifecycle state for the booster
- `Checkpoint` is the fixed restart-summary section and stays distinct from `Current State`
- `Log` is reverse chronological: newest entries are added at the top
- each `Log` entry should use a short dated heading plus structured `Decision`, `Findings`, `Blockers`, and `Next action` lines
- use [`status-rules.md`](./status-rules.md) and [`scripts/update_status.sh`](./scripts/update_status.sh) as the canonical update surface

## State Model

Jettison v1 uses a 2-layer visible state model.

- `Propel Status` lives in `status.md` and describes review / execution readiness
- `Booster Lifecycle` lives in `status.md` and describes where the booster is in the lifecycle

Both are part of `status.md` because both are current state that changes over time. `story.md` should remain closer to a stable story statement.

### Allowed `Propel Status` values

- `draft`
- `story-reviewed`
- `plan-draft`
- `plan-reviewed`
- `done`
- `closed`

Meaning:

- `draft`: `fuel` completed; `story.md` exists but has not been human-reviewed
- `story-reviewed`: `story.md` is accepted and the booster may enter `ready`
- `plan-draft`: `ready` completed; execution bundle exists but `spec.md` / `plan.md` are still being drafted or refined
- `plan-reviewed`: `spec.md` / `plan.md` are reviewed enough for `propel`
- `done`: deliverables and `done when` are satisfied; the booster is ready for jettison checks
- `closed`: jettison is complete

### Allowed `Booster Lifecycle` values

- `fuel`
- `ready`
- `propel`
- `jettison`

Meaning:

- `fuel`: story-first drafting and review preparation
- `ready`: execution bundle exists and the booster is being prepared for execution
- `propel`: execution is underway
- `jettison`: close, acceptance finalization, archive, and upstream handoff

### Transition Guidance

- After `fuel`, set `Propel Status` to `draft`
- After human story review accepts the story, set `Propel Status` to `story-reviewed`
- After `ready`, set `Booster Lifecycle` to `ready` and `Propel Status` to `plan-draft`
- After human review accepts `spec.md` / `plan.md`, set `Propel Status` to `plan-reviewed`
- When execution actually starts, set `Booster Lifecycle` to `propel`
- When deliverables and `done when` are satisfied, set `Propel Status` to `done`
- When jettison begins, set `Booster Lifecycle` to `jettison`
- When jettison completes, set `Propel Status` to `closed`

Close semantics:

- Before close: `Propel Status = done`, `Booster Lifecycle = jettison`
- After close: `Propel Status = closed`, `Booster Lifecycle = jettison`

## Skill Boundary

Durable rules define allowed values, meanings, and preferred transitions.

Helper skills should guide actual transitions by:

- reading the current booster state
- checking whether prerequisites are met
- proposing the next valid `Propel Status` or `Booster Lifecycle`
- eventually helping with `spec` / `plan` draft generation and jettison checks

The rules should remain understandable without the skills, but the skills are expected to make real transitions safer and more consistent.

## Asset Boundary

Jettison v1 uses a 3-layer responsibility split.

- `AGENTS.md` holds repo-global durable operating rules only.
- repo-root durable docs and canonical assets define the reviewed contract for this repository.
- `skills/` holds operator workflow and skill-private supporting context.

Canonical repo-root assets in this repo include:

- `templates/booster/`
- `scripts/`
- `.github/assets/` for GitHub-facing branding assets referenced by the public repo surface
- durable decision records and method docs in the repo root

These assets are authoritative for repo behavior and should remain discoverable without reading skill internals first.

`skills/` may contain:

- step-by-step workflow
- refusal conditions
- required inputs
- skill-private examples or supporting files

Do not duplicate the same canonical contract across repo-root assets and skill-private files. If a rule or asset is repo-authoritative, keep that authority in the durable layer and let skills point to it.

story-local support files
- optional additions such as `notes.md` or `artifacts/` when the story needs extra handoff-critical context
- if restart, rollback, or temporary-path details matter, record them explicitly without making a repo-wide canonical filename mandatory

## Handoff Rule

A fresh agent should be able to resume a story from the booster alone. If the booster is still in draft mode, `story.md` must be sufficient to review scope and acceptance. If the booster is in execution mode, the execution bundle must be sufficient to continue work. If resumption requires hidden conversational history, the booster is incomplete.

## Context Discipline

- Keep global rules in `AGENTS.md` or other durable docs.
- Keep story-local execution context in the booster.
- Keep the booster minimal. Prefer the core handoff bundle over ad hoc parallel documents.
- Temporary files may live outside the booster. The booster should point to them, not necessarily contain them.
- If a work product becomes broadly reusable or durable, promote it out of the booster into the persistent layer.
- When promoting a durable output, rewrite any booster-local dependency into durable form before promotion. A durable doc must not require `boosters/<story-id>/...` to stay interpretable.
- Do not turn `AGENTS.md` into a backlog or diary.
- Do not turn boosters into long-lived project memory.

## Skills

The first skills for this repo are:

- `jettison-fuel`
- `jettison-ready`
- `jettison-hydrate`
- `jettison`

Use them as the default way to start or resume a story once the repo contains active boosters.

Their workflows live in `skills/`, while the canonical scripts and templates they invoke live under `scripts/` and `templates/booster/`.
