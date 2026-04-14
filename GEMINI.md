# Bioliminal Project Documentation

Bioliminal is a clinical-grade movement screening application that merges computer vision with real-time sEMG biopotential sensing to detect biomechanical compensations and provide immediate corrective biofeedback.

## Project Architecture

The project follows a feature-first structure with a high-fidelity data pipeline bridging on-device sensing and server-side clinical analysis.

### Directory Structure

- `lib/core/`: Global configurations and cross-cutting services.
  - `services/hardware_controller.dart`: Manages BLE communication with the ESP32-S3 Hub.
  - `services/biofeedback_engine.dart`: Real-time coordination ratio analysis (Premium).
  - `services/bioliminal_client.dart`: HTTP client for clinical server uploads and report fetching.
- `lib/domain/`: Core business logic and data models aligned with clinical schemas.
  - `models.dart`: Includes `SessionPayload`, `PoseFrame`, and `EMGData`.
- `lib/features/`: UI and state management grouped by feature.
  - `camera/`: 33-landmark ML Kit integration and real-time sEMG sidebars.
  - `screening/`: Clinical movement screening flow (Overhead Squat, SLS, Push-up, Rollup).
  - `report/`: Post-session clinical kinetics and muscle activation summaries.

## Key Implementation Details

### High-Fidelity Capture Pipeline
The app uses a dual-stream data fusion model:
1. **Vision:** MediaPipe BlazePose Full captures 33 landmarks at 30+ FPS via a "busy flag" pattern.
2. **Sensing:** ESP32-S3 Hub streams 10 channels of sEMG data over BLE at high frequency.

### Hardware Setup & Calibration
To ensure clinical data integrity, the app includes a dedicated setup flow:
- **Anatomical Placement:** The `PlacementGhostSkeleton` uses pulsing targets to guide the user to 10 specific lower-body electrode sites.
- **Lead Verification:** `SignalLED` widgets monitor real-time voltage levels to detect "Leads Off" or signal saturation before screening begins.
- **Time Synchronization:** The `SyncCalibrationService` identifies a "Sync Stomp" peak in both vision (ankle acceleration) and sensing (calf spike) to calculate a sub-10ms `sync_offset` applied to all captured frames.

### Premium Biofeedback Loop
The "Premium" tier unlocks the immediate physical correction layer:
- **Calculation:** The app monitors the **Gastrocnemius:Soleus** ratio in real-time during squats.
- **Cues:** If coordination drift is detected (e.g., Gastroc dominance), the app sends corrective commands (vibrate/squeeze) back to the hardware hub.
- **Visualization:** Anatomical Heatmapping allows the skeleton overlay limb segments to glow based on live muscle firing.

### Privacy-First Persistence
- **Local Video:** Raw camera frames are never transmitted. Inference happens entirely on-device.
- **Anonymized Data:** Only landmark coordinates and relative activation levels are sent to the clinical server.
- **Offline Fallback:** `LocalStorageService` uses an in-memory fallback for web demos and secure local JSON storage for mobile.
