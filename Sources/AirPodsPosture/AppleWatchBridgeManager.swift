import Foundation
import Combine

#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

public struct WatchTelemetryPacket: Codable {
    public let wristPitch: Double
    public let wristRoll: Double
    public let heartRateBPM: Double
    public let hrvSDNN: Double
    public let isTypingOnDesk: Bool
    public let timestamp: Date
}

@MainActor
public final class AppleWatchBridgeManager: NSObject, ObservableObject {
    public static let shared = AppleWatchBridgeManager()
    
    @Published public var isWatchConnected: Bool = false
    @Published public var isWatchAppInstalled: Bool = false
    @Published public var wristPitch: Double = 0.0
    @Published public var wristRoll: Double = 0.0
    @Published public var heartRateBPM: Double = 72.0
    @Published public var hrvSDNN: Double = 48.0
    @Published public var thoracicSlumpDetected: Bool = false
    @Published public var hapticFeedbackEnabled: Bool = true
    @Published public var statusMessage: String = "Watch Bridge Standby"
    
    private override init() {
        super.init()
        setupWatchSession()
    }
    
    public func setupWatchSession() {
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            statusMessage = "WatchConnectivity Session Activated"
        } else {
            statusMessage = "WatchConnectivity not supported on this host"
        }
        #else
        statusMessage = "Simulated Apple Watch Kinematic Bridge Ready"
        #endif
    }
    
    public func updateThoracicKinematics(airpodsPitch: Double) {
        // Biomechanical Sensor Fusion:
        // When AirPods detect head flexion (pitch < -10 deg) AND Apple Watch detects elevated wrist typing angles
        // with slumped forearm tilt (wristPitch < -15 deg), thoracic spine compression is confirmed.
        let isForwardHead = airpodsPitch < -10.0
        let isSlumpedForearm = wristPitch < -15.0
        
        if isForwardHead && isSlumpedForearm {
            if !thoracicSlumpDetected {
                thoracicSlumpDetected = true
                statusMessage = "⚠️ Thoracic Slump Detected (Hunched Shoulders)"
                sendWristHapticAlert()
            }
        } else {
            thoracicSlumpDetected = false
            if isWatchConnected {
                statusMessage = "Spine & Wrist Alignment Harmonized"
            }
        }
    }
    
    public func sendWristHapticAlert() {
        guard hapticFeedbackEnabled else { return }
        
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() && WCSession.default.isReachable {
            let payload: [String: Any] = ["command": "trigger_haptic", "type": "directionUp"]
            WCSession.default.sendMessage(payload, replyHandler: nil) { [weak self] error in
                Task { @MainActor [weak self] in
                    self?.statusMessage = "Watch Haptic Sent: \(error.localizedDescription)"
                }
            }
        }
        #endif
        
        // Also simulate wrist tap trigger
        MotionManager.shared.playFeedbackSound("Tink")
    }
    
    public func ingestSimulatedWatchPacket(pitch: Double, roll: Double, bpm: Double, hrv: Double) {
        self.isWatchConnected = true
        self.wristPitch = pitch
        self.wristRoll = roll
        self.heartRateBPM = bpm
        self.hrvSDNN = hrv
    }
}

#if canImport(WatchConnectivity)
extension AppleWatchBridgeManager: WCSessionDelegate {
    public nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            AppleWatchBridgeManager.shared.isWatchConnected = (activationState == .activated)
            AppleWatchBridgeManager.shared.isWatchAppInstalled = session.isWatchAppInstalled
        }
    }
    
    public nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            AppleWatchBridgeManager.shared.isWatchConnected = session.isReachable
        }
    }
    
    public nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        Task { @MainActor in
            if let pitch = message["wristPitch"] as? Double,
               let roll = message["wristRoll"] as? Double {
                AppleWatchBridgeManager.shared.wristPitch = pitch
                AppleWatchBridgeManager.shared.wristRoll = roll
            }
            if let bpm = message["heartRate"] as? Double {
                AppleWatchBridgeManager.shared.heartRateBPM = bpm
            }
            if let hrv = message["hrv"] as? Double {
                AppleWatchBridgeManager.shared.hrvSDNN = hrv
            }
            AppleWatchBridgeManager.shared.isWatchConnected = true
        }
    }
}
#endif
