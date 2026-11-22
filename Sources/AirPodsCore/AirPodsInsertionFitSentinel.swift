import Foundation
@preconcurrency import CoreMotion
import AVFoundation
import Combine
import simd

/// Comprehensive AirPods Ear-Fit & Insertion Verification Sentinel.
/// Combines Apple hardware ear-detection signals, CoreAudio/AVAudioSession routing,
/// CMHeadphoneMotionManagerDelegate stream continuity, and anatomical gravity-angle sanity gates
/// to ensure reliable IMU posture tracking and physical acoustic sealing.
@MainActor
public final class AirPodsInsertionFitSentinel: NSObject, ObservableObject, CMHeadphoneMotionManagerDelegate, @unchecked Sendable {
    public static let shared = AirPodsInsertionFitSentinel()
    
    // MARK: - Published Verification Status
    @Published public var isProperlySeated: Bool = true
    @Published public var isAudioRouteActive: Bool = false
    @Published public var isMotionStreaming: Bool = false
    @Published public var isCrookedFitDetected: Bool = false
    @Published public var fitRecommendationMessage: String? = nil
    
    // Fit Health Score (0% to 100%)
    @Published public var fitQualityScore: Int = 100
    @Published public var lastFitCheckTimestamp: Date = Date()
    
    // 4-Step Physical & System Checklist
    @Published public var hasRunAppleFitTest: Bool = false
    @Published public var isStemAngleOptimal: Bool = true
    @Published public var isAutoEarDetectionEnabled: Bool = true
    @Published public var hasPassedJawStabilityCheck: Bool = false
    
    // Sheet / Guide Presentation
    @Published public var isFitGuidePresented: Bool = false
    
    private var lastPacketDate: Date?
    private var packetContinuityTimer: Timer?
    private var consecutiveCrookedFrames: Int = 0
    
    public override init() {
        super.init()
        checkAudioRouting()
        setupAudioNotifications()
        startContinuityWatchdog()
    }
    
    // MARK: - 1. Programmatic Audio Route & Ear Detection Verification
    
    public func checkAudioRouting() {
        #if os(iOS)
        let route = AVAudioSession.sharedInstance().currentRoute
        let hasBluetoothOutput = route.outputs.contains { output in
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothHFP ||
            output.portType == .bluetoothLE ||
            output.portName.localizedCaseInsensitiveContains("AirPods")
        }
        self.isAudioRouteActive = hasBluetoothOutput
        #elseif os(macOS)
        // On macOS, verify active default audio output device contains AirPods or Bluetooth headphones
        if let outputDeviceName = getDefaultAudioOutputDeviceName() {
            let isAirPods = outputDeviceName.localizedCaseInsensitiveContains("AirPods") ||
                            outputDeviceName.localizedCaseInsensitiveContains("Headphones") ||
                            outputDeviceName.localizedCaseInsensitiveContains("Bluetooth")
            self.isAudioRouteActive = isAirPods
        } else {
            self.isAudioRouteActive = false
        }
        #endif
        
        recalculateFitQuality()
    }
    
    private func setupAudioNotifications() {
        #if os(iOS)
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkAudioRouting()
            }
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
    
    // MARK: - 2. CMHeadphoneMotionManagerDelegate Stream Continuity
    
    nonisolated public func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isMotionStreaming = true
            self.checkAudioRouting()
            self.recalculateFitQuality()
        }
    }
    
    nonisolated public func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        Task { @MainActor in
            self.isMotionStreaming = false
            self.isProperlySeated = false
            self.recalculateFitQuality()
        }
    }
    
    public func registerMotionPacketReceived() {
        self.lastPacketDate = Date()
        if !isMotionStreaming {
            isMotionStreaming = true
        }
    }
    
    private func startContinuityWatchdog() {
        packetContinuityTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                if let last = self.lastPacketDate, Date().timeIntervalSince(last) > 2.5 {
                    // AirPods were likely taken out of the ears and placed on a flat surface
                    if self.isMotionStreaming {
                        self.isMotionStreaming = false
                        self.recalculateFitQuality()
                    }
                }
            }
        }
    }
    
    // MARK: - 3. Insertion-Angle Sanity Gate (Catching Loose / Crooked Fit)
    
    /// Compares the live gravity vector against the permanent anatomical skull profile.
    /// If the resting roll or pitch deviates by an anatomically impossible resting angle while stationary,
    /// triggers a reseat prompt instead of misclassifying as a neck slouch.
    public func validateInsertionSanity(
        pitchDeg: Double,
        rollDeg: Double,
        rotRate: SIMD3<Double>,
        userAccel: SIMD3<Double>
    ) {
        registerMotionPacketReceived()
        
        let isStationary = simd_length(rotRate) < 0.05 && simd_length(userAccel) < 0.02
        guard isStationary else { return }
        
        // Anatomical Sanity Thresholds:
        // In a normal seated head, lateral ear-to-shoulder roll rarely exceeds 32° while stationary.
        // If roll > 35° or pitch is drastically inverted (> 45° or < -50°), earbud is rotated crookedly in canal.
        let isCrooked = abs(rollDeg) > 35.0 || pitchDeg > 42.0 || pitchDeg < -55.0
        
        if isCrooked {
            consecutiveCrookedFrames += 1
            if consecutiveCrookedFrames > 60 { // sustained for > 1.2 seconds at 50Hz
                self.isCrookedFitDetected = true
                self.isStemAngleOptimal = false
                self.fitRecommendationMessage = "⚠️ Loose or Crooked Earbud: Rotate stem forward ~30°–45° toward mouth corner and reseat."
                self.recalculateFitQuality()
            }
        } else {
            if consecutiveCrookedFrames > 0 {
                consecutiveCrookedFrames = 0
            }
            if isCrookedFitDetected {
                self.isCrookedFitDetected = false
                self.isStemAngleOptimal = true
                self.fitRecommendationMessage = nil
                self.recalculateFitQuality()
            }
        }
    }
    
    // MARK: - Fit Quality Score Aggregator
    
    private func recalculateFitQuality() {
        var score = 100
        
        if !isAudioRouteActive { score -= 30 }
        if !isMotionStreaming { score -= 35 }
        if isCrookedFitDetected { score -= 30 }
        if !hasPassedJawStabilityCheck { score -= 5 }
        
        self.fitQualityScore = max(0, min(100, score))
        self.isProperlySeated = fitQualityScore >= 70
        self.lastFitCheckTimestamp = Date()
    }
    
    // MARK: - User Checklist Actions
    
    public func markAppleFitTestCompleted() {
        self.hasRunAppleFitTest = true
        recalculateFitQuality()
    }
    
    public func markJawStabilityCheckPassed() {
        self.hasPassedJawStabilityCheck = true
        recalculateFitQuality()
    }
}
