import SwiftUI

public struct UpgradesSuiteView: View {
    @ObservedObject var spatialAudio = SpatialAudioBiofeedback.shared
    @ObservedObject var multiMonitor = MultiMonitorGuard.shared
    @ObservedObject var headPointer = HeadPointerManager.shared
    @ObservedObject var walkAway = WalkAwayLockManager.shared
    @ObservedObject var focusTracker = FocusRestlessnessTracker.shared
    @ObservedObject var standingTracker = StandingDeskTracker.shared
    @ObservedObject var hearingSafety = HearingSafetyMonitor.shared
    @ObservedObject var notchHUD = NotchHUDManager.shared
    @ObservedObject var motion = MotionManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    Image(systemName: "sparkles.square.filled.on.square")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AirPods Power Upgrade Suite")
                            .font(.title2.bold())
                        Text("Active hardware intelligence powered by AirPods Pro 2 sensors & macOS subsystems")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section 1: Spatial Audio Biofeedback
                UpgradeCard(
                    title: "Spatial Audio Posture Coaching",
                    subtitle: "Psychoacoustic low-pass filtering: audio rolls off when you slouch, blossoms open when upright.",
                    icon: "ear.and.waveform",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Current Acoustic Cutoff:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(String(format: "%.0f Hz", spatialAudio.filterCutoffHz))
                                .font(.system(.body, design: .monospaced, weight: .bold))
                                .foregroundColor(spatialAudio.filterCutoffHz > 12000 ? .green : .orange)
                            Spacer()
                            Text(spatialAudio.filterCutoffHz > 15000 ? "Pristine Spatial" : "Acoustic Slouch Muffle")
                                .font(.caption.bold())
                                .foregroundColor(spatialAudio.filterCutoffHz > 15000 ? .green : .orange)
                        }
                        
                        ProgressView(value: Double(spatialAudio.filterCutoffHz), total: 20000.0)
                            .tint(spatialAudio.filterCutoffHz > 15000 ? .green : .orange)
                        
