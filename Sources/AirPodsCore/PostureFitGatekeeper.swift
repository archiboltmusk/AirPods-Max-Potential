import Foundation
import CoreMotion
import simd
import Combine
#if os(iOS)
import AVFoundation
#elseif os(macOS)
import CoreAudio
#endif

/// Tri-State Posture Tracking Lifecycle.
/// Encapsulates the 3 independent validation gates before evaluating posture telemetry.
public enum PostureTrackingState: Equatable, Sendable {
    case ready
    case airPodsNotInEar
    case motionStreamDisconnected
    case crookedInsertion(rollErrorDeg: Double, pitchErrorDeg: Double)
    case needsInitialCalibration
    
    public var statusTitle: String {
        switch self {
        case .ready:
            return "Active • In-Ear & Aligned"
        case .airPodsNotInEar:
            return "AirPods Out of Ear (Desk/Pocket)"
        case .motionStreamDisconnected:
            return "Motion Stream Disconnected"
        case .crookedInsertion:
            return "⚠️ Crooked Earbud Insertion"
        case .needsInitialCalibration:
            return "Needs Initial Ear Profile"
        }
    }
    
    public var isTrackingValid: Bool {
        return self == .ready
    }
}

/// PostureFitGatekeeper: 3-Tier Multi-Gate Posture Validation Engine.
/// Prevents false slouch alerts when AirPods are sitting on a desk, in a pocket,
/// or twisted at a crooked angle in the ear canal.
///
/// Combines:
/// 1. Audio Route & Ear-Detection Gate (AVAudioSession / CoreAudio)
/// 2. Motion Stream & Freshness Gate (CMHeadphoneMotionManagerDelegate + Heartbeat)
/// 3. Anatomical Insertion-Angle Gate (simd skull projection + isStationary guard)
@MainActor
public final class PostureFitGatekeeper: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {
    public static let shared = PostureFitGatekeeper()
    
    private let motionManager = CMHeadphoneMotionManager()
    
    // Saved permanent ear-fit profiles keyed by CMDeviceMotion.SensorLocation.rawValue
    @Published public var profiles: [Int: AnatomicalEarProfile] = [:]
    
    // Gate states
    @Published public private(set) var isAudioRoutedToHeadphones: Bool = false
    @Published public private(set) var isMotionConnected: Bool = false
    @Published public private(set) var lastMotionTimestamp: TimeInterval = 0
    
    // Anatomical plausibility thresholds (beyond these, the earbud is twisted or lying down)
    public let maxPlausibleRestingRollDeg: Double = 35.0
    public let maxPlausibleRestingPitchDeg: Double = 55.0
    
    // Public telemetry
    @Published public var state: PostureTrackingState = .airPodsNotInEar
    @Published public var validatedPitchDeg: Double = 0.0
    @Published public var validatedRollDeg: Double = 0.0
    @Published public var isSlouching: Bool = false
    
    public init(savedProfiles: [Int: AnatomicalEarProfile] = [:]) {
        self.profiles = savedProfiles.isEmpty ? PermanentPostureEngine.shared.profiles : savedProfiles
        super.init()
        
        motionManager.delegate = self
        
        configureAudioSessionObserver()
        refreshAudioRouteStatus()
    }
    
