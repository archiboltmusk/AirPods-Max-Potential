import SwiftUI

public struct PostureVisualizerView: View {
    @ObservedObject var motion: MotionManager
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    
    enum VisualizerRigMode: String, CaseIterable, Identifiable {
        case humanFace = "3D Human Face & AirPods"
        case anatomical = "Metal Anatomical Rig"
        case agamemnon = "Agamemnon Odyssey"
        case avatar = "2.5D Spatial Head"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .humanFace: return "face.smiling"
            case .anatomical: return "cube.transparent.fill"
            case .agamemnon: return "shield.lefthalf.filled"
            case .avatar: return "person.crop.circle"
            }
        }
    }
    
    @State private var selectedRigMode: VisualizerRigMode = .humanFace
    
    public init(motion: MotionManager) {
        self.motion = motion
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
        VStack(spacing: 16) {
            // Streamlined Header Bar
            HStack {
                // Posture Profile Selector
                Menu {
                    ForEach(PostureProfile.allCases) { profile in
                        Button(action: {
                            motion.activeProfile = profile
                        }) {
                            Label(profile.rawValue, systemImage: profile.icon)
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: motion.activeProfile.icon)
                            .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                        Text(motion.activeProfile.rawValue)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                
                Spacer()
                
                // Unified Status Capsule (Right)
                HStack(spacing: 10) {
                    if audioMonitor.isMicrophoneInUse {
                        HStack(spacing: 4) {
                            Circle().fill(Color.purple).frame(width: 6, height: 6)
                            Text("Mic")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.purple)
                        }
                    }
                    
                    if motion.isSnoozed {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.blue)
                            Text("\(Int(ceil(motion.snoozeTimeRemaining / 60)))m")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.blue)
                        }
                    }
                    
                    // Live Alignment Score
                    HStack(spacing: 5) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 7, height: 7)
                        Text("\(motion.postureScore)%")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(statusColor)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(statusColor.opacity(0.12))
                    .clipShape(Capsule())
                }
                .padding(4)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.8))
                .cornerRadius(12)
            }
            
            // Grace Period Warning Bar
            if motion.postureState == .warning {
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Slouch posture detected — sit up to clear")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                        Spacer()
                        Text(String(format: "Alert in %.1fs", (1.0 - motion.warningProgress) * motion.gracePeriodSeconds))
                            .font(.caption2.monospaced())
                            .foregroundColor(.secondary)
                    }
                    ProgressView(value: motion.warningProgress)
                        .tint(.orange)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Dynamic 3D Rig Rendering based on selectedRigMode
            switch selectedRigMode {
            case .humanFace:
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.15), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.cyan.opacity(0.15), radius: 15)
                    
                    HumanFace3DView(
                        pitch: motion.deltaPitch,
                        roll: motion.deltaRoll,
                        yaw: motion.deltaYaw,
                        postureScore: motion.postureScore
                    )
                    
                    VStack {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "face.smiling.fill")
                                    .foregroundColor(.cyan)
                                Text("3D Studio Portrait: Human Head & AirPods Pro 2 Rig")
                                    .font(.caption2.bold())
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text(motion.postureScore >= 80 ? "Optimal Neutral Alignment" : "Forward Neck Flexion")
                                .font(.caption2.bold())
                                .foregroundColor(motion.postureScore >= 80 ? .green : .orange)
                        }
                        .padding(14)
                        Spacer()
                    }
                }
                .frame(height: 270)
                
            case .agamemnon:
                ZStack {
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    LinearGradient(
                                        colors: [Color.yellow.opacity(0.35), Color.orange.opacity(0.15), .clear],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1.5
                                )
                        )
                        .shadow(color: Color.yellow.opacity(0.15), radius: 15)
                    
                    AgamemnonOdysseySpineView(
                        pitch: motion.deltaPitch,
                        roll: motion.deltaRoll,
                        yaw: motion.deltaYaw,
                        postureScore: motion.postureScore
                    )
                    
                    VStack {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "shield.fill")
                                    .foregroundColor(.yellow)
                                Text("Agamemnon Odyssey Spine: Mycenaean Gold & Aegean Disc Rig")
                                    .font(.caption2.bold())
                                    .foregroundColor(.primary)
                            }
                            Spacer()
                            Text(motion.postureScore >= 80 ? "Heroic Alignment (Odyssey Core: 100%)" : "Titan Compression Detected")
                                .font(.caption2.bold())
                                .foregroundColor(motion.postureScore >= 80 ? .green : .orange)
                        }
                        .padding(14)
                        Spacer()
                    }
                }
                .frame(height: 270)
                
            case .anatomical:
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(LinearGradient(colors: [.white.opacity(0.15), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                        )
                    
                    AnatomicalSpine3DView(
                        pitch: motion.deltaPitch,
                        roll: motion.deltaRoll,
                        yaw: motion.deltaYaw,
                        postureScore: motion.postureScore
                    )
                    
                    VStack {
                        HStack {
                            Text("3D Metal/SceneKit Cervical-Thoracic Rig (C1–C7)")
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(motion.postureScore >= 80 ? "Optimal Alignment" : "Intervertebral Compression")
                                .font(.caption2.bold())
                                .foregroundColor(statusColor)
                        }
                        .padding(12)
                        Spacer()
                    }
                }
                .frame(height: 250)
                
            case .avatar:
                ZStack {
                    // Radar Rings
                    Circle()
                        .stroke(statusColor.opacity(0.15), lineWidth: 32)
                        .frame(width: 220, height: 220)
                
                Circle()
                    .stroke(statusColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 170, height: 170)
                
                // Crosshairs
                Path { path in
                    path.move(to: CGPoint(x: 110, y: 30))
                    path.addLine(to: CGPoint(x: 110, y: 190))
                    path.move(to: CGPoint(x: 30, y: 110))
                    path.addLine(to: CGPoint(x: 190, y: 110))
                }
                .stroke(Color.primary.opacity(0.1), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                .frame(width: 220, height: 220)
                
                // Head + AirPods Max Model
                HeadModelView(statusColor: statusColor)
                    .rotation3DEffect(.degrees(-motion.deltaPitch), axis: (x: 1, y: 0, z: 0))
                    .rotation3DEffect(.degrees(motion.deltaRoll), axis: (x: 0, y: 0, z: 1))
                    .rotation3DEffect(.degrees(-motion.deltaYaw), axis: (x: 0, y: 1, z: 0))
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.75), value: motion.deltaPitch)
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.75), value: motion.deltaRoll)
                    .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.75), value: motion.deltaYaw)
                
                // Gesture popup banner
                if let ts = motion.gestureTimestamp, Date().timeIntervalSince(ts) < 2.0 {
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: motion.lastDetectedGesture == .nod ? "hand.thumbsup.fill" : "hand.raised.fill")
                            Text("Gesture: \(motion.lastDetectedGesture.rawValue)")
                                .font(.caption.bold())
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.accentColor, lineWidth: 1))
                        .shadow(radius: 6)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                    .frame(height: 220)
                }
            }
            .frame(height: 220)
            }
            
            // Clean Segmented Rig Mode Switcher
            Picker("3D Viewport Rig", selection: $selectedRigMode) {
                ForEach(VisualizerRigMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 4)
            
            // Apple-Style Concentric Activity Rings
            ActivityRingsDashboardView(
                postureScore: Double(motion.postureScore),
                hydrationGlasses: HydrationTracker.shared.waterGlassesLogged,
                romScore: Double(CervicalROMDiagnostic.shared.flexibilityScore)
            )
            
            // Detailed Axis Meters
            HStack(spacing: 14) {
                AxisMeterCard(
                    title: "Pitch (Slouch)",
                    value: motion.deltaPitch,
                    threshold: motion.pitchThreshold,
                    unit: "°",
                    description: motion.deltaPitch < -motion.pitchThreshold ? "Slouching Down" : (motion.deltaPitch > motion.pitchThreshold ? "Looking Up" : "Good"),
                    color: abs(motion.deltaPitch) > motion.pitchThreshold ? .red : .green
                )
                
                AxisMeterCard(
                    title: "Roll (Tilt)",
                    value: motion.deltaRoll,
                    threshold: motion.rollThreshold,
                    unit: "°",
                    description: motion.deltaRoll < -motion.rollThreshold ? "Tilted Left" : (motion.deltaRoll > motion.rollThreshold ? "Tilted Right" : "Level"),
                    color: abs(motion.deltaRoll) > motion.rollThreshold ? .orange : .green
                )
                
                AxisMeterCard(
                    title: "Yaw (Turn)",
                    value: motion.deltaYaw,
                    threshold: 30.0,
                    unit: "°",
                    description: abs(motion.deltaYaw) > 20.0 ? "Turned Away" : "Front Facing",
                    color: abs(motion.deltaYaw) > 25.0 ? .blue : .secondary
                )
            }
        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }
}

