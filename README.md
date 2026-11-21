<div align="center">

# 🎧 AirPodsIQ: AirPods Max Potential

**The Ultimate Biomechanical, Spatial Audio & Neural Posture OS for macOS.**  
*Leveraging 60Hz 6-DOF IMU Telemetry, On-Device Neural Classification, and 3D Audio Anchors from AirPods Pro 2 & AirPods Max.*

[![Platform](https://img.shields.io/badge/Platform-macOS%2014.0%2B%20%7C%20Apple%20Silicon-black?logo=apple&style=for-the-badge)](https://apple.com)
[![Hardware](https://img.shields.io/badge/Hardware-AirPods%20Pro%202%20%7C%20AirPods%20Max-0071e3?logo=apple&style=for-the-badge)](https://apple.com/airpods)
[![Swift](https://img.shields.io/badge/Swift-6.0-F05138?logo=swift&style=for-the-badge)](https://swift.org)
[![License](https://img.shields.io/badge/License-MIT-success?style=for-the-badge)](LICENSE)

</div>

---

## ⚡️ Why Existing AirPods Posture Apps Fail

Existing competitors (*PosturePal, AirPosture, BackTrack*) are built on flawed assumptions that break on modern macOS:

1. **The H2 Standby & TCC Crash:**
   - On macOS Sonoma and Sequoia, unsigned binaries or apps without sealed `NSMotionUsageDescription` trigger instant `__TCC_CRASHING_DUE_TO_PRIVACY_VIOLATION__`.
   - Apple's H2 chip automatically enters low-power sleep when macOS routes audio output to internal speakers. Competitor apps fail silently with 0 packets/sec.
2. **Gimbal Lock Disasters:**
   - Competitors calculate raw Euler angles ($\text{pitch}/\text{roll}$), flipping violently whenever your head turns past $\pm 90^\circ$.
3. **Audio Beeps in Meetings:**
   - Competitors ring harsh alert beeps directly into your ear while you are speaking during Zoom, Microsoft Teams, or Google Meet calls.

---

## 🛡️ The AirPodsIQ Solution

```
┌────────────────────────────────────────────────────────────────────────┐
│                   AirPodsIQ Kinematic Pipeline                         │
│                                                                        │
│   AirPods Pro 2 / Max (H2 Engine)                                      │
│             │                                                          │
│             ▼ (60Hz Bluetooth Stream)                                  │
│   ┌─────────────────────────────────────────────────────────┐          │
│   │ Dual-Pipeline Ingestion:                                │          │
│   │ 1. Direct CMHeadphoneMotionManager                      │          │
│   │ 2. Localhost 127.0.0.1:4243 Low-Latency UDP Loopback    │          │
│   └────────────────────────┬────────────────────────────────┘          │
│                            │                                           │
│                            ▼                                           │
│   ┌─────────────────────────────────────────────────────────┐          │
│   │ 4D SIMD Quaternion Matrix Decomposition Engine:         │          │
│   │ q_rel = normalize(q_baseline⁻¹ ⊗ q_current)             │          │
│   │ Continuous Slerp Auto-Drift Correction                  │          │
│   └────────────────────────┬────────────────────────────────┘          │
│                            │                                           │
│         ┌──────────────────┼──────────────────┐                        │
│         ▼                  ▼                  ▼                        │
│  [Neural Pose]       [3D Spatial Anchor]  [Silent Biofeedback]         │
│  On-Device CoreML    (0, 0, -2m) Sound    Screen Glow / Notch HUD      │
│  Pose Classification Virtual Beacon       Low-Pass Audio Muffle        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Innovations & Upgrades

### 1. 🧠 On-Device Neural Pose Classifier (`NeuralPoseClassifier.swift`)
Multi-dimensional classification running at $<1\text{ms}$ latency:
- **Optimal Upright Alignment**
- **Tech-Neck / Cervical Flexion**
- **Lateral Shoulder Pinch** (phone between ear & shoulder)
- **Multi-Monitor Cervical Asymmetry**
- **Hydration Ingestion Signature**

### 2. 🎯 Spatial Audio 3D Acoustic Anchor (`Spatial3DAnchorManager.swift`)
Anchors a continuous, subtle binaural sound source in virtual 3D room coordinates strictly at $(0, 0, -2\text{m})$. If your head drifts forward or rotates, your vestibular system naturally guides you back to center without intrusive beeps.

### 3. 🩺 Clinical Cervical Range-of-Motion (ROM) Diagnostic (`CervicalROMDiagnostic.swift`)
6-stage guided clinical assessment measuring:
- Flexion ($50^\circ$) & Extension ($60^\circ$)
- Left/Right Lateral Flexion ($45^\circ$)
- Left/Right Axial Rotation ($75^\circ$)  
Calculates your mobility ratio and estimates your **Biological Cervical Spine Age**.

### 4. 🎮 Cervical Flight: Neck ROM Warmup Game (`CervicalGameEngine.swift`)
Interactive 60-second warmup game: gently tilt your head up and down to fly through posture pillars, warming up the suboccipital and splenius capitis muscles.

### 5. 🪟 Cervical Window Snapper (`WindowSnapManager.swift`)
Snap windows left or right on macOS simply by tilting your head by $24^\circ$. Nod upward to maximize.

### 6. 💧 Biomechanical Hydration Sip Tracker (`HydrationTracker.swift`)
Recognizes the exact kinematics of drinking water (backwards pitch $+22^\circ\text{ to }+58^\circ$, held $>2.2\text{s}$) to count daily fluid volume automatically.

### 7. 💓 Micro-Pulse Ballistocardiogram Estimator (`AcousticPulseEstimator.swift`)
Measures the microscopic ballistic recoil of the carotid artery in resting AirPods Pro 2 accelerometer readings to estimate resting pulse (BPM).

### 8. 🎙️ Vocal Cord Strain Guard (`VocalStrainCoach.swift`)
Monitors microphone hardware status during calls; alerts you if speaking with forward cervical neck posture to protect the laryngeal muscles.

### 9. 📈 Live Menu Bar Waveform Sparkline (`MenuBarSparklineRenderer.swift`)
Draws a rolling 30-minute mini sparkline curve directly in your macOS menu bar next to your battery.

### 10. ⚡️ Raycast & Shortcuts Deep-Link Integration (`RaycastIntegrationManager.swift`)
Supports native URL schemes:
- `open airpodsposture://calibrate`
- `open airpodsposture://toggle-anchor`
- `open airpodsposture://start-pomodoro`

---

## 🛠️ Quick Installation

### Option 1: Terminal One-Liner
```bash
curl -fsSL https://raw.githubusercontent.com/archiboltmusk/AirPods-Max-Potential/main/build_app.sh | bash
```

### Option 2: Clone & Build
```bash
git clone https://github.com/archiboltmusk/AirPods-Max-Potential.git
cd AirPods-Max-Potential
chmod +x build_app.sh
./build_app.sh
open AirPodsPosture.app
```

---

## 📜 License
Released under the **MIT License**. Crafted with precision for macOS Power Users.
