import SwiftUI

public struct EcosystemBridgesView: View {
    @ObservedObject var sentinel = OpticalContinuitySentinel.shared
    @ObservedObject var watchBridge = AppleWatchBridgeManager.shared
    @ObservedObject var visionBridge = TrueDepthVisionBridgeManager.shared
    @ObservedObject var smartDesk = SmartDeskBLEController.shared
    @ObservedObject var rsaEngine = RespiratorySinusArrhythmiaEngine.shared
    @ObservedObject var squad = StandUpSquadLANManager.shared
    @ObservedObject var ideSentinel = TypingFlowStateGatingManager.shared
    @ObservedObject var vocalCoach = VocalStrainCoach.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "applewatch.and.arrow.forward")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cross-Device Hardware & Physiological Sensor Fusion")
                            .font(.title2.bold())
                        Text("Unify Apple Watch, Continuity Camera, Smart Desks, Vagal Tone RSA, and Developer IDE Sentinels.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                // 0. FaceTime HD & Continuity Camera Optical Sentinel (AirPods In-Case Fallback)
                OpticalCameraPreviewView()
                
                // 1. Respiratory Sinus Arrhythmia (RSA) & Vagal Tone Sync
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.teal)
                            .font(.title3)
                        Text("1. Respiratory Sinus Arrhythmia (RSA) & Vagal Tone Posture Sync")
                            .font(.headline)
                        Spacer()
                        Text("\(rsaEngine.vagalToneScore)/100 Index")
                            .font(.caption.bold())
                            .foregroundColor(.teal)
                    }
                    
                    Text("Correlates cervical spine lordosis with thoracic cavity expansion (+22% volume) and parasympathetic vagus nerve activation, lowering stress hormones.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(rsaEngine.thoracicExpansionPercent)%")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.teal)
                            Text("Thoracic Lung Expansion")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "+%.1f ms", rsaEngine.hrvBoostFromUprightMs))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("HRV Upright Posture Boost")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.2fx", rsaEngine.rsaGainRatio))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                            Text("RSA Vagus Coupling Ratio")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(rsaEngine.parasympatheticState)
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 2. Developer IDE & Typing Flow-State Ergonomic Sentinel
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "curlybraces.square.fill")
                            .foregroundColor(.indigo)
                            .font(.title3)
                        Text("2. Developer IDE Flow-State Sentinel & Laryngeal Speech Coach")
                            .font(.headline)
                        Spacer()
                        Text(ideSentinel.statusMessage)
                            .font(.caption.bold())
                            .foregroundColor(.indigo)
                    }
                    
                    Text("Suppresses jarring audio chimes in favor of ambient screen glows during intense coding in Xcode, VS Code, Cursor, or Terminal. Monitors microphone during calls to prevent vocal tract pinch.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(ideSentinel.currentWPM) WPM")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.indigo)
                            Text("Typing Velocity")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ideSentinel.currentIDEAppName)
                                .font(.system(size: 20, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Active Environment")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(vocalCoach.laryngealCompressionPercent)%")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(vocalCoach.laryngealCompressionPercent > 25 ? .red : .teal)
                            Text("Laryngeal Vocal Pinch")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("Flow Gate Active", isOn: $ideSentinel.isFlowGatingEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 3. Zero-Cloud P2P Stand-Up Squad LAN
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "person.3.sequence.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                        Text("3. Zero-Cloud Peer-to-Peer Stand-Up Squads (Local LAN)")
                            .font(.headline)
                        Spacer()
                        Text("Squad Avg: \(squad.squadAverageScore)% • \(squad.squadStandingRatio)% Standing")
                            .font(.caption.bold())
                            .foregroundColor(.green)
                    }
                    
                    Text("Bonjour local network circle with office teammates. 100% private with zero cloud telemetry. Celebrate upright posture streaks together.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 8) {
                        ForEach(squad.squadPeers) { peer in
                            HStack {
                                Image(systemName: peer.isStandingDeskActive ? "figure.stand" : "figure.seated.side")
                                    .foregroundColor(peer.isStandingDeskActive ? .green : .secondary)
                                Text(peer.displayName)
                                    .font(.system(size: 13, weight: .semibold))
                                Spacer()
                                Text("\(peer.uprightMinutesStreak)m Upright")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("\(peer.postureScore)%")
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                                Button("Cheer 🙌") {
                                    squad.cheerPeer(id: peer.id)
                                }
                                .font(.caption2.bold())
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 4. Apple Watch Fusion
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(.pink)
                            .font(.title3)
                        Text("4. Apple Watch Wrist IMU & Taptic Feedback Engine")
                            .font(.headline)
                        Spacer()
                        Text(watchBridge.statusMessage)
                            .font(.caption.bold())
                            .foregroundColor(watchBridge.thoracicSlumpDetected ? .red : .green)
                    }
                    
                    Text("Combines AirPods cervical neck angles with Apple Watch forearm tilt and typing angles to identify Thoracic Spine Slumping (hunched upper back).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(watchBridge.heartRateBPM)) BPM")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.pink)
                            Text("Apple Watch Optical Pulse")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(watchBridge.hrvSDNN)) ms")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                            Text("Heart Rate Variability (SDNN)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f°", watchBridge.wristPitch))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("Forearm Typing Angle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("Silent Wrist Haptic Alerts", isOn: $watchBridge.hapticFeedbackEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 5. Smart Standing Desk BLE & HomeKit Controller
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "table.furniture")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("5. Smart Standing Desk Bluetooth & Matter Automation")
                            .font(.headline)
                        Spacer()
                        Text(smartDesk.statusLog)
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    
                    Text("Connects over CoreBluetooth to automatic motorized standing desks (Linak, Idasen, Fully). Automatically transitions when sedentary slouch limits are reached.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(smartDesk.currentDeskHeightCm)) cm")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("Current Height")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Glide to Standing (106cm)") {
                            smartDesk.triggerGlideToStanding()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Glide to Sitting (72cm)") {
                            smartDesk.triggerGlideToSitting()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Toggle("Auto-Elevate Desk on Chronic Slouch", isOn: $smartDesk.isAutoGlideEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(24)
        }
    }
}
