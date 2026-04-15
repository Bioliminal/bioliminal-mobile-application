# Sensor Purchase Plan — Fastest Path to Proof

**Date:** 2026-04-09  
**Location:** Austin, TX  
**Goal:** Working EMG demo on erector spinae within 48 hours, full 4-channel prototype within 1 week  
**Strategy:** Buy all three sensor tiers simultaneously — something arrives every day, you never stop building

---

## The Three Sensors (Buy All Three)

### Tier 1: Generic EMG Clone — "Proof Tomorrow" ($15–25)
- **What:** Treedix / OUOParts EMG Muscle Sensor for Arduino
- **Why:** Cheapest, fastest to arrive, comes with cable + 3 electrodes included, Amazon Prime overnight
- **Signal quality:** Noisy but functional — enough to see muscle activation and fatigue trends
- **Setup:** Requires ±3.5V dual power supply (two 9V batteries or two 18650 cells), analog output to ESP32/Arduino
- **Buy link:** [Treedix EMG Sensor on Amazon](https://www.amazon.com/Treedix-Myoelectric-Electronic-Development-Compatible/dp/B0CK1P4NZ9)
- **Alt link:** [OUOParts EMG Sensor on Amazon](https://www.amazon.com/Controller-Detects-Activity-Development-Wearable/dp/B0DYY9L9H2)
- **Price:** ~$15–25
- **Delivery:** Amazon Prime — arrives tomorrow

### Tier 2: BioAmp EXG Pill × 4 — "Real Prototype" ($40)
- **What:** Upside Down Labs BioAmp EXG Pill, 4 boards for 4-channel prototype
- **Why:** $10/channel, pill-size (25mm × 10mm, <2g), open-source (CERN-OHL-S), publication-grade signal quality, embeds into compression garment
- **Signal quality:** ~5μV noise floor, comparable to clinical EMG when configured for EMG mode
- **Setup:** Requires soldering pin headers + solder jumper bridge for EMG band config. Analog output to ESP32 ADC
- **Buy link:** [BioAmp EXG Pill on DigiKey](https://www.digikey.com/short/7hzv5wb2)
- **Alt link:** [BioAmp EXG Pill on Crowd Supply](https://www.crowdsupply.com/upside-down-labs/bioamp-exg-pill)
- **Alt link:** [BioAmp on Tindie](https://www.tindie.com/products/upsidedownlabs/bioamp-exg-pill-x2-sensor-for-ecg-emg-eog-eeg/)
- **Price:** ~$40 for 4 boards (Explorer Pack × 2)
- **Delivery:** DigiKey with FedEx overnight — arrives Friday. Crowd Supply from Portland — 3–5 days

### Tier 3: MyoWare 2.0 — "Clean Demo" ($43.50)
- **What:** SparkFun MyoWare 2.0 Muscle Sensor (updated DEV-27924)
- **Why:** Zero soldering, snap-on electrodes directly onto board, three output modes (raw/rectified/envelope), adjustable gain knob, extensive Arduino tutorials, the sensor you show investors
- **Signal quality:** Best out-of-box experience, 25–450Hz bandwidth, envelope mode gives instant fatigue proxy
- **Setup:** Stick on electrodes, connect 3 wires (VIN, GND, SIG) to ESP32/Arduino, done
- **Buy link:** [MyoWare 2.0 on SparkFun](https://www.sparkfun.com/myoware-2-muscle-sensor.html)
- **Alt link:** [MyoWare on Adafruit](https://www.adafruit.com/product/2699)
- **Alt link:** [SparkFun MyoWare on Amazon](https://www.amazon.com/SparkFun-MyoWare-Muscle-Sensor-DEV-21265/dp/B0FXQPVDRG)
- **Price:** ~$43.50
- **Delivery:** SparkFun ships from Colorado — 2–3 days ground. Adafruit from NYC — 2–3 days. Amazon — check Prime eligibility

---

## Supporting Components (Order with Tier 1 on Amazon Prime)

| Item | Price | Amazon Link | Notes |
|------|-------|-------------|-------|
| ESP32-S3 DevKitC | ~$12 | [Search: ESP32-S3 DevKitC](https://www.amazon.com/s?k=ESP32-S3+DevKitC) | Or grab from Micro Center Austin today |
| Ag/AgCl Electrode Pads 50-pack | ~$8 | [Search: EMG electrodes snap 24mm](https://www.amazon.com/s?k=EMG+electrodes+disposable+snap+24mm) | Generic snap-mount, pre-gelled |
| Jumper Wires (M-M, M-F, F-F) | ~$5 | [Search: jumper wire kit Arduino](https://www.amazon.com/s?k=jumper+wire+kit+Arduino) | Get an assorted pack |
| Half-Size Breadboard | ~$3 | [Search: half size breadboard](https://www.amazon.com/s?k=half+size+breadboard) | For prototyping connections |
| 10mm Coin Vibration Motors (10-pack) | ~$6 | [Search: 10mm coin vibration motor](https://www.amazon.com/s?k=10mm+coin+vibration+motor) | Haptic feedback — use 4, keep 6 spares |
| 2N7002 N-Channel MOSFET (10-pack) | ~$2 | [Search: 2N7002 MOSFET](https://www.amazon.com/s?k=2N7002+MOSFET) | Drive vibration motors from ESP32 GPIO |
| 9V Battery Clip (2-pack) | ~$3 | [Search: 9V battery clip snap](https://www.amazon.com/s?k=9V+battery+clip+snap+connector) | Power for generic EMG clone (needs ±V) |
| 9V Batteries (2-pack) | ~$5 | [Search: 9V battery](https://www.amazon.com/s?k=9V+battery) | Dual supply for Tier 1 sensor |
| 800mAh LiPo + TP4056 Charger | ~$10 | [Search: 800mAh LiPo TP4056](https://www.amazon.com/s?k=800mAh+LiPo+3.7V+TP4056) | Powers ESP32 + BioAmp in garment |
| Compression Shirt (your size) | ~$15 | [Search: mens compression shirt](https://www.amazon.com/s?k=mens+compression+shirt) | The garment base |

**Amazon Prime subtotal: ~$69** (arrives tomorrow with Tier 1 sensor)

---

## Same-Day: Micro Center Austin

**Address:** 10900 Domain Dr, Austin, TX 78758  
**Hours:** 10am–9pm

Pick up if you want to start TODAY before Amazon arrives:
- ESP32 DevKit (~$10) — check online stock first
- Breadboard + jumper wires (~$8)
- Soldering iron + solder (~$25 if you don't own one)
- USB-C cable for ESP32

---

## Daily Timeline

### Day 0 — TODAY (Wednesday)
**Orders placed:**
- Amazon Prime: Tier 1 EMG clone + all supporting components (~$84 total)
- DigiKey: BioAmp EXG Pill × 4 with FedEx overnight (~$55 total with shipping)
- SparkFun: MyoWare 2.0 with standard shipping (~$48 total with shipping)

**If you go to Micro Center:** Grab ESP32, breadboard, wires. Start writing Arduino/ESP32 code tonight:
- `analogRead()` loop for EMG signal
- Serial plotter output
- BLE streaming to phone
- Vibration motor test (GPIO → MOSFET → motor)

**Total Day 0 spend: ~$187** (all three tiers + all supporting components + shipping)

### Day 1 — TOMORROW (Thursday)
**Arrives:** Amazon Prime — Tier 1 EMG clone + ESP32 + electrodes + everything else

**Do this:**
1. Wire generic EMG sensor to ESP32 (3 wires: +V, -V, SIG → analog pin)
2. Stick electrodes on your erector spinae (lower back, 2–3cm lateral to L3)
3. Open Arduino Serial Plotter
4. Do bodyweight good-mornings or light deadlifts
5. Watch the signal rise and fall with each rep
6. Do a set to near-fatigue — watch the RMS amplitude climb as you fatigue
7. **That graph is your proof of concept.** Screenshot it. Send it to your partner.

**What this proves:** "We can read muscle activation from the erector spinae through surface electrodes. The signal visibly changes as fatigue accumulates."

### Day 2 — FRIDAY
**Arrives:** BioAmp EXG Pill × 4 from DigiKey (overnight)

**Do this:**
1. Solder pin headers onto BioAmp boards
2. Bridge the solder jumper for EMG mode (by default it's configured for EEG/EOG)
3. Wire all 4 to ESP32 ADC pins
4. Test each channel individually on: left erector spinae, right erector spinae, vastus lateralis, vastus medialis
5. Compare signal quality to the generic clone from yesterday
6. Start BLE streaming to phone

**What this proves:** "We can get 4-channel EMG data simultaneously. BioAmp signal quality is good enough for fatigue detection through compression fabric."

### Day 3–4 — WEEKEND
**Build the garment:**
1. Sew electrode pockets into compression shirt (lower back) and shorts (front thigh)
2. Wire BioAmp boards into garment with flat ribbon cable
3. Create waist hub pocket for ESP32 + battery
4. Mount vibration motors at each sensor location
5. Test full system: put on garment → connect to phone → do squats and deadlifts

**What this proves:** "The full closed loop works: sense → stream → see → cue."

### Day 5 — MONDAY/TUESDAY
**Arrives:** MyoWare 2.0 from SparkFun

**Do this:**
1. Snap on electrodes (zero soldering)
2. Side-by-side comparison with BioAmp on same muscle
3. Record clean demo video: MyoWare on erector spinae during deadlifts, showing fatigue signal on screen, vibration motor firing at threshold
4. This is the demo you show people

**What this proves:** "Here's a polished 60-second video of the product concept working on a real person doing real deadlifts."

---

## Cost Summary

| Tier | Item | Price | Source | Arrives |
|------|------|-------|--------|---------|
| 1 | Generic EMG clone | ~$20 | Amazon Prime | Tomorrow |
| 2 | BioAmp EXG Pill × 4 | ~$55 (w/ overnight ship) | DigiKey | Friday |
| 3 | MyoWare 2.0 | ~$48 (w/ shipping) | SparkFun | Mon–Tue |
| — | ESP32-S3 DevKitC | ~$12 | Amazon Prime | Tomorrow |
| — | Electrodes, wires, breadboard, batteries | ~$26 | Amazon Prime | Tomorrow |
| — | Vibration motors + MOSFETs | ~$8 | Amazon Prime | Tomorrow |
| — | LiPo + charger | ~$10 | Amazon Prime | Tomorrow |
| — | Compression shirt | ~$15 | Amazon Prime | Tomorrow |
| | **Total** | **~$194** | | |

You get a working proof of concept for under $200, with sensors arriving every day so you never stop building.

---

## What Each Sensor Is For (Long Term)

| Sensor | Role | Keep or Replace |
|--------|------|----------------|
| Generic EMG clone | Quick proof, first signal ever | **Replace** — too noisy and bulky for garment |
| BioAmp EXG Pill × 4 | Production prototype sensor | **Keep** — this is what goes in the compression shirt |
| MyoWare 2.0 | Demo sensor, investor presentations | **Keep** — the "show people" sensor when you need it to just work |
