# AuraLink Hardware Buy List — Final Revision

**Date:** April 8, 2026 | **Budget:** ~$745 | **Location:** Austin, TX

---

## Card Limits

| Card | Limit |
|---|---|
| Rajiv | $215.52 |
| Rajat | $200 |
| Kelsi | $80 |
| Aaron | $100 |
| Leo | $150 |
| **Total** | **$745.52** |

---

## 🏫 FREE from UT Austin — Don't Buy These

These items are available at no cost through UT campus resources. Use them instead of buying.

| Item | Where | Details | Savings |
|---|---|---|---|
| **Soldering stations + solder** | Texas Inventionworks (EER 0.618) | 8 stations in Electronics Lab 1. Check out kits from The Garage. | ~$25 (Rajat already owns one too) |
| **3D printing (PETG, PLA, resin)** | TIW DFAB Lab (EER 0.602) OR Hello Maker (Welch Hall) | Free filament for UT students. Pod housings, harness clips, snap mounts. | ~$20 |
| **Sewing machines** | TIW DFAB Lab OR Hello Maker | For textile garment prototype — sewing conductive fabric into compression shirt. | ~$15 |
| **Laser cutter** | TIW Laser Lab (EER 0.602) | Cut neoprene strap padding, acrylic pod enclosures. Way cleaner than hand cutting. | — |
| **Oscilloscope + bench power supply** | TIW Electronics Lab 1 | Critical for debugging sEMG signal chain. Don't buy one. | ~$200+ avoided |
| **Heat shrink tubing** | TIW Electronics Lab | Available in The Garage supplies. | ~$5 |
| **Wire strippers, multimeter, hand tools** | TIW The Garage (EER 0.618) | Full checkout system for hand tools. | ~$20 |

**Total savings: ~$285+ in avoided purchases**

> **Access requirements:** All UT students can use TIW and Hello Maker. Most equipment requires a quick online training + in-person demo. TIW is open Mon–Fri 10am–6pm. **Do the 3D printer and soldering training ASAP** — someone on the team should knock these out tomorrow.

---

## 🔬 TRY TO BORROW — Cold Email These Labs This Week

This is the highest-ROI move you can make. A few hours with a research-grade Delsys system would let you validate electrode placements against gold-standard data and potentially skip buying the ADS1292R entirely.

| Lab | PI / Contact | What They Have | What to Ask For |
|---|---|---|---|
| **KHE Neuromuscular Control Lab** | Dr. Lisa Griffin (512-471-1273, KHE main office) | Multichannel surface EMG + intramuscular EMG | 2–3 hours of bench time with their sEMG system to validate electrode placements during compound lifts |
| **Clinical Biomechanics & Mobility Lab** | Dr. Hsiao-Wecksler | Surface EMG, force plates, motion capture | Same ask — frame it as interdisciplinary collaboration |
| **ReNeu Robotics Lab (ME Dept)** | Dr. Ashish Deshpande | Builds rehab wearables — closest to your project | Bench time + potential mentorship. They may have spare OpenBCI or similar boards. |
| **Human Locomotion Lab (ME Dept)** | Dr. Richard Neptune | Biomechanics + EMG during movement | Gold-standard EMG data for your target muscles during squats/deadlifts |

**Email template:** "We're a 5-person UT team building a closed-loop sEMG wearable for injury prevention during weightlifting. We have our own prototype hardware arriving this week and would love 2–3 hours of bench time with your EMG system to validate our electrode placements against a gold standard. Happy to share our data and results. Would any time this week or next work?"

> **If you get lab access:** You can potentially **skip the ADS1292R purchase ($50)** and **defer the Cerelog decision** entirely. The lab's Delsys data becomes your reference signal to benchmark your AD8232s against.

---

## 🏪 Local Austin Pickup — Same Day

