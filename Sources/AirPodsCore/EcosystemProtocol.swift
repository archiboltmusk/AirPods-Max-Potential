import Foundation

/// Unified Cross-Device Ecosystem Protocols & Packets for AirPodsIQ.
/// Powers seamless real-time synchronization between Mac, iPhone, iPad, and Apple Watch.

public enum DeviceEcosystemRole: String, Codable, Sendable {
    case macHub = "Mac Studio Hub"
    case iphoneCompanion = "iPhone Ambient HUD"
    case ipadCompanion = "iPad Drafting Studio"
    case appleWatchSentinel = "Apple Watch Haptic Sentinel"
}

public enum CrossDevicePostureState: String, Codable, Sendable {
    case optimal = "Optimal Alignment"
    case warning = "Slight Flexion"
    case slouching = "Slouch Detected"
    case snoozed = "Snoozed"
    case calibrating = "Calibrating"
    case sleeping = "Sleep Lab Active"
}

public struct PostureTelemetryPacket: Codable, Sendable {
    public let pitch: Double
    public let roll: Double
    public let yaw: Double
    public let postureScore: Int
    public let state: CrossDevicePostureState
    public let isSlouching: Bool
    public let timestamp: Date
    public let sourceDevice: DeviceEcosystemRole
    
    public init(
        pitch: Double,
        roll: Double,
        yaw: Double,
        postureScore: Int,
        state: CrossDevicePostureState,
        isSlouching: Bool,
        timestamp: Date = Date(),
        sourceDevice: DeviceEcosystemRole
    ) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.postureScore = postureScore
        self.state = state
        self.isSlouching = isSlouching
        self.timestamp = timestamp
        self.sourceDevice = sourceDevice
    }
}

public struct HapticCommandPacket: Codable, Sendable {
    public enum HapticStyle: String, Codable, Sendable {
        case gentleTap = "directionUp"
        case criticalWarning = "retry"
        case successRestored = "success"
        case doubleTap = "click"
    }
    
    public let command: String
    public let style: HapticStyle
    public let timestamp: Date
    
    public init(command: String = "trigger_haptic", style: HapticStyle = .gentleTap, timestamp: Date = Date()) {
        self.command = command
        self.style = style
        self.timestamp = timestamp
    }
}

public struct SleepTriangulationPacket: Codable, Sendable {
    public let leftSideMinutes: Double
    public let rightSideMinutes: Double
    public let supineMinutes: Double
    public let proneMinutes: Double
    public let asymmetryRiskPercent: Int
    public let heartRateBPM: Double
    public let sleepStage: String
    public let timestamp: Date
    
    public init(
        leftSideMinutes: Double,
        rightSideMinutes: Double,
        supineMinutes: Double,
        proneMinutes: Double,
        asymmetryRiskPercent: Int,
        heartRateBPM: Double,
        sleepStage: String,
        timestamp: Date = Date()
    ) {
        self.leftSideMinutes = leftSideMinutes
        self.rightSideMinutes = rightSideMinutes
        self.supineMinutes = supineMinutes
        self.proneMinutes = proneMinutes
        self.asymmetryRiskPercent = asymmetryRiskPercent
        self.heartRateBPM = heartRateBPM
        self.sleepStage = sleepStage
        self.timestamp = timestamp
    }
}

public struct TrueDepthScreenDistancePacket: Codable, Sendable {
    public let distanceCentimeters: Double
    public let isTooClose: Bool
    public let shoulderImbalanceDegrees: Double
    public let timestamp: Date
    
    public init(
        distanceCentimeters: Double,
        isTooClose: Bool,
        shoulderImbalanceDegrees: Double,
        timestamp: Date = Date()
    ) {
        self.distanceCentimeters = distanceCentimeters
        self.isTooClose = isTooClose
        self.shoulderImbalanceDegrees = shoulderImbalanceDegrees
        self.timestamp = timestamp
    }
}
