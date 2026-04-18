# bioliminal-mobile-application — Claude Context

**Updated:** 2026-04-18
**Owner:** kelsi.andrews

Flutter app — the phone-side client in the BioLiminal movement screening loop. Pairs with the server in `ML_RandD_Server` (aka `RnD_Server`) and the firmware in `esp32-firmware`.

**Documentation conventions:** see https://gitlab.com/bioliminal/bioliminal/-/blob/main/CONVENTIONS.md — header schema (`Status` / `Created` / `Updated` / `Owner`), git-author → gitlab-handle mapping, and the delete-over-archive rule. Follow the schema for every new doc.

## Cross-repo centralization

- **Strategy, plans, decisions, session progress, internal comms:** private `bioliminal-ops` repo.
- **Literature, paper notes, synthesis:** private `research` repo.
- **Server-side contract (Dart interface, JSON schemas, sample fixtures, MediaPipe fetch instructions):** `bioliminal-ops/operations/handover/mobile/`.
- **Server source and API:** `ML_RandD_Server`.

Keep mobile-specific engineering notes (UI decisions, platform-channel glue, build config) in this repo. Move cross-team strategy/ops to `bioliminal-ops`; literature findings to `research`. When referencing prior work, point at the other repo rather than copying content here.
