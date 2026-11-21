import Foundation
import AppKit

@MainActor
public final class RaycastIntegrationManager: ObservableObject {
    public static let shared = RaycastIntegrationManager()
    
    @Published public var urlSchemeRegistered: Bool = true
    @Published public var lastCommandExecuted: String = "Ready"
    
    private init() {
        registerCustomURLHandler()
    }
    
    public func registerCustomURLHandler() {
        // Registers airpodsposture:// deeplink scheme for Raycast & Alfred
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURL(event:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }
    
    @objc private func handleGetURL(event: NSAppleEventDescriptor, withReplyEvent replyEvent: NSAppleEventDescriptor) {
        guard let urlString = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: urlString) else { return }
        
        let command = url.host ?? ""
        lastCommandExecuted = command
        
        switch command {
        case "calibrate":
            MotionManager.shared.calibrateCurrentPosture()
        case "snooze":
            MotionManager.shared.snooze(minutes: 15)
        case "toggle-pointer":
            HeadPointerManager.shared.isEnabled.toggle()
        case "toggle-anchor":
            Spatial3DAnchorManager.shared.toggleAnchor()
        case "start-pomodoro":
            ErgonomicPomodoroEngine.shared.startFocusSprint()
        default:
            break
        }
    }
}
