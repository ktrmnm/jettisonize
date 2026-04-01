# Story: {{STORY_TITLE}}

- Story ID: `{{STORY_ID}}`
- Slug: `{{STORY_SLUG}}`
- External Ref: `{{EXTERNAL_REF}}`
- Epic: `{{EPIC_ID}}`
- Created: `{{CREATED_DATE}}`
- Story Preset: `{{STORY_PRESET}}`
- Acceptance Mode: `{{ACCEPTANCE_MODE}}`

## Background

Write only the story-specific background here. Use the preset prompts below as a checklist, not as content to keep verbatim.

Preset prompts:
{{PRESET_BACKGROUND_PROMPTS}}

## Deliverables

List only the concrete deliverables for this story.
If this booster blocks another active booster, include the closure note that must be appended before jettison.
{{PRESET_DELIVERABLE_PROMPTS}}

## Done When

List only the acceptance conditions that make this story complete.
If this booster blocked another active booster, that booster's `status.md` must end with a note that this booster was closed.
{{PRESET_DONE_WHEN_PROMPTS}}

## Guardrails

List only the constraints that must not be violated during this story.

## Durable Outputs That Must Survive Jettison

List only the outputs that must still matter after the booster is retired.

## Review Checklist

- Is the story small enough to finish in about two weeks?
- Are the deliverables concrete?
- Is `done when` actually checkable?
- Is the selected preset appropriate?
- Is the active booster behavior clear if this booster is created mid-session?
- Is the story ready to enter the propel phase into the ready phase?

## Boundary Hint

{{PRESET_BOUNDARY_HINT}}

## Notes

Add only story-local notes here. Durable conclusions belong in a persistent document before jettison.
