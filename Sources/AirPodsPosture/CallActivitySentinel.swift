import Foundation
import CoreAudio
import AppKit
import Combine

/// Call Activity & Meeting Sentinel.
/// Prevents posture nudges and chimes from interrupting Zoom, Google Meet, Teams, FaceTime, or Slack calls.
/// Monitors CoreAudio default microphone stream activity (kAudioDevicePropertyDeviceIsRunningSomewhere)
/// and known conferencing process signatures.
@MainActor
public final class CallActivitySentinel: ObservableObject {
    public static let shared = CallActivitySentinel()
    
    @Published public var isInCall: Bool = false
    @Published public var activeCallApp: String? = nil
    @Published public var isCallMuteEnabled: Bool = true
    @Published public var suppressedAlertsCount: Int = 0
    @Published public var statusMessage: String = "Monitoring microphone for active calls"
    
    private var pollTimer: Timer?
    private let knownVoIPApps: [String: String] = [
        "us.zoom.xos": "Zoom",
        "com.microsoft.teams2": "Microsoft Teams",
        "com.microsoft.teams": "Microsoft Teams",
        "com.tinyspeck.slackmacgap": "Slack Call",
        "com.apple.FaceTime": "FaceTime",
        "com.cisco.webexmeetingsapp": "Webex",
        "com.skype.skype": "Skype",
        "com.discord": "Discord"
    ]
    
    private init() {
        startMonitoring()
    }
    
    public func startMonitoring() {
        pollTimer?.invalidate()
        // Poll every 1.5 seconds for active microphone input streams
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateCallState()
            }
        }
        evaluateCallState()
    }
    
    public func stopMonitoring() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
    
    public func evaluateCallState() {
        let micActive = isDefaultMicStreaming()
        let activeApp = detectActiveVoIPApp()
        
        let callActive = micActive || (activeApp != nil)
        
        if callActive != isInCall {
            isInCall = callActive
            activeCallApp = activeApp ?? (micActive ? "Active Microphone" : nil)
            
            if isInCall {
                statusMessage = "📞 In Call (\(activeCallApp ?? "Meeting")) • Audio Posture Nudges Suppressed"
            } else {
                statusMessage = "No Active Calls • Full Spatial Audio Enabled"
            }
        }
    }
    
    /// Queries CoreAudio to check if the default input device is currently running
    private func isDefaultMicStreaming() -> Bool {
        var defaultInputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultInputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0,
            nil,
            &propertySize,
            &defaultInputDeviceID
        )
        
        guard status == noErr, defaultInputDeviceID != 0 else { return false }
        
        var isRunning: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        var isRunningAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        let err = AudioObjectGetPropertyData(defaultInputDeviceID, &isRunningAddress, 0, nil, &size, &isRunning)
        return err == noErr && isRunning != 0
    }
    
    /// Detects if any known conferencing application is actively running
    private func detectActiveVoIPApp() -> String? {
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if let bundleID = app.bundleIdentifier, let appName = knownVoIPApps[bundleID], !app.isTerminated {
                return appName
            }
        }
        return nil
    }
    
    /// Called before playing posture sounds. Returns true if audio should be silenced.
    public func shouldSuppressAudioCue() -> Bool {
        guard isCallMuteEnabled && isInCall else { return false }
        suppressedAlertsCount += 1
        return true
    }
}