// 2.5D Stylized Avatar with AirPods Max
struct HeadModelView: View {
    let statusColor: Color
    
    var body: some View {
        ZStack {
            // Head Silhouette
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.2), Color.accentColor.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 95, height: 110)
                .overlay(
                    Capsule()
                        .stroke(Color.primary.opacity(0.25), lineWidth: 1.5)
                )
            
            // Face Direction
            VStack {
                Triangle()
                    .fill(Color.primary.opacity(0.35))
                    .frame(width: 10, height: 12)
                    .offset(y: 4)
                Spacer()
            }
            .frame(width: 95, height: 110)
            
            // AirPods Max Headband Arc
            AirPodsMaxHeadband()
                .stroke(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.6), Color.primary.opacity(0.8), Color.primary.opacity(0.6)],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 130, height: 115)
                .offset(y: -22)
            
            // Left Ear Cup
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlAccentColor).opacity(0.25))
                .frame(width: 22, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(statusColor, lineWidth: 2.5)
                )
                .offset(x: -60, y: 0)
                .shadow(color: statusColor.opacity(0.5), radius: 6)
            
            // Right Ear Cup
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(NSColor.controlAccentColor).opacity(0.25))
                .frame(width: 22, height: 42)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(statusColor, lineWidth: 2.5)
                )
                .offset(x: 60, y: 0)
                .shadow(color: statusColor.opacity(0.5), radius: 6)
        }
        .frame(width: 170, height: 170)
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

struct AxisMeterCard: View {
    let title: String
    let value: Double
    let threshold: Double
    let unit: String
    let description: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(String(format: "%+.1f", value))
                    .font(.system(.title2, design: .monospaced, weight: .bold))
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.1))
                    
                    Rectangle()
                        .fill(Color.secondary.opacity(0.4))
                        .frame(width: 2)
                        .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    
                    let halfW = geo.size.width / 2.0
                    let clampedVal = max(-threshold * 2.0, min(threshold * 2.0, value))
                    let widthVal = abs(clampedVal / (threshold * 2.0)) * halfW
                    let startX = value >= 0 ? halfW : (halfW - widthVal)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(2, widthVal), height: geo.size.height)
                        .offset(x: startX)
                }
            }
            .frame(height: 6)
            
            Text(description)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .frame(maxWidth: .infinity)
    }
}
