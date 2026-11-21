import SwiftUI

public struct EliteUpgradesView: View {
    @ObservedObject var romDiagnostic = CervicalROMDiagnostic.shared
    @ObservedObject var hydration = HydrationTracker.shared
    @ObservedObject var parallax = HolographicParallaxManager.shared
    @ObservedObject var windowSnap = WindowSnapManager.shared
    @ObservedObject var pomodoro = ErgonomicPomodoroEngine.shared
    @ObservedObject var soundstage = SpatialSoundstageManager.shared
    @ObservedObject var pulseEstimator = AcousticPulseEstimator.shared
    @ObservedObject var vocalCoach = VocalStrainCoach.shared
    @ObservedObject var cloudSync = iCloudSyncManager.shared
    @ObservedObject var sparkline = MenuBarSparklineRenderer.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(LinearGradient(colors: [.yellow, .orange], startPoint: .top, endPoint: .bottom))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Elite AirPods Innovation Suite")
                            .font(.title2.bold())
                        Text("Next-generation biomechanical, spatial, and productivity capabilities powered by AirPods Pro 2 & Max sensors.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                // 1. Cervical ROM Diagnostic & Physical Therapy Lab
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "stethoscope")
                            .foregroundColor(.cyan)
                        Text("1. Clinical Cervical Range-of-Motion (ROM) Diagnostic")
                            .font(.headline)
                        Spacer()
                        if romDiagnostic.isDiagnosticActive, let stage = romDiagnostic.currentStage {
                            Text("\(stage.name)")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text("Quantify cervical spine mobility in 6 clinical anatomical planes: Flexion, Extension, Left/Right Lateral Bend, Left/Right Axial Rotation.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if romDiagnostic.isDiagnosticActive, let stage = romDiagnostic.currentStage {
                        VStack(spacing: 8) {
                            Text(stage.instruction)
                                .font(.subheadline.bold())
                                .foregroundColor(.accentColor)
                            
                            ProgressView(value: min(romDiagnostic.peakAngleReached, stage.clinicalNormDegrees), total: stage.clinicalNormDegrees)
                                .accentColor(.cyan)
                            
                            HStack {
                                Text("Peak Angle: \(String(format: "%.1f°", romDiagnostic.peakAngleReached))")
                                Spacer()
                                Text("Normal Threshold: \(Int(stage.clinicalNormDegrees))°")
                            }
                            .font(.caption.monospaced())
                            .foregroundColor(.secondary)
                            
                            HStack(spacing: 12) {
                                Button("Lock Peak & Next Stage") {
                                    romDiagnostic.lockStageAndAdvance()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        HStack {
                            Button("Start 60-Second ROM Assessment") {
                                romDiagnostic.startTest()
                            }
                            .buttonStyle(.borderedProminent)
                            
                            if romDiagnostic.testCompleted {
                                Text("Score: \(romDiagnostic.flexibilityScore)/100 • Biological Spine Age: \(romDiagnostic.mobilityAgeEstimate) yrs")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 2. Hydration Sip Tracker & 3. Menu Bar Sparkline
                HStack(alignment: .top, spacing: 16) {
                    // Hydration Tracker
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "drop.fill")
                                .foregroundColor(.blue)
                            Text("2. Kinematic Hydration Tracker")
                                .font(.headline)
                        }
                        Text("Recognizes backwards head pitch (+25° to +50°) held for 1.8s corresponding to drinking water.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("\(hydration.sipsToday)")
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.blue)
                                Text("Sips Today")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            VStack(alignment: .leading) {
                                Text(hydration.estimatedVolumeOunces)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .foregroundColor(.teal)
                                Text("Est. Volume")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $hydration.isEnabled)
                                .labelsHidden()
                        }
                        
                        Text(hydration.recentSipMessage)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Menu Bar Sparkline
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "waveform.path.ecg")
                                .foregroundColor(.green)
                            Text("3. Real-Time Menu Bar Sparkline")
                                .font(.headline)
                        }
                        Text("Draws a live 30-minute mini sparkline curve directly in your macOS menu bar next to the battery.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Toggle("Show Live Waveform in Menu Bar", isOn: $sparkline.isEnabled)
                                .toggleStyle(.switch)
                        }
                        
                        Text("Updates continuously at 60Hz. Green = upright, Orange = slouch warning, Red = chronic compression.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 4. Cervical Window Snapper & 5. Holographic Parallax
                HStack(alignment: .top, spacing: 16) {
                    // Window Snapper
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "macwindow.on.rectangle")
                                .foregroundColor(.purple)
                            Text("4. Cervical Window Snapper")
                                .font(.headline)
                        }
                        Text("Snap windows left or right on macOS by performing a sharp 24° tilt of your head.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Head-Tilt Window Snapping", isOn: $windowSnap.isSnapEnabled)
                            .toggleStyle(.switch)
                        
                        Text("Status: \(windowSnap.lastSnappedDirection)")
                            .font(.caption2.bold())
                            .foregroundColor(.purple)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Holographic Parallax
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "cube.transparent")
                                .foregroundColor(.indigo)
                            Text("5. Holographic Parallax HUD")
                                .font(.headline)
                        }
                        Text("Shifts UI perspective dynamically based on your head's 3D angle for natural depth.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Dynamic UI Parallax", isOn: $parallax.isParallaxEnabled)
                            .toggleStyle(.switch)
                        
                        HStack {
                            Text("Parallax Offset: X: \(String(format: "%.1f", parallax.offsetX)), Y: \(String(format: "%.1f", parallax.offsetY))")
                                .font(.caption2.monospaced())
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 6. Ergonomic Pomodoro & 7. Acoustic Pulse Estimator
                HStack(alignment: .top, spacing: 16) {
                    // Pomodoro Engine
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "timer")
                                .foregroundColor(.red)
                            Text("6. Biomechanical Pomodoro")
                                .font(.headline)
                        }
                        Text("Standard Pomodoros tick blindly. This engine pauses the sprint if your posture collapses below 70%.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(pomodoro.formattedTimeRemaining)
                                .font(.system(size: 28, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)
                            Spacer()
                            Text(pomodoro.stateDescription)
                                .font(.caption.bold())
                                .foregroundColor(pomodoro.isFocusPhase ? .green : .orange)
                        }
                        
                        HStack(spacing: 10) {
                            Button(pomodoro.isFocusPhase ? "Pause Sprint" : "Start 25-Min Sprint") {
                                if pomodoro.isFocusPhase {
                                    pomodoro.pauseSprint()
                                } else {
                                    pomodoro.startFocusSprint()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Acoustic Pulse Estimator
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.pink)
                            Text("7. Micro-Pulse Kinematic Estimator")
                                .font(.headline)
                        }
                        Text("Detects microscopic ballistic recoil of the carotid artery pulse in motionless AirPods Pro 2 accelerometer readings.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("\(pulseEstimator.estimatedBPM) BPM")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.pink)
                            Spacer()
                            Text(pulseEstimator.statusMessage)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle("Active Ballistocardiogram Tracking", isOn: $pulseEstimator.isEnabled)
                            .toggleStyle(.switch)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 8. Spatial Soundstage, 9. Vocal Strain Coach, 10. iCloud Sync
                HStack(alignment: .top, spacing: 16) {
                    // Spatial Soundstage
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "speaker.wave.3.fill")
                                .foregroundColor(.orange)
                            Text("8. Spatial App Soundstage")
                                .font(.headline)
                        }
                        Text("Pans macOS audio stereo balance to mirror the screen location of your active window.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Toggle("Window-Aligned Spatial Sound", isOn: $soundstage.isEnabled)
                            .toggleStyle(.switch)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Vocal Strain Coach
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.mint)
                            Text("9. Vocal Cord Strain Guard")
                                .font(.headline)
                        }
                        Text("Alerts if you speak into Zoom/Teams with forward neck compression.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text(vocalCoach.isMicActive ? "🎙️ Mic Active" : "Mic Idle")
                                .font(.caption.bold())
                                .foregroundColor(vocalCoach.isMicActive ? .green : .secondary)
                            Spacer()
                            Text("Events: \(vocalCoach.strainEventsCount)")
                                .font(.caption.monospaced())
                        }
                        
                        Toggle("Protect Laryngeal Posture", isOn: $vocalCoach.isEnabled)
                            .toggleStyle(.switch)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                }
                
                // 10. iCloud Sync
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Image(systemName: "icloud.fill")
                            .foregroundColor(.blue)
                        Text("10. CloudKit / iCloud Keychain Synchronization")
                            .font(.headline)
                        Spacer()
                        Text(cloudSync.syncStatus)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text("Syncs your ergonomic baseline angles, streaks, calibration profile, and daily scores across all your Mac computers seamlessly.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        Toggle("Seamless iCloud Synchronization", isOn: $cloudSync.isSyncEnabled)
                            .toggleStyle(.switch)
                        Spacer()
                        Button("Force Sync Now") {
                            cloudSync.pullLatestCloudData()
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(24)
        }
    }
}
