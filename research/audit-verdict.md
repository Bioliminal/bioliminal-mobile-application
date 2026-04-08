# Research Audit: Final Verdict

Covers all 7 documents against prior verification results and new spot-checks. Each source gets: KEEP, FIX, or CUT.

---

## Document-Level Summary

| Document | Verdict | Issues |
|----------|---------|--------|
| capstone-overview.md | KEEP with 2 fixes | In-vitro caveat on 30% force transmission; Kalichman doesn't cite Wilke (independent, not "corroborated") |
| fascial-chain-science.md | KEEP as-is | Accurately balanced. Criticisms and evidence both well-represented. |
| mediapipe-accuracy.md | KEEP as-is | Correctly scoped. Degradation data well-documented. Good distinction between controlled vs real-world. |
| why-the-gap-exists.md | KEEP with 1 fix | FDA barrier mixes CDS and General Wellness guidance language — needs precision |
| ai-movement-screening-landscape.md | KEEP as-is | Competitive landscape solid. Novelty claim ("no fascial chain integration") holds. |
| ai-applications-in-sports.md | KEEP with caveats noted | Broader context doc. NFL injury claims properly caveated. Not critical for capstone core argument. |
| research-all-findings.md | KEEP with 3 fixes | PMC12864725 is methodologically compromised; one unsourced claim; Merletti citation structure |

---

## CUT — Remove or Replace Entirely

### PMC12864725 (Hybrid IMU-sEMG, 92.3% accuracy) — CUT from all documents

This paper has severe methodological red flags:

1. **"[insert sEMG system name if available]"** is literally left in the published text — the authors forgot to fill in their sensor name
2. **Joint angle numbers contradict themselves**: Abstract says 125° knee during running; supplementary figures say 45.2°
3. **No control group** — admitted by the authors as a limitation, using "quasi-control" from warm-up data
4. **Suspiciously round muscle force numbers**: 150 N, 170 N, 230 N — real biomechanical data doesn't come out this clean
5. **Mixed pilot and main study data** — consumer wearable data (n=4) analyzed alongside the main study (n=50)
6. **Industrial data presented as collected but marked "conceptual/Phase 2"** elsewhere

**Where it appears**: research-all-findings.md Section 2 (ML Accuracy Benchmarks table), ai-applications-in-sports.md Section 2 (ML Accuracy Benchmarks table)

**Action**: Remove the "Hybrid IMU-sEMG (BiLSTM) | 92.3%, AUC-ROC 0.93 | PMC12864725" row from both tables. Do not cite this paper. The other three rows in that table (Random Forest, CNN, LSTM) all come from PMC12383302 and are verified.

---

## FIX — Correct Specific Claims

### Fix 1: Kalichman 2025 "corroboration" language

**Where**: capstone-overview.md line 52, fascial-chain-science.md line 22

**Current**: "Corroborated by Kalichman (2025)"

**Fix**: Change to "Independently confirmed by Kalichman (2025)" — Kalichman does NOT cite Wilke et al. 2016. This makes the agreement stronger (genuinely independent), not weaker. But "corroborated" implies Kalichman was responding to Wilke, which isn't the case.

### Fix 2: 30% force transmission — add in-vitro caveat

**Where**: capstone-overview.md line 56, fascial-chain-science.md line 28, research-all-findings.md line 428

**Current**: "In-vitro studies show fascia can transmit up to 30% of mechanical forces (Kalichman 2025)"

**Fix**: Already correct in capstone-overview.md (says "in-vitro"). Verify fascial-chain-science.md also says "in-vitro" (it does, line 28). In research-all-findings.md line 428, the SBL row says "7-69% force transfer between biceps femoris and sacrotuberous ligament" — this is from Krause et al. 2016 cadaveric data. Add "(cadaveric)" qualifier.

### Fix 3: FDA guidance precision in why-the-gap-exists.md

**Where**: why-the-gap-exists.md, Barrier 3, line 70

**Current**: "FDA's January 2026 updated guidance prohibits exempted CDS from including 'claims prompting specific clinical action or medical management'"

**Fix**: That language ("claims prompting specific clinical action or medical management") comes from the **General Wellness guidance**, not the CDS guidance. The CDS guidance's relevant restriction is Criterion 3: software must "support or provide recommendations to a healthcare professional" without replacing their judgment. The General Wellness guidance says products must not "include claims, functionality, or outputs that prompt or guide specific clinical action or medical management." These are different regulatory pathways with different criteria. Be precise about which guidance imposes which restriction.

Additionally, line 68 compresses all 4 CDS criteria into one sentence and slightly mischaracterizes Criterion 1. The actual Criterion 1 text is: "not intended to acquire, process, or analyze a medical image or a signal from an in vitro diagnostic device or a pattern or signal from a signal acquisition system." This is more specific than "no analysis of medical signals/images." The distinction matters because a phone camera processing video for movement analysis could be argued as analyzing a "medical image" under the 2026 definition (which explicitly includes "images not originally acquired for a medical purpose but being processed for a medical purpose").

### Fix 4: Merletti et al. citation structure

**Where**: research-all-findings.md (implied throughout Section 12 and why-the-gap-exists.md Barrier 5)

**Current**: Various references to the sEMG adoption barriers as if from a single study

