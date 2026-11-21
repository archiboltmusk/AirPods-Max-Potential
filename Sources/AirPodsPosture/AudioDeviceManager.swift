import Foundation
import CoreAudio

@MainActor
public final class AudioDeviceManager: ObservableObject {
    public static let shared = AudioDeviceManager()
    
    @Published public var currentOutputDeviceName: String = "Detecting..."
    @Published public var isAirPodsActiveOutput: Bool = false
    @Published public var availableDevices: [(id: AudioDeviceID, name: String)] = []
    
    private var timer: Timer? = nil
    
    private init() {
        refreshDevices()
        startMonitoring()
    }
    
    public func startMonitoring() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDevices()
            }
        }
    }
    
    public func refreshDevices() {
        // Query Default Output Device
        var defaultOutputDeviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &size,
            &defaultOutputDeviceID
        )
        
        if status == noErr && defaultOutputDeviceID != 0 {
            var nameCF: CFString = "" as CFString
            var nameSize = UInt32(MemoryLayout<CFString>.size)
            var nameAddr = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyDeviceNameCFString,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            
            withUnsafeMutablePointer(to: &nameCF) { ptr in
                _ = AudioObjectGetPropertyData(defaultOutputDeviceID, &nameAddr, 0, nil, &nameSize, ptr)
            }
            
            let name = nameCF as String
            self.currentOutputDeviceName = name
            let lower = name.lowercased()
            self.isAirPodsActiveOutput = lower.contains("airpod") || lower.contains("beats") || lower.contains("headphone")
        }
    }
}
