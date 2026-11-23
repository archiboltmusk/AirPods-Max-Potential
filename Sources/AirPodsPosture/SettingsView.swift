import SwiftUI
import AirPodsCore

/// Comprehensive macOS Settings & Preferences Center.
/// Contains all granular preferences, sensitivity sliders, audio & haptic options,
/// loophole sentinels, ecosystem bridges, and display overlays.
public struct SettingsView: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var sentinel = OpticalContinuitySentinel.shared
    @ObservedObject var inCase = AirPodsInCaseLifecycleManager.shared
    @ObservedObject var callSentinel = CallActivitySentinel.shared
    @ObservedObject var drift = AutoZeroDriftCompensator.shared
    @ObservedObject var clamshell = HardwareClamshellSentinel.shared
    @ObservedObject var glance = GlanceAndLockAutoCalibrator.shared
    @ObservedObject var companion = FloatingMiniDeskCompanionManager.shared
    @ObservedObject var spatialAudio = SpatialAudioBiofeedback.shared
    @ObservedObject var voiceAlert = SystemAudioVoiceAlertEngine.shared
    @ObservedObject var haptics = SyntheticEarHapticEngine.shared
    @ObservedObject var watchBridge = AppleWatchBridgeManager.shared
    @ObservedObject var smartDesk = SmartDeskBLEController.shared
    @ObservedObject var ghostDimming = GhostDimmingBiofeedbackManager.shared
    @ObservedObject var spatialElevation = SpatialElevationSoundstageEngine.shared
    @ObservedObject var stemGesture = StemForceGestureInterceptor.shared
    @ObservedObject var permanentEngine = PermanentPostureEngine.shared
    @ObservedObject var fitSentinel = AirPodsInsertionFitSentinel.shared
    
    @AppStorage("appVisualTheme") var appVisualTheme: String = "humanCinema"
    @AppStorage("appPresentationMode") var appPresentationMode: String = "hideWhenClosed"
    
    let availableSounds = ["Tink", "Ping", "Hero", "Pop", "Submarine", "Basso", "Funk", "Glass"]
    
    public init(motion: MotionManager) {
        self.motion = motion
    }
    
    public var body: some View {
        Form {
            // 0. ADA Onboarding Tour
            Section(header: Text("Apple Design Award Experience").font(.headline)) {
                Button(action: {
                    UserDefaults.standard.set(false, forKey: "hasCompletedADAOnboarding")
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                            .foregroundColor(CREDPalette.emeraldPlasma)
                        Text("Replay 3-Screen Onboarding Tour")
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Launch")
                            .foregroundColor(.secondary)
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }
            
            // 1. Software Updates
            Section(header: Text("Software Updates & Release Channel").font(.headline)) {
                SoftwareUpdateCardView()
            }
            
            // 2. Posture Profiles & Auto-Calibration
            Section(header: Text("Posture Profiles & Auto-Calibration").font(.headline)) {
                Picker("Active Profile", selection: $motion.activeProfile) {
                    ForEach(PostureProfile.allCases) { profile in
                        Text(profile.rawValue).tag(profile)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(motion.activeProfile.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Toggle("Glance & Lock Auto-Calibration", isOn: $glance.isGlanceLockEnabled)
                Text("Autonomous zero-click onboarding: When you put on AirPods and look at your Mac screen for 3 steady seconds, locks baseline automatically with a soft chime.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Continuous Center-Seeking Yaw Drift Filter (EWMA)", isOn: $drift.isDriftCompensationEnabled)
                Text("Continuously eliminates cumulative gyro yaw drift by re-anchoring to the primary display over a 20-minute half-life window without magnetic interference.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // Permanent Anatomical Ear-Fit Basis (Zero Re-Calibration Across Restarts)
            Section(header: Text("Permanent Ear-Fit Calibration (Across Restarts)").font(.headline)) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "ear.and.waveform")
                            .foregroundColor(.green)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Permanent Anatomical Skull Basis")
                                .font(.headline)
                            Text(permanentEngine.isProfileActive ? "Active — Left & Right Ear Profiles Calibrated" : "Active — Standard Factory Horizon Active")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text(permanentEngine.adaptationStatusText)
                            .font(.caption2.bold())
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    Divider()
                    
                    Text("Separates anatomical ear-fit geometry from arbitrary session yaw heading. Earth's gravity vector is projected onto your permanent skull coordinate frame, giving instantaneous 0-latency posture tracking on app launch without needing to recalibrate.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Clamped Micro-Fit Adaptation")
                                .font(.subheadline.bold())
                            Text("Slowly auto-tunes via EMA (α = 0.001) within ±6° neutral zone to absorb daily earbud insertion angle differences without ever drifting into slouch.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Circle()
                            .fill(permanentEngine.isAdaptingInsertionTolerance ? Color.green : Color.secondary.opacity(0.3))
                            .frame(width: 10, height: 10)
                    }
                    
                    if permanentEngine.isOnboardingActive {
                        VStack(spacing: 6) {
                            HStack {
                                Text(permanentEngine.onboardingStep.rawValue)
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                Spacer()
                                Button("Cancel") {
                                    permanentEngine.cancelGuidedOnboarding()
                                }
                                .font(.caption)
                            }
                            ProgressView(value: permanentEngine.onboardingProgress)
                                .tint(.orange)
                        }
                        .padding(10)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        Button(action: {
                            permanentEngine.startGuidedOnboarding()
                        }) {
                            Label("Run 4s Guided Ear Calibration (Sit Upright 2s -> Nod 2s)", systemImage: "sparkles")
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // AirPods Ear Tip Fit & Insertion Verification
            Section(header: Text("AirPods Ear-Fit & Acoustic Seal Verification").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: fitSentinel.isProperlySeated ? "ear.badge.checkmark" : "ear.trianglebadge.exclamationmark")
                            .foregroundColor(fitSentinel.isProperlySeated ? .green : .orange)
                            .font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Acoustic Seal & Seating Health")
                                .font(.headline)
                            Text(fitSentinel.isProperlySeated ? "Good Seal • Hardware Signals Certified" : "Adjustment Recommended")
                                .font(.caption)
                                .foregroundColor(fitSentinel.isProperlySeated ? .green : .orange)
                        }
                        Spacer()
                        Text("\(fitSentinel.fitQualityScore)% Seal")
                            .font(.subheadline.bold())
                            .foregroundColor(fitSentinel.isProperlySeated ? .green : .orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background((fitSentinel.isProperlySeated ? Color.green : Color.orange).opacity(0.12))
                            .clipShape(Capsule())
                    }
                    
                    if let warning = fitSentinel.fitRecommendationMessage {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(warning)
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                        .padding(8)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(6)
                    }
                    
                    HStack(spacing: 8) {
                        Button(action: {
                            fitSentinel.isFitGuidePresented = true
                        }) {
                            Label("Open 4-Step Ear Tip & Insertion Guide", systemImage: "info.circle.fill")
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: {
                            fitSentinel.checkAudioRouting()
                        }) {
                            Label("Re-verify Routing", systemImage: "arrow.clockwise")
                        }
                        .buttonStyle(.borderless)
                        .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }
            
            // 3. Fine-Tuning Sensitivity & Thresholds
            Section(header: Text("Fine-Tuning Sensitivity & Thresholds").font(.headline)) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Forward Slouch Sensitivity (Pitch)")
                        Spacer()
                        Text("\(Int(motion.pitchThreshold))°")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.pitchThreshold, in: 6.0...30.0, step: 1.0)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Lateral Tilt Sensitivity (Roll)")
                        Spacer()
                        Text("\(Int(motion.rollThreshold))°")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.rollThreshold, in: 5.0...25.0, step: 1.0)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Grace Period Buffer (Hysteresis)")
                        Spacer()
                        Text(String(format: "%.1fs", motion.gracePeriodSeconds))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.gracePeriodSeconds, in: 1.0...15.0, step: 0.5)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Anti-Gaming Stabilization Lockout")
                        Spacer()
                        Text(String(format: "%.1fs", motion.recoveryGraceSeconds))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.recoveryGraceSeconds, in: 1.0...5.0, step: 0.5)
                    Text("Requires holding an upright posture for this duration before resetting slouch warnings.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // 4. Audio, Haptics & Biofeedback
            Section(header: Text("Audio, Haptics & Biofeedback").font(.headline)) {
                Toggle("Audible Posture Reminders", isOn: $motion.soundAlertsEnabled)
                
                if motion.soundAlertsEnabled {
                    Picker("Alert Chime", selection: $motion.alertSoundName) {
                        ForEach(availableSounds, id: \.self) { sound in
                            Text(sound).tag(sound)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    HStack {
                        Spacer()
                        Button("Test Sound") {
                            motion.playFeedbackSound(motion.alertSoundName)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                Toggle("Music Posture Dimmer (Psychoacoustic Treble Muffle)", isOn: $spatialAudio.isEnabled)
                Text("Operant conditioning without beeps: Subtly muffles music/podcast high frequencies when slouching; crystal clarity returns the moment you sit upright.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Spoken Voice Posture Announcements", isOn: $voiceAlert.isVoiceCueEnabled)
                Text("Gently announces 'Sit up straight' through system speech synthesizer during severe slouching.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Synthetic Ear Haptics (Directional Clicks)", isOn: $haptics.isHapticAudioEnabled)
                Text("Delivers localized directional tactile acoustic micro-clicks in the ear corresponding to slouch direction.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("MacBook Trackpad Silent Haptics (Force Touch)", isOn: $haptics.isTrackpadHapticEnabled)
                Text("Silent tactile micro-pulses via the MacBook trackpad Taptic Engine. Zero audio noise during meetings or silent study.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Ghost Dimming (Subconscious Screen Dimming)", isOn: $ghostDimming.isGhostDimmingEnabled)
                Text("Subtle visual biofeedback: When slouched for > 20s, screen dims by 20%. The instant you sit tall, screen glides back to 100% brightness.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Spatial Elevation Soundstage (Audio Tied to Spine)", isOn: $spatialElevation.isSpatialElevationEnabled)
                Text("Music elevation drops to chest level during a slouch; sitting upright lifts audio back to eye level.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("AirPods Stem Force Squeeze Shortcuts", isOn: $stemGesture.isStemControlEnabled)
                Text("Double-squeeze earbud stem or double-nod to calibrate baseline; triple-squeeze to snooze 15 minutes.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 5. Smart Meeting Cloak & Call Sentinel
            Section(header: Text("Smart Meeting Cloak & Call Sentinel").font(.headline)) {
                Toggle("Auto-Silence Chimes on Zoom / Teams / Meet", isOn: $callSentinel.isCallMuteEnabled)
                Text("Continuously monitors CoreAudio input streams and active conferencing apps. Automatically silences auditory nudges during meetings so you are never interrupted.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Smart Meeting Guard (Microphone Usage Lock)", isOn: $motion.muteInMeetings)
                Text("Suppresses audio alerts whenever any Mac application claims the microphone.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 6. AirPods In-Case & Energy Management
            Section(header: Text("AirPods In-Case & Energy Management").font(.headline)) {
                Picker("In-Case Behavior", selection: $inCase.actionOnCaseIn) {
                    Text("Deep Standby (0.0% CPU)").tag(AirPodsInCaseLifecycleManager.ActionOnCaseIn.deepHibernate)
                    Text("Auto-Quit App (15s)").tag(AirPodsInCaseLifecycleManager.ActionOnCaseIn.autoQuit)
                }
                .pickerStyle(.segmented)
                
                Toggle("Battery Saver Mode (Eco Sampling)", isOn: $motion.batterySaverMode)
                Text("Dynamically throttles sensor polling to 10Hz in background mode. Conserves AirPods battery and drops Mac CPU usage below 0.1%.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("FaceTime HD Optical Sentinel (AirPods In-Case Fallback)", isOn: $sentinel.autoFallbackEnabled)
                Text("Autonomous on-device Apple Neural Engine facial pose estimation keeps monitoring posture while AirPods charge. Automatically enters standby if the laptop lid is closed in Clamshell Mode.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 7. Visual Overlays, Companions & Appearance
            Section(header: Text("Visual Overlays, Companions & Appearance").font(.headline)) {
                Toggle("Float Posture Buddy on Desktop", isOn: Binding(
                    get: { companion.isCompanionVisible },
                    set: { _ in companion.toggleCompanion() }
                ))
                Text("Places an interactive living mascot on your screen that physically slumps with you. Tap to switch avatar style; double-tap to recalibrate.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                if companion.isCompanionVisible {
                    Picker("Buddy Avatar Style", selection: $companion.avatarStyle) {
                        ForEach(FloatingMiniDeskCompanionManager.AvatarStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Picker("App Visual Canvas Theme", selection: $appVisualTheme) {
                    Text("CRED Obsidian Noir").tag("credStandard")
                    Text("Warm Human Cinema").tag("humanCinema")
                    Text("Cupertino Metal").tag("cupertino")
                }
                .pickerStyle(.segmented)
                
                VStack(alignment: .leading, spacing: 4) {
                    Picker("Dock & Menu Bar Visibility", selection: $appPresentationMode) {
                        Text("Hide from Dock when window is closed (Recommended)").tag("hideWhenClosed")
                        Text("Menu Bar Only (Never show in Dock)").tag("menuBarOnly")
                        Text("Always show in Dock and Menu Bar").tag("alwaysShowDock")
                    }
                    .onChange(of: appPresentationMode) { _, _ in
                        AppDelegate.shared?.applyPresentationMode()
                    }
                    Text("When set to 'Hide from Dock', closing the window or quitting from the Dock removes the app from the Dock while keeping posture tracking fully active in the Menu Bar.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Toggle("Screen Edge Ambient Glow Alert", isOn: Binding(
                    get: { ScreenGlowManager.shared.isGlowEnabled },
                    set: { ScreenGlowManager.shared.isGlowEnabled = $0 }
                ))
                Text("Subtly pulses a gentle amber or red glow along the border of your display when slouching. Completely silent and click-through.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Camera Notch Ambient HUD Pill", isOn: Binding(
                    get: { DynamicIslandNotchHaloManager.shared.isEnabled },
                    set: { _ in DynamicIslandNotchHaloManager.shared.toggleEnabled() }
                ))
                Text("Optional floating status capsule under the display notch.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Launch at Login (Start with macOS)", isOn: $motion.launchAtLogin)
            }
            
            // 8. 20-20-20 Ergonomic Rest Break Timer
            Section(header: Text("20-20-20 Ergonomic Eye & Spine Break Timer").font(.headline)) {
                Toggle("Enable 20-20-20 Rule Reminders", isOn: $breakTimer.isEnabled)
                
                if breakTimer.isEnabled {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Reminder Frequency")
                            Spacer()
                            Text("\(Int(breakTimer.intervalMinutes)) mins")
                                .font(.system(.body, design: .monospaced, weight: .bold))
                        }
                        Slider(value: $breakTimer.intervalMinutes, in: 15.0...60.0, step: 5.0)
                    }
                    
                    Button("Start Break Now") {
                        breakTimer.startBreak()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
            // 9. Ecosystem & Hardware Bridges
            Section(header: Text("Ecosystem & Hardware Bridges").font(.headline)) {
                Toggle("Apple Watch Thoracic Kinematics Bridge", isOn: $watchBridge.hapticFeedbackEnabled)
                Text("Pairs AirPods cervical head pitch with Apple Watch thoracic chest angles for true whole-spine curvature tracking.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Smart Standing Desk BLE Controller", isOn: $smartDesk.isAutoGlideEnabled)
                Text("Automatically commands Bluetooth motorized desks to alternate between sit and stand heights.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            // 10. Testing & Demo Simulation
            Section(header: Text("Testing & Demo Simulation").font(.headline)) {
                Toggle("Enable Simulation Mode", isOn: Binding(
                    get: { motion.isSimulated },
                    set: { _ in motion.toggleSimulation() }
                ))
                
                if motion.isSimulated {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Simulated Pitch: \(Int(motion.simulatedPitch))°")
                            .font(.caption.bold())
                        Slider(value: $motion.simulatedPitch, in: -35.0...35.0, step: 1.0)
                        
                        Text("Simulated Roll: \(Int(motion.simulatedRoll))°")
                            .font(.caption.bold())
                        Slider(value: $motion.simulatedRoll, in: -30.0...30.0, step: 1.0)
                        
                        HStack {
                            Button("Simulate Upright") {
                                motion.simulatedPitch = 0
                                motion.simulatedRoll = 0
                                motion.simulatedYaw = 0
                            }
                            Button("Simulate Slouch") {
                                motion.simulatedPitch = -20
                            }
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(8)
                    .background(Color.primary.opacity(0.04))
                    .cornerRadius(8)
                }
            }
            
            // 11. Session Statistics
            Section(header: Text("Session Statistics").font(.headline)) {
                HStack {
                    Text("Total Tracked:")
                    Spacer()
                    Text(formatTime(Int(motion.secondsTracked)))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Good Posture:")
                    Spacer()
                    Text(formatTime(Int(motion.secondsGoodPosture)))
                        .foregroundColor(.green)
                }
                HStack {
                    Text("Slouching Time:")
                    Spacer()
                    Text(formatTime(Int(motion.secondsSlouching)))
                        .foregroundColor(.red)
                }
                HStack {
                    Text("Slouch Events:")
                    Spacer()
                    Text("\(motion.slouchEventCount)")
                        .foregroundColor(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .sheet(isPresented: $fitSentinel.isFitGuidePresented) {
            AirPodsFitVerificationGuideView()
        }
    }
    
    private func formatTime(_ seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        if h > 0 {
            return String(format: "%dh %02dm %02ds", h, m, s)
        }
        return String(format: "%02dm %02ds", m, s)
    }
}
