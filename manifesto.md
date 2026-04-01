# Jettisonize Manifesto

## Thesis

AI-agent development breaks down less because models are weak than because teams keep too much working context alive for too long.

Jettisonize is a method for open-ended development. It treats story-scoped context as disposable support for one bounded move, not as permanent project memory. Durable knowledge should stay small, explicit, and intentional.

## Problem

Open-ended work makes context sprawl feel rational.

- teams keep the same session alive because restarting feels risky
- local notes, plans, and partial decisions pile up because nothing declares an expiry point
- human operators lose track of which files are operative and which are residue
- project memory fills with intermediate reasoning that no longer changes anything

The result is predictable: the project starts optimizing for carrying context instead of changing reality.

## Core Claims

### 1. Context is consumable

Working context exists to enable a specific change. Once that change lands, most of the local context has already expired.

### 2. Projects should preserve outcomes, not every path

Durable memory should hold deliverables, accepted constraints, guardrails, and the minimum evidence needed to trust them.

### 3. Every story must declare what survives

If something must remain after the story closes, it needs to be a deliverable or be promoted into a durable project surface before jettison.

### 4. A story is valid only if completion changes reality

A story is not a reminder. A valid story changes implementation, understanding, or stakeholder decisions within a bounded time window.

### 5. Specification is useful when it expires

Jettisonize is not anti-spec. Local specs, plans, and acceptance notes are useful when they help a story move. They become noise when they outlive their purpose by default.

## Operating Loop

1. `fuel`: create a story-first booster with clear background, deliverables, `done when`, and guardrails
2. `ready`: expand the accepted story into the execution bundle needed for handoff and implementation
3. `propel`: do the work and keep `status.md` current at real decision boundaries
4. `jettison`: confirm the durable outcomes, then archive or delete the booster by policy

The loop is intentionally strict. A booster supports one story. It is not a second project wiki.

## Definitions

### Epic

A larger frame of work whose value is judged by humans or stakeholders.

### Story

A bounded unit of work under an epic. A story is valid only when it has clear purpose, concrete deliverables, explicit `done when`, enforceable guardrails, and a completion shape that changes project state.

### Booster

A short-lived story-local directory that holds the handoff-critical context for one story.

### Handoff Bundle

The minimum set of files a fresh agent needs to continue the story without hidden chat history.

## Booster Contract

A booster starts with `story.md` only. After review and acceptance for execution, it normally gains:

- `spec.md`
- `plan.md`
- `status.md`
- optional support files such as `notes.md` or `artifacts/` when the story needs them

The bundle should stay small enough that a fresh agent can resume from the booster alone.

## What Must Persist

- shipped code and tests
- accepted design constraints
- operating rules and safety guardrails
- decisions that affect later stories
- reusable scripts, templates, and skills
- findings that materially change the project

Everything else is a candidate for retirement.

## What Jettisonize Refuses

- immortal exploratory specs
- session transcripts as the system of record
- progress logs treated as durable knowledge by default
- story scope that grows until completion stops being testable
- public method contracts built from accidental residue

## Human Role

Some stories finish with tests. Others finish with human judgment: a design is clear enough, a finding is strong enough, or a release surface is coherent enough to ship. Jettisonize requires that acceptance boundary to be explicit.

## Non-goals

Jettisonize is not:

- a universal project management system
- a replacement for version control
- a promise that agent work will be risk-free
- an excuse to discard evidence needed for audit, safety, or reproducibility
- a justification for keeping every intermediate artifact forever

## Positioning Notes

Jettisonize should be read as a recomposition of familiar development ideas for AI-agent work, not as a total break from prior methods.

It aligns with spec-driven development in valuing clear deliverables, explicit constraints, and bounded plans, but it treats local specs as short-lived story support by default.

It aligns with Agile and Scrum in valuing small units of work, explicit acceptance boundaries, and iterative progress, but it is much stricter about retiring story-local context.

It aligns with Lean and Kanban in keeping work bounded and limiting sprawl, but it applies that discipline to working context as well as work in flight.

It is best understood not as a replacement for those methods, but as a context-management discipline for AI-agent development.

## Closing

Create bounded context.
Use it to make a move.
Then let it go.
