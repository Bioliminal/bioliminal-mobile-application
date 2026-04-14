# Implementation Plan: Bioliminal Landing Page (Full Build)

This plan outlines the steps to build and integrate a high-fidelity, interactive landing page for the Bioliminal platform in Flutter Web.

## Journal
- **2026-04-14**: Full autonomous implementation of the Bioliminal landing page completed. 
  - Integrated `seo_renderer`, `google_fonts`, and `responsive_builder`.
  - Built a multi-section landing page with Hero, Vision, Insight, Trust, and CTA segments.
  - Configured `web/index.html` with SEO-optimized meta tags and Open Graph data.
  - Realigned `GoRouter` to prioritize the landing page on web while maintaining the disclaimer flow on mobile.
  - Successfully rebranded all references from AuraLink to Bioliminal.

## Phase 1: Preparation & Setup
- [x] Run all tests to ensure the project is in a good state before starting modifications.
- [x] Add `seo_renderer`, `google_fonts`, and `responsive_builder` to `pubspec.yaml`.
- [x] Verify `web/index.html` for meta-tag entry points.
- [x] Create `lib/features/landing/views/landing_page_view.dart`.

### Phase 1 Completion Checklist
- [x] Create/modify unit tests for testing the code added or modified in this phase, if relevant.
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Update the Journal section.
- [x] Commit the changes with a descriptive message.

## Phase 2: Structural Components & Hero Section
- [x] Implement `StickyNavbar` with Glassmorphism effect.
- [x] Implement `HeroSection` with bold typography and a stylized skeletal overlay demo (using a reference image).
- [x] Ensure `seo_renderer` wraps all critical marketing text.

### Phase 2 Completion Checklist
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Update the Journal section.
- [x] Commit the changes.

## Phase 3: Interactive Demos & Body Map
- [x] Create `FeatureShowcase` section with a side-by-side vision demonstration.
- [x] Integrate the `BodyMap` widget into the landing page for interactive insights.
- [x] Add "Finding Cards" as hover/tap overlays on the Body Map.

### Phase 3 Completion Checklist
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Update the Journal section.
- [x] Commit the changes.

## Phase 4: Clinical Trust & CTA
- [x] Implement "Rule-Based Engine" section with an "Explainable AI" visual.
- [x] Implement the Final CTA section with "App Store" and "Play Store" download buttons.
- [x] Add links to research documentation (`research/yijinjing-fascial-chain-remodeling.md`).

### Phase 4 Completion Checklist
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Update the Journal section.
- [x] Commit the changes.

## Phase 5: Routing & Web Optimization
- [x] Update `lib/core/router.dart` to include the landing page at `/` (for web only or as the root).
- [x] Configure `web/index.html` with dynamic meta tags for Open Graph and Twitter Cards.
- [x] Run `flutter build web --web-renderer html` to verify the build output.

### Phase 5 Completion Checklist
- [x] Run the `dart_fix` tool to clean up the code.
- [x] Run the `analyze_files` tool one more time and fix any issues.
- [x] Run any tests to make sure they all pass.
- [x] Run `dart_format` to make sure that the formatting is correct.
- [x] Update the Journal section.
- [x] Commit the changes.

## Phase 6: Final Verification
- [x] Update any `README.md` file for the package with relevant information.
- [x] Update `GEMINI.md` to describe the new landing page and its role.
- [x] Verify responsiveness across multiple device sizes (Desktop, Tablet, Mobile).
- [x] Final project-wide check for any branding inconsistencies.

---
*Note: After completing a task, if you added any TODOs to the code or didn't fully implement anything, make sure to add new tasks so that you can come back and complete them later.*
