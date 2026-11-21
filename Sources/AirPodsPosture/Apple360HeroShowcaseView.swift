import SwiftUI
import SceneKit

public struct Apple360HeroShowcaseView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var respiratory = AcousticRespiratoryEngine.shared
    @ObservedObject var calibrator = AutonomousAutoCalibrator.shared
    @ObservedObject var sentinel = OpticalContinuitySentinel.shared
    @ObservedObject var spineStress = CervicalVertebralStressEngine.shared
    
    // Earwear selection stored persistently
    @AppStorage("studioEarwearStyle") private var earwearStyleRaw: String = EarwearStyle.airPodsPro.rawValue
    
    // Inertial Orbit Drag State
    @State private var dragOffset: CGSize = .zero
    @State private var manualYawOffset: Double = 0.0
    @State private var manualPitchOffset: Double = 0.0
    @State private var isInteracting: Bool = false
    @State private var showWireframe: Bool = false
    @State private var dynamicLightingIntensity: Double = 1.0
    
    public init() {}
    
    private var currentEarwear: EarwearStyle {
        EarwearStyle(rawValue: earwearStyleRaw) ?? .airPodsPro
    }
    
    private var effectivePitch: Double {
        isInteracting ? (motion.deltaPitch + manualPitchOffset) : motion.deltaPitch
    }
    
    private var effectiveYaw: Double {
        isInteracting ? (motion.deltaYaw + manualYawOffset) : motion.deltaYaw
    }
    
    public var body: some View {
        VStack(spacing: 22) {
            // Hero Title Banner (Apple Keynote Style)
            VStack(spacing: 6) {
                Text("AIRPODS SPATIAL KINEMATICS")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .tracking(2.8)
                    .foregroundColor(.accentColor)
                
                Text("Cervical Precision. Uncompromised.")
                    .font(.system(size: 28, weight: .heavy, design: .default))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .primary.opacity(0.72)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                Text("Real-time 60Hz 6-axis attitude decomposition rendered on an anatomically faithful human topology.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 580)
            }
            .padding(.top, 10)
            
            // Central 360° Interactive 3D Showcase Stage
            ZStack {
                // Ambient Radial Glow
                RadialGradient(
                    gradient: Gradient(colors: [
                        motion.postureState == .optimal ? Color.cyan.opacity(0.14) :
                        (motion.postureState == .warning ? Color.orange.opacity(0.14) : Color.red.opacity(0.14)),
                        Color.clear
                    ]),
                    center: .center,
                    startRadius: 20,
                    endRadius: 260
                )
                .frame(height: 390)
                
                // 3D Anatomical Human Face View with Precision Earwear Alignment
                HumanFace3DView(
                    pitch: effectivePitch,
                    roll: motion.deltaRoll,
                    yaw: effectiveYaw,
                    postureScore: motion.postureScore,
                    earwearStyle: currentEarwear
                )
                .frame(height: 390)
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .gesture(
                    DragGesture(minimumDistance: 2)
                        .onChanged { value in
                            isInteracting = true
                            manualYawOffset = Double(value.translation.width) * 0.45
                            manualPitchOffset = -Double(value.translation.height) * 0.35
                        }
                        .onEnded { _ in
                            // Spring-snap with smooth inertia back to live IMU stream
                            withAnimation(.interpolatingSpring(stiffness: 140, damping: 18)) {
                                manualYawOffset = 0.0
                                manualPitchOffset = 0.0
                                isInteracting = false
                            }
                        }
                )
                
                // Top Overlay Badges
                VStack {
                    HStack {
                        // Live State Badge (Supports AirPods 60Hz IMU & Optical Sentinel Handoff)
                        HStack(spacing: 6) {
                            Circle()
                                .fill(isInteracting ? Color.yellow : (sentinel.isRunning ? Color.orange : Color.green))
                                .frame(width: 8, height: 8)
                            Text(isInteracting ? "360° Turntable Mode" : (sentinel.isRunning ? "⚡️ In Case • 👁️ Optical Sentinel (\(sentinel.opticalFps) FPS)" : "Live IMU Synced (60Hz)"))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(isInteracting ? .yellow : (sentinel.isRunning ? .orange : .green))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                        
                        Spacer()
                        
                        // Apple-Standard Floating Earwear Mode Pill Switcher
                        HStack(spacing: 3) {
                            ForEach(EarwearStyle.allCases) { style in
                                EarwearPillButton(
                                    style: style,
                                    isSelected: currentEarwear == style,
                                    action: {
                                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                            earwearStyleRaw = style.rawValue
                                        }
                                    }
                                )
                            }
                        }
                        .padding(3)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                        
                        Spacer()
                        
                        // Auto-Recenter Button
                        Button(action: {
                            calibrator.triggerInstantDoubleNodCalibration()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                Text("Slouch-Proof Zero")
                            }
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(.ultraThinMaterial)
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                    
                    // Slouch-Proof Interlock Warning Banner
                    if let interlock = motion.calibrationInterlockAlert {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 12))
                            Text(interlock)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.yellow)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.yellow.opacity(0.4), lineWidth: 1))
                        .shadow(color: Color.yellow.opacity(0.25), radius: 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Forward Craning Alert
                    if sentinel.isRunning && sentinel.forwardCraningCm > 4.5 {
                        HStack(spacing: 8) {
                            Image(systemName: "tortoise.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 12))
                            Text("Forward Head Crane: +\(String(format: "%.1f", sentinel.forwardCraningCm))cm (Turtle Neck)")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.orange.opacity(0.4), lineWidth: 1))
                        .shadow(color: Color.orange.opacity(0.25), radius: 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    // Screen Apnea / Dry Eye Warning
                    if let apnea = sentinel.screenApneaAlert {
                        HStack(spacing: 8) {
                            Image(systemName: "eye.trianglebadge.exclamationmark")
                                .foregroundColor(.cyan)
                                .font(.system(size: 12))
                            Text(apnea)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.cyan)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.85))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.4), lineWidth: 1))
                        .shadow(color: Color.cyan.opacity(0.25), radius: 8)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    }
                    
                    Spacer()
                    
                    // Bottom Angle HUD Strip
                    HStack(spacing: 16) {
                        HeroMetricPill(title: "Pitch", value: "\(Int(effectivePitch))°", color: .cyan)
                        HeroMetricPill(title: "Roll", value: "\(Int(motion.deltaRoll))°", color: .purple)
                        HeroMetricPill(title: "Yaw", value: "\(Int(effectiveYaw))°", color: .blue)
                        HeroMetricPill(title: "C1–C7 Load", value: String(format: "%.1flbs", spineStress.instantLoadLbs), color: spineStress.instantLoadLbs > 25.0 ? .red : .teal)
                        HeroMetricPill(title: "Breathing", value: "\(respiratory.breathsPerMinute) BPM", color: .indigo)
                        
                        if sentinel.isRunning {
                            HeroMetricPill(
                                title: "Forward Crane",
                                value: String(format: "+%.1fcm", sentinel.forwardCraningCm),
                                color: sentinel.forwardCraningCm > 4.0 ? .red : .teal
                            )
                            HeroMetricPill(title: "Blinks", value: "\(sentinel.blinkRateBPM) BPM", color: .purple)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                    .padding(.bottom, 14)
                }
            }
            .appleGlass(cornerRadius: 24, opacity: 0.45)
            .padding(.horizontal, 24)
            
            // Bottom 3-Card Apple Feature Grid with Spatial Head Parallax
            HStack(spacing: 16) {
                ShowcaseCard(
                    icon: "sparkles",
                    title: "Zero-Touch Alignment",
                    subtitle: "Autonomous Earth gravity vector decomposition eliminates calibration buttons forever.",
                    color: .cyan
                )
                
                ShowcaseCard(
                    icon: "lungs.fill",
                    title: "Screen Apnea Guard",
                    subtitle: "Continuous micro-vibration analysis flags unconscious breath-holding during coding sessions.",
                    color: .blue
                )
                
                ShowcaseCard(
                    icon: "waveform.circle.fill",
                    title: "40Hz Gamma Soundscape",
                    subtitle: "Procedural CoreAudio binaural waves adapt dynamically to upright posture quality.",
                    color: .purple
                )
            }
            .padding(.horizontal, 24)
            .spatialHeadParallax(sensitivity: 0.05)
        }
    }
}

// MARK: - Supporting Component Views

struct HeroMetricPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
    }
}

struct ShowcaseCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 38, height: 38)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            
            Text(title)
                .font(.system(size: 15, weight: .semibold))
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appleGlass(cornerRadius: 18, opacity: 0.4)
    }
}

struct EarwearPillButton: View {
    let style: EarwearStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: style.icon)
                    .font(.system(size: 10))
                Text(style.rawValue)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .foregroundColor(isSelected ? .white : .secondary)
            .background(isSelected ? Color.accentColor.opacity(0.85) : Color.clear)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
