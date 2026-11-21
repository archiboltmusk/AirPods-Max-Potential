import SwiftUI

public struct SettingsView: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var sentinel = OpticalContinuitySentinel.shared
    
    let availableSounds = ["Tink", "Ping", "Hero", "Pop", "Submarine", "Basso", "Funk", "Glass"]
    
    public init(motion: MotionManager) {
        self.motion = motion
    }
    
    public var body: some View {
        Form {
            Section(header: Text("Posture Profiles & Presets").font(.headline)) {
                Picker("Active Profile", selection: $motion.activeProfile) {
                    ForEach(PostureProfile.allCases) { profile in
                        Text(profile.rawValue).tag(profile)
                    }
                }
                .pickerStyle(.segmented)
                
                Text(motion.activeProfile.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 2)
            }
            
            Section(header: Text("Loophole Defenses & Smart Automation").font(.headline)) {
                Toggle("Launch at Login (Start with macOS)", isOn: $motion.launchAtLogin)
                
                Toggle("Screen Edge Ambient Glow Alert", isOn: Binding(
                    get: { ScreenGlowManager.shared.isGlowEnabled },
                    set: { ScreenGlowManager.shared.isGlowEnabled = $0 }
                ))
                Text("Subtly pulses a gentle amber or red glow along the border of your display when slouching. Completely silent, click-through, and perfect for meetings and deep focus.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Camera Notch Ambient HUD Pill", isOn: Binding(
                    get: { DynamicIslandNotchHaloManager.shared.isEnabled },
                    set: { _ in DynamicIslandNotchHaloManager.shared.toggleEnabled() }
                ))
                Text("Optional floating status capsule under the display notch. Disabled by default to keep your screen completely unobstructed.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Smart Meeting Guard (Mute during Zoom / Calls)", isOn: $motion.muteInMeetings)
                Text("Monitors macOS microphone state in real-time. Automatically silences audio chimes during meetings, calls, or screen recordings so you are never interrupted.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Battery Saver Mode (Eco Sampling)", isOn: $motion.batterySaverMode)
                Text("Dynamically throttles sensor polling in background mode to ~10Hz. Conserves AirPods Max/Pro battery and drops Mac CPU usage below 0.1%.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("Auto-Drift Posture Compensation", isOn: $motion.autoDriftCorrection)
                Text("Applies a subtle exponential moving filter to compensate for headphones gently slipping on hair/ears over 4+ hours of continuous wear.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Toggle("FaceTime HD Optical Sentinel (AirPods In-Case Fallback)", isOn: $sentinel.autoFallbackEnabled)
                Text("Autonomous on-device Apple Neural Engine facial pose estimation keeps monitoring neck posture and turtle-neck craning while your AirPods charge. Shuts down automatically when AirPods re-enter the ear.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Section(header: Text("20-20-20 Ergonomic Eye & Spine Break Timer").font(.headline)) {
                Toggle("Enable 20-20-20 Rule Reminders", isOn: $breakTimer.isEnabled)
                
                if breakTimer.isEnabled {
                    HStack {
                        Text("Interval:")
                        Spacer()
                        Text("\(Int(breakTimer.intervalMinutes)) minutes")
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $breakTimer.intervalMinutes, in: 15.0...60.0, step: 5.0)
                    
                    HStack {
                        Text("Time until next break:")
                        Spacer()
                        Text(String(format: "%02dm %02ds", Int(breakTimer.secondsRemaining) / 60, Int(breakTimer.secondsRemaining) % 60))
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    
                    Button("Trigger Break Now") {
                        breakTimer.startBreak()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            
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
                        Text("Grace Period Buffer")
                        Spacer()
                        Text(String(format: "%.1fs", motion.gracePeriodSeconds))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.gracePeriodSeconds, in: 1.0...10.0, step: 0.5)
                }
            }
            
            Section(header: Text("Audio & Feedback Options").font(.headline)) {
                Toggle("Sound Alert on Slouching", isOn: $motion.soundAlertsEnabled)
                
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
            }
            
            Section(header: Text("Testing & Demo Mode").font(.headline)) {
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
            
            Section(header: Text("Session Statistics").font(.headline)) {
                HStack {
                    Text("Total Tracked:")
                    Spacer()
                    Text(formatTime(motion.secondsTracked))
                        .foregroundColor(.secondary)
                }
                HStack {
                    Text("Optimal Posture Time:")
                    Spacer()
                    Text(formatTime(motion.secondsGoodPosture))
                        .foregroundColor(.green)
                }
                HStack {
                    Text("Slouching Time:")
                    Spacer()
                    Text(formatTime(motion.secondsSlouching))
                        .foregroundColor(.red)
                }
                HStack {
                    Text("Slouch Incidents:")
                    Spacer()
                    Text("\(motion.slouchEventCount)")
                        .foregroundColor(.orange)
                }
            }
        }
        .formStyle(.grouped)
        .padding(16)
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%02dm %02ds", mins, secs)
    }
}
