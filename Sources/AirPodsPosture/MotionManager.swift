import Foundation
@preconcurrency import CoreMotion
import Combine
import AppKit

public enum PostureState: String, CaseIterable, Identifiable {
    case optimal = "Optimal"
    case warning = "Drifting"
    case slouching = "Slouching"
    case disconnected = "No AirPods"
    
    public var id: String { rawValue }
    
    public var colorName: String {
        switch self {
        case .optimal: return "green"
        case .warning: return "orange"
        case .slouching: return "red"
        case .disconnected: return "gray"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .slouching: return "xmark.octagon.fill"
        case .disconnected: return "headphones.circle"
        }
    }
}

public enum HeadGesture: String {
    case nod = "Nod (Yes)"
    case shake = "Shake (No)"
    case none = "None"
}

@MainActor
public final class MotionManager: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate {
    public static let shared = MotionManager()
    
    private let motionManager = CMHeadphoneMotionManager()
    
    // Live raw angles (degrees)
    @Published public var rawPitch: Double = 0.0
    @Published public var rawRoll: Double = 0.0
    @Published public var rawYaw: Double = 0.0
    
    // Calibrated baseline (degrees)
    @Published public var baselinePitch: Double = 0.0
    @Published public var baselineRoll: Double = 0.0
    @Published public var baselineYaw: Double = 0.0
    @Published public var isCalibrated: Bool = false
    
    // Delta relative to calibrated baseline (degrees)
    @Published public var deltaPitch: Double = 0.0
    @Published public var deltaRoll: Double = 0.0
    @Published public var deltaYaw: Double = 0.0
    
    // Status & Health
    @Published public var isConnected: Bool = false
    @Published public var isTracking: Bool = false
    @Published public var postureState: PostureState = .disconnected
    @Published public var postureScore: Int = 100 // 0 to 100
    
    // Statistics
    @Published public var secondsTracked: TimeInterval = 0
    @Published public var secondsGoodPosture: TimeInterval = 0
    @Published public var secondsSlouching: TimeInterval = 0
    @Published public var slouchEventCount: Int = 0
    
    // Gestures
    @Published public var lastDetectedGesture: HeadGesture = .none
    @Published public var gestureTimestamp: Date? = nil
    
    // Settings & Thresholds
    @Published public var pitchThreshold: Double = 12.0 // degrees downward
    @Published public var rollThreshold: Double = 10.0  // degrees lateral
    @Published public var gracePeriodSeconds: Double = 3.0
    @Published public var soundAlertsEnabled: Bool = true
    @Published public var alertSoundName: String = "Tink"
    
    // Simulation / Demo Mode (for testing without AirPods on)
    @Published public var isSimulated: Bool = false
    @Published public var simulatedPitch: Double = 0.0 {
        didSet { if isSimulated { processAngles(pitch: simulatedPitch, roll: simulatedRoll, yaw: simulatedYaw) } }
    }
    @Published public var simulatedRoll: Double = 0.0 {
        didSet { if isSimulated { processAngles(pitch: simulatedPitch, roll: simulatedRoll, yaw: simulatedYaw) } }
    }
    @Published public var simulatedYaw: Double = 0.0 {
        didSet { if isSimulated { processAngles(pitch: simulatedPitch, roll: simulatedRoll, yaw: simulatedYaw) } }
    }
    
    // Internal timing
    private var warningStartTime: Date? = nil
    private var lastAlertSoundTime: Date? = nil
    private var timer: Timer? = nil
    
    // Gesture detection buffers
    private var pitchHistory: [(time: Date, value: Double)] = []
    private var yawHistory: [(time: Date, value: Double)] = []
    
    public override init() {
        super.init()
        motionManager.delegate = self
        checkConnection()
        startTracking()
        startPeriodicTimer()
    }
    
    public func checkConnection() {
        if isSimulated {
            isConnected = true
            return
        }
        isConnected = motionManager.isDeviceMotionAvailable
        if !isConnected {
            postureState = .disconnected
        }
    }
    
