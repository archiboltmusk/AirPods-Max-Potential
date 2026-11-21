import Foundation
import CoreAudio

/// Zero-latency event-driven CoreAudio hardware output device monitor.
/// Inspired by chandansgowda/posture-fix: detects Bluetooth & AirPods connection state
/// immediately via CoreAudio property listener blocks without polling.
@MainActor
public final class CoreAudioDeviceMonitor: ObservableObject {
    public static let shared = CoreAudioDeviceMonitor()

    @Published public private(set) var isHeadphonesConnected: Bool = false
    @Published public private(set) var deviceName: String = "Detecting..."
    @Published public private(set) var isAirPodsOrBeats: Bool = false

    private init() {
        refresh()
        registerHardwareListener()
    }

    public func refresh() {
        guard let device = defaultOutputDeviceID() else {
            isHeadphonesConnected = false
            deviceName = "No Output Device"
            isAirPodsOrBeats = false
            return
        }

        let name = deviceName(for: device)
        let transport = deviceTransportType(for: device)
        let lower = name.lowercased()

        self.deviceName = name
        self.isAirPodsOrBeats = lower.contains("airpod") || lower.contains("beats")
        self.isHeadphonesConnected = self.isAirPodsOrBeats ||
            lower.contains("headphone") ||
            transport == kAudioDeviceTransportTypeBluetooth ||
            transport == kAudioDeviceTransportTypeBluetoothLE
    }

    private func defaultOutputDeviceID() -> AudioDeviceID? {
        var deviceID = AudioDeviceID(0)
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
            &deviceID
        )
        return (status == noErr && deviceID != 0) ? deviceID : nil
    }

    private func deviceName(for deviceID: AudioDeviceID) -> String {
        var cfName: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &cfName)
        guard status == noErr, let cfName = cfName else { return "Unknown Audio Device" }
        return cfName.takeRetainedValue() as String
    }

    private func deviceTransportType(for deviceID: AudioDeviceID) -> UInt32 {
        var transport = UInt32(0)
        var size = UInt32(MemoryLayout<UInt32>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        _ = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &transport)
        return transport
    }

    private func registerHardwareListener() {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            DispatchQueue.main
        ) { [weak self] _, _ in
            self?.refresh()
        }
    }
}
