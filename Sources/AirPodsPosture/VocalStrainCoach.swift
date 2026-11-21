import Foundation
import SwiftUI
import CoreAudio

@MainActor
public final class VocalStrainCoach: ObservableObject {
    public static let shared = VocalStrainCoach()
    
    @Published public var isEnabled: Bool = true
    @Published public var isMicActive: Bool = false
    @Published public var strainDetected: Bool = false
    @Published public var strainEventsCount: Int = 0
    @Published public var statusMessage: String = "Normal Laryngeal Posture"
    
    private var micCheckTimer: Timer?
    private var strainStartTime: Date?
    
    private init() {
        startMicPolling()
    }
    
    public func update(pitch: Double, roll: Double) {
        guard isEnabled && isMicActive else {
            strainDetected = false
            return
        }
        
        // Forward head posture (forward pitch < -12 degrees) compresses cervical spine and tenses strap muscles of larynx
        let isForwardHead = pitch < -12.0
        
        if isForwardHead {
            if let start = strainStartTime {
                let duration = Date().timeIntervalSince(start)
                if duration > 4.0 && !strainDetected {
                    strainDetected = true
                    strainEventsCount += 1
                    statusMessage = "⚠️ Forward Head Vocal Strain: Retract chin to unload vocal cords!"
                    NotificationManager.shared.sendCustomAlert(
                        title: "Vocal Strain Detected",
                        body: "Speaking with your neck tilted forward puts excessive pressure on your vocal cords. Tuck your chin back!"
                    )
                }
            } else {
                strainStartTime = Date()
            }
        } else {
            strainStartTime = nil
            strainDetected = false
            statusMessage = "Good Alignment for Diaphragmatic Speech"
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
        } else {
            self.isMicActive = false
        }
    }
}
