import SwiftUI
import AirPodsCore

public struct PostureTabContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var glance = GlanceAndLockAutoCalibrator.shared
    @ObservedObject var companion = FloatingMiniDeskCompanionManager.shared
    @ObservedObject var torqueEngine = CervicalSpineTorqueEngine.shared
    @ObservedObject var physioReport = ClinicalPhysioReportExporter.shared
    @ObservedObject var zupt = AnteriorZUPTKinematicEngine.shared
    @ObservedObject var fitSentinel = AirPodsInsertionFitSentinel.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // "Glance & Lock" Autonomous Auto-Calibrate Pill
                if glance.glanceLockHoldProgress > 0 && glance.glanceLockHoldProgress < 1.0 {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.cyan)
                        Text("Auto-Aligning Posture in \(Int(ceil((1.0 - glance.glanceLockHoldProgress) * 2.0)))s...")
                            .font(.caption.bold())
                            .foregroundColor(.cyan)
                        ProgressView(value: glance.glanceLockHoldProgress, total: 1.0)
                            .progressViewStyle(.linear)
                            .tint(.cyan)
                            .frame(width: 80)
                    }
                    .padding(8)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(8)
                }
                
                // Hero Posture Visualizer with CRED Standard Obsidian styling
                PostureVisualizerView(motion: motion)
                
                // Biomechanical Daily Heatmap
                BiomechanicalHeatmapView()
                
                // Slouch-Proof Interlock Warning
                if let interlock = motion.calibrationInterlockAlert {
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.yellow)
                        Text(interlock)
                            .font(.caption.bold())
                            .foregroundColor(.yellow)
                        Spacer()
                        Button("Dismiss") {
                            motion.calibrationInterlockAlert = nil
                        }
                        .buttonStyle(.borderless)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.yellow.opacity(0.12))
                    .cornerRadius(10)
                }
                
                // Action Strip
                HStack(spacing: 12) {
                    CREDTactileButton(action: {
                        _ = motion.calibrateCurrentPosture(force: true)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "scope")
                                .foregroundColor(CREDPalette.champagneGold)
                            Text("CALIBRATE UPRIGHT")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.platinumWhite)
                        }
                    }
                    .disabled(!motion.isConnected)
                    
                    Button(action: {
                        companion.toggleCompanion()
                    }) {
                        Label(companion.isCompanionVisible ? "Hide Mascot" : "Float Posture Buddy", systemImage: "person.crop.artzone")
                    }
                    .buttonStyle(.bordered)
                    
                    // Snooze Menu
                    if motion.isSnoozed {
                        Button(action: { motion.clearSnooze() }) {
                            Label("Clear Snooze", systemImage: "play.circle")
                        }
                        .buttonStyle(.bordered)
                    } else {
                        Menu {
                            Button("Snooze 5 mins") { motion.snooze(minutes: 5) }
                            Button("Snooze 15 mins") { motion.snooze(minutes: 15) }
                            Button("Snooze 30 mins") { motion.snooze(minutes: 30) }
                        } label: {
                            Label("Snooze", systemImage: "moon.zzz")
                        }
                    }
                    
                    Button(action: {
                        motion.toggleSimulation()
                    }) {
                        Label(motion.isSimulated ? "Exit Demo" : "Try Demo", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Reset Today's Stats") {
                        motion.secondsTracked = 0
                        motion.secondsGoodPosture = 0
                        motion.secondsSlouching = 0
                        motion.slouchEventCount = 0
                    }
                    .buttonStyle(.borderless)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 4)
                
                // Kapandji Cervical Spine Torque & Biomechanical Disc Load Card
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "scalemass.fill")
                                .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 15.0 ? CREDPalette.moltenRuby : CREDPalette.emeraldPlasma)
                            Text("CERVICAL SPINE TORQUE & C5–C7 DISC COMPRESSION")
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(CREDPalette.platinumWhite)
                        }
                        Spacer()
                        Text(torqueEngine.currentLoad.discCompressionRisk.rawValue.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 15.0 ? CREDPalette.champagneGold : CREDPalette.emeraldPlasma)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(CREDPalette.insetTrough)
                            .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text(String(format: "%.1f", torqueEngine.currentLoad.effectiveLoadLbs))
                                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                                    .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 15.0 ? CREDPalette.champagneGold : CREDPalette.platinumWhite)
                                Text("LBS")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(CREDPalette.phantomGray)
                                Text("(\(String(format: "%.1f", torqueEngine.currentLoad.effectiveLoadKg)) kg)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(CREDPalette.phantomGray)
                            }
                            Text("EFFECTIVE NECK LOAD")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.phantomGray)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("+\(Int(torqueEngine.currentLoad.extraTorqueOverheadLbs)) LBS")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 0 ? CREDPalette.moltenRuby : CREDPalette.emeraldPlasma)
                            Text("EXTRA SLOUCH SHEAR")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.phantomGray)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(Int(torqueEngine.cumulativeDayTorquePoundHours))")
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.platinumWhite)
                            Text("CUMULATIVE LB-HOURS")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.phantomGray)
                        }
                        
                        Divider().frame(height: 36)
                        
                        // ZUPT Anterior Translation (Tech Neck Detector)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(String(format: "%+.1f", zupt.anteriorDisplacementCm))
                                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                                    .foregroundColor(zupt.isTechNeckDetected ? CREDPalette.champagneGold : CREDPalette.emeraldPlasma)
                                Text("CM")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(CREDPalette.phantomGray)
                            }
                            Text(zupt.isTechNeckDetected ? "TECH NECK POKE" : "CHIN FORWARD")
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(zupt.isTechNeckDetected ? CREDPalette.champagneGold : CREDPalette.phantomGray)
                        }
                        
                        Spacer()
                        
                        // 1-Click Clinical PDF Report Exporter
                        Button(action: {
                            _ = physioReport.generateClinicalReportPDF()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(CREDPalette.electricCyan)
                                Text("EXPORT PHYSIO PDF")
                                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                                    .foregroundColor(CREDPalette.platinumWhite)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(CREDPalette.insetTrough)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(CREDPalette.specularRimStroke, lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    HStack {
                        Text(zupt.statusDescription.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(zupt.currentPattern == .optimal ? CREDPalette.emeraldPlasma : CREDPalette.champagneGold)
                        Spacer()
                        Text(zupt.activityMode == .walkingActive ? "🚶‍♂️ WALKING ACTIVE (\(String(format: "%.1f", zupt.stepCadenceHz)) Hz)" : "💻 DESK SITTING MODE")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(CREDPalette.phantomGray)
                    }
                    
                    Text(torqueEngine.reliefCallToAction)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 10.0 ? CREDPalette.champagneGold : CREDPalette.phantomGray)
                    
                    Divider()
                    
                    HStack {
                        HStack(spacing: 5) {
                            Circle().fill(CREDPalette.emeraldPlasma).frame(width: 6, height: 6)
                            Text("PERMANENT EAR-FIT HORIZON")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(CREDPalette.emeraldPlasma)
                        }
                        Spacer()
                        Button(action: {
                            fitSentinel.isFitGuidePresented = true
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: fitSentinel.isProperlySeated ? "ear.badge.checkmark" : "ear.trianglebadge.exclamationmark")
                                    .foregroundColor(fitSentinel.isProperlySeated ? CREDPalette.emeraldPlasma : CREDPalette.champagneGold)
                                Text("\(fitSentinel.fitQualityScore)% SEAL")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(fitSentinel.isProperlySeated ? CREDPalette.emeraldPlasma : CREDPalette.champagneGold)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
                .credCard(cornerRadius: 16, elevation: 6)
            }
            .padding(20)
        }
    }
}
