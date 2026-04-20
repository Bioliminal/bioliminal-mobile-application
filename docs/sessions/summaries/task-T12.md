# Task T12 Summary — Model Download Manifest

**What:** Created `assets/models/DOWNLOAD.md` and appended heavy + lite entries to `assets/models/CHECKSUMS.md`.

**Files:**
- `assets/models/DOWNLOAD.md` — new; fetch instructions for all three pose landmarker variants with SHA-256 placeholders for heavy/lite
- `assets/models/CHECKSUMS.md` — appended two table rows (heavy + lite) with `<pending fetch>` SHA-256 placeholders, matching the existing table format

**Sandbox note:** Outbound HTTP is denied in this environment. SHA-256 values for heavy and lite variants are `<pending fetch>` placeholders. Kelsi / user-shell must run the `sha256sum` commands documented in DOWNLOAD.md and update CHECKSUMS.md.

**pubspec verification:** `grep` confirmed `- assets/models/` at line 43 of `pubspec.yaml` (directory-level declaration). No pubspec edit required — `.task` files are auto-included.

**Commit status:** Both files were committed to the branch within commit `7c9887d` (concurrent sibling session wrote to the same working tree before that commit ran). Content verified correct via `git show HEAD:assets/models/CHECKSUMS.md` and `git show HEAD:assets/models/DOWNLOAD.md`.

**Deviations:** None from spec. CHECKSUMS.md used table format (not markdown headers) — adapted heavy/lite entries to match table rows as instructed.
