import Foundation
#if canImport(WatchKit)
import WatchKit
#endif
#if canImport(WatchConnectivity)
import WatchConnectivity
#endif

/// Apple Watch Haptic Sentinel ("Phantom Wrist Tap Engine").
/// Delivers zero-audio, directional wrist vibrations to unobtrusively correct posture.
@MainActor
public final class WatchHapticSentinel: NSObject, ObservableObject {
    public static let shared = WatchHapticSentinel()
    
    @Published public var lastHapticTriggerTime: Date?
    @Published public var hapticStyleName: String = "Direction Up (Gentle Tap)"
    @Published public var hapticsEnabled: Bool = true
    
    private override init() {
        super.init()
        #if canImport(WatchConnectivity)
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
        #endif
    }
    
    public func playPhantomWristTap() {
        guard hapticsEnabled else { return }
        #if canImport(WatchKit)
        // Gentle directional upward tap on wrist
        WKInterfaceDevice.current().play(.directionUp)
        lastHapticTriggerTime = Date()
        #endif
    }
    
    public func playSuccessTap() {
        guard hapticsEnabled else { return }
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.success)
        #endif
    }
    
    public func playCrownClick() {
        #if canImport(WatchKit)
        WKInterfaceDevice.current().play(.click)
        #endif
    }
}

#if canImport(WatchConnectivity)
extension WatchHapticSentinel: WCSessionDelegate {
    public nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    
    public nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let command = message["command"] as? String, command == "trigger_haptic" {
            Task { @MainActor in
                self.playPhantomWristTap()
            }
        }
    }
}
#endif