    public func start() {
        guard motionManager.isDeviceMotionAvailable else { return }
        
        #if os(iOS)
        if #available(iOS 14.0, *) {
            // Note: startConnectionStatusUpdates() if supported on target iOS
        }
        #endif
        
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self, let motion, error == nil else { return }
            self.evaluateFrame(motion)
        }
    }
    
    public func stop() {
        motionManager.stopDeviceMotionUpdates()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Gate 1: Audio Route & Ear-Detection Gate
    
    private func configureAudioSessionObserver() {
        #if os(iOS)
        let session = AVAudioSession.sharedInstance()
        // Use .ambient + .mixWithOthers so we observe routing without interrupting background music/podcasts
        try? session.setCategory(.ambient, options: [.mixWithOthers, .allowBluetoothA2DP, .allowBluetoothHFP])
        try? session.setActive(true)
        
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: session,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAudioRouteStatus()
            }
        }
        #elseif os(macOS)
        // On macOS, poll / refresh audio output routing
        refreshAudioRouteStatus()
        #endif
    }
    
    public func refreshAudioRouteStatus() {
        #if os(iOS)
        let outputs = AVAudioSession.sharedInstance().currentRoute.outputs
        let hasHeadphoneRoute = outputs.contains { output in
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE ||
            output.portName.localizedCaseInsensitiveContains("AirPods")
        }
        
        self.isAudioRoutedToHeadphones = hasHeadphoneRoute
        if !hasHeadphoneRoute {
            updateState(.airPodsNotInEar, slouching: false)
        }
        #elseif os(macOS)
        if let outputDeviceName = getDefaultAudioOutputDeviceName() {
            let isAirPods = outputDeviceName.localizedCaseInsensitiveContains("AirPods") ||
                            outputDeviceName.localizedCaseInsensitiveContains("Headphones") ||
                            outputDeviceName.localizedCaseInsensitiveContains("Bluetooth")
            self.isAudioRoutedToHeadphones = isAirPods
        } else {
            self.isAudioRoutedToHeadphones = true // fallback on Mac when device name is virtual
        }
        if !isAudioRoutedToHeadphones {
            updateState(.airPodsNotInEar, slouching: false)
        }
        #endif
    }
    
    #if os(macOS)
    private func getDefaultAudioOutputDeviceName() -> String? {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )
        
        guard status == noErr else { return nil }
        
        var name: Unmanaged<CFString>?
        var nameSize = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var nameAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let nameStatus = AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &nameAddress,
            0,
            nil,
            &nameSize,
            &name
        )
        
        if nameStatus == noErr, let unmanaged = name {
            return unmanaged.takeRetainedValue() as String
        }
        return nil
    }
    #endif
    
    // MARK: - Gate 2: CMHeadphoneMotionManagerDelegate Connection Lifecycle
    
    nonisolated public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isMotionConnected = true
            self.refreshAudioRouteStatus()
        }
    }
    
    nonisolated public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isMotionConnected = false
            self.updateState(.motionStreamDisconnected, slouching: false)
        }
    }
    
    // MARK: - Gate 3: Frame-Level Fit & Crooked-Insertion Sanity Check
    
    public func evaluateFrame(_ motion: CMDeviceMotion) {
        let rotRate = SIMD3<Double>(motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
        let userAccel = SIMD3<Double>(motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
        let gravity = SIMD3<Double>(motion.gravity.x, motion.gravity.y, motion.gravity.z)
        
        evaluateDirect(
            gravity: gravity,
            rotRate: rotRate,
            userAccel: userAccel,
            timestamp: motion.timestamp,
            sensorLocationRaw: motion.sensorLocation.rawValue
        )
    }
    
    /// Pure programmatic evaluation entry point for any incoming kinematics packet
    public func evaluateDirect(
        gravity: SIMD3<Double>,
        rotRate: SIMD3<Double>,
        userAccel: SIMD3<Double>,
        timestamp: TimeInterval,
        sensorLocationRaw: Int
    ) {
        // 1. Enforce Audio Route & Motion Connection Gates
        guard isAudioRoutedToHeadphones else {
            updateState(.airPodsNotInEar, slouching: false)
            return
        }
        
        // Freshness heartbeat: allow grace if timestamp is progressing normally (< 1.5s interval)
        if lastMotionTimestamp > 0 && (timestamp - lastMotionTimestamp > 2.0) {
            updateState(.motionStreamDisconnected, slouching: false)
            lastMotionTimestamp = timestamp
            return
        }
        lastMotionTimestamp = timestamp
        
        // 2. Load permanent anatomical profile for active earbud (.headphoneLeft / .headphoneRight)
        if profiles.isEmpty {
            profiles = PermanentPostureEngine.shared.profiles
        }
        
        let locKey = (sensorLocationRaw == 1 || sensorLocationRaw == 2) ? sensorLocationRaw : (profiles[1] != nil ? 1 : 0)
        guard let profile = profiles[locKey] ?? profiles[0] else {
            updateState(.needsInitialCalibration, slouching: false)
            return
        }
        
        // 3. Project live gravity into the saved anatomical skull basis
        let gDown = simd_dot(-gravity, profile.up)
        let gForward = simd_dot(gravity, profile.forward)
        let gRight = simd_dot(gravity, profile.right)
        
        let pitchDeg = atan2(-gForward, gDown) * 180.0 / .pi
        let rollDeg = atan2(gRight, gDown) * 180.0 / .pi
        
        // 4. Check if user is stationary before testing insertion geometry
        let rotSpeed = simd_length(rotRate)
        let linAccel = simd_length(userAccel)
        let isStationary = rotSpeed < 0.08 && linAccel < 0.03
        
        // 5. Crooked Insertion Gate: If stationary at an implausible head tilt, earbud is twisted or off-ear
        if isStationary && (abs(rollDeg) > maxPlausibleRestingRollDeg || abs(pitchDeg) > maxPlausibleRestingPitchDeg) {
            updateState(.crookedInsertion(rollErrorDeg: rollDeg, pitchErrorDeg: pitchDeg), slouching: false)
            return
        }
        
        // 6. All gates passed -> Safe to evaluate posture
        let slouchDetected = pitchDeg < -15.0 || abs(rollDeg) > 12.0
        self.state = .ready
        self.validatedPitchDeg = pitchDeg
        self.validatedRollDeg = rollDeg
        self.isSlouching = slouchDetected
    }
    
    public func updateState(_ newState: PostureTrackingState, slouching: Bool) {
        self.state = newState
        self.isSlouching = slouching
    }
    
    /// Convenience helper to manually force audio route connected (e.g. in test suites or desktop simulation)
    public func setAudioRoutedForTesting(_ routed: Bool) {
        self.isAudioRoutedToHeadphones = routed
        if !routed {
            updateState(.airPodsNotInEar, slouching: false)
        }
    }
}