    public func startTracking() {
        if isSimulated {
            isTracking = true
            isConnected = true
            postureState = .optimal
            return
        }
        
        guard motionManager.isDeviceMotionAvailable else {
            isConnected = false
            postureState = .disconnected
            return
        }
        
        isConnected = true
        isTracking = true
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion, error == nil else { return }
            
            // CoreMotion Euler angles (radians -> degrees)
            let pitchDeg = motion.attitude.pitch * 180.0 / .pi
            let rollDeg = motion.attitude.roll * 180.0 / .pi
            let yawDeg = motion.attitude.yaw * 180.0 / .pi
            
            self.processAngles(pitch: pitchDeg, roll: rollDeg, yaw: yawDeg)
        }
    }
    
    public func stopTracking() {
        if !isSimulated {
            motionManager.stopDeviceMotionUpdates()
        }
        isTracking = false
        postureState = .disconnected
    }
    
    public func calibrateCurrentPosture() {
        baselinePitch = rawPitch
        baselineRoll = rawRoll
        baselineYaw = rawYaw
        isCalibrated = true
        deltaPitch = 0
        deltaRoll = 0
        deltaYaw = 0
        postureState = .optimal
        warningStartTime = nil
        playFeedbackSound("Hero")
    }
    
    public func toggleSimulation() {
        isSimulated.toggle()
        if isSimulated {
            motionManager.stopDeviceMotionUpdates()
            isConnected = true
            isTracking = true
            if !isCalibrated {
                calibrateCurrentPosture()
            }
            processAngles(pitch: simulatedPitch, roll: simulatedRoll, yaw: simulatedYaw)
        } else {
            startTracking()
        }
    }
    
    private func processAngles(pitch: Double, roll: Double, yaw: Double) {
        rawPitch = pitch
        rawRoll = roll
        rawYaw = yaw
        
        // Auto-calibrate on first valid read if not yet calibrated
        if !isCalibrated {
            baselinePitch = pitch
            baselineRoll = roll
            baselineYaw = yaw
            isCalibrated = true
        }
        
        // Calculate deviations from calibrated posture
        deltaPitch = rawPitch - baselinePitch
        deltaRoll = rawRoll - baselineRoll
        deltaYaw = rawYaw - baselineYaw
        
        // Check for gestures
        detectGestures(pitch: deltaPitch, yaw: deltaYaw)
        
        // Evaluate posture deviation
        // Downward tilt (looking down/slouching) is typically deltaPitch < 0 or > 0 depending on earbud orientation.
        // We evaluate magnitude of head drop or backward slump:
        let pitchDeviation = abs(deltaPitch)
        let rollDeviation = abs(deltaRoll)
        
        let isPitchBad = pitchDeviation > pitchThreshold
        let isRollBad = rollDeviation > rollThreshold
        
        if isPitchBad || isRollBad {
            if warningStartTime == nil {
                warningStartTime = Date()
            }
            
            let elapsedWarning = Date().timeIntervalSince(warningStartTime!)
            if elapsedWarning >= gracePeriodSeconds {
                if postureState != .slouching {
                    slouchEventCount += 1
                    triggerSlouchAlert()
                }
                postureState = .slouching
            } else {
                postureState = .warning
            }
        } else {
            warningStartTime = nil
            postureState = .optimal
        }
        
        // Compute dynamic posture score based on deviations
        let pitchPenalty = min(pitchDeviation / pitchThreshold, 2.0) * 40.0
        let rollPenalty = min(rollDeviation / rollThreshold, 2.0) * 30.0
        let calculatedScore = max(0, min(100, Int(100.0 - (pitchPenalty + rollPenalty))))
        postureScore = (postureScore * 9 + calculatedScore) / 10
    }
    
    private func detectGestures(pitch: Double, yaw: Double) {
        let now = Date()
        pitchHistory.append((time: now, value: pitch))
        yawHistory.append((time: now, value: yaw))
        
        // Keep last 1 second of history
        pitchHistory.removeAll { now.timeIntervalSince($0.time) > 1.0 }
        yawHistory.removeAll { now.timeIntervalSince($0.time) > 1.0 }
        
        guard pitchHistory.count > 10 else { return }
        
        let minPitch = pitchHistory.map { $0.value }.min() ?? 0
        let maxPitch = pitchHistory.map { $0.value }.max() ?? 0
        
        let minYaw = yawHistory.map { $0.value }.min() ?? 0
        let maxYaw = yawHistory.map { $0.value }.max() ?? 0
        
        // Nod gesture: rapid oscillation of > 18° up and down
        if (maxPitch - minPitch) > 18.0 && (maxYaw - minYaw) < 10.0 {
            if lastDetectedGesture != .nod || (gestureTimestamp != nil && now.timeIntervalSince(gestureTimestamp!) > 1.5) {
                lastDetectedGesture = .nod
                gestureTimestamp = now
                pitchHistory.removeAll()
            }
        }
        // Shake gesture: rapid oscillation of > 22° left and right
        else if (maxYaw - minYaw) > 22.0 && (maxPitch - minPitch) < 10.0 {
            if lastDetectedGesture != .shake || (gestureTimestamp != nil && now.timeIntervalSince(gestureTimestamp!) > 1.5) {
                lastDetectedGesture = .shake
                gestureTimestamp = now
                yawHistory.removeAll()
            }
        }
    }
    
    private func triggerSlouchAlert() {
        guard soundAlertsEnabled else { return }
        
        let now = Date()
        if let lastSound = lastAlertSoundTime, now.timeIntervalSince(lastSound) < 10.0 {
            return // rate limit alerts
        }
        lastAlertSoundTime = now
        playFeedbackSound(alertSoundName)
    }
    
    public func playFeedbackSound(_ name: String) {
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    private func startPeriodicTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard self.isTracking && self.isConnected else { return }
                self.secondsTracked += 1.0
                if self.postureState == .optimal {
                    self.secondsGoodPosture += 1.0
                } else if self.postureState == .slouching {
                    self.secondsSlouching += 1.0
                }
            }
        }
    }
    
    // Delegate hooks
    nonisolated public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isConnected = true
            self.startTracking()
        }
    }
    
    nonisolated public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isConnected = false
            self.postureState = .disconnected
        }
    }
    
    isolated deinit {
        timer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
    }
}
