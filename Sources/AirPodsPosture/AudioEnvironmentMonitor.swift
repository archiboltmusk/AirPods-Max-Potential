import Foundation
import CoreAudio

@MainActor
public final class AudioEnvironmentMonitor: ObservableObject {
    public static let shared = AudioEnvironmentMonitor()
    
    @Published public var isMicrophoneInUse: Bool = false
    @Published public var meetingAppDetected: Bool = false
    
    private var timer: Timer? = nil
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        checkMicUsage()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkMicUsage()
            }
        }
    }
    
    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    public func checkMicUsage() {
        var inputDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &inputDeviceID
        )
        
        guard status == noErr, inputDeviceID != 0 else {
            isMicrophoneInUse = false
            return
        }
        
        var isRunning: UInt32 = 0
        size = UInt32(MemoryLayout<UInt32>.size)
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let runStatus = AudioObjectGetPropertyData(
            inputDeviceID,
            &address,
            0,
            nil,
            &size,
            &isRunning
        )
        
        let inUse = (runStatus == noErr && isRunning != 0)
        if self.isMicrophoneInUse != inUse {
            self.isMicrophoneInUse = inUse
            self.meetingAppDetected = inUse
        }
    }
    
    public func toggleMute() {
        var inputDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &inputDeviceID
        )
        guard status == noErr && inputDeviceID != 0 else { return }
        
        var muteAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeInput,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var isMuted: UInt32 = 0
        var muteSize = UInt32(MemoryLayout<UInt32>.size)
        
        if AudioObjectGetPropertyData(inputDeviceID, &muteAddress, 0, nil, &muteSize, &isMuted) == noErr {
            var newMute: UInt32 = (isMuted == 0) ? 1 : 0
            AudioObjectSetPropertyData(inputDeviceID, &muteAddress, 0, nil, muteSize, &newMute)
        }
    }
}
