import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var calibrator = AutonomousAutoCalibrator.shared
    @ObservedObject var binaural = ProceduralBinauralSoundscapeEngine.shared
    @ObservedObject var miniDesk = FloatingMiniDeskCompanionManager.shared
    @ObservedObject var screenBlur = ProgressiveScreenBlurManager.shared
    @ObservedObject var voiceAlert = SystemAudioVoiceAlertEngine.shared
    let openDashboard: () -> Void
    
    public init(motion: MotionManager, openDashboard: @escaping () -> Void) {
        self.motion = motion
        self.openDashboard = openDashboard
    }
    
    private var statusColor: Color {
        switch motion.postureState {
        case .optimal: return .green
        case .warning: return .orange
        case .slouching: return .red
        case .snoozed: return .blue
        case .disconnected: return .gray
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header status
            HStack {
                Image(systemName: motion.postureState.systemImage)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 1) {
                    Text(motion.isConnected ? motion.postureState.rawValue : "No AirPods Connected")
                        .font(.headline)
                    if motion.isSnoozed {
                        Text("Snoozed for \(Int(ceil(motion.snoozeTimeRemaining / 60)))m")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    } else if motion.isConnected {
                        Text("Pitch \(Int(motion.deltaPitch))°, Roll \(Int(motion.deltaRoll))°")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Put on AirPods Max or Pro")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                let tone: LiveSpineMenuBarGlyph.Tone = !motion.isConnected ? .disconnected : (motion.postureState == .slouching ? .alert : .calm)
                let glyph = LiveSpineMenuBarGlyph.image(pitchDegrees: motion.deltaPitch, tone: tone, height: 20)
                Image(nsImage: glyph)
                
                Text("\(motion.postureScore)%")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(motion.postureScore > 80 ? .green : (motion.postureScore > 60 ? .orange : .red))
            }
            .padding(.bottom, 2)
            
            if motion.isRecoveringHysteresis {
                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text("Hold Upright (2s Anti-Gaming Stabilization)")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)
                }
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .cornerRadius(4)
            }
            
            // Auto-Calibration status
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
                    .font(.caption2)
                Text(calibrator.autoCalibrationStatus)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 3)
            .padding(.horizontal, 6)
            .background(Color.cyan.opacity(0.08))
            .cornerRadius(4)
            
            // Slouch-Proof Safety Interlock Warning
            if let alert = motion.calibrationInterlockAlert {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                    Text(alert)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.yellow)
                        .lineLimit(2)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.yellow.opacity(0.15))
                .cornerRadius(6)
            }
            
            // Smart Meeting Guard notice
            if audioMonitor.isMicrophoneInUse {
                HStack(spacing: 6) {
                    Image(systemName: "mic.fill")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text("Meeting Active — Chimes Muted")
                        .font(.caption.bold())
                        .foregroundColor(.purple)
                }
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.12))
                .cornerRadius(6)
            }
            
            Divider()
            
            // Profile Selector
            Menu {
                ForEach(PostureProfile.allCases) { profile in
                    Button(action: {
                        motion.activeProfile = profile
                    }) {
                        HStack {
                            Text(profile.rawValue)
                            if motion.activeProfile == profile {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Label("Profile: \(motion.activeProfile.rawValue)", systemImage: motion.activeProfile.icon)
            }
            
            // Quick Snooze Menu
            if motion.isSnoozed {
                Button(action: { motion.clearSnooze() }) {
                    Label("Resume Tracking (Clear Snooze)", systemImage: "play.circle")
                }
            } else {
                Menu {
                    Button("Snooze for 5 minutes") { motion.snooze(minutes: 5) }
                    Button("Snooze for 15 minutes") { motion.snooze(minutes: 15) }
                    Button("Snooze for 30 minutes") { motion.snooze(minutes: 30) }
                    Button("Snooze for 1 hour") { motion.snooze(minutes: 60) }
                } label: {
                    Label("Snooze Alerts...", systemImage: "moon.zzz")
                }
            }
            
            // 20-20-20 Break Timer Status
            if breakTimer.isEnabled {
                HStack {
                    Label(
                        breakTimer.isBreakDue ? "20-20-20 Break Due!" : "Next Break: \(Int(ceil(breakTimer.secondsRemaining / 60)))m",
                        systemImage: "timer"
                    )
                    .font(.caption)
                    .foregroundColor(breakTimer.isBreakDue ? .orange : .secondary)
                    
                    Spacer()
                    
                    if breakTimer.isBreakDue {
                        Button("Rest Eyes") {
                            breakTimer.startBreak()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.mini)
                    }
                }
            }
            
            Divider()
            
            // Upgraded Features Quick Bar
            Group {
                Button(action: {
                    miniDesk.toggleCompanion()
                }) {
                    Label(miniDesk.isCompanionVisible ? "Hide Mini Desk Companion" : "Show Mini 3D Companion Orb", systemImage: "person.crop.circle")
                }
                
                Menu {
                    Button(binaural.isPlaying ? "Stop Waves" : "Start Synthesizer") {
                        binaural.togglePlay()
                    }
                    Divider()
                    ForEach(BinauralWaveFrequency.allCases) { wave in
                        Button(action: {
                            binaural.selectedWave = wave
                            if binaural.isPlaying {
                                binaural.togglePlay()
                                binaural.togglePlay()
                            }
                        }) {
                            HStack {
                                Text(wave.rawValue)
                                if binaural.selectedWave == wave {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    Label(binaural.isPlaying ? "Binaural: Active (\(binaural.selectedWave.rawValue.prefix(11)))" : "Binaural Focus Waves", systemImage: "waveform")
                }
            }
            
            Divider()
            
            // Primary Quick Actions
            Button(action: {
                calibrator.triggerInstantDoubleNodCalibration()
            }) {
                Label("Auto-Align Calibration (or Double-Nod)", systemImage: "scope")
            }
            .disabled(!motion.isConnected)
            
            Button(action: {
                if motion.isTracking {
                    motion.stopTracking()
                } else {
                    motion.startTracking()
                }
            }) {
                Label(motion.isTracking ? "Pause Tracking" : "Resume Tracking", systemImage: motion.isTracking ? "pause.circle" : "play.circle")
            }
            
            Button(action: {
                motion.toggleSimulation()
            }) {
                Label(motion.isSimulated ? "Exit Demo Mode" : "Try Demo / Simulation Mode", systemImage: "wand.and.stars")
            }
            
            Divider()
            
            Button(action: {
                openDashboard()
            }) {
                Label("Open Full Dashboard...", systemImage: "macwindow")
            }
            
            Button(action: {
                openDashboard()
                AppUpdateManager.shared.checkForUpdates()
            }) {
                Label("Check for Updates...", systemImage: "arrow.triangle.2.circlepath")
            }
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit AirPods Posture", systemImage: "power")
            }
        }
        .padding(14)
        .frame(width: 310)
    }
}
