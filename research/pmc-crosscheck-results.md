# PMC Citation Cross-Check: research-all-findings.md

16 unique PMC/PubMed sources checked against their published abstracts/full text. PMC12383302 (scoping review) was already fully verified in a prior round.

---

## Errors Found (6)

### 1. MISATTRIBUTED — Shoulder OR=3.25 (PubMed 20601606)

**Claim**: "Shoulder injury risk (hypermobile with shoulder involvement) | OR = 3.25 | PubMed 20601606"

**Reality**: PubMed 20601606 (Pacey et al. 2010) is titled "Generalized joint hypermobility and risk of **lower limb** joint injury." It reports only knee (OR=4.69) and ankle outcomes. There is zero mention of shoulder injuries, shoulder involvement, or OR=3.25 anywhere in the abstract.

**Action**: Remove the shoulder OR=3.25 row, or find and attribute the correct source. The knee OR=4.69 from this paper is confirmed.

---

### 2. WRONG P-VALUE — Overall injury rate (PMC6196975)

**Claim**: "Overall injury rate difference (hypermobile vs not) | NOT significant (p=0.66)"

**Reality**: The paper's Table 3 reports p=0.74 for the hypermobility-injury contingency table. The p=0.66 appears in the conclusion section but seems to reference a different comparison. The primary result is p=0.74.

**Action**: Change p=0.66 to p=0.74, or note that the paper itself contains conflicting p-values (0.74 in Table 3 vs 0.66 in conclusion).

---

### 3. MISATTRIBUTED — Asymmetry >10° and imbalance >15% (PMC11592714)

**Claim**: "Joint angle asymmetry >10 degrees and muscle-force imbalance >15% accurately predicted ACL and muscle-strain risks (PMC11592714)"

**Reality**: PMC11592714 (Musat et al. 2024, "A Comprehensive Review of Injury Risk Prediction Methods") does NOT contain these specific thresholds. No mention of ">10 degrees" asymmetry or ">15%" muscle-force imbalance anywhere in the paper.

**Action**: Find the actual source for these thresholds or remove. These may come from the already-cut PMC12864725 (the compromised hybrid IMU-sEMG paper), which did claim ">10° asymmetry and >15% imbalance."

---

### 4. MISFRAMED — 2D video scoring accuracy (PMC8595159)

**Claim**: "A 2D video scoring system using 5 criteria achieved >96% classification accuracy (ICC >0.94)"

**Reality**: The paper reports two separate things conflated here:
- **96% classification**: From the integrated frontal plane assessment (not the 5-criteria system alone). Specifically, "only 4% misclassified in high-KAM group and 2% in low-KAM group."
- **ICC >0.94**: For intra-rater and inter-rater reliability of the 2D scoring criteria (range 0.94–1.00). This is scoring reliability, not classification accuracy.

**Action**: Rewrite to: "A 2D qualitative scoring system showed ICC 0.94–1.00 for inter/intra-rater reliability, and the integrated frontal plane assessment correctly classified 96–98% of athletes into high vs low knee abduction moment groups (PMC8595159)."

---

### 5. PARTIALLY WRONG — Proprioceptive deficits at "elbow and knee" (PMC9397026)

**Claim**: "Hypermobile individuals show proprioceptive deficits at elbow and knee"

**Reality**: PMC9397026 (Zabriskie 2022) documents proprioceptive deficits at the **knee** (confirmed: Rombaut et al. data showing 6.9° vs 4.6° passive error at 30° flexion) and **greater postural sway** (confirmed). The **elbow** is not mentioned in the extracted data. The 8-week closed-chain exercise improvement is confirmed (Ferrell 2004, Sahin 2008).

**Action**: Change "at elbow and knee" to "at the knee" unless the elbow data can be sourced elsewhere.

---

### 6. NUANCE — Biotensegrity model source (PubMed 29317079)

**Claim**: "Biotensegrity model: body as continuous tensional network where bones are compression rods and fascia is tension elements"

**Reality**: The paper (Dischiavi et al. 2018) describes biotensegrity as "bones of the skeletal system are postulated to be held together by the resting muscle tone of numerous viscoelastic muscular chains in a tension dependent manner." The specific "compression rods / tension elements" framing is the general biotensegrity concept (from Ingber, Levin, etc.) but isn't this paper's exact language. More importantly, this was published in *Medical Hypotheses* — a speculative/theoretical journal, not an empirical research journal.

**Action**: Note the source is from *Medical Hypotheses* (theoretical). The biotensegrity concept itself is well-established; this paper is just one citation for it. Consider citing Ingber (1998) or Levin (2002) as the original biotensegrity sources instead.

---

## Minor Notes (Correct but worth context)

### PMC12200876 — 98.9% accuracy is EuroLeague, not NBA

The 98.9% MLP accuracy comes from Ballı et al. 2021 using EuroLeague data. The NBA-specific highest reported accuracy in this review is 93.81% (Random Forest, Migliorati 2020). The doc says "NBA prediction ML models found accuracy ranges from 58% to 98.9%" — technically the review covers basketball broadly (including EuroLeague/CBA), not only NBA.

### PMC9474351 — Deceleration figures are from a cited study

The 8.63° vs 1.66° hip adduction values come from Dix et al. [103] as cited within the Harper et al. 2022 review, not from original data in that paper. The citation chain is accurate but worth noting.

---

## All Verified (10 sources, exact match)

| Source | Claim | Status |
|--------|-------|--------|
| PMC12200876 | 58%–98.9% accuracy range | ✅ Confirmed (with EuroLeague caveat) |
| PMC12400819 | κ = 0.897 taekwondo AI | ✅ Exact match |
| PubMed 20601606 | Knee OR = 4.69 | ✅ Exact match |
| PMC6196975 | 50% injured 2-6 months; sprains p=0.03; 3 dislocations | ✅ All confirmed |
| PubMed 41639883 | 91.9% sensitivity, 42.4% specificity, 125 adults | ✅ Exact match |
| PubMed 15722287 | 2.5x abduction, 8°, 20% GRF, 73%/78% | ✅ All four numbers exact |
| PMC12964768 | SHAP: 0.394, 0.218, 0.072 | ✅ Exact match (Table 5) |
| PMC8558993 | 3.5° lower knee valgus, 4.5° greater ext rotation | ✅ Confirmed |
| PMC9474351 | 8.63° vs 1.66° hip add, 8.57° vs 0.65° knee valgus | ✅ Exact match |
| PMC10935765 | AUC 0.88, balanced accuracy 0.80 | ✅ Exact match |
| PMC11896072 | 1,812 keyframes, 45 subjects, 91% accuracy, kappa 0.82 | ✅ All confirmed |
| PMC9397026 | Knee proprioception deficits, postural sway, 8-week improvement | ✅ (minus elbow) |
| PMC12383302 | All 6 claims | ✅ Previously verified |
