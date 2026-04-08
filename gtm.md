# Go-to-Market Plan: 100 GitHub Stars in 3 Weeks

## Passing Criteria
- **Target**: 100 GitHub stars (vs 50 paying users — stars is the faster path)
- **Timeline**: 3 weeks from capstone start
- **Why stars over revenue**: 50 paying users for a novel health tool with no brand requires working product + payment + marketing + trust. 100 GitHub stars requires one good HN post and a compelling README.

---

## Strategy: Open-Source the Chain Reasoning Engine

The research confirmed **zero open-source tools** implement fascial chain reasoning for movement screening. That's the hook. "First open-source movement compensation reasoning engine" is genuinely novel and interesting to CV researchers, sports scientists, PT academics, and fitness developers.

The competitive landscape makes this inherently shareable: Hinge Health ($3B IPO), Sword Health ($4B), DARI Motion (FDA-cleared) — none do chain-level reasoning. A free open-source tool that does what billion-dollar companies don't is a compelling story.

---

## 3-Week Sprint

### Week 1: Build (product team handles this)

Product team scaffolds and builds the Flutter app with:
- MediaPipe BlazePose integration (33 landmarks, real-time)
- Joint angle analysis + compensation detection
- SBL/BFL/FFL chain reasoning rules
- Report generation with chain-level findings
- Web build deployed to a public URL

**GTM owner's week 1 tasks**:
- Draft README (see below)
- Prepare demo GIF/video (record as soon as overhead squat + chain reasoning works)
- Set up GitHub repo with good structure
- Write CONTRIBUTING.md (signals active project)
- Prepare social copy for all channels

### Week 2: Package for Virality

**Days 6-7: README that sells** (most important artifact — see README template below)

**Days 8-9: Supporting content**
- `/research` folder in repo with synthesis doc + market analysis (these are genuinely impressive and add credibility to the project)
- `/docs` with how the chain reasoning works (diagrams)
- Clean the pitch.md into a `/docs/science.md`
- Record a polished 30-60 second demo GIF for the README

**Day 10: Deploy live demo**
- Flutter web build to a public URL (GitHub Pages, Vercel, or Firebase Hosting)
- Critical: people star repos they can *try*, not just read about
- Demo must work on mobile browsers (most HN/Reddit traffic is mobile)

### Week 3: Launch Blitz

**Day 11 — Hacker News** (THE key moment)
- **Title**: "Show HN: Open-source tool that traces movement compensations to upstream drivers using fascial chain maps"
- **Post timing**: Tuesday or Wednesday, 8-9am ET (highest traffic)
- HN loves: novel technical approach + research backing + working demo + "first to do X"
- A front-page HN post can deliver 100+ stars in hours
- Include: 2-3 sentence description, link to live demo, link to repo
- Be active in comments — the biomechanics and health-tech crowd will have questions

**Day 11-12 — Reddit** (stagger by a few hours from HN)

| Subreddit | Angle |
|---|---|
| r/computervision | "Built a CV pipeline that goes beyond form correction to trace compensations to upstream drivers" |
| r/physiotherapy | "Open-source tool encoding regional interdependence reasoning — would love practitioner feedback" |
| r/bodyweightfitness | "Free movement screen that shows what's actually driving your compensations" |
| r/fitness | "5-minute phone screen that tells you why your knee collapses, not just that it does" |
| r/Python or r/FlutterDev | Technical angle on the architecture |
| r/SideProject | The capstone/builder narrative |

**Day 12-13 — Twitter/X thread**

Thread structure:
1. "We spent [X weeks] researching the $4.4B digital MSK market."
2. "Found that zero tools — not Hinge Health ($3B), not DARI Motion (FDA-cleared), not Sword Health ($4B) — do chain-level reasoning for movement screening."
3. "So we built one. It's open source and runs in your browser."
4. [Demo GIF]
5. "Here's why this matters: 50-72% of MSK treatments recur when only the pain site is treated. Address the upstream driver → recurrence drops to 6-8%."
6. "This reasoning is locked behind $150-2,000 practitioner visits. We made it free."
7. [Link to repo + live demo]

Tag: biomechanics researchers, PT influencers, sports science accounts, Anatomy Trains, relevant tech accounts.

**Day 13 — Product Hunt**
- Schedule launch for Wednesday or Thursday
- Category: Health & Fitness, Developer Tools
- Tagline: "AI movement screening with fascial chain intelligence"
- Maker comment: explain the "zero tools do this" finding

**Days 14-15 — Tail push**
- Email researchers you cited: "I cited your work in building this open-source tool — thought you'd find it interesting." (Wilke, Kalichman, Stecco team, Schleip)
- Anatomy Trains forums / community
- SFMA practitioner groups on Facebook
- Sports science Discord servers
- LinkedIn post targeting PT/sports science network
- Physiopedia / PT student communities

---

## Star Accumulation Model

| Channel | Expected Stars | Timing |
|---|---|---|
| Hacker News (front page) | 50-150 | Day 1 of launch |
| Hacker News (doesn't front page) | 10-30 | Day 1 |
| Reddit (across 4-5 subs) | 20-50 | Days 1-3 |
| Twitter/X thread | 10-30 | Days 1-5 |
| Product Hunt | 10-30 | Day 3 |
| Direct researcher emails | 5-15 | Days 3-7 |
| Niche communities | 5-15 | Days 5-7 |
| Organic tail (from all above) | 10-30 | Week 3 |

**Conservative (no HN front page)**: 70-170 stars across all channels
**If HN front pages**: 100+ from HN alone, 150-300 total

Spread across channels, 100 is reachable even without a single viral hit.

---

## Risk Mitigation

**Risk: HN doesn't front page**
- Mitigation: Reddit across 4-5 subreddits + Twitter + Product Hunt + direct outreach covers the gap. Don't depend on any single channel.

**Risk: Demo isn't ready by launch day**
- Mitigation: Launch with a compelling README + research docs + recorded demo video. Stars can come from the research and positioning alone — but a working demo doubles conversion.

**Risk: Low engagement in comments**
- Mitigation: Seed with 2-3 team members asking genuine questions. Be responsive in first 2 hours (critical for HN algorithm).

**Risk: "This is just heuristics, not real AI"**
- Response: "Exactly. The intelligence is in the rule system encoding expert fascial chain logic, not in a neural network. That's the point — it's interpretable, evidence-based, and auditable. The pitch.md explains why."

**Risk: "Fascial chains aren't proven"**
- Response: "We restrict to the 3 chains with strong anatomical evidence (Wilke 2016, confirmed by Kalichman 2025). We exclude chains with insufficient evidence. And our approach doesn't depend on long-range force transmission — we detect co-occurring movement patterns, regardless of mechanism."

---

## Dual Track: Stars + Revenue (Optional)

If pursuing both simultaneously:
- Add a "Get Full Report" flow to the web demo with Stripe ($4.99 one-time per report)
- Don't gate the core tool — the free version must be fully functional for stars
- Premium = PDF export + detailed citations + practitioner discussion guide
- Target: 50 reports sold from the same traffic that generates stars

This is secondary to stars. Don't let payment integration delay launch.

---

## What the README Must Do

The README is the single most important GTM asset. It must:

1. **Hook in 5 seconds**: Demo GIF + one-line value prop at the top
2. **Establish credibility in 30 seconds**: Competitive comparison table + research backing
3. **Let them try it in 60 seconds**: Live demo link + quick-start instructions
4. **Make them star it**: The combination of "this is novel" + "this actually works" + "I might use this"

See README.md for the actual implementation.
