---
name: jettison-hydrate
description: Use when resuming or handing off an existing Jettisonize story booster so a fresh agent can reconstruct the story from the booster alone.
---

# `hydrate`

Use this skill when work needs to resume on an existing booster or when a new agent is taking over.

## Workflow

1. Read `AGENTS.md` if you have not already done so in the current task.
2. Use the canonical repo-root hydrate surface:
   - `bash scripts/hydrate_booster.sh <story-id>`
   - the hydrate script should read the `Checkpoint` section from `status.md`; legacy `Latest Checkpoint` wording is fallback-only for older boosters
3. If the summary is still ambiguous, read the full booster files in this order:
   - `story.md`
   - `spec.md` if present
   - `plan.md` if present
   - `status.md` if present
4. Restate the active objective, unfinished work, blockers, and non-negotiable guardrails before proceeding.
5. If the booster is still story-first, treat `story.md` as a review artifact rather than an execution bundle.
6. If resumption still depends on hidden conversational history, treat the booster as incomplete and update it before further execution.

## Asset Boundary

- `scripts/hydrate_booster.sh` is the canonical repo-root executable surface.
- The booster files under `boosters/<story-id>/` are the canonical story-local handoff surface.
- This `SKILL.md` defines how to reconstruct context from those repo-root and booster-local artifacts.

## Required Input

- story ID

## Output Contract

A successful hydration should make the following explicit:

- what the story is trying to change
- what counts as done
- what constraints cannot be violated
- what the next action is
- whether the booster is still in draft mode or ready for execution

## Do Not

- skip `status.md`
- assume old conversation context is authoritative if the booster disagrees
- continue execution when `done when` or guardrails are missing
- invent a parallel hydration contract inside `skills/`