| Store | Address | What to Get There | Why |
|---|---|---|---|
| **Elliott Electronic Supply** | Austin, TX (call for stock) | Basic components: resistors, capacitors, wire, connectors. May have AD8232 or similar breakouts. | Walk-in, no minimum order. Call first to check stock on specific ICs. |
| **ATX Hackerspace** | Austin, TX | $75/month membership gets access to laser cutter, 3D printers, CNC mill, electronics bench. | Backup workspace if UT labs are booked. Also a good place to network with hardware folks who may have sEMG gear. |
| **CVS / Walgreens / HEB** | Everywhere | Ag/AgCl ECG electrodes (sold as cardiac monitoring pads), medical tape, isopropyl alcohol, razors | Faster than Amazon for skin prep consumables. Check the medical supplies aisle. |
| **Amazon Locker** | Various Austin locations | Everything on the Amazon buy list | Same-day or next-day pickup, no porch theft risk |

### Mouser Will-Call (Mansfield, TX)

Mouser has a will-call counter at 1000 N Main St, Mansfield, TX 76063. You can place an order online and pick it up in about an hour. It's a ~3 hour round trip from Austin, so only worth it if you need a critical-path component (like the BioAmp or ADS1292R) and can't wait for shipping. Open Mon–Fri 7am–8pm.

**When to drive to Mansfield:** Only if (a) Cerelog is sold out, AND (b) Mouser has BioAmp EXG Pill in US warehouse stock, AND (c) you need research-grade sensors before Monday. Otherwise, overnight shipping from Mansfield arrives next day anyway.

> ⚠️ **Micro Center Austin is NOT open yet.** It's slated for mid-to-late 2026 grand opening. Don't plan around it.

---

## WAVE 1: Order NOW — Amazon Next-Day (Wed Apr 9)

| Item | Qty | Unit $ | Total | Card | Purpose |
|---|---|---|---|---|---|
| **sEMG Sensors** | | | | | |
| AD8232 ECG/EMG module (generic) | 10 | $7 | $70 | Leo | Full 10ch placement testing Day 1 |
| ADS1115 16-bit ADC breakout | 5 | $3 | $15 | Leo | External ADC for AD8232s |
| **MCU** | | | | | |
| ESP32-S3 DevKitC-1 (N16R8) | 2 | $10 | $20 | Rajiv | Vest MCU + spare |
| **Electrodes & Skin Prep** | | | | | |
| Ag/AgCl snap electrodes 100-pack | 3 | $8 | $24 | Kelsi | 300 electrodes for testing |
| Ten20 conductive paste 4oz | 1 | $12 | $12 | Kelsi | Electrode-skin interface |
| NuPrep skin prep gel 4oz | 1 | $8 | $8 | Kelsi | Abrasive prep |
| 3M Transpore medical tape 1" ×2 | 1 | $5 | $5 | Kelsi | Wire management |
| Coban self-adhering wrap 2" | 2 | $3 | $6 | Kelsi | Overwrap for wire runs |
| Disposable razors 10-pack | 1 | $5 | $5 | Kelsi | Hair removal at electrode sites |
| Isopropyl alcohol 70% 16oz | 1 | $3 | $3 | Kelsi | Skin cleaning |
| Skin-safe marker (surgical) | 2 | $3 | $6 | Kelsi | Mark validated positions |
| **Cueing (Vibrotactile)** | | | | | |
| ERM coin vibe motors 10mm, 10-pack | 2 | $7 | $14 | Rajiv | 20 motors for cueing |
| **Power** | | | | | |
| 1200mAh LiPo 3.7V (JST-PH 2.0) | 3 | $5 | $15 | Aaron | Vest power + spares |
| TP4056 USB-C LiPo charger module | 3 | $1.50 | $5 | Aaron | Charging |
| **Wiring** | | | | | |
| 30AWG silicone wire kit (6 colors) | 1 | $8 | $8 | Rajiv | Signal wiring |
| Shielded cable 4-conductor 30AWG 5m | 2 | $8 | $16 | Rajiv | sEMG signal runs |
| Mini breadboard 400-point | 4 | $2.50 | $10 | Aaron | Prototyping |
| Jumper wire kit (M-M, M-F, F-F) | 1 | $7 | $7 | Aaron | Prototyping |
| **Harness Build** | | | | | |
| Elastic webbing 1" + buckles 10-pack | 1 | $12 | $12 | Rajiv | Harness straps |
| Velcro adhesive hook+loop 1" × 5yd | 1 | $6 | $6 | Rajiv | Pod mounting |
| Neoprene fabric 2mm 12"×24" | 1 | $8 | $8 | Rajiv | Strap padding |
| Snap button kit (press studs, 100pc) | 1 | $6 | $6 | Aaron | Electrode-to-pod connections |
| **Textile Garment Prototype** | | | | | |
| Compression shirts (athletic, M+L) | 2 | $10 | $20 | Aaron | Base garment |
| Adafruit conductive fabric 20×20cm | 2 | $5 | $10 | Rajiv | Textile electrode patches |
| 12mm snap connector kit | 1 | $10 | $10 | Leo | Snap-connect textile electrodes |
| Conductive thread (silver-coated, 50ft) | 1 | $12 | $12 | Rajiv | Traces between patches |
| | | | | | |
| **WAVE 1 SUBTOTAL** | | | **~$353** | | |

