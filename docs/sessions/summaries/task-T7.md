---
Status: Complete
Created: 2026-04-19
Updated: 2026-04-19
Owner: aaron.carney
---

# Task T7 — PoseChannel `initialize` delegate param

## What
Extended `PoseChannel.initialize` to accept a required `delegate` string parameter, forwarded to native as part of the method arguments map. Updated the `initialize` test group to assert the new `{assetPath, delegate}` argument structure.

## Files
- `lib/features/camera/services/pose_channel.dart` — added `delegate` param to `initialize`
- `test/features/camera/services/pose_channel_test.dart` — updated `initialize` test group in-place

## Test count
6 tests — 1 updated (initialize sends {assetPath, delegate}), 1 updated for delegate arg (returns false on null), 4 unchanged.

## Deviations
None. Existing test replaced in-place; no duplication.

## Commit
`b69cc9f feat(pose): pose_channel initialize accepts delegate string`
