## What

<!-- one sentence, present tense, what this MR does -->

## Why

<!-- the constraint, research finding, user-visible outcome -->

## Scope-change checklist

Does this MR change what the system does, move work between components
(firmware ↔ mobile ↔ server), or touch a locked interface contract
(IC-1 … IC-4)?

- [ ] **No** — bug fix / lint / tuning / dep bump / docs-only / refactor that preserves behaviour.
- [ ] **Yes** — I have:
  - [ ] Updated `bioliminal-ops/operations/interface-contracts.md` (if an interface changed)
  - [ ] Updated `bioliminal-ops/operations/2026-04-19-demo-stack-diagram.md` (if the cross-system flow changed)
  - [ ] Considered whether `bioliminal-ops/operations/2026-04-19-technical-brief-v1.md` needs a version bump
  - [ ] Opened a companion MR in `bioliminal-ops` with a decision doc at `decisions/YYYY-MM-DD-<slug>.md` + a row appended to `decisions/decisions.md`
  - [ ] Linked that companion MR below

Convention: `bioliminal-ops/operations/conventions-scope-changes.md`.

## Ops-repo companion MR

<!-- link to the bioliminal-ops MR, or "N/A — no scope change" -->

## Test plan

<!-- checklist of what was exercised, or "N/A" -->
