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
            status: .active,
            icon: "ear.and.waveform",
            color: .orange,
            summary: "Subconscious audio biofeedback: when slouching, audio subtly lowers in fidelity or shifts spatial position downward, naturally nudging you upright.",
            technicalDetails: "Uses AVAudioEngine and AVAudioEnvironmentNode. Slouch angle maps to dynamic 20kHz down to 800Hz low-pass filter cutoff giving non-intrusive auditory biofeedback."
        ),
        FeatureItem(
            id: "dual_monitor",
            title: "Dual-Monitor Cervical Asymmetry Guard",
            category: "Ergonomics",
            status: .active,
            icon: "display.2",
            color: .indigo,
            summary: "Alerts you if your head has been turned toward a secondary side monitor (>25° yaw) for over 45 minutes continuously to prevent unilateral neck strain.",
            technicalDetails: "Tracks cumulative yaw angle distribution over rolling 30-minute windows. If standard deviation is skewed > 25° away from midline, triggers a notification to recenter your primary window."
        ),
        FeatureItem(
            id: "walk_away_lock",
            title: "Walk-Away Auto-Lock (Mac Security)",
            category: "Security",
            status: .active,
            icon: "lock.shield",
            color: .red,
            summary: "Immediately locks your Mac screen and pauses video/audio when you take off your AirPods Max or step away from your desk.",
            technicalDetails: "Listens to CMHeadphoneMotionManager disconnect notifications and Bluetooth packet drop. Instantly invokes SACLockScreenImmediate() to enforce zero-trust workstation security."
        ),
        FeatureItem(
            id: "fidget_focus",
            title: "Restlessness & Deep Focus Index",
            category: "Focus & Analytics",
            status: .active,
            icon: "chart.line.uptrend.xyaxis",
            color: .teal,
            summary: "Measures micro-head movements and rotation velocity variance to detect when you are in deep flow state versus fatigued and fidgeting.",
            technicalDetails: "Samples gyro variance (CMRotationRate) at 60Hz. High stability indicates deep coding flow; high variance triggers gentle ergonomic rest suggestions."
        ),
        FeatureItem(
            id: "standing_desk",
            title: "Sit / Stand Desk Cadence Detection",
            category: "Ergonomics",
            status: .active,
            icon: "arrow.up.and.down.and.sparkles",
            color: .mint,
            summary: "Detects whether you are sitting or standing at your desk via micro-vertical bobbing and step detection without requiring an Apple Watch.",
            technicalDetails: "Analyzes vertical kinetic acceleration (CMAcceleration.z). Distinguishes sedentary seated micro-stillness from upright shifting and pacing."
        ),
        FeatureItem(
            id: "head_pointer",
            title: "Hands-Free Cervical Tilt Document Scroll",
            category: "Productivity",
            status: .active,
            icon: "computermouse.fill",
            color: .cyan,
            summary: "Scroll through long source code files, documents, and web pages hands-free by tilting your head slightly up or down.",
            technicalDetails: "CGEvent scroll generation triggered when head pitch exceeds +/- 12° deadzone with quadratic speed scaling."
        ),
        FeatureItem(
            id: "notch_hud",
            title: "Camera Notch Ergonomic HUD Ring",
            category: "Visual Biofeedback",
            status: .active,
            icon: "dot.circle.viewfinder",
            color: .green,
            summary: "Subtle glowing status halo anchored directly beneath the MacBook Pro camera notch for silent, non-intrusive peripheral posture awareness.",
            technicalDetails: "NSPanel click-through transparent window positioned at the exact pixel coordinates of the MacBook display notch."
        ),
        FeatureItem(
            id: "cervical_rom",
            title: "Clinical 6-Axis Cervical ROM Diagnostic",
            category: "Physical Therapy",
            status: .active,
            icon: "stethoscope",
            color: .pink,
            summary: "6-stage clinical assessment measuring cervical flexion, extension, lateral flexion, and axial rotation to estimate biological spine age.",
            technicalDetails: "Quantifies maximum sustained angle against clinical peer-reviewed normative mobility thresholds."
        ),
        FeatureItem(
            id: "hydration_kinematics",
            title: "Kinematic Hydration Sip Tracker",
            category: "Wellness",
            status: .active,
            icon: "drop.fill",
            color: .blue,
            summary: "Recognizes the unique biomechanical signature of drinking water (+22° to +58° backward pitch held for >2.2s) to track daily fluid intake automatically.",
            technicalDetails: "Eliminates false-positive slouch warnings while logging glasses and fluid volume throughout your workday."
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
                
                // Badge
                Text(feature.status.rawValue)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.15))
                    .foregroundColor(.green)
                    .clipShape(Capsule())
            }
            
            Text(feature.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
            
            Button(action: action) {
                HStack(spacing: 4) {
                    Text("View Architecture & Details")
                        .font(.caption2.bold())
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }
}

struct FeatureDetailModal: View {
    let feature: FeatureItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: feature.icon)
                    .font(.title)
                    .foregroundColor(feature.color)
                VStack(alignment: .leading) {
                    Text(feature.title)
                        .font(.title3.bold())
                    Text(feature.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Functional Overview")
                    .font(.headline)
                Text(feature.summary)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Technical & Biomechanical Architecture")
                    .font(.headline)
                Text(feature.technicalDetails)
                    .font(.callout)
                    .foregroundColor(.primary)
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)
            }
            
            HStack {
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(24)
        .frame(width: 480)
    }
}
