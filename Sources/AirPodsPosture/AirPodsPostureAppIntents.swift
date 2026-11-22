import Foundation
import AppIntents
import SwiftUI

// MARK: - Calibrate Posture Intent

@available(macOS 13.0, *)
public struct CalibratePostureIntent: AppIntent {
    public static let title: LocalizedStringResource = "Calibrate Desk Posture"
    public static let description = IntentDescription("Calibrates AirPods Posture to your current upright screen-facing baseline.")
    public static let openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some ProvidesDialog & ReturnsValue<Bool> {
        let success = MotionManager.shared.calibrateCurrentPosture(force: false, isSilentAuto: false)
        if success {
            return .result(value: true, dialog: "Posture baseline calibrated to neutral upright alignment.")
        } else {
            return .result(value: false, dialog: "Please seat AirPods upright in your ear before calibrating.")
        }
    }
}

// MARK: - Get Posture Score Intent

@available(macOS 13.0, *)
public struct GetPostureScoreIntent: AppIntent {
    public static let title: LocalizedStringResource = "Get Current Posture Score"
    public static let description = IntentDescription("Retrieves your real-time desk posture quality score and alignment state.")
    public static let openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some ProvidesDialog & ReturnsValue<Int> {
        let score = MotionManager.shared.postureScore
        let state = MotionManager.shared.postureState.rawValue
        let pitch = Int(MotionManager.shared.deltaPitch)
        
        return .result(
            value: score,
            dialog: "Your current posture score is \(score)% (\(state)), with pitch at \(pitch)°."
        )
    }
}

// MARK: - Toggle Tracking Intent (Work Focus Automation)

@available(macOS 13.0, *)
public struct TogglePostureTrackingIntent: AppIntent {
    public static let title: LocalizedStringResource = "Toggle Posture Tracking"
    public static let description = IntentDescription("Starts or pauses real-time AirPods posture tracking when entering or leaving a Focus mode.")
    public static let openAppWhenRun: Bool = false
    
    public init() {}
    
    @MainActor
    public func perform() async throws -> some ProvidesDialog & ReturnsValue<Bool> {
        let motion = MotionManager.shared
        if motion.isTracking {
            motion.stopTracking()
            return .result(value: false, dialog: "AirPods Posture tracking paused.")
        } else {
            motion.startTracking()
            return .result(value: true, dialog: "AirPods Posture tracking active.")
        }
    }
}

// MARK: - App Shortcuts Provider (Siri & Shortcuts App)

@available(macOS 13.0, *)
public struct AirPodsPostureShortcutsProvider: AppShortcutsProvider {
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CalibratePostureIntent(),
            phrases: [
                "Calibrate my posture in \(.applicationName)",
                "Zero my posture in \(.applicationName)",
                "Set neutral posture in \(.applicationName)"
            ],
            shortTitle: "Calibrate Posture",
            systemImageName: "scope"
        )
        AppShortcut(
            intent: GetPostureScoreIntent(),
            phrases: [
                "Check my posture in \(.applicationName)",
                "What is my posture score in \(.applicationName)",
                "Get posture score in \(.applicationName)"
            ],
            shortTitle: "Check Posture",
            systemImageName: "figure.walk"
        )
    }
}
