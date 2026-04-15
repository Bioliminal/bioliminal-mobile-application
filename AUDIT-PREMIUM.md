# Bioliminal Premium Experience Audit

This audit evaluates Bioliminal through the lens of a **high-end, clinical-grade consumer product**. While the underlying scientific logic is robust, the current implementation sits between a "proof-of-concept" and a "stock" mobile app.

---

## 1. Core Value Proposition: The "AI" Intelligence
**Status: ⚠️ Theoretical**

*   **The Gap:** The "AI" is currently missing. `google_mlkit_pose_detection` is commented out, meaning the app is a shell running on deterministic mocks. A "premium" experience cannot exist without the core functional promise being met.
*   **The Strength:** The **Rule-Based Chain Mapper** is the crown jewel. It doesn't just look for "bad form"; it uses fascial chain reasoning to find *drivers*. This is a $200/hour practitioner's brain encoded into Dart.
*   **Audit Note:** The logic for hypermobility detection and "Body-path" language (avoiding jargon) is top-tier and feels professional.

## 2. User Experience: Flow & Onboarding
**Status: 🟠 Functional but Low-Tech**

*   **The "Disclaimer" Friction:** The scroll-to-bottom requirement is a necessary "compliance" hurdle, but it feels like a legal wall. A premium app would integrate this into a more welcoming "Welcome/Science" carousel.
*   **Manual Setup:** The `SetupChecklist` requires manual user taps for "Distance," "Lighting," etc.
    *   *Premium Fix:* Use the AI to *automatically* validate the environment. "Distance OK" should turn green only when the AI sees the full skeleton. This creates immediate "Wow" factor and trust.
*   **Feedback Loop:** During the 15-60s screening, the user is left in a "blind" state with just a timer.
    *   *Premium Fix:* Real-time skeletal overlay (even if simplified) gives the user confidence that the "AI" is actually working.

## 3. Visual & Interactive Design: The "Premium" Feel
**Status: 🔵 Modern but "Stock"**

*   **Typography & Brand:** The app uses default Material 3 fonts and primitives. For a "premium" feel, the app needs a custom typographic hierarchy and bespoke iconography.
*   **The "Report" Presentation:**
    *   *Current:* Cards and ExpansionTiles. It looks like a checklist.
    *   *Premium Expectation:* Interactive body maps. Instead of reading "ankle restriction," the user should see a heat-map of their skeleton where the "driver" (ankle) is highlighted in one color and the "symptom" (knee) in another.
*   **Evidence Display:** The `CitationExpandable` is excellent. It provides "Authority," which is a key pillar of premium health apps.

## 4. Functional Integrity: Gaps in Reality
**Status: 🔴 Critical Architectural Risks**

*   **Privacy Contradiction:** The app promises "No data leaves your phone," yet `FirestoreService` and `AuthService` are fully implemented and wired to sync data. This is a "trust-killer."
*   **State Management Leaks:** The `MockPoseEstimationService` has timer/stream leaks. In a premium app, any "glitch" or "stutter" during a screening ruins the perceived accuracy of the clinical results.
*   **Deep-Linking:** The report view is currently broken for browser refreshes or deep-links (it relies on ephemeral `extra` data). A premium user expects to be able to share a link to their report that "just works."

## 5. Privacy & Trust
**Status: 🟢 Design Intent / 🔴 Implementation**

*   **Design Intent:** The "Privacy First" framing is perfect for this market.
*   **Implementation:** As noted in previous audits, the Firebase backend should be removed or made explicitly "Opt-in" with a high-friction confirmation to maintain the "Local-First" premium promise.

---

## The "Road to Premium" Recommendations

1.  **Automated Environment Validation:** Replace the manual checklist with AI-driven detection. "Ready to start" should be a reward for the user setting up correctly.
2.  **Skeletal Overlay:** Implement a "Ghost" or "Skeleton" overlay during screening. This provides visual proof of the $4.4B technology the user is interacting with.
3.  **Visual Report Logic:** Move away from "Text-First" reports to "Visual-First" reports. Use a 3D model or 2D SVG body-map to illustrate the fascial chains.
4.  **Specific Next Steps:** Instead of "Talk to a PT," provide 1-2 "Educational Mobility Drills" based on the specific finding (e.g., if "Ankle Restriction" is the driver, show a 30-second ankle mobilization video).
5.  **Longitudinal UI:** Even if data is empty, show a "History" tab. Premium users want to see "the journey" (e.g., "Knee valgus improved by 4 degrees since last month").

---

## Audit Verdict
*   **Clinical Logic:** 9/10 (Expert level)
*   **User Experience:** 4/10 (Student project level)
*   **Technical Integrity:** 2/10 (High risk/Broken)

**Focus on "The Wow" (Visual AI feedback) and "The Trust" (Fixing the privacy contradiction and ML stub) to reach a Premium status.**
