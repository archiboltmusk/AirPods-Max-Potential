import Foundation
@preconcurrency import CoreMotion
import Combine
import AppKit
import ServiceManagement
import simd
import AirPodsCore

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
    @Published public var activeSensorLocationRaw: Int = 1
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
        
        motionManager.delegate = self
        loadPreferences()
        
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
        resetPostureReminder()
        postureState = .snoozed
        playFeedbackSound("Pop")
    }
    
    public func clearSnooze() {
        snoozeUntil = nil
        postureState = isTracking && isConnected ? .optimal : .disconnected
        playFeedbackSound("Pop")
    }
    
    public func startTracking() {
        if isSimulated {
            isTracking = true
        AppNapPowerAssertionManager.shared.acquireSleepTrackingAssertion()
            isConnected = true
            postureState = .optimal
            activeDataSource = "Simulation Demo"
            return
        }
        
        isTracking = true
        AppNapPowerAssertionManager.shared.acquireSleepTrackingAssertion()
        
        // 1. Direct CoreMotion setup (Delivered directly to OperationQueue.main to eliminate cross-actor SIGTRAP assertions)
        if motionManager.isDeviceMotionAvailable && !motionManager.isDeviceMotionActive {
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let self = self else { return }
                if let error = error {
                    self.lastErrorMessage = error.localizedDescription
                    return
                }
                guard let m = motion else { return }
                
                let q = m.attitude.quaternion
                let quat = simd_quatd(ix: q.x, iy: q.y, iz: q.z, r: q.w)
                let gyro = SIMD3<Double>(m.rotationRate.x, m.rotationRate.y, m.rotationRate.z)
                let accel = SIMD3<Double>(m.userAcceleration.x, m.userAcceleration.y, m.userAcceleration.z)
                let grav = SIMD3<Double>(m.gravity.x, m.gravity.y, m.gravity.z)
                let locRaw = m.sensorLocation.rawValue
                
                self.processIncomingSample(
                    quat: quat,
                    gyro: gyro,
                    accel: accel,
                    gravity: grav,
                    pps: 50,
                    source: "Direct CoreMotion",
                    sensorLocation: locRaw
                )
            }
        }
    }
    
    public func stopTracking() {
        if !isSimulated {
            motionManager.stopDeviceMotionUpdates()
        }
        isTracking = false
        resetPostureReminder()
        AppNapPowerAssertionManager.shared.releaseAssertion()
        postureState = .disconnected
    }
    
    @discardableResult
    public func calibrateCurrentPosture(force: Bool = false, isSilentAuto: Bool = false) -> Bool {
        // In-ear orientation requires gravity pulling downwards along Z (gravity.z <= -0.4)
        let currentGravity = (gravityX != 0 || gravityY != 0 || gravityZ != 0) ? SIMD3<Double>(gravityX, gravityY, gravityZ) : SIMD3<Double>(0, 0, -1.0)
        
        // Strict Slouch-Proof Interlock: Reject only if AirPods are demonstrably upside down
        if !force && currentGravity.z > -0.4 {
            isInterlockActive = true
            calibrationInterlockAlert = "⚠️ AirPods not in ear: please seat AirPods upright before calibrating."
            SyntheticEarHapticEngine.shared.playGentleDoubleTap()
            DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Calibration Blocked: Wear AirPods in Ear", autoDismissSeconds: 4.5)
            
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
        _ = TrueNorthCalibrationEngine.shared.calibrateInstant(quat: currentQuat, gravity: currentGravity)
        PermanentPostureEngine.shared.calibrateWithUprightGravity(
            currentGravity,
            sensorLocation: activeSensorLocationRaw
        )
        qBaseline = currentQuat
        isCalibrated = true
        deltaPitch = 0.0
        deltaRoll = 0.0
        deltaYaw = 0.0
        postureScore = 100
        postureState = isSnoozed ? .snoozed : .optimal
        resetPostureReminder()
        savePreferences()
        
        if isSilentAuto {
            SyntheticEarHapticEngine.shared.playSuccessChirp()
            DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "✨ Auto-Aligned: Posture Centered", autoDismissSeconds: 2.5)
        } else {
            playFeedbackSound("Hero")
            SyntheticEarHapticEngine.shared.playSuccessChirp()
            DynamicIslandNotchHaloManager.shared.triggerExpansion(message: "Calibrated: Locked to Upright Baseline", autoDismissSeconds: 3.0)
        }
        
        // Also calibrate Optical Webcam Sentinel to neutral upright baseline if active
        if OpticalContinuitySentinel.shared.isRunning {
            OpticalContinuitySentinel.shared.calibrateNeutralBaseline()
        }
        return true
    }
    
    public func toggleSimulation() {
        resetPostureReminder()
        isSimulated.toggle()
        if isSimulated {
            motionManager.stopDeviceMotionUpdates()
            isConnected = true
            isTracking = true
        AppNapPowerAssertionManager.shared.acquireSleepTrackingAssertion()
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
        source: String,
        sensorLocation: Int = 1
    ) {
        guard isTracking, !isSimulated else { return }
        guard AdaptiveSleepDutyCycle.shared.shouldProcessSampleInDutyCycle() else { return }
        
        let now = Date()
        if let lastPacketDate, now.timeIntervalSince(lastPacketDate) > 5.0 {
            resetPostureReminder()
            postureState = .disconnected
        }
        self.activeSensorLocationRaw = sensorLocation
        packetCount += 1
        lastPacketDate = now
        isConnected = true
        activeDataSource = source
        
        // Calculate rolling PPS
        ppsWindowTimestamps.append(now)
        ppsWindowTimestamps.removeAll { now.timeIntervalSince($0) > 1.0 }
        
        let rotDegX = gyro.x * 180.0 / .pi
        let rotDegY = gyro.y * 180.0 / .pi
        let rotDegZ = gyro.z * 180.0 / .pi
        let rotRateMag = sqrt(pow(rotDegX, 2) + pow(rotDegY, 2) + pow(rotDegZ, 2))
        let energy = sqrt(pow(accel.x, 2) + pow(accel.y, 2) + pow(accel.z, 2))
        
        // 1. Compute exact 3D relative kinematics at full 60Hz
        let qRel = QuaternionMath.relativeOrientation(baseline: qBaseline, current: quat)
        let relEuler = QuaternionMath.euler(from: qRel)
        
        // Update Euler angles at 30Hz or on meaningful angle change (>0.1°) to keep Mac CPU < 4%
        if packetCount % 2 == 0 || abs(relEuler.pitch - deltaPitch) > 0.10 {
            deltaPitch = relEuler.pitch
            deltaRoll = relEuler.roll
            deltaYaw = AutoZeroDriftCompensator.shared.compensatedYaw(relEuler.yaw)
        }
        
        // 2. Throttle auxiliary telemetry and secondary analyzers to 10Hz to keep Mac cool (CPU < 5%)
        let isThrottledTick = (packetCount % 6 == 0)
        if isThrottledTick {
            quatW = quat.real
            quatX = quat.imag.x
            quatY = quat.imag.y
            quatZ = quat.imag.z
            
            rawPitch = relEuler.pitch
            rawRoll = relEuler.roll
            rawYaw = relEuler.yaw
            
            userAccelX = accel.x
            userAccelY = accel.y
            userAccelZ = accel.z
            totalKineticEnergy = energy
            
            rotRateX = rotDegX
            rotRateY = rotDegY
            rotRateZ = rotDegZ
            
            if let g = gravity {
                gravityX = g.x
                gravityY = g.y
                gravityZ = g.z
            }
            
            packetsPerSecond = max(pps, ppsWindowTimestamps.count)
            
            // Touchless Teeth-Click Micro-Gesture Sentinel
            if totalKineticEnergy > TeethClickGestureEngine.shared.sensitivityLevel.threshold {
                TeethClickGestureEngine.shared.processAcousticImpulse(energy: totalKineticEnergy)
            }
            
            // AirPods Wear State & Collarbone Neck-Rest Sentinel
            AirPodsWearStateSentinel.shared.evaluateWearPose(
                pitch: deltaPitch,
                roll: deltaRoll,
                yaw: deltaYaw,
                kineticEnergy: energy,
                rotRateMagnitude: rotRateMag
            )
            
            // Continuous Center-Seeking EWMA Yaw Drift Compensation
            AutoZeroDriftCompensator.shared.updateDrift(
                currentYaw: relEuler.yaw,
                userKineticEnergy: energy,
                rotRate: rotRateMag
            )
            
            // Autonomous Continuous Gravitational Auto-Alignment
            AutonomousAutoCalibrator.shared.processIncomingSample(
                currentQuat: quat,
                gravity: gravity,
                gyroVariance: rotRateMag,
                userEnergy: energy,
                deltaPitch: deltaPitch,
                deltaRoll: deltaRoll
            )
            
            // "Glance & Lock" Autonomous Screen Alignment
            GlanceAndLockAutoCalibrator.shared.evaluate(
                currentQuat: quat,
                gravity: gravity,
                deltaPitch: deltaPitch,
                deltaRoll: deltaRoll,
                rotRate: rotRateMag,
                userEnergy: energy,
                isConnected: isConnected
            )
            
            // Also update PermanentPostureEngine in background for diagnostics
            if let g = gravity {
                _ = PermanentPostureEngine.shared.evaluate(
                    gravity: g,
                    rotRate: SIMD3<Double>(rotDegX * .pi / 180.0, rotDegY * .pi / 180.0, rotDegZ * .pi / 180.0),
                    userAccel: SIMD3<Double>(accel.x, accel.y, accel.z),
                    sensorLocation: sensorLocation
                )
            }
        }
        
        // Auto-calibrate on first incoming packet if within physiological upright zone
        if !isCalibrated {
            var canAutoZeroFirstPacket = false
            if let g = gravity, g.z <= -0.50 {
                let gravPitch = atan2(-g.y, -g.z) * 180.0 / .pi
                let gravRoll = -atan2(g.x, -g.z) * 180.0 / .pi
                if gravPitch >= -7.0 && gravPitch <= 7.5 && abs(gravRoll) <= 5.5 {
                    canAutoZeroFirstPacket = true
                }
            } else if relEuler.pitch >= -6.0 && relEuler.pitch <= 7.0 && abs(relEuler.roll) <= 5.5 {
                canAutoZeroFirstPacket = true
            }
            
            if canAutoZeroFirstPacket {
                _ = TrueNorthCalibrationEngine.shared.calibrateInstant(quat: quat, gravity: gravity)
                if let g = gravity {
                    PermanentPostureEngine.shared.calibrateWithUprightGravity(g, sensorLocation: sensorLocation)
                }
                qBaseline = quat
                isCalibrated = true
                deltaPitch = 0.0
                deltaRoll = 0.0
                deltaYaw = 0.0
                savePreferences()
            }
        }
        
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
    
    private func resetPostureReminder() {
        warningStartTime = nil
        warningProgress = 0
        uprightRecoveryStartTime = nil
        isRecoveringHysteresis = false
        TieredPostureEscalationEngine.shared.updateSlouchDuration(
            isCompromised: false, deltaPitch: 0, deltaRoll: 0
        )
    }

    private func evaluatePosture() {
        guard isTracking else { return }
        detectGestures(pitch: deltaPitch, yaw: deltaYaw)
        
        // 1. Calculate live posture score on every frame (reactive and smooth)
        let pitchDeviation = abs(deltaPitch)
        let rollDeviation = abs(deltaRoll)
        
        let pitchPenalty = min(pitchDeviation / pitchThreshold, 2.0) * 45.0
        let rollPenalty = min(rollDeviation / rollThreshold, 2.0) * 35.0
        let calculatedScore = max(0, min(100, Int(100.0 - (pitchPenalty + rollPenalty))))
        // Fast, responsive 4-sample EMA: drops visibly when slouching, rises when upright
        postureScore = (postureScore * 3 + calculatedScore) / 4
        
        // 2. Collarbone neck-rest / Snooze check
        if AirPodsWearStateSentinel.shared.isRestingOnNeck || isSnoozed {
            postureState = .snoozed
            resetPostureReminder()
        } else {
            let effectivePitchThreshold = pitchThreshold
            let isPitchBad = pitchDeviation > effectivePitchThreshold
            let isRollBad = rollDeviation > rollThreshold
            
            TieredPostureEscalationEngine.shared.updateSlouchDuration(
                isCompromised: isPitchBad || isRollBad,
                deltaPitch: deltaPitch,
                deltaRoll: deltaRoll,
                allowsAudio: canPlayPostureAudio
            )
            
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
                        if !TypingFlowStateGatingManager.shared.shouldSuppressAlertForFlow() {
                            slouchEventCount += 1
                            postureState = .slouching
                            triggerSlouchAlert()
                        }
                        DynamicIslandNotchHaloManager.shared.updatePosture(postureState: .slouching, deltaPitch: deltaPitch)
                    }
                    postureState = .slouching
                } else {
                    postureState = .warning
                }
            } else {
                warningStartTime = nil
                warningProgress = 0.0
                
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
        }
        
        // 3. Throttle secondary analytical engines to 10Hz (every 6th frame) to keep Mac CPU cool (< 5%)
        let isThrottledTick = (packetCount % 6 == 0)
        if isThrottledTick {
            ScreenGlowManager.shared.update(postureState: postureState)
            ProgressiveScreenBlurManager.shared.update(postureState: postureState, deltaPitch: deltaPitch)
            CervicalRepCounterEngine.shared.update(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw)
            HeadShortcutsActionRunner.shared.processMotion(pitch: deltaPitch, roll: deltaRoll, yaw: deltaYaw, userAccelY: userAccelY)
            DualDirectionPosturalEngine.shared.update(pitch: deltaPitch, dt: 0.1)
            HourlyFatigueProfiler.shared.recordMonitoredSecond(dt: 0.1)
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
            MenuBarSparklineRenderer.shared.addSample(score: postureScore)
            CervicalSpineTorqueEngine.shared.updateLivePitch(deltaPitch)
            GhostDimmingBiofeedbackManager.shared.updatePostureState(
                isSlouching: postureState == .slouching,
                warningProgress: warningProgress
            )
            SpatialElevationSoundstageEngine.shared.updateCervicalElevation(pitch: deltaPitch)
            StemForceGestureInterceptor.shared.processKinematicStream(pitch: deltaPitch, rotRateY: rotRateY)
            
            AnteriorZUPTKinematicEngine.shared.processSample(
                pitch: deltaPitch,
                roll: deltaRoll,
                userAccel: SIMD3<Double>(userAccelX, userAccelY, userAccelZ),
                rotRate: SIMD3<Double>(rotRateX, rotRateY, rotRateZ)
            )
            
            AirPodsInsertionFitSentinel.shared.validateInsertionSanity(
                pitchDeg: deltaPitch,
                rollDeg: deltaRoll,
                rotRate: SIMD3<Double>(rotRateX * .pi / 180.0, rotRateY * .pi / 180.0, rotRateZ * .pi / 180.0),
                userAccel: SIMD3<Double>(userAccelX, userAccelY, userAccelZ)
            )
            
            let liveGravity = SIMD3<Double>(gravityX, gravityY, gravityZ)
            PostureFitGatekeeper.shared.evaluateDirect(
                gravity: liveGravity,
                rotRate: SIMD3<Double>(rotRateX * .pi / 180.0, rotRateY * .pi / 180.0, rotRateZ * .pi / 180.0),
                userAccel: SIMD3<Double>(userAccelX, userAccelY, userAccelZ),
                timestamp: Date().timeIntervalSince1970,
                sensorLocationRaw: 1
            )
        }
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
    
    private var canPlayPostureAudio: Bool {
        soundAlertsEnabled
            && !CallActivitySentinel.shared.shouldSuppressAudioCue()
            && !(muteInMeetings && AudioEnvironmentMonitor.shared.isMicrophoneInUse)
    }

    public func triggerSlouchAlert() {
        guard isTracking, isConnected, !isSnoozed,
              !AirPodsWearStateSentinel.shared.isRestingOnNeck,
              postureState == .slouching else { return }
        guard isSimulated || lastPacketDate.map({ Date().timeIntervalSince($0) <= 5 }) == true else { return }
        NotificationManager.shared.sendSlouchNotification(pitch: deltaPitch, roll: deltaRoll)
        HourlyFatigueProfiler.shared.recordAlert()

        guard canPlayPostureAudio else {
            SyntheticEarHapticEngine.shared.performTrackpadHaptic()
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
        if CallActivitySentinel.shared.shouldSuppressAudioCue() {
            SyntheticEarHapticEngine.shared.performTrackpadHaptic(pattern: .alignment)
            return
        }
        if let sound = NSSound(named: NSSound.Name(name)) {
            sound.play()
        } else {
            NSSound.beep()
        }
    }
    
    private func startWatchdog() {
        let timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                guard !self.isSimulated, self.isTracking else { return }
                
                // If no packets in 5 seconds while tracking, attempt non-blocking CoreMotion recovery
                if let last = self.lastPacketDate, Date().timeIntervalSince(last) > 5.0 {
                    self.packetsPerSecond = 0
                    if self.isConnected {
                        self.isConnected = false
                        self.postureState = .disconnected
                        self.resetPostureReminder()
                    }
                    if self.motionManager.isDeviceMotionAvailable && !self.motionManager.isDeviceMotionActive {
                        self.startTracking()
                    }
                }
            }
        }
        timer.tolerance = 1.0
        watchdogTimer = timer
    }
    
    private func startPeriodicTimer() {
        let timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
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
        timer.tolerance = 0.5
        periodicTimer = timer
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
        defaults.set([qBaseline.real, qBaseline.imag.x, qBaseline.imag.y, qBaseline.imag.z], forKey: "calibratedBaselineQuat")
    }
    
    public func loadPreferences() {
        if let quatArr = defaults.array(forKey: "calibratedBaselineQuat") as? [Double], quatArr.count == 4 {
            qBaseline = simd_quatd(ix: quatArr[1], iy: quatArr[2], iz: quatArr[3], r: quatArr[0])
            isCalibrated = true
        }
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
            if self.isTracking { self.startTracking() }
            AirPodsInsertionFitSentinel.shared.headphoneMotionManagerDidConnect(manager)
            PostureFitGatekeeper.shared.headphoneMotionManagerDidConnect(manager)
            AirPodsInCaseLifecycleManager.shared.handleAirPodsRemovedFromCase()
            AirPodsBatteryOptimizerEngine.shared.refreshHardwareBattery()
        }
    }
    
    nonisolated public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isConnected = false
            self.resetPostureReminder()
            self.postureState = .disconnected
            AirPodsInsertionFitSentinel.shared.headphoneMotionManagerDidDisconnect(manager)
            PostureFitGatekeeper.shared.headphoneMotionManagerDidDisconnect(manager)
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
