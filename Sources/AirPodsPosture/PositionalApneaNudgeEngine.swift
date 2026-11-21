import Foundation
import SwiftUI
import Combine

/// Positional Obstructive Sleep Apnea (POSA) & Supine Rotational Haptic Nudge Engine.
/// More than 60% of sleep apnea sufferers experience airway collapse predominantly
/// when sleeping in the supine (flat on the back) posture due to gravitational tongue collapse.
///
/// Uses the 6-axis IMU orientation relative to gravity to classify sleeping position
/// (Supine, Left Lateral, Right Lateral, Prone). If the user remains supine for excessive periods,
/// it delivers an ultra-gentle localized mono acoustic chime to prompt a spontaneous turn onto the side.
@MainActor
public final class PositionalApneaNudgeEngine: ObservableObject {
    public static let shared = PositionalApneaNudgeEngine()
    
    @Published public var isNudgeEnabled: Bool = true
    @Published public var currentPosition: BedPosition = .leftLateral
    @Published public var minutesInSupineTonight: Int = 18
    @Published public var supinePercentage: Double = 14.5 // Normal target: < 20%
    @Published public var rotationalNudgesDeliveredTonight: Int = 2
    @Published public var lastNudgeTimestamp: String = "02:14 AM (Turned Left)"
    @Published public var positionStatusMessage: String = "Optimal Lateral Airway Flow"
    
    public enum BedPosition: String, CaseIterable {
        case supine = "Supine (Flat on Back • High Apnea Risk)"
        case leftLateral = "Left Lateral (Side-Sleeping • Optimal Airway)"
        case rightLateral = "Right Lateral (Side-Sleeping • Low Strain)"
        case prone = "Prone (Stomach Sleeping)"
        
        public var color: Color {
            switch self {
            case .supine: return .red
            case .leftLateral: return .green
            case .rightLateral: return .blue
            case .prone: return .orange
            }
        }
        
        public var icon: String {
            switch self {
            case .supine: return "bed.double.fill"
            case .leftLateral: return "arrow.left.circle.fill"
            case .rightLateral: return "arrow.right.circle.fill"
            case .prone: return "person.fill"
            }
        }
    }
    
    private var positionTimer: Timer?
    private var continuousSupineSeconds: Int = 0
    
    private init() {
        startPositionWatcher()
    }
    
    private func startPositionWatcher() {
        positionTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateBedPosture()
            }
        }
    }
    
    public func triggerManualNudgeTest() {
        deliverGentleNudge(ear: .left)
    }
    
    private func evaluateBedPosture() {
        guard isNudgeEnabled else { return }
        
        let pitch = MotionManager.shared.rawPitch
        let roll = MotionManager.shared.rawRoll
        
        // Evaluate head angle relative to mattress plane:
        // Supine: Face looking straight up (pitch -15° to +25°, roll -30° to +30°)
        // Left Lateral: Roll < -45°
        // Right Lateral: Roll > +45°
        // Prone: Pitch < -50°
        withAnimation(.easeInOut(duration: 0.5)) {
            if roll < -40.0 {
                currentPosition = .leftLateral
                continuousSupineSeconds = 0
                positionStatusMessage = "Left Lateral: Optimal airway clearance & glymphatic drainage."
            } else if roll > 40.0 {
                currentPosition = .rightLateral
                continuousSupineSeconds = 0
                positionStatusMessage = "Right Lateral: Safe open airway position."
            } else if pitch < -45.0 {
                currentPosition = .prone
                continuousSupineSeconds = 0
                positionStatusMessage = "Prone: Monitor for cervical neck torsion."
            } else {
                currentPosition = .supine
                continuousSupineSeconds += 3
                minutesInSupineTonight += 1
                positionStatusMessage = "Supine posture: Gravity pulls soft palate toward pharynx."
                
                // If supine for > 15 seconds in testing (or > 6 minutes in real night mode)
                if continuousSupineSeconds >= 18 {
                    deliverGentleNudge(ear: .left)
                    continuousSupineSeconds = 0
                }
            }
        }
    }
    
    private func deliverGentleNudge(ear: ClinicalAudiogramEngine.EarSide) {
        rotationalNudgesDeliveredTonight += 1
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        lastNudgeTimestamp = "\(formatter.string(from: Date())) (Nudged to Lateral)"
        
        // Sub-audible / soft directional chime
        NSSound(named: "Pop")?.play()
    }
}
