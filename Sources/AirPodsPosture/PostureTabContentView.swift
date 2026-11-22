import SwiftUI
import AirPodsCore

public struct PostureTabContentView: View {
    @ObservedObject private var motion = MotionManager.shared
    @ObservedObject private var companion = FloatingMiniDeskCompanionManager.shared
    @ObservedObject private var fitSentinel = AirPodsInsertionFitSentinel.shared
    @State private var showsResetConfirmation = false

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sessionCard

                if motion.isConnected && motion.isCalibrated && motion.isTracking {
                    HStack(spacing: 16) {
                        metric("Forward / back", value: angle(motion.deltaPitch))
                        metric("Side tilt", value: angle(motion.deltaRoll))
                    }
                    .padding(20)
                    .credCard(cornerRadius: 16, elevation: 6)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Today")
                        .font(.title3.weight(.semibold))
                    HStack(spacing: 16) {
                        metric("Tracked", value: "\(Int(motion.secondsTracked / 60)) min")
                        metric("Drift events", value: "\(motion.slouchEventCount)")
                    }
                }

                Menu("More actions") {
                    Button(companion.isCompanionVisible ? "Hide Posture Buddy" : "Show Posture Buddy") {
                        companion.toggleCompanion()
                    }
                    Button("AirPods fit guide") {
                        fitSentinel.isFitGuidePresented = true
                    }
                    Button("Reset today’s stats", role: .destructive) {
                        showsResetConfirmation = true
                    }
                }
                .fixedSize()
            }
            .padding(24)
            .frame(maxWidth: 960)
            .frame(maxWidth: .infinity)
        }
        .confirmationDialog("Reset today’s stats?", isPresented: $showsResetConfirmation) {
            Button("Reset stats", role: .destructive) {
                motion.secondsTracked = 0
                motion.secondsGoodPosture = 0
                motion.secondsSlouching = 0
                motion.slouchEventCount = 0
            }
        } message: {
            Text("This clears the current tracking totals and drift count.")
        }
    }

    private func angle(_ degrees: Double) -> String {
        guard degrees.isFinite else { return "Unavailable" }
        return String(format: "%+.1f°", degrees)
    }

    private func metric(_ title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold).monospacedDigit())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(statusTitle)
                        .font(.title2.weight(.semibold))
                    Text(statusDetail)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)
                sessionAction
            }

            if let interlock = motion.calibrationInterlockAlert {
                HStack(alignment: .firstTextBaseline) {
                    Label(interlock, systemImage: "exclamationmark.triangle")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Button("Dismiss") {
                        motion.calibrationInterlockAlert = nil
                    }
                    .buttonStyle(.borderless)
                }
                .font(.callout)
                .foregroundStyle(CREDPalette.champagneGold)
            }
        }
        .padding(20)
        .credCard(cornerRadius: 16, elevation: 6)
    }

    private var statusTitle: String {
        if motion.isSimulated { return "Demo mode" }
        if !motion.isConnected { return "Connect your AirPods" }
        if !motion.isTracking { return "Tracking stopped" }
        if !motion.isCalibrated { return "Set your baseline" }
        if motion.isSnoozed { return "Reminders snoozed" }
        return "Tracking head angle"
    }

    private var statusDetail: String {
        if motion.isSimulated { return "The displayed angles are simulated." }
        if !motion.isConnected { return "Wear your AirPods and connect them to this Mac." }
        if !motion.isTracking { return "Start tracking to resume live head-angle feedback." }
        if !motion.isCalibrated { return "Look where you normally work and hold still while you calibrate." }
        if motion.isSnoozed { return "You can resume reminders whenever you’re ready." }
        return "Your head angle is measured relative to your calibrated position."
    }

    @ViewBuilder
    private var sessionAction: some View {
        if motion.isSimulated {
            Button("Exit demo") { motion.toggleSimulation() }
                .buttonStyle(.borderedProminent)
        } else if motion.isConnected {
            if !motion.isTracking {
                Button("Start tracking") { motion.startTracking() }
                    .buttonStyle(.borderedProminent)
            } else if !motion.isCalibrated {
                Button("Calibrate") { calibrate() }
                    .buttonStyle(.borderedProminent)
            } else if motion.isSnoozed {
                Button("Resume reminders") { motion.clearSnooze() }
                    .buttonStyle(.borderedProminent)
            } else {
                Menu("Session actions") {
                    Button("Recalibrate") { calibrate() }
                    Button("Snooze reminders for 5 minutes") { motion.snooze(minutes: 5) }
                    Button("Snooze reminders for 15 minutes") { motion.snooze(minutes: 15) }
                    Button("Snooze reminders for 30 minutes") { motion.snooze(minutes: 30) }
                }
                .fixedSize()
            }
        }
    }

    private func calibrate() {
        _ = motion.calibrateCurrentPosture()
    }
}