**Fix**: As verified in our follow-up, the vicious cycle is an editorial synthesis across an 18-paper special issue. The 28 interviewees come from Cappellini et al.; the 35 respondents from Manca et al. Wherever cited, ensure the structure is clear: "Merletti et al. (2021) synthesized findings across an 18-paper special issue..." not "a study of 28 experts found..."

### Fix 5: "30-50% injury rate reduction" claim

**Where**: research-all-findings.md line 443

**Current**: "Multi-intervention training targeting fascial health reduces injury rates by 30-50%"

**Fix**: This claim has no PMC ID or source URL attached. It appears in the fascia section without attribution. Either find and cite the specific source, or remove it. Unsourced percentage claims are exactly the kind of thing that undermines credibility.

---

## KEEP — Verified and Solid

### PMC12383302 (Scoping Review) — ALL CLAIMS VERIFIED

Every number from this paper checks out:

| Claim | Verified |
|-------|----------|
| 43.84% adequate validation | Yes — 32/73 studies (Table 1) |
| Random Forest 87.5% median (n=18) | Yes — exact quote in results |
| CNN 91% median, 94% expert agreement (n=12) | Yes — 94% from gymnastics judging specifically |
| LSTM <5% MAE for GRF | Yes — Mundt et al. cited in Table 5 |
| Gradient boosting > physiotherapists | Yes — Sharafat et al. in Section 6.3 |
| LSTM 2.5 sessions before symptoms | Yes — Hafer et al. in Section 7.2 |

This is your strongest ML benchmarks source. Keep all citations.

### Zone7 72.4% — KEEP with caveat already present

The 72.4% figure is verified from their case study. Key context already noted in your docs:
- Retrospective analysis, not prospective
- Published by Zone7 (Sportsmith), not independently peer-reviewed
- They explicitly state it was "not intended nor designed to serve as peer reviewed scientific research"
- Out-of-sample testing (AI not trained on the data before analysis) — this is the good part
- 423 injuries across 11 clubs — reasonable sample

Your docs already note the self-published nature. No change needed.

### Jiang et al. 2024 (sEMG + Vision Fusion) — FULLY VERIFIED

All error numbers match Table 1 exactly. Combined knee error: 1.04 ± 0.52°. n=12, VICON, 9 muscles, 4.5 km/h treadmill. Keep.

### Wilke et al. 2016 — VERIFIED, INDEPENDENTLY CONFIRMED

Chain transition counts match across all documents. Kalichman 2025 independently arrives at the same evidence hierarchy without citing Wilke. The strongest possible validation pattern: two independent reviews, same conclusions.

### Fascial chain criticism (Lehman, Krause) — ACCURATELY REPRESENTED

The 4-10cm displacement critique, cadaveric methodology concerns, and Tom Myers' concession are all accurately presented in fascial-chain-science.md and why-the-gap-exists.md. This honest treatment of skepticism is one of your research's greatest strengths.

### FDA regulatory analysis — VERIFIED WITH NUANCE

The 4 criteria, the January 2026 updates, the single-recommendation enforcement discretion — all confirmed from the actual FDA guidance PDF and multiple law firm analyses (Arnold & Porter, Frier Levitt, Latham & Watkins). The DARI Motion 510(k) clearance is a real, verifiable precedent. Just fix the CDS vs General Wellness attribution issue noted above.

### All hypermobility data (Section 9) — KEEP

Sources are all PMC-indexed peer-reviewed studies. The Beighton score video tool (91.9% sensitivity, 42.4% specificity) from PubMed 41639883 is correctly characterized as academic-only.

### All deceleration data (Section 10) — KEEP

Well-sourced from PMC articles. The 2D video scoring >96% classification (PMC8595159) and LSTM AUC 0.88 (PMC10935765) are from distinct peer-reviewed studies.

### CV in Movement Disorders review (PMC12481449) — KEEP with corrected framing

As verified in our follow-up: the 61/71 studies are all neurological conditions. The search terms excluded musculoskeletal by design. The finding isn't "only 61 studies used CV for movement assessment" — it's "the only systematic review of CV in clinical movement assessment focused exclusively on neurology, ignoring musculoskeletal entirely." The absence of a parallel MSK review is the evidence of the silo.

---

## What's NOT in Your Research (Gaps to Acknowledge)

1. **No first-person accounts from CV researchers** explaining why they stop at measurement (noted in why-the-gap-exists.md)
2. **No company statements from DARI, Kinetisense, or Uplift** on why they exclude fascial chain logic
3. **No failed-attempt case studies** of encoding manual therapy reasoning into software
4. **No citation analysis** quantifying cross-field citation rates (recommended in our research-angles.md)
5. **The Athos 37% figure was fabricated** — you correctly don't use it in your docs, but be aware it's circulating in AI-generated content online

---

## Overall Assessment

Your research base is strong. The documents are well-sourced, properly caveated, and honest about limitations. The fascial chain skepticism is presented fairly alongside the supporting evidence. The competitive landscape analysis is thorough.

The three actions that matter most:
1. **Cut PMC12864725** — it's the weakest link and you don't need it (the other three ML benchmarks from PMC12383302 are solid)
2. **Fix the FDA guidance attribution** — mixing CDS and General Wellness language will get caught by anyone who reads the actual guidance
3. **Source or cut the 30-50% injury reduction claim** — unsourced percentage claims are credibility poison in a document that's otherwise meticulously cited