### Wave 1 Card Split

| Card | Items | Subtotal | Remaining |
|---|---|---|---|
| Leo | AD8232 ×10, ADS1115 ×5, snap connectors | $95 | $55 |
| Rajiv | ESP32, vibes, wire, shielded cable, elastic, velcro, neoprene, conductive fabric, thread | $106 | $110 |
| Kelsi | All electrodes & skin prep | $69 | $11 |
| Aaron | LiPo, TP4056, breadboards, jumpers, snaps, shirts | $63 | $37 |
| Rajat | — (saving for Wave 2) | $0 | $200 |

---

## WAVE 2: Order NOW — Mouser / SparkFun (2–5 day delivery)

| Item | Qty | Unit $ | Total | Source | Card | Purpose |
|---|---|---|---|---|---|---|
| **Research-Grade sEMG** | | | | | | |
| ADS1292R breakout (2ch, 24-bit) | 2 | $25 | $50 | SparkFun / Mouser | Rajat | 4ch research-grade: erector spinae L/R + upper trap L/R |
| BioAmp EXG Pill 2-pack | 1 | $65 | $65 | Mouser (check US stock!) | Rajat | Head-to-head eval vs AD8232 |
| **TSA Cueing** | | | | | | |
| DRV8833 dual H-bridge driver | 4 | $2 | $8 | Mouser | Rajiv | TSA + vibe motor control |
| N20 gearmotor 6V 100RPM | 4 | $3 | $12 | Mouser | Leo | TSA squeeze actuators |
| INA219 current sensor breakout | 2 | $2 | $4 | Mouser | Leo | TSA force proxy |
| SS49E linear hall sensor | 4 | $1 | $4 | Mouser | Leo | TSA position feedback |
| Dyneema braided line 50lb 25m | 1 | $8 | $8 | Amazon 2-day | Aaron | TSA string |
| PTFE tubing 1.5mm ID, 5m | 1 | $5 | $5 | Amazon 2-day | Aaron | TSA Bowden routing |
| | | | | | | |
| **WAVE 2 SUBTOTAL** | | | **~$156** | | | |

### Wave 2 Card Split

| Card | Items | Subtotal | Cumulative | Remaining |
|---|---|---|---|---|
| Rajat | ADS1292R ×2, BioAmp 2-pack | $115 | $115 | $85 |
| Rajiv | DRV8833 ×4 | $8 | $114 | $102 |
| Leo | N20 motors, INA219, SS49E | $20 | $115 | $35 |
| Aaron | Dyneema, PTFE | $13 | $76 | $24 |

---

## WAVE 3: Reserve — Data-Driven Purchases (Days 4–6)

**Remaining budget: ~$257 across all cards**

| Item | Price | Source | Card (remaining) | Trigger |
|---|---|---|---|---|
| Cerelog ESP-EEG (ADS1299, 8ch) | $362 | cerelog.com | **Needs card split — no single card fits** | AD8232 + ADS1292R confirmed insufficient for MDF fatigue |
| *OR* ADS1292R ×3 more (6 more ch) | $75 | SparkFun | Rajat ($85) | Need more research-grade channels |
| DRV2605L + LRA haptic driver | $32 | SparkFun | Leo ($35) | Coin vibes can't be localized on torso |
| nRF52840 DK | $40 | Mouser | Rajiv ($102) | ESP32 BLE can't handle 10ch × 500Hz |
| LessEMF A321 silver Lycra | $35 | LessEMF | Rajiv ($102) | Want higher-quality textile electrodes |
| Extra Ag/AgCl electrodes 100-pack ×2 | $16 | Amazon | Kelsi ($11) + Aaron ($5) | Burning through faster than expected |
| Pod housings | FREE | **UT TIW 3D printers** | — | Always — print at TIW, don't buy filament |

