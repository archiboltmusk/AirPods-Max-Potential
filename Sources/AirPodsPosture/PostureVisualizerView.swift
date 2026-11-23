import SwiftUI
import AppKit

public struct PostureVisualizerView: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    
    enum VisualizerRigMode: String, CaseIterable, Identifiable {
        case hergeCompanion = "Ligne Claire Avatar"
        case humanFace = "3D Human Face & AirPods"
        case anatomical = "Metal Anatomical Rig"
        case agamemnon = "Agamemnon Odyssey"
        case avatar = "2.5D Spatial Head"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .hergeCompanion: return "person.crop.artzone"
            case .humanFace: return "face.smiling"
            case .anatomical: return "cube.transparent.fill"
            case .agamemnon: return "shield.lefthalf.filled"
            case .avatar: return "person.crop.circle"
            }
        }
    }
    
    @AppStorage("postureVisualizerRig") private var selectedRigMode: VisualizerRigMode = .humanFace
    @AppStorage("postureFaceEarwear") private var earwearStyle: EarwearStyle = .airPodsPro
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    public init(motion: MotionManager) {
        self.motion = motion
    }
    
    private var currentTier: CREDPostureTier {
        CREDPostureTier.from(score: motion.postureScore)
    }
    
    private var statusColor: Color {
        currentTier.accentColor
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // MARK: - CRED Top Status & Privilege Header Bar
            HStack(alignment: .center) {
                // Posture Profile Selector (Tactile Pill)
                Menu {
                    ForEach(PostureProfile.allCases) { profile in
                        Button(action: {
                            motion.activeProfile = profile
                            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                        }) {
                            Label(profile.rawValue, systemImage: profile.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: motion.activeProfile.icon)
                            .foregroundColor(CREDPalette.champagneGold)
                            .font(.system(size: 13, weight: .bold))
                        Text(motion.activeProfile.rawValue.uppercased())
                            .font(.system(size: 11, weight: .black, design: .monospaced))
                            .foregroundColor(CREDPalette.platinumWhite)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(CREDPalette.phantomGray)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(CREDPalette.cardElevated)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(CREDPalette.specularRimStroke, lineWidth: 1)
                    )
                }
                .menuStyle(BorderlessButtonMenuStyle())
                
                Spacer()
                
                // CRED Member Tier Privilege Badge
                HStack(spacing: 10) {
                    if audioMonitor.isMicrophoneInUse {
                        HStack(spacing: 5) {
                            Circle().fill(Color.purple).frame(width: 6, height: 6)
                            Text("MIC ACTIVE")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(.purple)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.12))
                        .cornerRadius(6)
                    }
                    
                    if motion.isSnoozed {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 9))
                                .foregroundColor(CREDPalette.electricCyan)
                            Text("\(Int(ceil(motion.snoozeTimeRemaining / 60)))M SNOOZE")
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                                .foregroundColor(CREDPalette.electricCyan)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(CREDPalette.electricCyan.opacity(0.12))
                        .cornerRadius(6)
                    }
                    
                    // CRED Member Status Pill
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(statusColor.opacity(0.25))
                                .frame(width: 14, height: 14)
                            Circle()
                                .fill(statusColor)
                                .frame(width: 7, height: 7)
                        }
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(currentTier.rawValue)
                                .font(.system(size: 10, weight: .black, design: .monospaced))
                                .foregroundColor(statusColor)
                            Text("\(motion.postureScore)% OPTIMAL")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.platinumWhite)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(CREDPalette.insetTrough)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(currentTier.rimGradient, lineWidth: 1.2)
                    )
                    .shadow(color: statusColor.opacity(0.25), radius: 6)
                }
            }
            
            // MARK: - Grace Period Warning Bar (Molten Ruby Inset Trough)
            if motion.postureState == .warning {
                HStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(CREDPalette.moltenRuby)
                        .font(.system(size: 14, weight: .bold))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("CERVICAL ANGLE DRIFT DETECTED")
                            .font(.system(size: 10, weight: .black, design: .monospaced))
                            .foregroundColor(CREDPalette.moltenRuby)
                        Text("Re-align posture to retain Member Luminary status")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(CREDPalette.platinumWhite.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Text(String(format: "ALERT IN %.1fS", (1.0 - motion.warningProgress) * motion.gracePeriodSeconds))
                        .font(.system(size: 10, weight: .black, design: .monospaced))
                        .foregroundColor(CREDPalette.moltenRuby)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(CREDPalette.insetTrough)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(CREDPalette.moltenRuby.opacity(0.5), lineWidth: 1)
                )
            }
            
            // MARK: - THE BIOMETRIC OBSIDIAN BLACK CARD (Hero 3D Stage)
            ZStack {
                // Card Background & Specular Layer
                RoundedRectangle(cornerRadius: 22)
                    .fill(
                        LinearGradient(
                            colors: [CREDPalette.cardElevated, CREDPalette.cardSurface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 22)
                            .stroke(currentTier.rimGradient, lineWidth: 1.5)
                    )
                    .shadow(color: Color.black.opacity(0.9), radius: 18, x: 0, y: 10)
                    .shadow(color: statusColor.opacity(0.18), radius: 24, x: 0, y: 4)
                
                // Dynamic Metallic Sheen Sweep
                CREDSheenSweepView()
                    .cornerRadius(22)
                
                // Card Foreground Content
                VStack(spacing: 0) {
                    // Card Top Laser-Etched Header & Hologram Chip
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 10, weight: .black))
                                    .foregroundColor(CREDPalette.champagneGold)
                                Text("AIRPODS BIOMETRIC PRIVILEGE")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(CREDPalette.platinumWhite.opacity(0.6))
                            }
                            Text(currentTier.tierNumber)
                                .font(.system(size: 11, weight: .black, design: .monospaced))
                                .foregroundColor(statusColor)
                        }
                        
                        Spacer()
                        
                        // Hologram EMV Sensor Chip
                        HStack(spacing: 8) {
                            VStack(alignment: .trailing, spacing: 1) {
                                Text("H2 CORE-MOTION")
                                    .font(.system(size: 8, weight: .black, design: .monospaced))
                                    .foregroundColor(CREDPalette.phantomGray)
                                Text("60HZ LOCKED")
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .foregroundColor(CREDPalette.emeraldPlasma)
                            }
                            CREDEMVChipView()
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Central 3D Visualizer Rig
                    ZStack {
                        switch selectedRigMode {
                        case .hergeCompanion:
                            HergePostureAvatarView(
                                pitch: motion.deltaPitch,
                                roll: motion.deltaRoll,
                                postureScore: motion.postureScore
                            )
                        case .humanFace:
                            HumanFace3DView(
                                pitch: motion.deltaPitch,
                                roll: motion.deltaRoll,
                                yaw: motion.deltaYaw,
                                postureScore: motion.postureScore,
                                earwearStyle: earwearStyle
                            )
                            .accessibilityHidden(true)
                        case .agamemnon:
                            AgamemnonOdysseySpineView(
                                pitch: motion.deltaPitch,
                                roll: motion.deltaRoll,
                                yaw: motion.deltaYaw,
                                postureScore: motion.postureScore
                            )
                        case .anatomical:
                            AnatomicalSpine3DView(
                                pitch: motion.deltaPitch,
                                roll: motion.deltaRoll,
                                yaw: motion.deltaYaw,
                                postureScore: motion.postureScore
                            )
                        case .avatar:
                            ZStack {
                                Circle()
                                    .stroke(statusColor.opacity(0.18), lineWidth: 28)
                                    .frame(width: 190, height: 190)
                                Circle()
                                    .stroke(statusColor.opacity(0.35), lineWidth: 2)
                                    .frame(width: 150, height: 150)
                                HeadModelView(statusColor: statusColor)
                                    .rotation3DEffect(.degrees(-motion.deltaPitch), axis: (x: 1, y: 0, z: 0))
                                    .rotation3DEffect(.degrees(motion.deltaRoll), axis: (x: 0, y: 0, z: 1))
                                    .rotation3DEffect(.degrees(-motion.deltaYaw), axis: (x: 0, y: 1, z: 0))
                            }
                            .frame(height: 200)
                        }
                    }
                    .frame(height: 205)
                    
                    Spacer()
                    
                    // Card Bottom Laser Engraving & Re-Calibrate Tactile Actuator
                    HStack(alignment: .center) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(motion.isConnected ? CREDPalette.emeraldPlasma : CREDPalette.moltenRuby)
                                .frame(width: 6, height: 6)
                            Text("APPLE AIRPODS MAX/PRO · SYNCED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(CREDPalette.platinumWhite.opacity(0.55))
                        }
                        
                        Spacer()
                        
                        // Tactile Re-Calibrate Actuator
                        CREDTactileButton(action: {
                            _ = motion.calibrateCurrentPosture(force: true)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "scope")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(CREDPalette.champagneGold)
                                Text("RE-CALIBRATE ZERO")
                                    .font(.system(size: 9, weight: .black, design: .monospaced))
                                    .foregroundColor(CREDPalette.platinumWhite)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 16)
                }
            }
            .frame(height: 300)
            
            if selectedRigMode == .humanFace {
                Picker("Face appearance", selection: $earwearStyle) {
                    ForEach(EarwearStyle.allCases) { style in
                        Label(style.rawValue, systemImage: style.icon).tag(style)
                    }
                }
                .pickerStyle(.segmented)
            }

            // MARK: - CRED Rig Mode Switcher (Sunken Dock)
            HStack(spacing: 6) {
                ForEach(VisualizerRigMode.allCases) { mode in
                    let isSelected = selectedRigMode == mode
                    Button(action: {
                        selectedRigMode = mode
                        NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: .bold))
                            Text(mode.rawValue.uppercased())
                                .font(.system(size: 9, weight: .black, design: .monospaced))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(
                            isSelected ?
                                LinearGradient(colors: [CREDPalette.cardHighlight, CREDPalette.cardElevated], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [Color.clear, Color.clear], startPoint: .top, endPoint: .bottom)
                        )
                        .cornerRadius(8)
                        .foregroundColor(isSelected ? CREDPalette.platinumWhite : CREDPalette.phantomGray)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(isSelected ? CREDPalette.specularRimStroke : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(4)
            .background(CREDPalette.insetTrough)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CREDPalette.troughRimStroke, lineWidth: 1)
            )
            
            // MARK: - Concentric Activity Rings (CRED Obsidian Chamber)
            ActivityRingsDashboardView(
                postureScore: Double(motion.postureScore),
                hydrationGlasses: HydrationTracker.shared.waterGlassesLogged,
                romScore: Double(CervicalROMDiagnostic.shared.flexibilityScore)
            )
            .padding(16)
            .credCard(cornerRadius: 16, elevation: 8)
            
            // MARK: - Precision Axis Telemetry (Sunken CNC Milled Troughs)
            HStack(spacing: 14) {
                CREDAxisMeterCard(
                    title: "PITCH (SAGITTAL SLOUCH)",
                    value: motion.deltaPitch,
                    threshold: motion.pitchThreshold,
                    unit: "°",
                    description: motion.deltaPitch < -motion.pitchThreshold ? "FORWARD SLOUCH" : (motion.deltaPitch > motion.pitchThreshold ? "CEILING TILT" : "LUMINARY NEUTRAL"),
                    color: abs(motion.deltaPitch) > motion.pitchThreshold ? CREDPalette.moltenRuby : CREDPalette.emeraldPlasma
                )
                
                CREDAxisMeterCard(
                    title: "ROLL (LATERAL TILT)",
                    value: motion.deltaRoll,
                    threshold: motion.rollThreshold,
                    unit: "°",
                    description: motion.deltaRoll < -motion.rollThreshold ? "LEFT SCOLIOSIS" : (motion.deltaRoll > motion.rollThreshold ? "RIGHT SCOLIOSIS" : "AXIAL SYMMETRY"),
                    color: abs(motion.deltaRoll) > motion.rollThreshold ? CREDPalette.champagneGold : CREDPalette.emeraldPlasma
                )
                
                CREDAxisMeterCard(
                    title: "YAW (CERVICAL ROTATION)",
                    value: motion.deltaYaw,
                    threshold: 30.0,
                    unit: "°",
                    description: abs(motion.deltaYaw) > 20.0 ? "HEAD TURNED" : "FORWARD RETENTION",
                    color: abs(motion.deltaYaw) > 25.0 ? CREDPalette.electricCyan : CREDPalette.phantomGray
                )
            }
        }
        .padding(20)
        .background(CREDPalette.canvasBg)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(CREDPalette.specularRimStroke, lineWidth: 1.2)
        )
        .shadow(color: Color.black.opacity(0.95), radius: 30, x: 0, y: 15)
    }
}

