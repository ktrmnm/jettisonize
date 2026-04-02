---
name: jettison-ready
description: Use when a reviewed Jettisonize story draft is ready to enter execution and the booster needs the canonical execution bundle.
---

# `ready`

Use this skill after a human has reviewed `story.md` and the story is ready to enter execution.

## Workflow

1. Read `AGENTS.md` if you have not already done so in the current task.
2. Confirm that `story.md` is reviewed and includes deliverables, `done when`, guardrails, preset, and acceptance mode.
3. Use the canonical repo-root ready surface:
   - `bash scripts/ready_booster.sh <story-id>`
4. Refine the generated `spec.md`, `plan.md`, and `status.md`.
5. Add support files only when the story actually needs them; do not treat any extra filename as a default part of `ready`.
6. Do not treat template text as finished content; replace placeholders before execution starts.

Current language boundary:

- `documents.language` is a preference for agent-authored drafts, not a template-localization switch.
- `ready_booster.sh` still renders the canonical repo-root templates as-is.
- When you draft or refine `spec.md`, `plan.md`, or `status.md` for review, prefer the configured draft language unless the user explicitly chooses otherwise.

## Asset Boundary

- `scripts/ready_booster.sh` is the canonical repo-root executable surface.
- `templates/booster/spec.md`, `templates/booster/plan.md`, and `templates/booster/status.md` are canonical repo-root templates.
- This `SKILL.md` owns the workflow for when and how to use those assets.

## Required Input

- story ID

## Do Not

- create ready-phase execution files before story review
- overwrite an existing execution bundle silently
- start implementation from placeholder templates
- treat skill-private notes as authoritative in place of the repo-root templates