> **Cerelog note:** At $362, it exceeds any single remaining card balance. If you need it: (a) Rajat ($85) + Rajiv ($102) + Leo ($35) + Aaron ($24) = $246 — still $116 short. You'd need someone to front and get reimbursed. **(b) Better alternative:** Buy 3 more ADS1292R boards ($75) for 10 total channels of 24-bit data. Fits on Rajat's card. Less elegant than Cerelog but same signal quality per channel.

---

## Budget Summary

| Wave | Spend | Status |
|---|---|---|
| Wave 1: Amazon (tonight) | ~$353 | Order tonight |
| Wave 2: Mouser / SparkFun (tonight) | ~$156 | Order tonight |
| **Day 0 total commit** | **~$509** | Well within $745 |
| UT Austin free resources | ~$285+ saved | Use starting tomorrow |
| Wave 3 reserve | ~$237 available | Data-driven |

### Per-Card Totals

| Card | Limit | W1 | W2 | Total | Remaining for W3 |
|---|---|---|---|---|---|
| Rajiv | $215.52 | $106 | $8 | $114 | $102 |
| Rajat | $200 | $0 | $115 | $115 | $85 |
| Kelsi | $80 | $69 | $0 | $69 | $11 |
| Aaron | $100 | $63 | $13 | $76 | $24 |
| Leo | $150 | $95 | $20 | $115 | $35 |
| **Total** | **$745.52** | **$333** | **$156** | **$489** | **$257** |

---

## Action Items — Tonight + Tomorrow

### Tonight (Tue Apr 8)
1. ☐ **Check Mouser** for BioAmp EXG Pill (BIOAMPEXGP-01) — US warehouse stock?
2. ☐ **Check Amazon** for AD8232 ×10, ADS1115 ×5 — confirm next-day to Austin
3. ☐ **Check SparkFun** for ADS1292R breakout — stock + shipping time
4. ☐ **Check cerelog.com** — is ESP-EEG still in stock? (Wave 3 option, not buying tonight, but good to know)
5. ☐ **Place Wave 1 Amazon orders** across Leo, Rajiv, Kelsi, Aaron cards
6. ☐ **Place Wave 2 Mouser/SparkFun orders** on Rajat, Rajiv, Leo, Aaron cards

### Tomorrow Morning (Wed Apr 9)
7. ☐ **Send cold emails** to KHE Neuromuscular Lab, ReNeu Lab, Neptune Lab, Clinical Biomechanics Lab
8. ☐ **One person: complete TIW training** for 3D printers + soldering (online quiz + in-person demo)
9. ☐ **One person: complete Hello Maker training** as backup makerspace
10. ☐ **Check CVS/HEB** for Ag/AgCl ECG electrodes if Amazon delivery is delayed
11. ☐ **Amazon arrives** — start electrode placement testing immediately

### Day 3 Decision Point (Fri Apr 11)
12. ☐ AD8232 signal quality verdict — good enough for demo? For MDF fatigue analysis?
13. ☐ Lab access response — did any UT lab say yes?
14. ☐ Wave 3 purchase decision based on data

---

## What Changed vs. Previous Version

| Change | Why | Impact |
|---|---|---|
| Removed soldering supplies from buy list | Rajat owns iron + TIW has stations | -$25 |
| Removed 3D printer filament | TIW + Hello Maker provide free | -$20 |
| Removed oscilloscope from consideration | TIW Electronics Lab has them | -$200+ avoided |
| Added UT lab outreach for Delsys EMG access | Gold-standard reference data for free | Could save $50–362 on research-grade sensors |
| Added local Austin pickup options | CVS for consumables, Elliott for components | Faster than Amazon for emergency restocks |
| Added Mouser will-call option | 1hr pickup if critical-path component needed | ~3hr round trip — last resort only |
| Noted Micro Center Austin NOT open yet | Opens mid-to-late 2026 | Don't plan around it |
| Added ATX Hackerspace as backup workspace | $75/month, laser cutter + CNC + electronics | Alternative if UT labs are booked |
