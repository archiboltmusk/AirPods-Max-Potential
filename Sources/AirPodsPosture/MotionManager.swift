import Foundation
@preconcurrency import CoreMotion
import Combine
import AppKit
import ServiceManagement
import simd

public enum PostureState: String, CaseIterable, Identifiable {
    case optimal = "Optimal"
    case warning = "Drifting"
    case slouching = "Slouching"
    case snoozed = "Snoozed"
    case disconnected = "No AirPods"
    
    public var id: String { rawValue }
    
    public var colorName: String {
        switch self {
        case .optimal: return "green"
        case .warning: return "orange"
        case .slouching: return "red"
        case .snoozed: return "blue"
        case .disconnected: return "gray"
        }
    }
    
    public var systemImage: String {
        switch self {
        case .optimal: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .slouching: return "xmark.octagon.fill"
        case .snoozed: return "moon.zzz.fill"
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
    private let motionQueue = OperationQueue()
    private let defaults = UserDefaults.standard
    
    // --- Live Sensor Telemetry (AirPods Pro 2 IMU Suite) ---
    // 1. Live Euler Angles (degrees)
    @Published public var rawPitch: Double = 0.0
    @Published public var rawRoll: Double = 0.0
    @Published public var rawYaw: Double = 0.0
    
    // 2. Quaternion
    @Published public var quatW: Double = 1.0
    @Published public var quatX: Double = 0.0
    @Published public var quatY: Double = 0.0
    @Published public var quatZ: Double = 0.0
    
    // 3. Gravity Vector (g units)
    @Published public var gravityX: Double = 0.0
    @Published public var gravityY: Double = 0.0
    @Published public var gravityZ: Double = -1.0
    
    // 4. User Dynamic Acceleration (g units)
    @Published public var userAccelX: Double = 0.0
    @Published public var userAccelY: Double = 0.0
    @Published public var userAccelZ: Double = 0.0
    @Published public var totalKineticEnergy: Double = 0.0
    
    // 5. Gyroscope Rotation Rate (deg/s)
    @Published public var rotRateX: Double = 0.0
    @Published public var rotRateY: Double = 0.0
    @Published public var rotRateZ: Double = 0.0
    
    // 6. Packet Counter & Pipeline Info
    @Published public var packetCount: Int = 0
    @Published public var packetsPerSecond: Int = 0
    @Published public var activeDataSource: String = "Connecting..."
    @Published public var lastPacketDate: Date? = nil
    @Published public var lastErrorMessage: String? = nil
    
    // Slouch-Proof Safety Interlock
    @Published public var calibrationInterlockAlert: String? = nil
    @Published public var isInterlockActive: Bool = false
    
    // Anti-Gaming Upright Recovery Lockout (AirPosture & PostureFix)
    @Published public var recoveryGraceSeconds: Double = 2.0
    @Published public var isRecoveringHysteresis: Bool = false
    private var uprightRecoveryStartTime: Date? = nil
    
    // Calibrated baseline quaternion & Euler
    public var qBaseline: simd_quatd = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    @Published public var isCalibrated: Bool = false
    
    // Relative Posture Deviations (degrees from calibrated baseline)
    @Published public var deltaPitch: Double = 0.0
    @Published public var deltaRoll: Double = 0.0
    @Published public var deltaYaw: Double = 0.0
    
    // Status & Health
    @Published public var isConnected: Bool = false
    @Published public var isTracking: Bool = false
    @Published public var postureState: PostureState = .disconnected
    @Published public var postureScore: Int = 100
    @Published public var warningProgress: Double = 0.0
    
    // Statistics
    @Published public var secondsTracked: TimeInterval = 0
    @Published public var secondsGoodPosture: TimeInterval = 0
    @Published public var secondsSlouching: TimeInterval = 0
    @Published public var slouchEventCount: Int = 0
    
    // Gestures
    @Published public var lastDetectedGesture: HeadGesture = .none
    @Published public var gestureTimestamp: Date? = nil
    
    // Settings & Thresholds
    @Published public var pitchThreshold: Double = 12.0
    @Published public var rollThreshold: Double = 10.0
    @Published public var gracePeriodSeconds: Double = 3.0
    @Published public var soundAlertsEnabled: Bool = true
    @Published public var alertSoundName: String = "Tink"
    
    // Intelligent Features
    @Published public var activeProfile: PostureProfile = .standardDesk {
        didSet {
            pitchThreshold = activeProfile.defaultPitchThreshold
            rollThreshold = activeProfile.defaultRollThreshold
            savePreferences()
        }
    }
    @Published public var muteInMeetings: Bool = true
    @Published public var autoDriftCorrection: Bool = false
    @Published public var batterySaverMode: Bool = false
    @Published public var snoozeUntil: Date? = nil
    @Published public var launchAtLogin: Bool = false {
        didSet {
            do {
                if launchAtLogin {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
            } catch {
                print("Failed to toggle launch at login:", error)
            }
        }
    }
    
    // Simulation / Demo Mode
    @Published public var isSimulated: Bool = false
    @Published public var simulatedPitch: Double = 0.0 {
        didSet { if isSimulated { processSimulated() } }
    }
    @Published public var simulatedRoll: Double = 0.0 {
        didSet { if isSimulated { processSimulated() } }
    }
    @Published public var simulatedYaw: Double = 0.0 {
        didSet { if isSimulated { processSimulated() } }
    }
    
    // Internal timing & buffers
    private var warningStartTime: Date? = nil
    private var lastAlertSoundTime: Date? = nil
    private var watchdogTimer: Timer? = nil
    private var periodicTimer: Timer? = nil
    private var lastSampleTime: Date = Date()
    private var ppsWindowTimestamps: [Date] = []
    
    private var pitchHistory: [(time: Date, value: Double)] = []
    private var yawHistory: [(time: Date, value: Double)] = []
    
    public override init() {
        super.init()
        
        motionQueue.name = "com.airpodsiq.motionqueue"
        motionQueue.qualityOfService = .userInteractive
        motionQueue.maxConcurrentOperationCount = 1
        
        motionManager.delegate = self
        loadPreferences()
        
        setupBridgeReceiver()
        startTracking()
        startPeriodicTimer()
        startWatchdog()
    }
    
    private func setupBridgeReceiver() {
        UDPBridgeReceiver.shared.onPacket = { [weak self] quat, gyro, accel, pps, device in
            self?.processIncomingSample(
                quat: quat,
                gyro: gyro,
                accel: accel,
                gravity: nil,
                pps: pps,
                source: "AirPods Pro (\(device))"
            )
        }
        UDPBridgeReceiver.shared.start(port: 4243)
    }
    
    public var isSnoozed: Bool {
        if let snooze = snoozeUntil {
            return Date() < snooze
        }
        return false
    }
    
    public var snoozeTimeRemaining: TimeInterval {
        guard let snooze = snoozeUntil else { return 0 }
        return max(0, snooze.timeIntervalSinceNow)
    }
    
    public func snooze(minutes: Double) {
        snoozeUntil = Date().addingTimeInterval(minutes * 60.0)
        postureState = .snoozed
        playFeedbackSound("Pop")
    }
    
    public func clearSnooze() {
        snoozeUntil = nil
        postureState = .optimal
        playFeedbackSound("Pop")
    }
    
    public func startTracking() {
        if isSimulated {
            isTracking = true
            isConnected = true
            postureState = .optimal
            activeDataSource = "Simulation Demo"
            return
        }
        
        isTracking = true
        
        // 1. Direct CoreMotion setup
        if motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive {
            motionManager.startDeviceMotionUpdates(to: motionQueue) { [weak self] motion, error in
                if let error = error {
                    Task { @MainActor in
                        self?.lastErrorMessage = error.localizedDescription
                    }
                    return
                }
                guard let m = motion else { return }
                
                let q = m.attitude.quaternion
                let quat = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
                let gyro = SIMD3<Double>(m.rotationRate.x, m.rotationRate.y, m.rotationRate.z)
                let accel = SIMD3<Double>(m.userAcceleration.x, m.userAcceleration.y, m.userAcceleration.z)
                let grav = SIMD3<Double>(m.gravity.x, m.gravity.y, m.gravity.z)
                
                Task { @MainActor in
                    self?.processIncomingSample(
                        quat: quat,
                        gyro: gyro,
                        accel: accel,
                        gravity: grav,
                        pps: 50,
                        source: "Direct CoreMotion"
                    )
                }
            }
        }
    }
    
    public func stopTracking() {
        if !isSimulated {
            motionManager.stopDeviceMotionUpdates()
        }
        isTracking = false
        postureState = .disconnected
    }
    
    @discardableResult
    public func calibrateCurrentPosture(force: Bool = false) -> Bool {
        // Evaluate raw anatomical orientation relative to gravity/world
        let rawEuler = QuaternionMath.euler(from: simd_quatd(ix: quatX, iy: quatY, iz: quatZ, r: quatW))
        let currentPitch = rawEuler.pitch
        let currentRoll = rawEuler.roll
        
        // Strict Slouch-Proof Interlock:
        // Prevent user from calibrating in a slouch (head down < -6.5° or tilted back > +10° or rolled > 6°)
        if !force && (currentPitch < -6.5 || currentPitch > 10.0 || abs(currentRoll) > 6.0) {
            let direction = currentPitch < -6.5 ? "looking down (\(Int(currentPitch))°)" : (currentPitch > 10.0 ? "tilted backward (\(Int(currentPitch))°)" : "tilted sideways (\(Int(currentRoll))°)")
            isInterlockActive = true
            calibrationInterlockAlert = "⚠️ Slouch-Proof Interlock: Rejected calibration while head is \(direction). Please sit upright with eyes level."
            SyntheticEarHapticEngine.shared.playGentleDoubleTap()
            DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Calibration Blocked: Sit Upright (Chin Level)", autoDismissSeconds: 4.5)
            
            // Auto-clear alert after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) { [weak self] in
                self?.isInterlockActive = false
                self?.calibrationInterlockAlert = nil
            }
            return false
        }
        
        isInterlockActive = false
        calibrationInterlockAlert = nil
        let currentQuat = simd_quatd(ix: quatX, iy: quatY, iz: quatZ, r: quatW)
        qBaseline = currentQuat
        isCalibrated = true
        deltaPitch = 0
        deltaRoll = 0
        deltaYaw = 0
        postureState = isSnoozed ? .snoozed : .optimal
        warningStartTime = nil
        warningProgress = 0.0
        savePreferences()
        playFeedbackSound("Hero")
        SyntheticEarHapticEngine.shared.playSuccessChirp()
        
        // Also calibrate Optical Webcam Sentinel to neutral upright baseline if active
        if OpticalContinuitySentinel.shared.isRunning {
            OpticalContinuitySentinel.shared.calibrateNeutralBaseline()
        }
        
        DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Calibrated: Locked to Upright Baseline", autoDismissSeconds: 3.0)
        return true
    }
    
    public func toggleSimulation() {
        isSimulated.toggle()
        if isSimulated {
            motionManager.stopDeviceMotionUpdates()
            isConnected = true
            isTracking = true
            activeDataSource = "Simulation Demo"
            if !isCalibrated {
                calibrateCurrentPosture()
            }
            processSimulated()
        } else {
            startTracking()
        }
    }
    
    public func processIncomingSample(
        quat: simd_quatd,
        gyro: SIMD3<Double>,
        accel: SIMD3<Double>,
        gravity: SIMD3<Double>?,
        pps: Int,
        source: String
    ) {
        guard !isSimulated else { return }
        
        let now = Date()
        packetCount += 1
        lastPacketDate = now
        isConnected = true
        activeDataSource = source
        
        // Calculate rolling PPS
        ppsWindowTimestamps.append(now)
        ppsWindowTimestamps.removeAll { now.timeIntervalSince($0) > 1.0 }
        packetsPerSecond = max(pps, ppsWindowTimestamps.count)
        
        // 1. Store raw Quaternion
        quatW = quat.real
        quatX = quat.imag.x
        quatY = quat.imag.y
        quatZ = quat.imag.z
        
        // 2. Compute absolute Euler angles
        let rawEuler = QuaternionMath.euler(from: quat)
        rawPitch = rawEuler.pitch
        rawRoll = rawEuler.roll
        rawYaw = rawEuler.yaw
        
        // 3. User acceleration & Kinetic energy
        userAccelX = accel.x
        userAccelY = accel.y
        userAccelZ = accel.z
        totalKineticEnergy = sqrt(pow(userAccelX, 2) + pow(userAccelY, 2) + pow(userAccelZ, 2))
        
        // Touchless Teeth-Click Micro-Gesture Sentinel
        if totalKineticEnergy > TeethClickGestureEngine.shared.sensitivityLevel.threshold {
            TeethClickGestureEngine.shared.processAcousticImpulse(energy: totalKineticEnergy)
        }
        
        // 4. Gyroscope rotation rate (rad/s -> deg/s)
        rotRateX = gyro.x * 180.0 / .pi
        rotRateY = gyro.y * 180.0 / .pi
        rotRateZ = gyro.z * 180.0 / .pi
        
        // 5. Gravity Vector
        if let g = gravity {
            gravityX = g.x
            gravityY = g.y
            gravityZ = g.z
        }
        
        // Auto-calibrate on first incoming packet
        if !isCalibrated {
            qBaseline = quat
            isCalibrated = true
            savePreferences()
        }
        
        // Autonomous Continuous Statistical Calibration
        AutonomousAutoCalibrator.shared.processIncomingSample(
            currentQuat: quat,
            gravity: gravity,
            gyroVariance: sqrt(pow(rotRateX, 2) + pow(rotRateY, 2) + pow(rotRateZ, 2)),
            userEnergy: totalKineticEnergy
        )
        
        // Auto-drift compensation: slowly pull baseline toward current if stable
        if autoDriftCorrection {
            let driftFactor = 0.0004
            qBaseline = simd_slerp(qBaseline, quat, driftFactor)
        }
        
        // 6. Compute exact relative posture in 3D quaternion space
        let qRel = QuaternionMath.relativeOrientation(baseline: qBaseline, current: quat)
        let relEuler = QuaternionMath.euler(from: qRel)
        
        deltaPitch = relEuler.pitch
        deltaRoll = relEuler.roll
        deltaYaw = relEuler.yaw
        
        evaluatePosture()
    }
    
    private func processSimulated() {
        rawPitch = simulatedPitch
        rawRoll = simulatedRoll
        rawYaw = simulatedYaw
        deltaPitch = simulatedPitch
        deltaRoll = simulatedRoll
        deltaYaw = simulatedYaw
        gravityX = 0
        gravityY = sin(simulatedRoll * .pi / 180)
        gravityZ = -cos(simulatedPitch * .pi / 180)
        userAccelX = 0
        userAccelY = 0
        userAccelZ = 0
        rotRateX = 0
        rotRateY = 0
        rotRateZ = 0
        packetsPerSecond = 60
        evaluatePosture()
    }
    
    private func evaluatePosture() {
        detectGestures(pitch: deltaPitch, yaw: deltaYaw)
        
        if isSnoozed {
            postureState = .snoozed
            warningProgress = 0.0
            ScreenGlowManager.shared.update(postureState: postureState)
        NotchHUDManager.shared.update(postureState: postureState)
        SpatialAudioBiofeedback.shared.updateSlouchMuffle(deltaPitch: deltaPitch, threshold: pitchThreshold)
        MultiMonitorGuard.shared.update(deltaYaw: deltaYaw)
        HeadPointerManager.shared.update(deltaPitch: deltaPitch)
        FocusRestlessnessTracker.shared.update(rotRateX: rotRateX, rotRateY: rotRateY, rotRateZ: rotRateZ)
        StandingDeskTracker.shared.update(userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        WalkAwayLockManager.shared.update(isConnected: isConnected, lastPacketAge: Date().timeIntervalSince(lastPacketDate ?? Date()))
        SpatialSpacesManager.shared.update(deltaYaw: deltaYaw)
        DrowsinessGuard.shared.update(deltaPitch: deltaPitch, userAccelZ: userAccelZ)
        ThoracicSlumpAnalyzer.shared.update(deltaPitch: deltaPitch, gravityY: gravityY, gravityZ: gravityZ, userAccelZ: userAccelZ)
        CervicalROMDiagnostic.shared.update(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        HydrationTracker.shared.update(pitch: deltaPitch, roll: deltaRoll)
        HolographicParallaxManager.shared.update(pitch: deltaPitch, yaw: deltaYaw)
        WindowSnapManager.shared.update(pitch: deltaPitch, roll: deltaRoll)
        ErgonomicPomodoroEngine.shared.update(score: Double(postureScore))
        AcousticPulseEstimator.shared.update(userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        VocalStrainCoach.shared.update(pitch: deltaPitch, roll: deltaRoll)
        MultiDisplayFocusManager.shared.update(yawDegrees: deltaYaw)
        MenuBarSparklineRenderer.shared.addSample(score: postureScore)
        Spatial3DAnchorManager.shared.updateListenerOrientation(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        NeuralPoseClassifier.shared.classify(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw, accel: SIMD3<Double>(userAccelX, userAccelY, userAccelZ), rotRate: SIMD3<Double>(rotRateX, rotRateY, rotRateZ))
        CervicalGameEngine.shared.updateHeadPitch(pitch: deltaPitch)
        AppleWatchBridgeManager.shared.updateThoracicKinematics(airpodsPitch: deltaPitch)
        OcclusionAudioTransparencyManager.shared.update(rotRateX: rotRateX, rotRateY: rotRateY, rotRateZ: rotRateZ, userAccelZ: userAccelZ)
        DisplayDistanceGuardManager.shared.update(pitch: deltaPitch, userAccelZ: userAccelZ)
        MicroNapSleepApneaDetector.shared.update(pitch: deltaPitch, userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        CervicalKeypressWheelManager.shared.update(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        AcousticRespiratoryEngine.shared.update(pitch: deltaPitch, userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        MultiDisplaySpatialGridMapper.shared.update(yaw: deltaYaw)
        ProceduralBinauralSoundscapeEngine.shared.updatePostureModulation(postureScore: postureScore)
        FaceTimeHeadReactionsManager.shared.checkReactionGestures(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
            return
        }
        
        let pitchDeviation = abs(deltaPitch)
        let rollDeviation = abs(deltaRoll)
        
        var effectivePitchThreshold = pitchThreshold
        if CircadianMelatoninShield.shared.isShieldEnabled && CircadianMelatoninShield.shared.isNightModeActive {
            effectivePitchThreshold = pitchThreshold / CircadianMelatoninShield.shared.eveningPostureThresholdMultiplier
        }
        let isPitchBad = pitchDeviation > effectivePitchThreshold
        let isRollBad = rollDeviation > rollThreshold
        
        if isPitchBad || isRollBad {
            uprightRecoveryStartTime = nil
            isRecoveringHysteresis = false
            
            if warningStartTime == nil {
                warningStartTime = Date()
            }
            
            let elapsedWarning = Date().timeIntervalSince(warningStartTime!)
            warningProgress = min(1.0, elapsedWarning / gracePeriodSeconds)
            
            if elapsedWarning >= gracePeriodSeconds {
                if postureState != .slouching {
                    // Check if user is typing rapidly (Flow state gating)
                    if !TypingFlowStateGatingManager.shared.shouldSuppressAlertForFlow() {
                        slouchEventCount += 1
                        triggerSlouchAlert()
                        SyntheticEarHapticEngine.shared.playDirectionalPostureCue(pitch: deltaPitch, roll: deltaRoll, pitchThreshold: pitchThreshold, rollThreshold: rollThreshold)
                    }
                    DynamicIslandNotchHaloManager.shared.updatePosture(postureState: .slouching, deltaPitch: deltaPitch)
                }
                postureState = .slouching
            } else {
                if postureState == .optimal {
                    SyntheticEarHapticEngine.shared.playDirectionalPostureCue(pitch: deltaPitch, roll: deltaRoll, pitchThreshold: pitchThreshold, rollThreshold: rollThreshold)
                }
                postureState = .warning
            }
        } else {
            warningStartTime = nil
            warningProgress = 0.0
            
            // Anti-gaming upright recovery lockout (AirPosture & PostureFix)
            if postureState == .slouching || isRecoveringHysteresis {
                let now = Date()
                if let start = uprightRecoveryStartTime {
                    if now.timeIntervalSince(start) >= recoveryGraceSeconds {
                        postureState = .optimal
                        isRecoveringHysteresis = false
                        uprightRecoveryStartTime = nil
                    } else {
                        isRecoveringHysteresis = true
                        postureState = .warning
                    }
                } else {
                    uprightRecoveryStartTime = now
                    isRecoveringHysteresis = true
                    postureState = .warning
                }
            } else {
                uprightRecoveryStartTime = nil
                isRecoveringHysteresis = false
                postureState = .optimal
            }
        }
        
        let pitchPenalty = min(pitchDeviation / pitchThreshold, 2.0) * 40.0
        let rollPenalty = min(rollDeviation / rollThreshold, 2.0) * 30.0
        let calculatedScore = max(0, min(100, Int(100.0 - (pitchPenalty + rollPenalty))))
        postureScore = (postureScore * 9 + calculatedScore) / 10
        
        ScreenGlowManager.shared.update(postureState: postureState)
        ProgressiveScreenBlurManager.shared.update(postureState: postureState, deltaPitch: deltaPitch)
        CervicalRepCounterEngine.shared.update(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        HeadShortcutsActionRunner.shared.processMotion(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw, userAccelY: userAccelY)
        DualDirectionPosturalEngine.shared.update(pitch: deltaPitch, dt: 1.0 / 60.0)
        HourlyFatigueProfiler.shared.recordMonitoredSecond(dt: 1.0 / 60.0)
        NotchHUDManager.shared.update(postureState: postureState)
        SpatialAudioBiofeedback.shared.updateSlouchMuffle(deltaPitch: deltaPitch, threshold: pitchThreshold)
        MultiMonitorGuard.shared.update(deltaYaw: deltaYaw)
        HeadPointerManager.shared.update(deltaPitch: deltaPitch)
        FocusRestlessnessTracker.shared.update(rotRateX: rotRateX, rotRateY: rotRateY, rotRateZ: rotRateZ)
        StandingDeskTracker.shared.update(userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        WalkAwayLockManager.shared.update(isConnected: isConnected, lastPacketAge: Date().timeIntervalSince(lastPacketDate ?? Date()))
        SpatialSpacesManager.shared.update(deltaYaw: deltaYaw)
        DrowsinessGuard.shared.update(deltaPitch: deltaPitch, userAccelZ: userAccelZ)
        ThoracicSlumpAnalyzer.shared.update(deltaPitch: deltaPitch, gravityY: gravityY, gravityZ: gravityZ, userAccelZ: userAccelZ)
        CervicalROMDiagnostic.shared.update(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        HydrationTracker.shared.update(pitch: deltaPitch, roll: deltaRoll)
        HolographicParallaxManager.shared.update(pitch: deltaPitch, yaw: deltaYaw)
        WindowSnapManager.shared.update(pitch: deltaPitch, roll: deltaRoll)
        ErgonomicPomodoroEngine.shared.update(score: Double(postureScore))
        AcousticPulseEstimator.shared.update(userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        VocalStrainCoach.shared.update(pitch: deltaPitch, roll: deltaRoll)
        MultiDisplayFocusManager.shared.update(yawDegrees: deltaYaw)
        MenuBarSparklineRenderer.shared.addSample(score: postureScore)
        Spatial3DAnchorManager.shared.updateListenerOrientation(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        NeuralPoseClassifier.shared.classify(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw, accel: SIMD3<Double>(userAccelX, userAccelY, userAccelZ), rotRate: SIMD3<Double>(rotRateX, rotRateY, rotRateZ))
        CervicalGameEngine.shared.updateHeadPitch(pitch: deltaPitch)
        AppleWatchBridgeManager.shared.updateThoracicKinematics(airpodsPitch: deltaPitch)
        OcclusionAudioTransparencyManager.shared.update(rotRateX: rotRateX, rotRateY: rotRateY, rotRateZ: rotRateZ, userAccelZ: userAccelZ)
        DisplayDistanceGuardManager.shared.update(pitch: deltaPitch, userAccelZ: userAccelZ)
        MicroNapSleepApneaDetector.shared.update(pitch: deltaPitch, userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        CervicalKeypressWheelManager.shared.update(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        AcousticRespiratoryEngine.shared.update(pitch: deltaPitch, userAccelZ: userAccelZ, totalEnergy: totalKineticEnergy)
        MultiDisplaySpatialGridMapper.shared.update(yaw: deltaYaw)
        ProceduralBinauralSoundscapeEngine.shared.updatePostureModulation(postureScore: postureScore)
        FaceTimeHeadReactionsManager.shared.checkReactionGestures(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
        StudentStudySuiteEngine.shared.processStudyGestures(pitch: deltaPitch, roll: deltaRoll)
    }
    
    private func detectGestures(pitch: Double, yaw: Double) {
        let now = Date()
        pitchHistory.append((time: now, value: pitch))
        yawHistory.append((time: now, value: yaw))
        
        pitchHistory.removeAll { now.timeIntervalSince($0.time) > 1.0 }
        yawHistory.removeAll { now.timeIntervalSince($0.time) > 1.0 }
        
        guard pitchHistory.count > 10 else { return }
        
        let minPitch = pitchHistory.map { $0.value }.min() ?? 0
        let maxPitch = pitchHistory.map { $0.value }.max() ?? 0
        
        let minYaw = yawHistory.map { $0.value }.min() ?? 0
        let maxYaw = yawHistory.map { $0.value }.max() ?? 0
        
        if (maxPitch - minPitch) > 18.0 && (maxYaw - minYaw) < 10.0 {
            if lastDetectedGesture != .nod || (gestureTimestamp != nil && now.timeIntervalSince(gestureTimestamp!) > 1.5) {
                lastDetectedGesture = .nod
                gestureTimestamp = now
                DictationTriggerManager.shared.recordNod()
                
                // If user is slouching or requesting calibration, deliberate nod recalibrates automatically
                if postureState == .slouching || postureState == .warning {
                    AutonomousAutoCalibrator.shared.triggerInstantDoubleNodCalibration()
                }
                
                pitchHistory.removeAll()
            }
        } else if (maxYaw - minYaw) > 22.0 && (maxPitch - minPitch) < 10.0 {
            if lastDetectedGesture != .shake || (gestureTimestamp != nil && now.timeIntervalSince(gestureTimestamp!) > 1.5) {
                lastDetectedGesture = .shake
                gestureTimestamp = now
                yawHistory.removeAll()
                if postureState == .slouching {
                    warningStartTime = Date()
                }
            }
        }
    }
    
    public func triggerSlouchAlert() {
        NotificationManager.shared.sendSlouchNotification(pitch: deltaPitch, roll: deltaRoll)
        SystemAudioVoiceAlertEngine.shared.triggerSlouchNudge(pitchDeviation: deltaPitch)
        HourlyFatigueProfiler.shared.recordAlert()
        
        guard soundAlertsEnabled else { return }
        if muteInMeetings && AudioEnvironmentMonitor.shared.isMicrophoneInUse {
            return
        }
        
        let now = Date()
        if let lastSound = lastAlertSoundTime, now.timeIntervalSince(lastSound) < 12.0 {
            return
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
    
    private func startWatchdog() {
        watchdogTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard !self.isSimulated else { return }
                
                // If no packets in 3.5 seconds, try triggering CoreMotion discovery again
                if let last = self.lastPacketDate, Date().timeIntervalSince(last) > 3.5 {
                    self.packetsPerSecond = 0
                    if self.motionManager.isDeviceMotionAvailable {
                        self.startTracking()
                    }
                }
            }
        }
    }
    
    private func startPeriodicTimer() {
        periodicTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
    
    public func savePreferences() {
        defaults.set(pitchThreshold, forKey: "pitchThreshold")
        defaults.set(rollThreshold, forKey: "rollThreshold")
        defaults.set(gracePeriodSeconds, forKey: "gracePeriodSeconds")
        defaults.set(soundAlertsEnabled, forKey: "soundAlertsEnabled")
        defaults.set(alertSoundName, forKey: "alertSoundName")
        defaults.set(activeProfile.rawValue, forKey: "activeProfile")
        defaults.set(muteInMeetings, forKey: "muteInMeetings")
        defaults.set(autoDriftCorrection, forKey: "autoDriftCorrection")
        defaults.set(batterySaverMode, forKey: "batterySaverMode")
        defaults.set(isCalibrated, forKey: "isCalibrated")
    }
    
    public func loadPreferences() {
        if defaults.object(forKey: "pitchThreshold") != nil {
            pitchThreshold = defaults.double(forKey: "pitchThreshold")
        }
        if defaults.object(forKey: "rollThreshold") != nil {
            rollThreshold = defaults.double(forKey: "rollThreshold")
        }
        if defaults.object(forKey: "gracePeriodSeconds") != nil {
            gracePeriodSeconds = defaults.double(forKey: "gracePeriodSeconds")
        }
        if defaults.object(forKey: "soundAlertsEnabled") != nil {
            soundAlertsEnabled = defaults.bool(forKey: "soundAlertsEnabled")
        }
        if let sound = defaults.string(forKey: "alertSoundName") {
            alertSoundName = sound
        }
        if let profileStr = defaults.string(forKey: "activeProfile"), let profile = PostureProfile(rawValue: profileStr) {
            activeProfile = profile
        }
        if defaults.object(forKey: "muteInMeetings") != nil {
            muteInMeetings = defaults.bool(forKey: "muteInMeetings")
        }
        if defaults.object(forKey: "autoDriftCorrection") != nil {
            autoDriftCorrection = defaults.bool(forKey: "autoDriftCorrection")
        }
        if defaults.object(forKey: "batterySaverMode") != nil {
            batterySaverMode = defaults.bool(forKey: "batterySaverMode")
        }
        launchAtLogin = (SMAppService.mainApp.status == .enabled)
    }
    
    nonisolated public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isConnected = true
            self.startTracking()
            AirPodsInCaseLifecycleManager.shared.handleAirPodsRemovedFromCase()
        }
    }
    
    nonisolated public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isConnected = false
            self.postureState = .disconnected
            AirPodsInCaseLifecycleManager.shared.handleAirPodsPlacedInCase()
        }
    }
    
    isolated deinit {
        watchdogTimer?.invalidate()
        periodicTimer?.invalidate()
        motionManager.stopDeviceMotionUpdates()
        UDPBridgeReceiver.shared.stop()
    }
}
