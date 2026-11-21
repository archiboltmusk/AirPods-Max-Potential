import SwiftUI

public struct LoopholeCardData: Identifiable {
    public let id: String
    public let number: String
    public let title: String
    public let competitorFlaw: String
    public let ourSolution: String
    public let icon: String
    public let color: Color
    public let isActive: Bool
}

public struct AuditAndLoopholesView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        Text("Loophole Audit & Production Defenses")
                            .font(.title2.bold())
                    }
                    Text("Analysis of major user complaints and technical flaws across current AirPods posture apps, and how AirPodsIQ resolves them.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Divider()
                
                // Active System Status Banner
                HStack(spacing: 16) {
                    StatusPill(
                        icon: "mic.fill",
                        title: "Meeting Guard",
                        subtitle: audioMonitor.isMicrophoneInUse ? "Meeting Active (Muted)" : "Monitoring Mic",
                        color: audioMonitor.isMicrophoneInUse ? .purple : .green
                    )
                    
                    StatusPill(
                        icon: "leaf.fill",
                        title: "Battery Saver",
                        subtitle: motion.batterySaverMode ? "Eco Mode Active" : "60Hz Precision",
                        color: motion.batterySaverMode ? .green : .blue
                    )
                    
                    StatusPill(
                        icon: "timer",
                        title: "20-20-20 Break",
                        subtitle: breakTimer.isBreakDue ? "Break Due!" : "\(Int(ceil(breakTimer.secondsRemaining / 60)))m left",
                        color: breakTimer.isBreakDue ? .orange : .secondary
                    )
                }
                .padding(.vertical, 4)
                
                // Detailed Loophole Breakdown Cards
                VStack(spacing: 14) {
                    LoopholeRowView(
                        number: "01",
                        title: "The Zoom / Call Interruption Catastrophe",
                        icon: "phone.down.circle.fill",
                        color: .red,
                        flaw: "Existing apps blast chime alerts or force audio ducking while users are speaking in Zoom, Teams, or Google Meet calls, switching AirPods to low-quality SCO telephony mode.",
                        solution: "Intelligent CoreAudio Meeting Guard checks system microphone execution (kAudioDevicePropertyDeviceIsRunningSomewhere) every 2.5s. When a call is live, audible chimes are instantly suppressed.",
                        toggleTitle: "Mute in Meetings",
                        isOn: $motion.muteInMeetings
                    )
                    
                    LoopholeRowView(
                        number: "02",
                        title: "The Desk Work & Notebook False Positive Trap",
                        icon: "book.circle.fill",
                        color: .orange,
                        flaw: "Looking down to write in a notebook, review physical papers, or read a book is mistakenly flagged as a severe slouch within 3 seconds, causing notification fatigue.",
                        solution: "Dedicated 'Reading & Paperwork' profile relaxes pitch tolerance to 24°, paired with 1-click Quick Snooze (5m/15m/30m) from the menu bar or keyboard shortcut.",
                        toggleTitle: "Reading Profile Active",
                        isOn: Binding(
                            get: { motion.activeProfile == .readingPaperwork },
                            set: { if $0 { motion.activeProfile = .readingPaperwork } else { motion.activeProfile = .standardDesk } }
                        )
                    )
                    
                    LoopholeRowView(
                        number: "03",
                        title: "Calibration Drift & Shift Frustration",
                        icon: "arrow.triangle.swap",
                        color: .blue,
                        flaw: "Headphones shift on hair/ears and users adjust chair heights, causing the initial baseline calibration to slowly become inaccurate and scream false warnings.",
                        solution: "Global quick-calibration shortcut (⌘⇧C) plus optional subtle exponential drift compensation that automatically recenters long-term median posture without manual resets.",
                        toggleTitle: "Auto-Drift Correction",
                        isOn: $motion.autoDriftCorrection
                    )
                    
                    LoopholeRowView(
                        number: "04",
                        title: "Earbud Battery Drain & High Mac CPU Usage",
                        icon: "bolt.batteryblock.fill",
                        color: .green,
                        flaw: "Continuous unthrottled 60-100Hz CoreMotion Bluetooth polling drains AirPods Max and MacBook battery during long 8-hour workdays.",
                        solution: "Adaptive Battery Saver engine dynamically throttles sampling to an efficient ~10Hz in background mode, dropping CPU usage below 0.1% while preserving all-day battery.",
                        toggleTitle: "Battery Saver Mode",
                        isOn: $motion.batterySaverMode
                    )
                    
                    LoopholeRowView(
                        number: "05",
                        title: "Earbud Blind Spot: Chin Up, Spine Slumped",
                        icon: "figure.stand.line.dotted.figure.stand",
                        color: .purple,
                        flaw: "AirPods only measure head angle, not spinal curvature. Users can tilt their chin up to fake good posture while hunching their thoracic and lumbar spine.",
                        solution: "Integrated 20-20-20 Ergonomic Eye & Spine Break timer prompts full-body posture resets (scapular retraction, chin tucks, and standing breaks) every 20 minutes.",
                        toggleTitle: "20-20-20 Break Timer",
                        isOn: $breakTimer.isEnabled
                    )
                }
            }
            .padding(20)
        }
    }
}

struct StatusPill: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(subtitle)
                    .font(.caption.bold())
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct LoopholeRowView: View {
    let number: String
    let title: String
    let icon: String
    let color: Color
    let flaw: String
    let solution: String
    let toggleTitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    Text(number)
                        .font(.system(.caption, design: .monospaced, weight: .bold))
                        .foregroundColor(color)
                        .padding(4)
                        .background(color.opacity(0.12))
                        .cornerRadius(6)
                    
                    Text(title)
                        .font(.headline)
                }
                
                Spacer()
                
                Toggle(toggleTitle, isOn: $isOn)
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 6) {
                    Text("FLAW IN OTHER APPS:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.red)
                    Text(flaw)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(alignment: .top, spacing: 6) {
                    Text("AIRPODSIQ DEFENSE:")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                    Text(solution)
                        .font(.caption)
                        .foregroundColor(.primary)
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)
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
