# AirPods Max Potential (AirPodsIQ)

> **Transform your Apple AirPods Max and AirPods Pro into an active ergonomic posture coach, hands-free gesture controller, and health intelligence monitor on macOS.**

---

## 💡 Overview

AirPods Max and AirPods Pro are far more than high-fidelity headphones—they contain high-precision **6-axis Inertial Measurement Units (IMUs)** featuring tri-axial accelerometers and gyroscopes capable of streaming continuous 60Hz spatial motion data via Apple's `CoreMotion` framework (`CMHeadphoneMotionManager`).

**AirPodsIQ** is a native macOS application built with **SwiftUI** and **AppKit** that harnesses this hardware to actively track your cervical posture, prevent "text neck" and slouching, guide you through interactive physical therapy neck stretches, and recognize hands-free head gestures.

---

## 🚀 Key Implemented Features

### 1. Active 3D Posture & Slouch Guard
- **Continuous 60Hz Kinematic Tracking**: Reads real-time `pitch` (forward/backward slouch), `roll` (lateral head tilt), and `yaw` (rotation).
- **Personalized 1-Click Calibration**: Calibrates your unique baseline upright posture when sitting naturally at your desk.
- **Dynamic 3D Visualizer**: Features an interactive 2.5D/3D avatar wearing AirPods Max that rotates and mimics your head orientation in real-time.
- **Configurable Slouch Guard**:
  - Pitch sensitivity threshold (default: $12^\circ$)
  - Roll lateral tilt threshold (default: $10^\circ$)
  - Grace period buffer ($1.0 - 10.0\text{s}$) to avoid false alarms when taking a sip of water or glancing down briefly.
- **Audio & Visual Alerts**: Customizable system sound chimes and macOS status indicators when slouching persists.
- **Demo / Simulation Mode**: Built-in interactive sliders to test and visualize head movements without requiring connected headphones.

### 2. Interactive Guided Neck Mobility Coach
- Real-time physical therapy routine designed to reset cervical spine compression:
  1. **Ceiling Gaze (Extension)**: Counteracts hunchback slouch by guiding you to $+20^\circ$ pitch.
  2. **Chin Tuck (Flexion)**: Relieves upper cervical and suboccipital tension.
  3. **Left/Right Lateral Flexion**: Relieves trapezius and levator scapulae strain.
  4. **Cervical Rotation**: Restores full range of motion.
- **Real-Time Hold Verification**: Monitors whether your head is in the target angle zone and counts down hold duration before automatically progressing.

### 3. Hands-Free Head Gesture Recognition
- **Nod Detection ("Yes")**: Recognizes vertical head nod oscillations for hands-free actions (e.g., acknowledging an alert or unmuting).
- **Shake Detection ("No")**: Recognizes horizontal head shake oscillations (e.g., silencing a notification or skipping tracks).

### 4. macOS Menu Bar Extra Integration
- Runs unobtrusively in your macOS Menu Bar with a live status glyph (🟢 Optimal, 🟡 Drifting, 🔴 Slouching).
- Quick popup view with posture score, quick calibration, pause/resume, and one-click access to the full dashboard.

---

## 🔮 10 Ideas & Architectural Blueprints to Maximize AirPods Potential

Beyond posture tracking, here is a breakdown of 10 high-value features leveraging AirPods sensors on macOS:

| # | Feature | Category | Hardware / APIs | Implementation Architecture |
|---|---|---|---|---|
| **1** | **Spatial Audio Posture Biofeedback** | Ergonomics / Audio | `AVAudioEngine`, `AVAudioEnvironmentNode` | Instead of intrusive alert beeps, audio subtly rolls off high frequencies (low-pass filter from 20kHz down to 8kHz) and lowers HRTF elevation when you slouch, creating natural, subconscious biofeedback that encourages you to sit upright. |
| **2** | **Dual-Monitor Cervical Asymmetry Guard** | Ergonomics | `CMHeadphoneMotionManager.attitude.yaw` | Power users with dual monitors often turn their head $30^\circ$ to the side for hours. By calculating rolling yaw distributions over 45-minute windows, the app detects asymmetric cervical strain and reminds you to center active windows. |
| **3** | **Walk-Away Mac Screen Auto-Lock** | Security | `CMHeadphoneMotionManagerDelegate`, `CoreAudio` | Detects when AirPods are taken off the head (`didDisconnect` / audio route changes) and instantly executes `SACLockScreenImmediate()` to lock your Mac the moment you step away from your desk. |
| **4** | **Restlessness & Cognitive Fatigue Index** | Focus / Health | `CMRotationRate` (Gyro variance) | Samples micro-head jitter and rotation rate variance. High stability indicates deep focus/reading; erratic bursts of small head movements signal physical fidgeting or cognitive fatigue, triggering an ergonomic micro-break prompt. |
| **5** | **Sit / Stand Desk Cadence Detection** | Fitness | `CMAcceleration.z` (Vertical axis) | Detects whether you are sitting or standing at your motorized standing desk by analyzing subtle vertical weight shifts and micro-bobbing, tracking standing desk hours without needing an Apple Watch. |
| **6** | **Spatial Head Pointer (Hands-Free Mac Navigation)** | Accessibility | `CGEventCreateMouseEvent`, `CMDeviceMotion` | Translates yaw and pitch into low-latency mouse cursor movement with velocity smoothing and dwell-click / nod-click for hands-free navigation. |
| **7** | **Real-Time Hearing Safety & Sound Exposure** | Health | CoreAudio HAL, `AVAudioSession` | Tracks cumulative decibel exposure (dBA) over daily sessions according to World Health Organization (WHO) safe listening guidelines (e.g. 80 dBA for max 40 hrs/week). |
| **8** | **Automatic Meeting Transparency Switching** | Productivity | `SFSpeechRecognizer` / Mic input level | Switches AirPods from Active Noise Cancellation (ANC) to Transparency mode automatically when your voice or someone speaking directly to you is detected. |
| **9** | **Focus Shield (Calendar-Driven Smart ANC)** | Focus | `EventKit`, AppleScript / Bluetooth | Automatically activates Maximum ANC when a calendar event marked "Deep Work" starts, and switches to Adaptive/Transparency between meetings. |
| **10** | **Resonance Breathing & Heart Rate Variability Coach** | Wellness | High-gain beamforming microphones | Listens to micro-respiratory acoustic patterns during quiet meditation or breathwork breaks to provide guided box breathing pacing. |

---

## 🛠️ Requirements & Compatibility

- **macOS**: macOS 14.0 (Sonoma) or macOS 15+ (Sequoia)
- **Supported Hardware**:
  - AirPods Max
  - AirPods Pro (1st & 2nd Generation)
  - AirPods (3rd & 4th Generation)
  - Beats Fit Pro & Beats Studio Pro

---

## 📦 How to Build and Run

### 1. Build the App Bundle (`.app`)
Run the included build script:
```bash
chmod +x build_app.sh
./build_app.sh
```
This compiles the release binary and packages `AirPodsPosture.app` with all necessary permissions and bundle metadata.

### 2. Launch the Application
```bash
open AirPodsPosture.app
```
Or run directly from the terminal with Swift Package Manager:
```bash
swift run
```

---

## 🏗️ Project Architecture

```
AirPodsMaxPotential/
├── Package.swift                    # Swift Package Manager configuration (macOS 14+)
├── build_app.sh                     # Automated release build & bundle packager
├── README.md                        # Documentation & potential roadmap
└── Sources/
    └── AirPodsPosture/
        ├── AirPodsPostureApp.swift  # App entry point (WindowGroup + MenuBarExtra)
        ├── MotionManager.swift      # CMHeadphoneMotionManager wrapper, kinematics, gestures
        ├── PostureVisualizerView.swift # 3D Avatar & real-time pitch/roll/yaw meters
        ├── StretchCoach.swift       # Guided physical therapy state machine
        ├── StretchCoachView.swift   # Interactive routine UI with hold timers
        ├── FeaturesHubView.swift    # AirPods potential exploration & architecture guide
        ├── SettingsView.swift       # Sensitivity sliders, sound picker, demo controls
        ├── MenuBarView.swift        # Compact Menu Bar dropdown UI
        └── ContentView.swift        # Main dashboard window layout & navigation
```

---

## 📄 License
MIT License. Created for the AirPods Max Potential project.
