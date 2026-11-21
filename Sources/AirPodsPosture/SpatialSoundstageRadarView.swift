import SwiftUI

public struct SpatialSoundstageRadarView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var spatial = SpatialAudioBiofeedback.shared
    @ObservedObject var multiDisplay = MultiDisplaySpatialGridMapper.shared
    @ObservedObject var spineStress = CervicalVertebralStressEngine.shared
    @ObservedObject var haptics = SyntheticEarHapticEngine.shared
    
    @State private var pulseAnimation: Double = 1.0
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 4) {
                    HStack {
                        Image(systemName: "dot.radiowaves.left.and.right")
                            .font(.title2)
                            .foregroundColor(.accentColor)
                        Text("Spatial Soundstage 360° Radar & Biomechanics")
                            .font(.title3.bold())
                    }
                    Text("Real-time polar mapping of head azimuth orientation, multi-display targets, spatial audio gravitation, and C1–C7 spinal load.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 10)
                
                // Polar Radar Scope
                ZStack {
                    // Outer Ambient Radar Glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.accentColor.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 180
                            )
                        )
                        .frame(width: 330, height: 330)
                    
                    // Concentric Range Rings
                    Circle()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
                        .frame(width: 110, height: 110)
                    
                    Circle()
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                        .frame(width: 220, height: 220)
                    
                    Circle()
                        .strokeBorder(Color.white.opacity(0.16), lineWidth: 1.2)
                        .frame(width: 310, height: 310)
                    
                    // Crosshairs
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 1, height: 310)
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 310, height: 1)
                    
                    // Cardinal Degree Labels
                    Group {
                        Text("0° (Primary)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                            .offset(y: -142)
                        Text("+90° (Right)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .offset(x: 125)
                        Text("-90° (Left)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .offset(x: -125)
                        Text("180°")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                            .offset(y: 142)
                    }
                    
                    // Secondary Display Target Nodes
                    DisplayNode(angleDeg: -35, label: "Left Display", icon: "display", isActive: multiDisplay.activeDisplayId == "left")
                    DisplayNode(angleDeg: 38, label: "Right Display", icon: "display", isActive: multiDisplay.activeDisplayId == "right")
                    DisplayNode(angleDeg: 0, label: "Center Retina", icon: "laptopcomputer", isActive: multiDisplay.activeDisplayId == "primary")
                    
                    // Live Head Orientation Needle & Cone
                    ZStack {
                        // Vision & Audio Cone
                        Path { path in
                            path.move(to: CGPoint(x: 155, y: 155))
                            path.addArc(
                                center: CGPoint(x: 155, y: 155),
                                radius: 135,
                                startAngle: .degrees(-22 - 90),
                                endAngle: .degrees(22 - 90),
                                clockwise: false
                            )
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [
                                    motion.postureState == .optimal ? Color.cyan.opacity(0.3) :
                                    (motion.postureState == .warning ? Color.orange.opacity(0.3) : Color.red.opacity(0.3)),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 310, height: 310)
                        
                        // Center Head Node
                        Circle()
                            .fill(Color.black)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white.opacity(0.4), lineWidth: 1.5)
                            )
                        
                        // Head Nose/Gaze Pointer
                        RadarPointerTriangle()
                            .fill(motion.postureState == .optimal ? Color.cyan : (motion.postureState == .warning ? Color.orange : Color.red))
                            .frame(width: 12, height: 14)
                            .offset(y: -22)
                    }
                    .rotationEffect(.degrees(motion.deltaYaw))
                    .animation(.interpolatingSpring(stiffness: 180, damping: 20), value: motion.deltaYaw)
                }
                .frame(width: 330, height: 330)
                .appleGlass(cornerRadius: 24, opacity: 0.35)
                
                // Telemetry Info Strip
                HStack(spacing: 16) {
                    RadarStatBadge(title: "Active Display", value: multiDisplay.activeDisplayId.capitalized, icon: "macwindow")
                    RadarStatBadge(title: "C1–C7 Spinal Load", value: String(format: "%.1f lbs", spineStress.instantLoadLbs), icon: "figure.stand")
                    RadarStatBadge(title: "Acoustic Cutoff", value: "\(Int(spatial.filterCutoffHz)) Hz", icon: "waveform")
                    RadarStatBadge(title: "Herniation Risk", value: spineStress.herniationRiskTier.rawValue.split(separator: " ").first.map(String.init) ?? "Nominal", icon: "exclamationmark.shield")
                }
                
                // Interactive 3-Card Spatial Control Center
                HStack(spacing: 16) {
                    // Card 1: Spatial Audio Soundstage Gravitation
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "headphones")
                                .foregroundColor(.cyan)
                                .font(.title3)
                            Text("Soundstage Gravitation")
                                .font(.subheadline.bold())
                            Spacer()
                            Toggle("", isOn: $spatial.isEnabled)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                        }
                        
                        Text("Subconscious operant audio tethering: pulls audio above/behind you when slouching with 20kHz -> 650Hz acoustic occlusion.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button(action: {
                                if spatial.isDemoPlaying {
                                    spatial.stopDemoSoundscape()
                                } else {
                                    spatial.startDemoSoundscape()
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: spatial.isDemoPlaying ? "stop.fill" : "play.fill")
                                    Text(spatial.isDemoPlaying ? "Stop Focus Audio" : "Test 40Hz Audio")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(spatial.isDemoPlaying ? Color.red.opacity(0.18) : Color.cyan.opacity(0.18))
                                .foregroundColor(spatial.isDemoPlaying ? .red : .cyan)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                            Spacer()
                            
                            Text("Occlusion: \(spatial.acousticOcclusionPercent)%")
                                .font(.caption2.bold())
                                .foregroundColor(spatial.acousticOcclusionPercent > 20 ? .orange : .secondary)
                        }
                    }
                    .padding(14)
                    .appleGlass(cornerRadius: 16, opacity: 0.35)
                    
                    // Card 2: Directional Synthetic Ear-Haptics
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Image(systemName: "hand.tap.fill")
                                .foregroundColor(.pink)
                                .font(.title3)
                            Text("Directional Ear-Taps")
                                .font(.subheadline.bold())
                            Spacer()
                            Toggle("", isOn: $haptics.isHapticAudioEnabled)
                                .toggleStyle(.switch)
                                .scaleEffect(0.8)
                        }
                        
                        Text("Transduces 52Hz-160Hz cartilage resonant pulses. Directional feedback taps left ear when tilting left, right ear when tilting right.")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 8) {
                            Button("Tap Left Ear") {
                                haptics.playSpatialEarTap(leftGain: 1.0, rightGain: 0.05, baseFreq: 155.0)
                            }
                            .font(.caption2.bold())
                            .buttonStyle(.bordered)
                            
                            Button("Tap Right Ear") {
                                haptics.playSpatialEarTap(leftGain: 0.05, rightGain: 1.0, baseFreq: 155.0)
                            }
                            .font(.caption2.bold())
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(14)
                    .appleGlass(cornerRadius: 16, opacity: 0.35)
                }
            }
            .padding(20)
        }
    }
}

// MARK: - Supporting Radar Shapes & Badges

struct DisplayNode: View {
    let angleDeg: Double
    let label: String
    let icon: String
    let isActive: Bool
    
    var body: some View {
        let radians = (angleDeg - 90) * .pi / 180.0
        let radius: CGFloat = 118
        let x = cos(radians) * radius
        let y = sin(radians) * radius
        
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: isActive ? .bold : .regular))
                .foregroundColor(isActive ? .cyan : .secondary)
                .frame(width: 28, height: 28)
                .background(isActive ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06))
                .clipShape(Circle())
                .overlay(
                    Circle().strokeBorder(isActive ? Color.cyan : Color.white.opacity(0.15), lineWidth: isActive ? 1.5 : 0.5)
                )
            
            Text(label)
                .font(.system(size: 9, weight: isActive ? .bold : .medium))
                .foregroundColor(isActive ? .cyan : .secondary)
        }
        .offset(x: x, y: y)
        .animation(.interpolatingSpring(stiffness: 200, damping: 20), value: isActive)
    }
}

struct RadarStatBadge: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 14))
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .appleGlass(cornerRadius: 12, opacity: 0.3)
    }
}

struct RadarPointerTriangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}
