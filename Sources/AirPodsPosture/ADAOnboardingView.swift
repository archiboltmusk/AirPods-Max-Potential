import SwiftUI
import AppKit
import AirPodsCore

/// Apple Design Award (ADA) Compliant 3-Screen Onboarding Flow.
/// Treats the Mac display and AirPods as a single, continuous ergonomic instrument.
/// Implements HIG progressive disclosure, 120Hz live kinetic feedback, and zero-fatigue permissions.
public struct ADAOnboardingView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var glance = GlanceAndLockAutoCalibrator.shared
    @ObservedObject var haptics = SyntheticEarHapticEngine.shared
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    @State private var currentStep: Int = 1
    @State private var selectedSensitivity: SensitivityLevel = .balanced
    @State private var enableDynamicNotch: Bool = true
    @State private var enableAppleHealth: Bool = false
    @State private var isTestingCue: Bool = false
    @State private var hasLockedInStep2: Bool = false
    @State private var pulseAnimation: Bool = false
    
    var onComplete: () -> Void
    
    public enum SensitivityLevel: Double, CaseIterable, Identifiable {
        case focused = 12.0
        case balanced = 18.0
        case relaxed = 25.0
        
        public var id: Double { rawValue }
        
        public var title: String {
            switch self {
            case .focused: return "Focused"
            case .balanced: return "Balanced"
            case .relaxed: return "Relaxed"
            }
        }
        
        public var subtitle: String {
            switch self {
            case .focused: return "12° • Deep Work"
            case .balanced: return "18° • Recommended"
            case .relaxed: return "25° • Casual"
            }
        }
    }
    
    public init(onComplete: @escaping () -> Void) {
        self.onComplete = onComplete
    }
    
    public var body: some View {
        ZStack {
            // Semantic Dark Canvas
            Color(nsColor: .windowBackgroundColor)
                .ignoresSafeArea()
            
            // Subtle Radial Specular Glow
            RadialGradient(
                gradient: Gradient(colors: [
                    CREDPalette.emeraldPlasma.opacity(currentStep == 2 ? 0.08 : 0.04),
                    Color.clear
                ]),
                center: .center,
                startRadius: 40,
                endRadius: 500
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Navigation Bar: Step Indicator & Dismiss
                headerBar
                    .padding(.horizontal, 36)
                    .padding(.top, 28)
                
                Spacer()
                
                // Screen Content Carousel
                Group {
                    switch currentStep {
                    case 1:
                        step1HardwareHandshake
                    case 2:
                        step2KineticCalibration
                    case 3:
                        step3NudgePreviewAndOptIns
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .trailing)),
                    removal: .opacity.combined(with: .move(edge: .leading))
                ))
                .animation(.spring(response: 0.45, dampingFraction: 0.85), value: currentStep)
                
                Spacer()
                
                // Bottom Primary Action Bar
                footerBar
                    .padding(.horizontal, 36)
                    .padding(.bottom, 32)
            }
        }
        .frame(minWidth: 780, minHeight: 560)
        .onAppear {
            pulseAnimation = true
            // Sync initial sensitivity to motionManager threshold
            if let match = SensitivityLevel.allCases.first(where: { abs($0.rawValue - motion.pitchThreshold) < 1.0 }) {
                selectedSensitivity = match
            }
        }
    }
    
    // MARK: - Header Bar
    
    private var headerBar: some View {
        HStack {
            // Step Dots
            HStack(spacing: 8) {
                ForEach(1...3, id: \.self) { step in
                    Capsule()
                        .fill(step == currentStep ? CREDPalette.emeraldPlasma : Color.secondary.opacity(0.3))
                        .frame(width: step == currentStep ? 24 : 8, height: 8)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Step \(currentStep) of 3")
            
            Spacer()
            
            // Skip / Jump to Dashboard
            Button("Skip") {
                onComplete()
            }
            .buttonStyle(.plain)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.secondary)
            .opacity(0.8)
            .onHover { inside in
                if inside { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
    }
    
    // MARK: - Screen 1: Value Proposition & Hardware Handshake
    
    private var step1HardwareHandshake: some View {
        VStack(spacing: 28) {
            // Dynamic Hardware Status Pill
            hardwarePillBadge
                .padding(.top, 10)
            
            // Horizon Breathing Ring Visual
            ZStack {
                Circle()
                    .stroke(CREDPalette.emeraldPlasma.opacity(0.12), lineWidth: 1.5)
                    .frame(width: 170, height: 170)
                    .scaleEffect(pulseAnimation && !reduceMotion ? 1.06 : 1.0)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 3.0).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [CREDPalette.emeraldPlasma.opacity(0.6), CREDPalette.electricCyan.opacity(0.3)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 2
                    )
                    .frame(width: 130, height: 130)
                
                Image(systemName: hardwareIconName)
                    .font(.system(size: 46, weight: .light))
                    .foregroundColor(motion.isConnected ? CREDPalette.emeraldPlasma : .secondary)
            }
            .frame(height: 190)
            
            // Headline & Subheadline
            VStack(spacing: 10) {
                Text("Better posture, guided by sound.")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Subtle spatial cues remind you to lift your head—without interrupting your flow.")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 480)
            }
            
            // Hardware Compatibility Note
            Text("Designed exclusively for AirPods Pro, AirPods Max, and AirPods 3/4.")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.secondary.opacity(0.7))
        }
    }
    
    private var hardwareIconName: String {
        if motion.activeDataSource.lowercased().contains("max") {
            return "airpodsmax"
        }
        return "airpodspro"
    }
    
    private var hardwarePillBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(motion.isConnected ? Color.green : Color.orange)
                .frame(width: 8, height: 8)
                .scaleEffect(motion.isConnected ? 1.0 : (pulseAnimation ? 1.25 : 0.8))
                .animation(motion.isConnected || reduceMotion ? nil : .easeInOut(duration: 1.0).repeatForever(), value: pulseAnimation)
            
            Text(motion.isConnected ? "AirPods Connected • Motion Ready" : "Put in your AirPods to begin")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(motion.isConnected ? .primary : .secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                .overlay(
                    Capsule()
                        .stroke(motion.isConnected ? Color.green.opacity(0.3) : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Screen 2: Live Kinetic Calibration ("Find Your Neutral")
    
    private var step2KineticCalibration: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Find Your Neutral")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Sit comfortably, take one deep breath, and look straight at your display.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
            }
            
            // 120Hz Interactive Kinetic Horizon
            ZStack {
                // Target Circle
                Circle()
                    .stroke(hasLockedInStep2 ? Color.green : Color.secondary.opacity(0.25), lineWidth: 2)
                    .frame(width: 180, height: 180)
                
                // Hands-Free Hold Progress Ring
                Circle()
                    .trim(from: 0, to: CGFloat(hasLockedInStep2 ? 1.0 : glance.glanceLockHoldProgress))
                    .stroke(
                        CREDPalette.emeraldPlasma,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 180, height: 180)
                    .animation(.easeOut(duration: 0.15), value: glance.glanceLockHoldProgress)
                
                if !reduceMotion {
                    // Kinetic Horizon Line (reacting to live pitch & roll)
                    let pitchOffset = CGFloat(clamping: -motion.deltaPitch * 3.5, min: -60.0, max: 60.0)
                    let rollAngle = Angle.degrees(clamping: -motion.deltaRoll, min: -35.0, max: 35.0)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.clear, CREDPalette.emeraldPlasma, Color.clear],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 140, height: 2.5)
                        .offset(y: pitchOffset)
                        .rotationEffect(rollAngle)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: pitchOffset)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: rollAngle)
                } else {
                    // Reduced Motion Accessible Pitch Readout
                    VStack(spacing: 4) {
                        Text(String(format: "%.1f°", motion.deltaPitch))
                            .font(.system(size: 26, weight: .semibold, design: .monospaced))
                            .foregroundColor(.primary)
                        Text("Current Pitch")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                
                // Center Crosshair
                Circle()
                    .fill(hasLockedInStep2 ? Color.green : CREDPalette.emeraldPlasma)
                    .frame(width: 8, height: 8)
            }
            .frame(height: 190)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Kinetic Horizon: current deviation \(Int(motion.deltaPitch)) degrees pitch.")
            
            // Lock State Feedback
            HStack(spacing: 6) {
                Image(systemName: hasLockedInStep2 ? "checkmark.circle.fill" : "sparkles")
                    .foregroundColor(hasLockedInStep2 ? .green : CREDPalette.emeraldPlasma)
                
                Text(hasLockedInStep2 ? "Neutral Baseline Locked" : "Hold steady for 2 seconds to auto-lock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(hasLockedInStep2 ? .green : .secondary)
            }
            
            // Sensitivity Presets
            VStack(spacing: 8) {
                Text("Select Sensitivity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.8))
                    .textCase(.uppercase)
                
                HStack(spacing: 12) {
                    ForEach(SensitivityLevel.allCases) { level in
                        Button {
                            selectedSensitivity = level
                            motion.pitchThreshold = level.rawValue
                            haptics.performTrackpadHaptic(pattern: .generic)
                        } label: {
                            VStack(spacing: 4) {
                                Text(level.title)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(selectedSensitivity == level ? .primary : .secondary)
                                Text(level.subtitle)
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(selectedSensitivity == level ? CREDPalette.emeraldPlasma : .secondary.opacity(0.7))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .frame(minWidth: 120)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(selectedSensitivity == level ? Color(nsColor: .controlAccentColor).opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(selectedSensitivity == level ? CREDPalette.emeraldPlasma.opacity(0.6) : Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Accessible Manual Fallback Button
            Button("Set Neutral Manually") {
                lockInStep2()
            }
            .buttonStyle(.plain)
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.secondary)
            .underline()
        }
        .onChange(of: glance.hasLockedSessionBaseline) { _, locked in
            if locked && !hasLockedInStep2 {
                hasLockedInStep2 = true
                haptics.performTrackpadHaptic(pattern: .alignment)
                haptics.playSuccessChirp()
            }
        }
    }
    
    private func lockInStep2() {
        _ = motion.calibrateCurrentPosture(force: true)
        hasLockedInStep2 = true
        haptics.performTrackpadHaptic(pattern: .alignment)
        haptics.playSuccessChirp()
    }
    
    // MARK: - Screen 3: Spatial Nudge Preview & Just-In-Time Permissions
    
    private var step3NudgePreviewAndOptIns: some View {
        VStack(spacing: 26) {
            VStack(spacing: 6) {
                Text("Gentle Reminders, Never Alarms")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("When your head drifts forward for 20 seconds, you'll hear a gentle lift cue—never a jarring sound.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 520)
            }
            
            // Interactive Preview Card
            VStack(spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "headphones")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(CREDPalette.electricCyan)
                    
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Spatial Audio Elevation Cue")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.primary)
                        Text("40ms tactile crown tap with ascending binaural tone")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        isTestingCue = true
                        haptics.performTrackpadHaptic(pattern: .alignment)
                        haptics.playSuccessChirp()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            isTestingCue = false
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: isTestingCue ? "speaker.wave.3.fill" : "play.fill")
                            Text(isTestingCue ? "Playing..." : "Test Cue")
                        }
                        .font(.system(size: 12, weight: .semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(CREDPalette.emeraldPlasma.opacity(0.2))
                                .overlay(Capsule().stroke(CREDPalette.emeraldPlasma, lineWidth: 1))
                        )
                        .foregroundColor(.primary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                )
            }
            .frame(maxWidth: 540)
            
            // Just-In-Time Ergonomic Toggles
            VStack(spacing: 12) {
                Toggle(isOn: $enableDynamicNotch) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Dynamic Notch Glanceable Horizon")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Subtle ambient halo on your MacBook notch when slouching begins.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                
                Divider()
                    .opacity(0.3)
                
                Toggle(isOn: $enableAppleHealth) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Log Mindful Minutes")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.primary)
                        Text("Sync sustained upright focus periods as mindful breaks in Apple Health.")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.4))
                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.secondary.opacity(0.15), lineWidth: 1))
            )
            .frame(maxWidth: 540)
        }
    }
    
    // MARK: - Footer Bar
    
    private var footerBar: some View {
        HStack {
            if currentStep > 1 {
                Button("Back") {
                    currentStep -= 1
                    haptics.performTrackpadHaptic(pattern: .generic)
                }
                .buttonStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button {
                handlePrimaryAction()
            } label: {
                HStack(spacing: 8) {
                    Text(primaryButtonTitle)
                        .font(.system(size: 14, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(CREDPalette.emeraldPlasma)
                )
                .foregroundColor(.black)
            }
            .buttonStyle(.plain)
        }
    }
    
    private var primaryButtonTitle: String {
        switch currentStep {
        case 1:
            return motion.isConnected ? "Calibrate Posture" : "Try Interactive Demo"
        case 2:
            return "Continue"
        case 3:
            return "Start First Session"
        default:
            return "Next"
        }
    }
    
    private func handlePrimaryAction() {
        haptics.performTrackpadHaptic(pattern: .alignment)
        
        if currentStep == 1 {
            if !motion.isConnected {
                motion.isSimulated = true
                motion.startTracking()
            }
            currentStep = 2
        } else if currentStep == 2 {
            if !hasLockedInStep2 {
                lockInStep2()
            }
            currentStep = 3
        } else if currentStep == 3 {
            // Apply preferences & complete onboarding
            UserDefaults.standard.set(enableDynamicNotch, forKey: "enableDynamicNotch")
            UserDefaults.standard.set(enableAppleHealth, forKey: "enableAppleHealth")
            onComplete()
        }
    }
}

// Clamping Helper for CGFloat and Double
private extension CGFloat {
    init(clamping value: Double, min minVal: Double, max maxVal: Double) {
        let clamped = Swift.max(minVal, Swift.min(maxVal, value))
        self.init(clamped)
    }
}

private extension Angle {
    static func degrees(clamping value: Double, min minVal: Double, max maxVal: Double) -> Angle {
        let clamped = Swift.max(minVal, Swift.min(maxVal, value))
        return Angle.degrees(clamped)
    }
}