                        HStack {
                            Button(action: {
                                if spatialAudio.isDemoPlaying {
                                    spatialAudio.stopDemoSoundscape()
                                } else {
                                    spatialAudio.startDemoSoundscape()
                                }
                            }) {
                                Label(
                                    spatialAudio.isDemoPlaying ? "Stop Focus Soundscape" : "Test Live Spatial Biofeedback Soundscape",
                                    systemImage: spatialAudio.isDemoPlaying ? "stop.fill" : "play.fill"
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            
                            Spacer()
                            
                            Text("Tilt head down to hear audio muffle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Section 2: Multi-Monitor Cervical Asymmetry Guard
                UpgradeCard(
                    title: "Dual-Monitor Cervical Asymmetry Guard",
                    subtitle: "Prevents unilateral neck stiffness by tracking yaw angle distribution across displays.",
                    icon: "display.2",
                    accentColor: .indigo
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        if let warning = multiMonitor.warningMessage {
                            Text(warning)
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                                .padding(8)
                                .background(Color.orange.opacity(0.12))
                                .cornerRadius(6)
                        }
                        
                        HStack(spacing: 12) {
                            DistributionBar(label: "Left Display", percent: multiMonitor.leftPercentage, color: .purple)
                            DistributionBar(label: "Primary Center", percent: multiMonitor.centerPercentage, color: .blue)
                            DistributionBar(label: "Right Display", percent: multiMonitor.rightPercentage, color: .indigo)
                        }
                        
                        HStack {
                            Text("Asymmetry Strain Index:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("\(multiMonitor.asymmetryStrainScore)%")
                                .font(.system(.subheadline, design: .monospaced, weight: .bold))
                                .foregroundColor(multiMonitor.asymmetryStrainScore > 40 ? .orange : .green)
                            Spacer()
                            Toggle("Asymmetry Guard", isOn: $multiMonitor.isEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.mini)
                        }
                    }
                }
                
                // Section 3: Head Pointer Hands-Free Scrolling
                UpgradeCard(
                    title: "Spatial Head Pointer & Hands-Free Scrolling",
                    subtitle: "Scroll documents, web pages, and code hands-free by subtly tilting your head up or down.",
                    icon: "hand.point.up.left.and.text.bubble",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Toggle("Enable Hands-Free Head Scrolling", isOn: $headPointer.isScrollEnabled)
                                .toggleStyle(.switch)
                            Spacer()
                            if headPointer.isScrollEnabled {
                                Text(String(format: "Speed: %+.1f px/s", headPointer.activeScrollSpeed))
                                    .font(.system(.caption, design: .monospaced, weight: .bold))
                                    .foregroundColor(.green)
                            }
                        }
                        
                        if headPointer.isScrollEnabled {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Scroll Sensitivity:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(format: "%.1fx", headPointer.scrollSensitivity))
                                        .font(.caption2.bold())
                                }
                                Slider(value: $headPointer.scrollSensitivity, in: 0.5...3.0, step: 0.1)
                                Text("Tilt head past ±12° to smoothly scroll active window.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // Section 4: Deep Focus & Restlessness Index
                UpgradeCard(
                    title: "Deep Cognitive Flow vs Restlessness Index",
                    subtitle: "Analyzes 60Hz gyroscope stability to detect deep focus vs cognitive fatigue and fidgeting.",
                    icon: "brain.head.profile",
                    accentColor: .purple
                ) {
                    HStack(spacing: 16) {
                        MetricPill(
                            title: "Focus Flow Score",
                            value: "\(focusTracker.focusScore)%",
                            subtitle: focusTracker.focusStateDescription,
                            color: focusTracker.focusScore > 75 ? .green : .orange
                        )
                        MetricPill(
                            title: "Restlessness Index",
                            value: "\(focusTracker.restlessnessIndex)%",
                            subtitle: "Micro-gyro jitter variance",
                            color: focusTracker.restlessnessIndex > 30 ? .red : .blue
                        )
                        MetricPill(
                            title: "Focus Streak",
                            value: "\(focusTracker.focusStreakMinutes)m",
                            subtitle: "Continuous desk work",
                            color: .purple
                        )
                    }
                }
                
                // Section 5: Sit / Stand Desk Cadence Tracker
                UpgradeCard(
                    title: "Auto Sit / Stand Desk Cadence Tracker",
                    subtitle: "Detects standing desk height transitions and weight shifts without needing an Apple Watch.",
                    icon: "figure.stand",
                    accentColor: .mint
                ) {
                    HStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(standingTracker.isStanding ? Color.green : Color.blue)
                                .frame(width: 10, height: 10)
                            Text(standingTracker.isStanding ? "Currently Standing" : "Currently Sitting")
                                .font(.headline)
                                .foregroundColor(standingTracker.isStanding ? .green : .blue)
                        }
                        
                        Spacer()
                        
                        Text("Standing Today: \(formatTime(standingTracker.secondsStandingToday))")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        Text("Sitting: \(formatTime(standingTracker.secondsSittingToday))")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                    }
                }
                
                // Section 6: Walk-Away Mac Screen Auto-Lock
                UpgradeCard(
                    title: "Walk-Away Mac Screen Auto-Lock",
                    subtitle: "Instantly locks your screen and pauses media when you take off your AirPods Pro.",
                    icon: "lock.shield.fill",
                    accentColor: .red
                ) {
                    HStack {
                        Toggle("Auto-Lock Screen When AirPods Removed", isOn: $walkAway.isEnabled)
                            .toggleStyle(.switch)
                        
                        Spacer()
                        
                        Button("Test Lock Screen Now") {
                            walkAway.lockScreenNow()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
                
                // Section 7: WHO Hearing Safety & Camera Notch HUD
                UpgradeCard(
                    title: "Hearing Dose & Peripheral Notch HUD",
                    subtitle: "Daily acoustic health monitoring and camera notch ambient posture glow.",
                    icon: "speaker.wave.3.fill",
                    accentColor: .teal
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Acoustic Output:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(hearingSafety.estimatedDecibels) dBA (\(hearingSafety.currentVolumePercent)% vol)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(hearingSafety.isVolumeDangerous ? .red : .green)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Daily WHO Dose:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text(String(format: "%.1f%%", hearingSafety.dailyDosePercentage))
                                    .font(.subheadline.bold())
                                    .foregroundColor(hearingSafety.dailyDosePercentage > 100 ? .red : .blue)
                            }
                        }
                        
                        Divider()
                        
                        Toggle("Show Camera Notch HUD Posture Ring", isOn: $notchHUD.isHUDEnabled)
                            .toggleStyle(.switch)
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let hrs = mins / 60
        if hrs > 0 {
            return String(format: "%dh %02dm", hrs, mins % 60)
        }
        return String(format: "%dm", mins)
    }
}

struct UpgradeCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let content: Content
    
    init(title: String, subtitle: String, icon: String, accentColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

struct DistributionBar: View {
    let label: String
    let percent: Double
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(Int(percent))%")
                    .font(.caption2.bold())
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.primary.opacity(0.08))
                    RoundedRectangle(cornerRadius: 3).fill(color)
                        .frame(width: max(2, (percent / 100.0) * geo.size.width))
                }
            }
            .frame(height: 5)
        }
    }
}

struct MetricPill: View {
    let title: String
    let value: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(color)
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
    }
}
