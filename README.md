# AirPods Max & Pro Potential (AirPodsIQ)

> **Transform your Apple AirPods Max and AirPods Pro into an intelligent ergonomic posture sentry, spatial computing canvas, biometric focus monitor, and hands-free Mac controller.**

---

## 🚀 Complete Master Feature Suite

### 1. 📐 Kinematic Posture & Biomechanical Core
* **3D SIMD Quaternion Tracking**: Uses exact $4\text{D}$ spatial quaternion inversion ($\mathbf{q}_{\text{baseline}}^{-1} \times \mathbf{q}_{\text{current}}$) to eliminate Euler angle gimbal lock and coordinate flips.
* **AirPods Pro 2 IMU Telemetry Hub**: Real-time readouts of **Earth's Gravity Vector** ($g_x, g_y, g_z$), **User Dynamic Acceleration** ($a_x, a_y, a_z$), **Gyroscope Rotational Velocity** ($\omega_x, \omega_y, \omega_z$ in $^\circ/\text{s}$), and total kinetic energy.
* **Thoracic Slump vs Chin-Tilt Disambiguation**: Differentiates between simple neck flexion vs full torso lumbar/thoracic compression using gravity vector projection.
* **Contextual Ergonomic Profiles**: One-click presets for *Standard Desk*, *Reading & Paperwork* ($24^\circ$ relaxed pitch), *Standing Desk*, and *Relaxed Recline*.
* **Interactive Guided Neck Mobility Coach**: A 4-stage guided physical therapy routine verifying live angular hold times before granting completion badges.

### 2. 🪟 Spatial Computing & Hands-Free Mac Control
* **Spatial Virtual Desktops**: Slide between macOS Spaces (`⌃←` / `⌃→`) simply by turning your head past $\pm 28^\circ$ with intelligent hysteresis.
* **Spatial Head Pointer & Hands-Free Scrolling**: Tilt head down past $12^\circ$ to smoothly scroll documents, websites, or code files down; tilt slightly up to scroll up.
* **Hands-Free Head Gestures**:
  - **Double-Nod ("Yes")**: Triggers macOS Dictation / Voice Control.
  - **Head Shake ("No")**: Dismisses active alerts or cancels prompts.
* **Walk-Away Mac Screen Auto-Lock**: Instantly pauses Spotify/Apple Music and locks the screen (`SACLockScreenImmediate()`) when you remove your AirPods or walk away.

### 3. 🧠 Cognitive Health, Focus & Biofeedback
* **Subconscious Spatial Audio Biofeedback**: Connects an audio filter ($800\text{ Hz} \leftrightarrow 20,000\text{ Hz}$) to rolling focus soundscapes. Audio rolls off high frequencies when you slouch and blossoms open into pristine spatial clarity when sitting upright.
* **Deep Cognitive Flow vs Restlessness Index**: Samples 60 Hz gyroscope variance ($\sigma^2_{\text{gyro}}$) to compute real-time **Focus Flow Scores** and detect cognitive fatigue before burnout.
* **Neuro-Acoustic Binaural Beats Synthesizer**: Generates true stereo sine waves for **40 Hz Gamma** (Hyper-focus & coding), **10 Hz Alpha** (Relaxed flow), and **6 Hz Theta** (Creativity).
* **Vagus Nerve Resonance Breathing Coach**: Interactive 4-4-4-4 Box Breathing and 4-7-8 Deep Relaxation pacer with expanding/contracting visual guides.
* **Micro-Sleep & Drowsiness Guard**: Detects the kinematic signature of nodding off (gradual pitch drop followed by a sudden hypnic jerk) to sound a wake-up sentry alert.

### 4. 🛡️ Loophole Defenses & Smart Automation
* **CoreAudio Meeting Guard**: Periodically monitors `kAudioDevicePropertyDeviceIsRunningSomewhere`. If Zoom, Teams, Meet, or FaceTime claims the mic, all audible chimes are instantly silenced.
* **Dual-Monitor Cervical Asymmetry Guard**: Analyzes rolling yaw distribution to alert you if your head stays skewed $>20^\circ$ toward a side monitor for $>55\%$ of the past 30 minutes.
* **App-by-App Posture Heatmap**: Monitors `NSWorkspace.shared.frontmostApplication` to reveal which apps (Xcode, Terminal, Slack, Browser) trigger your worst slouching habits.
* **Screen Edge Ambient Glow**: Completely click-through, floating border vignette that pulses amber or red when slouching—silent, non-intrusive, and flow-preserving.
* **Camera Notch HUD Posture Ring**: Floating status crescent positioned right beneath the MacBook camera notch.
* **WHO Hearing Safety Dose Meter**: Integrates daily sound exposure (dBA) against WHO allowable safety limits.
* **Zen Bonsai Desk Companion**: Gamified virtual bonsai that blooms with good posture and droops when slouching.
* **Weekly Scorecard Exporter**: Exports formatted markdown/text ergonomic health scorecards with 1-click clipboard copy or disk save.
* **Dual-Pipeline Ingestion**: Direct CoreMotion (`.userInteractive` background queue) + local UDP bridge listener (`127.0.0.1:4243`).
* **Launch at Login**: Full native `SMAppService` launch-at-login integration.

---

## 📦 How to Build and Run

### Run the App Bundle
```bash
open /Users/anupam/.gemini/antigravity/scratch/AirPodsMaxPotential/AirPodsPosture.app
```

### Build from Source
```bash
cd /Users/anupam/.gemini/antigravity/scratch/AirPodsMaxPotential
./build_app.sh
```
