import SwiftUI

public struct FeatureItem: Identifiable {
    public let id: String
    public let title: String
    public let category: String
    public let status: FeatureStatus
    public let icon: String
    public let color: Color
    public let summary: String
    public let technicalDetails: String
    
    public enum FeatureStatus: String {
        case active = "Active (Built-in)"
        case beta = "Interactive Preview"
        case planned = "Architected / Next"
    }
}

public struct FeaturesHubView: View {
    @ObservedObject var motion: MotionManager
    @State private var selectedFeature: FeatureItem? = nil
    
    private let features: [FeatureItem] = [
        FeatureItem(
            id: "posture",
            title: "Active 3D Posture & Slouch Guard",
            category: "Ergonomics",
            status: .active,
            icon: "figure.walk.motion",
            color: .green,
            summary: "Continuous 60Hz 6-axis IMU tracking of cervical spine flexion (pitch) and lateral tilt (roll) relative to personal calibrated baseline.",
            technicalDetails: "Leverages CoreMotion's CMHeadphoneMotionManager attitude updates. Calculates real-time angular deviation from zeroed ergonomic baseline with configurable grace periods to eliminate false positives from quick head nods or drinking coffee."
        ),
        FeatureItem(
            id: "stretches",
            title: "Real-Time Guided Neck Mobility",
            category: "Health & Recovery",
            status: .active,
            icon: "figure.mind.and.body",
            color: .blue,
            summary: "Interactive guided stretches that verify your range of motion in real-time using AirPods orientation before advancing to the next exercise.",
            technicalDetails: "Targets cervical extension, flexion, lateral ear-to-shoulder stretches, and rotation. Tracks live angle thresholds and hold timers with progressive audio cues on completion."
        ),
        FeatureItem(
            id: "gestures",
            title: "Hands-Free Head Gestures (Nod & Shake)",
            category: "Productivity",
            status: .active,
            icon: "waveform.path.badge.plus",
            color: .purple,
            summary: "Nod your head 'yes' or shake your head 'no' to acknowledge reminders, toggle mic mute, or dismiss notifications without touching keyboard or mouse.",
            technicalDetails: "Real-time peak-to-peak frequency analysis on pitch and yaw acceleration streams with minimum amplitude and duration filtering to prevent accidental triggers."
        ),
        FeatureItem(
            id: "spatial_biofeedback",
            title: "Spatial Audio Posture Coaching",
            category: "Audio Experience",
            status: .planned,
            icon: "ear.and.waveform",
            color: .orange,
            summary: "Subconscious audio biofeedback: when slouching, audio subtly lowers in fidelity or shifts spatial position downward, naturally nudging you upright.",
            technicalDetails: "Uses AVAudioEngine and AVAudioEnvironmentNode. Slouch angle maps to HRTF 3D elevation and low-pass filter cutoff (20kHz down to 8kHz) giving non-intrusive auditory biofeedback."
        ),
        FeatureItem(
            id: "dual_monitor",
            title: "Dual-Monitor Cervical Asymmetry Guard",
            category: "Ergonomics",
            status: .planned,
            icon: "display.2",
            color: .indigo,
            summary: "Alerts you if your head has been turned toward a secondary side monitor (>25° yaw) for over 45 minutes continuously to prevent unilateral neck strain.",
            technicalDetails: "Tracks cumulative yaw angle distribution over rolling 60-minute windows. If standard deviation is skewed > 25° away from midline for > 40 minutes, triggers a recommendation to center primary tasks."
        ),
        FeatureItem(
            id: "walk_away_lock",
            title: "Walk-Away Auto-Lock (Mac Security)",
            category: "Security",
            status: .planned,
            icon: "lock.shield",
            color: .red,
            summary: "Immediately locks your Mac screen and pauses video/audio when you take off your AirPods Max or step away from your desk.",
            technicalDetails: "Listens to CMHeadphoneMotionManager disconnect notifications and CoreAudio audio route changes via AudioObjectAddPropertyListener. Instantly invokes SACLockScreenImmediate() or sleep command."
        ),
        FeatureItem(
            id: "fidget_focus",
            title: "Restlessness & Deep Focus Index",
            category: "Focus & Analytics",
            status: .planned,
            icon: "chart.line.uptrend.xyaxis",
            color: .teal,
            summary: "Measures micro-head movements and rotation velocity variance to detect when you are in deep flow state versus fatigued and fidgeting.",
            technicalDetails: "Samples gyro variance (CMRotationRate) at 10Hz. High stability indicates deep reading/coding focus; intermittent rapid bursts indicate cognitive fatigue or restlessness, triggering gentle break suggestions."
        ),
        FeatureItem(
            id: "standing_desk",
            title: "Sit / Stand Desk Cadence Detection",
            category: "Ergonomics",
            status: .planned,
            icon: "arrow.up.and.down.and.sparkles",
            color: .mint,
            summary: "Detects whether you are sitting or standing at your desk via micro-vertical bobbing and step detection without requiring an Apple Watch.",
            technicalDetails: "Analyzes high-frequency acceleration on vertical axis (CMAcceleration.z). Subtle weight shifts and stepping present when standing create a distinct signature compared to sedentary sitting."
        )
    ]
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "headphones")
                            .font(.system(size: 28))
                            .foregroundColor(.accentColor)
                        Text("AirPods Max Potential Architecture")
                            .font(.title2.bold())
                    }
                    Text("Unlocking Apple's advanced 6-axis IMU, CoreMotion kinematics, and Spatial Audio capabilities on macOS.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 6)
                
                // Grid of Features
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 320), spacing: 16)], spacing: 16) {
                    ForEach(features) { feature in
                        FeatureCard(feature: feature) {
                            selectedFeature = feature
                        }
                    }
                }
            }
            .padding(20)
        }
        .sheet(item: $selectedFeature) { feature in
            FeatureDetailModal(feature: feature)
        }
    }
}

struct FeatureCard: View {
    let feature: FeatureItem
    let action: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundColor(feature.color)
                    .frame(width: 36, height: 36)
                    .background(feature.color.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(feature.category)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: feature.status)
            }
            
            Text(feature.summary)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack {
                Text("View Architecture & Details")
                    .font(.caption.bold())
                    .foregroundColor(.accentColor)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(16)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
    }
}

struct StatusBadge: View {
    let status: FeatureItem.FeatureStatus
    
    var body: some View {
        Text(status.rawValue)
            .font(.system(size: 9, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }
    
    private var badgeColor: Color {
        switch status {
        case .active: return .green
        case .beta: return .blue
        case .planned: return .orange
        }
    }
}

struct FeatureDetailModal: View {
    let feature: FeatureItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.title)
                    .foregroundColor(feature.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(feature.title)
                        .font(.title2.bold())
                    Text(feature.category)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("Close") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Overview")
                    .font(.headline)
                Text(feature.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Technical & Sensor Implementation")
                    .font(.headline)
                Text(feature.technicalDetails)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .background(Color(NSColor.textBackgroundColor).opacity(0.5))
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding(24)
        .frame(width: 520, height: 380)
    }
}