// MARK: - CRED Precision Axis Meter (Sunken Trough)
public struct CREDAxisMeterCard: View {
    let title: String
    let value: Double
    let threshold: Double
    let unit: String
    let description: String
    let color: Color
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(size: 8.5, weight: .black, design: .monospaced))
                    .foregroundColor(CREDPalette.phantomGray)
                Spacer()
                Circle()
                    .fill(color)
                    .frame(width: 5, height: 5)
                    .shadow(color: color.opacity(0.6), radius: 3)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%+.1f", value))
                    .font(.system(size: 24, weight: .heavy, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(color)
                Text(unit)
                    .font(.system(size: 13, weight: .black, design: .monospaced))
                    .foregroundColor(CREDPalette.phantomGray)
            }
            
            // Precision Laser Gauge with Center Detent
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Sunken Trough Track
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.black.opacity(0.75))
                        .overlay(
                            RoundedRectangle(cornerRadius: 3)
                                .stroke(Color.white.opacity(0.06), lineWidth: 0.5)
                        )
                    
                    // Zero Neutral Center Hairline
                    Rectangle()
                        .fill(CREDPalette.phantomGray.opacity(0.5))
                        .frame(width: 1.5)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    
                    // Active Value Filament
                    let halfW = geo.size.width / 2.0
                    let clampedVal = max(-threshold * 2.0, min(threshold * 2.0, value))
                    let widthVal = abs(clampedVal / (threshold * 2.0)) * halfW
                    let startX = value >= 0 ? halfW : (halfW - widthVal)
                    
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.7), color],
                                startPoint: value >= 0 ? .leading : .trailing,
                                endPoint: value >= 0 ? .trailing : .leading
                            )
                        )
                        .frame(width: max(2, widthVal), height: geo.size.height)
                        .offset(x: startX)
                        .shadow(color: color.opacity(0.5), radius: 4)
                }
            }
            .frame(height: 5)
            
            Text(description.uppercased())
                .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                .foregroundColor(color.opacity(0.9))
                .lineLimit(1)
        }
        .padding(14)
        .credInsetTrough(cornerRadius: 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(String(format: "%+.1f", value)) degrees, \(description)")
        .frame(maxWidth: .infinity)
    }
}

