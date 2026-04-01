# Status Rules

## Purpose

This document defines the durable update surface for `status.md`.

The goal is not to turn `status.md` into a diary. The goal is to make progress updates short, scan-friendly, and consistent enough that a fresh agent can reconstruct current intent quickly.

## Section Roles

`status.md` has three different layers:

### `Current State`

`Current State` is the current operating header.

It should contain only the current, overwrite-in-place fields:

- `Propel Status`
- `Booster Lifecycle`
- `Owner`
- `Next action`

Use this section for the latest current value, not for history.

### `Checkpoint`

`Checkpoint` is the fixed restart summary.

It should stay compact and overwrite in place. In v1 it carries:

- `Done-when focus`
- `Unfinished work`
- `Blockers`
- `Pending decisions`
- `Scope / guardrail check`

Use this section to help a fresh agent restart safely without reading the whole log first.

### `Log`

`Log` is the reverse-chronological history of meaningful decision boundaries.

New entries are added at the top. Older entries stay below.

## Log Entry Schema

Each log entry should use this shape:

```md
### YYYY-MM-DD - Short label

- Decision: ...
- Findings: ...
- Findings: ...
- Blockers: ...
- Next action: ...
```

Rules:

- the heading is date plus a short factual label
- `Decision:` is optional and may appear more than once
- `Findings:` is optional and may appear more than once
- `Blockers:` appears exactly once
- `Next action:` appears exactly once
- keep entries terse enough to scan quickly

Do not turn the log into:

- a transcript
- long narrative prose
- repeated copies of current state
- speculative design dumping unrelated to the immediate story boundary

## Update Rules

When a meaningful boundary happens:

1. update `Current State` if its current values changed
2. update `Checkpoint` if the restart summary changed
3. append one structured log entry under `Log`

Typical examples:

- human review accepted a plan
- implementation direction changed
- a blocker appeared or was cleared
- the next action materially changed
- acceptance evidence was recorded

## Helper Surface

The canonical helper is:

```bash
bash scripts/update_status.sh <story-id> --label "<short label>" --next-action "<next action>"
```

The helper:

- appends one reverse-chronological log entry
- updates `Current State` fields only when explicit flags are provided
- updates `Current State: Next action` to the log `--next-action` by default
- updates `Checkpoint` fields only when explicit flags are provided
- supports `--dry-run` so the operator can inspect the rendered entry first

The helper is intentionally thin. It does not infer acceptance, checkpoint policy, or lifecycle transitions on its own.

## Verification Expectation

A good update surface should make these things easy:

- writing one short, consistent entry at a real decision boundary
- reading the top of `status.md` and the first few log entries to understand current work
- reusing the same structure across future execution stories
