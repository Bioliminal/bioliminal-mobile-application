# story-1308: Fix MovementInstructions Positioned wrapper

## Problem

`MovementInstructions.build()` returns a `Positioned` widget (line 20), forcing every caller to use a `Stack`. This is a layout concern that belongs to the caller, not the component.

## Contract

**Before:** `MovementInstructions.build()` returns `Positioned(top: 0, left: 0, right: 0, child: Container(...))`
**After:** `MovementInstructions.build()` returns `Container(...)` directly

Callers that place `MovementInstructions` inside a `Stack` must add their own `Positioned` wrapper.

## Write files

- `lib/features/screening/widgets/movement_instructions.dart`

## Cross-story seam

story-1304 owns `screening_view.dart`. After this change lands, story-1304 must wrap the `MovementInstructions` call (line 154-157) in `Positioned(top: 0, left: 0, right: 0, child: ...)` to preserve current layout.

<!-- CODER_ONLY -->
## Tasks

1. In `movement_instructions.dart`, remove the `Positioned` wrapper from `build()`:
   - Delete the `return Positioned(top: 0, left: 0, right: 0, child:` on line 20
   - Return `Container(...)` directly (the current child of Positioned)
   - Remove the corresponding closing paren + semicolon for Positioned (line 76)
   - Result: `build()` returns `Container(padding: ..., decoration: ..., child: SafeArea(...))` 
<!-- /CODER_ONLY -->

## Acceptance criteria

- `MovementInstructions.build()` returns a `Container`, not a `Positioned`
- No other files modified

## Test plan

N/A -- pure structural refactor. Verified by static analysis (`flutter analyze`) and visual inspection that the widget tree is otherwise identical.
