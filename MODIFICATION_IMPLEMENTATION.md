# Implementation Plan: Premium Bioliminal Landing Page (Storytelling Overhaul)

This plan outlines the steps to transform the Bioliminal landing page into a premium, scroll-driven cinematic experience using shader-based glassmorphism and the `flutter_animate` storytelling pattern.

## Journal
- **2026-04-14**: Plan initialized for premium redesign. Research confirmed `liquid_glass_widgets` and `flutter_animate` as core pillars.
- **2026-04-14**: Phase 1 & 2 completed. Refactored `LandingPageView` with `CustomScrollView` and `ScrollAdapter`. Integrated `GlassMotionScope` for dynamic lighting and verified API usage for `liquid_glass_widgets`. All compilation errors resolved.

## Phase 1: Foundation & Storytelling Engine
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Add `flutter_animate` and `liquid_glass_widgets` to `pubspec.yaml`.
- [x] Refactor `LandingPageView` to use `CustomScrollView` and `Slivers`.
- [x] Initialize the global `ScrollController` and link it to a `flutter_animate` `ScrollAdapter`.

### Phase 1 Completion Checklist
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Update the Journal section.
- [x] Commit the changes.

## Phase 2: Liquid Glass Design System
- [x] Implement `GlassMotionScope` to enable scroll-driven specular highlights.
- [x] Create `PremiumGlassCard` and `PremiumGlassButton` reusable widgets. (Note: Using built-in GlassCard and GlassButton.custom directly)
- [x] Add stylized background "Glow Blobs" and noise textures to `BioliminalTheme.screenBackground`.

### Phase 2 Completion Checklist
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool and fix any issues.
- [x] Run `dart_format`.
- [x] Update the Journal section.
- [x] Commit the changes.

## Phase 3: The Origin (Hero Section)
- [ ] Implement the cinematic entry animation for the Hero Visual.
- [ ] Add scroll-driven rotation and scale transitions for the Skeleton visual (placeholder).
- [ ] Implement typography cross-fades ("REDEFINE MOVEMENT" -> "VISION BEYOND SIGHT").

### Phase 3 Completion Checklist
- [ ] Run analysis and formatting.
- [ ] Update the Journal section.
- [ ] Commit the changes.

## Phase 4: The Sight (Feature Showcase)
- [ ] Build the interactive feature grid using `GlassPanel` with "Jelly Physics".
- [ ] Sync icon animations with scroll progress.
- [ ] Refine the "Beyond Joint Metrics" side-by-side comparison with high-fidelity visuals.

### Phase 4 Completion Checklist
- [ ] Run analysis and formatting.
- [ ] Update the Journal section.
- [ ] Commit the changes.

## Phase 5: The Connection (Fascial Storytelling)
- [ ] Implement the linear "Tracing" animation for the Fascial Chain visual.
- [ ] Add interactive hotspots that reveal frosted glass "Insight Overlays".
- [ ] Sync the clinical documentation links with the storytelling flow.

### Phase 5 Completion Checklist
- [ ] Run analysis and formatting.
- [ ] Update the Journal section.
- [ ] Commit the changes.

## Phase 6: Final Polish & Assets
- [ ] **Request Assets:** User to provide high-res Hero and Fascial Chain visuals from `nano banana`.
- [ ] Integrate provided assets and finalize visual timings.
- [ ] Optimize for 60FPS using `RepaintBoundary` on complex shader sections.
- [ ] Update `GEMINI.md` and `README.md`.

---
*Note: After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.*