// MARK: - 2.5D Head Model View
struct HeadModelView: View {
    let statusColor: Color
    
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [CREDPalette.cardElevated, CREDPalette.cardSurface],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 85, height: 100)
                .overlay(
                    Capsule()
                        .stroke(CREDPalette.specularRimStroke, lineWidth: 1.2)
                )
            
            VStack {
                Triangle()
                    .fill(CREDPalette.champagneGold)
                    .frame(width: 10, height: 12)
                    .offset(y: 4)
                Spacer()
            }
            .frame(width: 85, height: 100)
            
            AirPodsMaxHeadband()
                .stroke(
                    LinearGradient(
                        colors: [CREDPalette.phantomGray, CREDPalette.platinumWhite, CREDPalette.phantomGray],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                )
                .frame(width: 115, height: 100)
                .offset(y: -18)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(CREDPalette.cardHighlight)
                .frame(width: 20, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor, lineWidth: 2)
                )
                .offset(x: -52, y: 0)
                .shadow(color: statusColor.opacity(0.6), radius: 8)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(CREDPalette.cardHighlight)
                .frame(width: 20, height: 38)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(statusColor, lineWidth: 2)
                )
                .offset(x: 52, y: 0)
                .shadow(color: statusColor.opacity(0.6), radius: 8)
        }
        .frame(width: 150, height: 150)
    }
}

struct AirPodsMaxHeadband: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: CGPoint(x: rect.midX, y: rect.maxY - 10),
            radius: rect.width / 2.0,
            startAngle: .degrees(190),
            endAngle: .degrees(350),
            clockwise: false
        )
        return path
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
