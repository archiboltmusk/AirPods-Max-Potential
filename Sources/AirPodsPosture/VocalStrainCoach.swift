import Foundation
import SwiftUI
import CoreAudio

/// Vocal Tract Strain & Laryngeal Compression Coach.
/// When speaking on Zoom / Google Meet / FaceTime with a forward slouched neck,
/// the hyoid bone shifts and compresses the larynx, causing vocal fatigue, hoarseness, and shallow clavicular breathing.
/// Detects microphone activity and provides real-time laryngeal biofeedback.
@MainActor
public final class VocalStrainCoach: ObservableObject {
    public static let shared = VocalStrainCoach()
    
    @Published public var isEnabled: Bool = true
    @Published public var isMicActive: Bool = false
    @Published public var strainDetected: Bool = false
    @Published public var laryngealCompressionPercent: Int = 12 // 0% = open, 100% = severe vocal fold pinch
    @Published public var resonanceQuality: String = "Open Diaphragmatic"
    @Published public var strainEventsCount: Int = 0
    @Published public var statusMessage: String = "Optimal Laryngeal Speech Alignment"
    
    @Published public var glottalFryDetected: Bool = false
    @Published public var fundamentalFrequencyHz: Double = 132.0 // Speech F0
    @Published public var continuousSpeakingMinutes: Int = 0
    @Published public var vocalHydrationAlert: String? = nil
    
    private var micCheckTimer: Timer?
    private var strainStartTime: Date?
    private var continuousMicTimer: Timer?
    
    private init() {
        startMicPolling()
        startSpeakingDurationTracker()
    }
    
    private func startSpeakingDurationTracker() {
        continuousMicTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.isMicActive {
                    self.continuousSpeakingMinutes += 1
                    if self.continuousSpeakingMinutes >= 25 {
                        self.vocalHydrationAlert = "25+ Mins Speaking • Sip Warm Water to Lubricate Vocal Folds"
                    }
                } else {
                    self.continuousSpeakingMinutes = 0
                    self.vocalHydrationAlert = nil
                }
            }
        }
    }
    
    public func update(pitch: Double, roll: Double) {
        guard isEnabled && isMicActive else {
            strainDetected = false
            laryngealCompressionPercent = 0
            resonanceQuality = "Microphone Inactive"
            return
        }
        
        let forwardDev = max(0.0, -pitch) // Looking down / forward craned
        let compression = min(100.0, (forwardDev / 25.0) * 100.0)
        self.laryngealCompressionPercent = Int(compression)
        
        if forwardDev > 12.0 {
            self.resonanceQuality = "⚠️ Compressed Clavicular (Vocal Pinch)"
            if let start = strainStartTime {
                let duration = Date().timeIntervalSince(start)
                if duration > 3.5 && !strainDetected {
                    strainDetected = true
                    strainEventsCount += 1
                    statusMessage = "⚠️ Laryngeal Pinch: Retract chin back to unload vocal cords!"
                    NotificationManager.shared.sendCustomAlert(
                        title: "Vocal Strain Detected",
                        body: "Speaking with your neck slouched compresses your vocal tract. Tuck your chin back for effortless vocal projection!"
                    )
                    SyntheticEarHapticEngine.shared.playTapticClick()
                }
            } else {
                strainStartTime = Date()
            }
        } else {
            strainStartTime = nil
            strainDetected = false
            self.resonanceQuality = "Open Diaphragmatic Resonance"
            statusMessage = "Optimal Alignment for Vocal Projection"
        }
    }
    
    private func startMicPolling() {
        micCheckTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.checkDefaultInputDevice()
            }
        }
    }
    
    private func checkDefaultInputDevice() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &dataSize,
            &deviceID
        )
        
        guard status == noErr && deviceID != 0 else {
            isMicActive = false
            return
        }
        
        var isRunning: UInt32 = 0
        var isRunningSize = UInt32(MemoryLayout<UInt32>.size)
        var isRunningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let runStatus = AudioObjectGetPropertyData(
            deviceID,
            &isRunningAddress,
            0,
            nil,
            &isRunningSize,
            &isRunning
        )
        
        if runStatus == noErr {
            self.isMicActive = (isRunning != 0)
        }
    }
}
