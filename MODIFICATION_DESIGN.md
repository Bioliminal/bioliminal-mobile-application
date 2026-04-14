# Modification Design: Bioliminal Landing Page

## Overview
This document outlines the design for a high-fidelity, interactive landing page for Bioliminal. The landing page will serve as the primary "digital front door" for the brand, showcasing its AI-powered movement screening capabilities, fascial chain mapping, and clinical-grade reporting—all while maintaining the "premium, tactile" aesthetic established in the mobile application.

## Detailed Analysis
The goal is to create a showcase that demonstrates the value of Bioliminal without requiring the user to perform an actual screening in the browser (avoiding the complexity of ML Kit/Camera on web for now). The page must be visually stunning, performant, and optimized for search engines (SEO).

### Key Objectives:
1.  **Brand Identity:** Establish "Bioliminal" as a leader in biomechanical analysis.
2.  **Feature Showcase:** High-fidelity demonstrations of the "Vision" (Skeletal Overlay) and "Insights" (Body Map/Fascial Chains).
3.  **Tiered Experience:** Clear paths for new users to explore features, while providing a clear call-to-action (CTA) to download the mobile app.
4.  **SEO & Performance:** Ensure the page is indexable by search engines despite being built in Flutter Web.

## Alternatives Considered
-   **Separate React/Next.js Project:** Considered for superior SEO and initial load times. *Rejected* to avoid code duplication and maintain stylistic parity with the existing Flutter codebase.
-   **Static Image Showcase:** Using only images to show features. *Rejected* in favor of interactive Flutter widgets (like the `BodyMap`) to provide a more engaging "app-like" experience.

## Detailed Design

### 1. Visual Aesthetic: "Tactile Futurism"
Following the 2026 design trend identified in research:
-   **Background:** `BioliminalTheme.screenBackground` (Slate 900) with a subtle noise texture.
-   **Depth:** Multi-layered drop shadows on cards to create a "lifted" feel.
-   **Glassmorphism:** Extensive use of `BioliminalTheme.glassEffect` for navigation bars and feature overlays.
-   **Color Palette:** Deep Indigo (#0D47A1), Sky Blue (#38BDF8), and Emerald (#10B981) for confidence indicators.

### 2. Page Structure (Sections)
1.  **Sticky Navbar:** Logo (Bioliminal), Features, Research, and "Get the App" CTA.
2.  **Hero Section:**
    -   Large, bold typography: "REDEFINE MOVEMENT."
    -   Sub-headline: "AI-powered biomechanics tracing compensations to their fascial root cause."
    -   Background: A stylized, slow-panning animation of a skeletal overlay on a reference movement (e.g., Overhead Squat).
3.  **The Vision (Interactive):**
    -   A side-by-side comparison. Left: Raw video. Right: Bioliminal's 33-landmark high-fidelity skeleton.
    -   Users can toggle "Fascial Chain View" to see the "upstream drivers" highlighted in real-time.
4.  **The Insight (Body Map):**
    -   A high-fidelity rendering of the `BodyMap` widget.
    -   Interactive hotspots that reveal "Finding Cards" (e.g., "Left Ankle Restriction → Lateral Line Tension").
5.  **Clinical Trust:**
    -   "Rule-Based Engine" explanation: Not just a "black box" AI, but a clinical logic layer.
    -   Link to `research/yijinjing-fascial-chain-remodeling.md`.
6.  **Final CTA:** "Transform your movement practice today." (App Store / Play Store links).

### 3. Technical Implementation
-   **Web Renderer:** Build using the HTML renderer (`--web-renderer html`) to ensure that `Semantics` widgets are translated into a readable DOM for search engines.
-   **SEO Optimization:**
    -   Use the `seo_renderer` package to wrap all headers and descriptive text.
    -   Inject dynamic meta tags (Open Graph, Twitter Cards) in `web/index.html`.
-   **Responsiveness:** Use `LayoutBuilder` and `MediaQuery` to ensure the landing page transitions seamlessly from a multi-column desktop layout to a focused single-column mobile view.
-   **Asset Management:** Leverage existing high-res reference images in `assets/reference_images/` for the feature demonstrations.

### Diagrams

```mermaid
graph TD
    A[User Arrives] --> B[Hero Section: The "Wow" Factor]
    B --> C[Interactive Demo: Vision & Landmarks]
    C --> D[Insight Section: Body Map & Fascial Chains]
    D --> E[Trust Section: Research & Clinical Logic]
    E --> F[Conversion: App Store / Play Store]
    
    subgraph "Technical Layer"
        G[Flutter Web - HTML Renderer]
        H["seo_renderer: Indexable Content"]
        I["BioliminalTheme: Unified Styling"]
    end
    
    A -.-> G
    G --- H
    G --- I
```

## Summary
The Bioliminal landing page will be a high-performance, visually immersive experience that bridges the gap between marketing and utility. By reusing existing UI components and theme definitions, we ensure absolute brand consistency while leveraging modern Flutter Web capabilities to provide an interactive showcase that builds immediate user trust.

## References
- [Google Material Design: Depth & Elevation](https://m3.material.io/foundations/elevation)
- [Flutter Web: SEO & Indexability Best Practices (2026)](https://docs.flutter.dev/platform-guides/web/seo)
- [Bioliminal Project Documentation (GEMINI.md)](./GEMINI.md)
