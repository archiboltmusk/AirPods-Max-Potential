import SwiftUI

public struct SettingsView: View {
    @ObservedObject var motion: MotionManager
    
    let availableSounds = ["Tink", "Ping", "Hero", "Pop", "Submarine", "Basso", "Funk", "Glass"]
    
    public init(motion: MotionManager) {
        self.motion = motion
    }
    
    public var body: some View {
        Form {
            Section(header: Text("Ergonomic Calibration & Sensitivity").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Neutral Upright Posture")
                                .font(.body.bold())
                            Text(motion.isCalibrated ? "Calibrated (Pitch: \(Int(motion.baselinePitch))°, Roll: \(Int(motion.baselineRoll))°)" : "Not yet calibrated")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Calibrate Now") {
                            motion.calibrateCurrentPosture()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Text("Sit straight with your eyes naturally level with the top third of your display, then click Calibrate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Forward Slouch Sensitivity (Pitch Threshold)")
                        Spacer()
                        Text("\(Int(motion.pitchThreshold))°")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.pitchThreshold, in: 6.0...25.0, step: 1.0)
                    Text("Smaller degrees trigger alerts with less slouching. Recommended: 10° - 14°.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Lateral Head Tilt Sensitivity (Roll Threshold)")
                        Spacer()
                        Text("\(Int(motion.rollThreshold))°")
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.rollThreshold, in: 5.0...20.0, step: 1.0)
                    Text("Detects resting head on hand or leaning sideways on armrests. Recommended: 8° - 12°.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Grace Period Before Alert")
                        Spacer()
                        Text(String(format: "%.1fs", motion.gracePeriodSeconds))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                    }
                    Slider(value: $motion.gracePeriodSeconds, in: 1.0...10.0, step: 0.5)
                    Text("Prevents alerts when temporarily taking a drink or briefly glancing at keyboard.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Feedback & Notifications").font(.headline)) {
                Toggle("Sound Alert on Slouching", isOn: $motion.soundAlertsEnabled)
                
                if motion.soundAlertsEnabled {
                    Picker("Alert Sound", selection: $motion.alertSoundName) {
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
            
            Section(header: Text("Testing & Simulation Mode").font(.headline)) {
                VStack(alignment: .leading, spacing: 10) {
                    Toggle("Enable Simulation / Demo Mode", isOn: Binding(
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
                            
                            Text("Simulated Yaw: \(Int(motion.simulatedYaw))°")
                                .font(.caption.bold())
                            Slider(value: $motion.simulatedYaw, in: -45.0...45.0, step: 1.0)
                            
                            HStack {
                                Button("Simulate Good Posture") {
                                    motion.simulatedPitch = 0
                                    motion.simulatedRoll = 0
                                    motion.simulatedYaw = 0
                                }
                                Button("Simulate Slouch") {
                                    motion.simulatedPitch = -18
                                    motion.simulatedRoll = 4
                                }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.04))
                        .cornerRadius(8)
                    }
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
