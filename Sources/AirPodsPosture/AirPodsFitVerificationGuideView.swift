import SwiftUI
import AirPodsCore

/// Interactive Apple-Grade Ear Tip Fit & Insertion Verification Guide.
/// Provides real-time hardware signal validation and a 4-step physical acoustic seal protocol.
public struct AirPodsFitVerificationGuideView: View {
    @ObservedObject var fitSentinel = AirPodsInsertionFitSentinel.shared
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "ear.badge.checkmark")
                        .font(.title2)
                        .foregroundColor(.green)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AirPods Ear-Fit & Insertion Verification")
                            .font(.headline)
                        Text("Hardware Signals & Acoustic Seal Protocol")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
            .padding(18)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Live Sealing Status Card
                    VStack(spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Live Insertion Health")
                                    .font(.subheadline.bold())
                                Text(fitSentinel.isProperlySeated ? "Good Seal • IMU Posture Certified" : "Adjustment Recommended")
                                    .font(.caption)
                                    .foregroundColor(fitSentinel.isProperlySeated ? .green : .orange)
                            }
                            Spacer()
                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text("\(fitSentinel.fitQualityScore)%")
                                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                                    .foregroundColor(fitSentinel.isProperlySeated ? .green : .orange)
                                Text("Fit Quality")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        // Hardware Signal Pills
                        HStack(spacing: 10) {
                            SignalPill(
                                title: "Audio Route",
                                isActive: fitSentinel.isAudioRouteActive,
                                activeText: "AirPods Active",
                                inactiveText: "Disconnected"
                            )
                            SignalPill(
                                title: "Motion Stream",
                                isActive: fitSentinel.isMotionStreaming,
                                activeText: "Streaming (In-Ear)",
                                inactiveText: "Suspended (Desk)"
                            )
                            SignalPill(
                                title: "Stem Alignment",
                                isActive: fitSentinel.isStemAngleOptimal,
                                activeText: "Optimal (~35°)",
                                inactiveText: "Crooked Angle"
                            )
                        }
                        
                        if let warning = fitSentinel.fitRecommendationMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(warning)
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                                Spacer()
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // 4-Step Verification Protocol
                    VStack(alignment: .leading, spacing: 14) {
                        Text("4-Step Physical & Acoustic Verification")
                            .font(.headline)
                            .padding(.horizontal, 4)
                        
                        // Step 1: Ear Tip Fit Test
                        StepCard(
                            stepNumber: "1",
                            title: "Run Apple Ear Tip Fit Test",
                            duration: "2 min • AirPods Pro",
                            instructions: "On iPhone/iPad, open Settings > Bluetooth > AirPods (i) > Ear Tip Fit Test > Continue > Play. Verify both earbuds show 'Good Seal' in green. If either reads 'Adjust', try a different tip size.",
                            isCompleted: fitSentinel.hasRunAppleFitTest,
                            actionTitle: "Mark Tested",
                            onAction: {
                                fitSentinel.markAppleFitTestCompleted()
                            }
                        )
                        
                        // Step 2: Stem Rotation Angle
                        StepCard(
                            stepNumber: "2",
                            title: "Seat Stem & Acoustic Vent at ~30°–45°",
                            duration: "30 sec",
                            instructions: "Insert the ear tip firmly and rotate the stem forward toward the corner of your mouth (roughly 30°–45° downward). Avoid pointing straight down vertically. Room noise should drop instantly.",
                            isCompleted: fitSentinel.isStemAngleOptimal,
                            actionTitle: nil,
                            onAction: nil
                        )
                        
                        // Step 3: Automatic Ear Detection
                        StepCard(
                            stepNumber: "3",
                            title: "Confirm Automatic Ear Detection is Active",
                            duration: "30 sec",
                            instructions: "In Settings > Bluetooth > AirPods (i), verify Automatic Ear Detection is toggled ON. Optical skin sensors confirm physical in-ear contact and halt motion tracking when taken out.",
                            isCompleted: fitSentinel.isAutoEarDetectionEnabled,
                            actionTitle: nil,
                            onAction: nil
                        )
                        
                        // Step 4: Jaw & Shake Stability Check
                        StepCard(
                            stepNumber: "4",
                            title: "Perform the Jaw-and-Shake Stability Check",
                            duration: "15 sec",
                            instructions: "Open and close your jaw wide twice (simulating talking or yawning) and give a firm nod. If the ear tip shifts loose or breaks acoustic seal, switch to a larger tip size.",
                            isCompleted: fitSentinel.hasPassedJawStabilityCheck,
                            actionTitle: "Confirm Stable",
                            onAction: {
                                fitSentinel.markJawStabilityCheckPassed()
                            }
                        )
                    }
                }
                .padding(18)
            }
        }
        .frame(width: 580, height: 600)
    }
}

// MARK: - Helper UI Views

private struct SignalPill: View {
    let title: String
    let isActive: Bool
    let activeText: String
    let inactiveText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
            HStack(spacing: 4) {
                Circle()
                    .fill(isActive ? Color.green : Color.orange)
                    .frame(width: 6, height: 6)
                Text(isActive ? activeText : inactiveText)
                    .font(.caption2.bold())
                    .foregroundColor(isActive ? .green : .orange)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(8)
    }
}

private struct StepCard: View {
    let stepNumber: String
    let title: String
    let duration: String
    let instructions: String
    let isCompleted: Bool
    let actionTitle: String?
    let onAction: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 8) {
                    Text(stepNumber)
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .frame(width: 20, height: 20)
                        .background(isCompleted ? Color.green : Color.accentColor)
                        .clipShape(Circle())
                    
                    Text(title)
                        .font(.subheadline.bold())
                }
                Spacer()
                Text(duration)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Text(instructions)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let title = actionTitle, let action = onAction {
                HStack {
                    Spacer()
                    Button(action: action) {
                        HStack(spacing: 4) {
                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.caption2.bold())
                            }
                            Text(isCompleted ? "Verified" : title)
                                .font(.caption.bold())
                        }
                    }
                    .buttonStyle(.bordered)
                    .tint(isCompleted ? .green : .accentColor)
                }
            }
        }
        .padding(12)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}
