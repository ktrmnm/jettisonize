---
name: jettison
description: Use when a Jettison booster has reached done state and needs final checks, close notes, optional upstream unblock updates, and archive-first retirement.
---

# Jettison

Use this skill when a booster is ready to be closed under the Jettison lifecycle.

## Workflow

1. Read `AGENTS.md` if you have not already done so in the current task.
2. Read the booster documents, especially `story.md` and `status.md`.
3. Confirm that the booster is actually ready to retire.
   - `Propel Status` must already be `done`.
   - `Booster Lifecycle` should already be `propel` or `jettison`.
   - the story's declared deliverables and `done when` must be satisfied
   - acceptance evidence must exist
   - durable findings must already be promoted to the persistent layer
4. Gather the explicit close notes that must survive retirement.
   - acceptance evidence note
   - durable promotion note
   - intentionally discarded context note
   - optional upstream unblock note for another booster's `status.md`
5. Use the canonical repo-root jettison surface:
   - `bash scripts/jettison_booster.sh <story-id> --acceptance-note "<note>" --promoted "<note>" --discarded "<note>"`
   - If another active booster was blocked by this one, also pass `--upstream-status <story-id> --unblock-note "<next step after unblock>"`
6. Verify that the booster now lives under `archive/boosters/<story-id>/` and that the archived `status.md` shows `Propel Status: closed` and `Booster Lifecycle: jettison`.

## Asset Boundary

- `scripts/jettison_booster.sh` is the canonical repo-root executable surface.
- archived boosters under `archive/boosters/` are the canonical closed-story record.
- This `SKILL.md` defines the operator workflow and refusal conditions for invoking the repo-root close surface.

## Required Input

- story ID
- acceptance evidence note
- durable promotion note
- discarded context note

## Output Contract

A successful run should make the following explicit:

- why the story was accepted
- what durable findings were promoted before close
- what was intentionally discarded
- whether an upstream booster was unblocked
- where the archived booster now lives

## Do Not

- close a booster that is not already in `Propel Status: done`
- treat `jettison` as a generic cleanup command
- silently infer acceptance evidence or durable promotion that was never recorded
- hard-delete boosters in v1
- move close semantics into a skill-private file that disagrees with the repo-root script or durable rules
