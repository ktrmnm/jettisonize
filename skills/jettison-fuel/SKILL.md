---
name: jettison-fuel
description: Use when working in this repository to start a new Jettisonize story-first booster draft from the standard template and ensure the story declares deliverables, done when, and guardrails before execution planning begins.
---

# `fuel`

Use this skill when a new story needs to be started under the Jettisonize method.

## Workflow

1. Read `AGENTS.md` if you have not already done so in the current task.
2. Confirm that the story has, at minimum, a story ID, title, preset, acceptance mode, deliverables, `done when`, and guardrails.
3. Use the canonical repo-root fuel surface:
   - `bash scripts/fuel_booster.sh --title "<story-title>" --preset <story-preset> [--acceptance <mode>] [--epic <epic-id>] [--slug <slug>]`
   - Legacy positional mode remains available for existing boosters, but prefer the flag-based interface.
4. Fill `story.md` with concrete values. Do not generate `spec.md`, `plan.md`, or `status.md` yet.
5. Hand the story draft to a human for review.
6. Refuse to begin execution work until the reviewed `story.md` contains explicit deliverables, `done when`, and guardrails.

## Asset Boundary

- `scripts/fuel_booster.sh` is the canonical repo-root executable surface.
- `templates/booster/story.md` is the canonical repo-root story template.
- This `SKILL.md` defines workflow and operator guidance, not the canonical booster contract.

## Required Inputs

- story ID
- story title
- story preset
- acceptance mode
- deliverables
- `done when`
- guardrails

## Defaults

- If epic linkage is unknown, use a provisional epic label and flag it in `story.md`.
- If no story ID is supplied, let `fuel_booster.sh` generate a local canonical ID from `.jettison.toml`.
- In v1, `.jettison.toml` is only for default epic, active-booster switch behavior, agent-authored draft language, and local ID generation.
- Acceptance mode comes from the selected preset unless `--acceptance` overrides it on that story.
- Treat `slug` as human-readable metadata, not the canonical identity.
- Treat `slug` and `external_ref` as per-story metadata, not config defaults.
- In v1, external issue or ticket references are optional metadata only.
- Keep the initial booster small. Split the story if it is clearly larger than a two-week unit.
- Story-first means the review artifact is `story.md` only.
- If `.jettison.toml` defines `documents.language`, treat it as the preferred language when you draft or refine story content for human review. Do not multiply repo-root templates by language just to satisfy that preference.

## Do Not

- create a booster for vague brainstorming with no deliverable
- invent `done when` silently
- generate execution documents before human story review
- assume active booster state is durably persisted by the script
- treat the booster as a permanent project document
- copy the canonical story template into `skills/` as a second authority
