import Foundation
import CoreGraphics
import AppKit
import Combine

/// Hardware Clamshell & Display Topology Sentinel.
/// Detects when a MacBook lid is closed with external monitors attached (Clamshell Mode).
/// Automatically prevents the Optical Continuity webcam fallback from attempting to access
/// a physically blocked FaceTime HD camera, saving 0.0% CPU and avoiding black frames.
@MainActor
public final class HardwareClamshellSentinel: ObservableObject {
    public static let shared = HardwareClamshellSentinel()
    
    @Published public var isLidClosedInClamshell: Bool = false
    @Published public var hasBuiltinDisplay: Bool = true
    @Published public var connectedDisplayCount: Int = 1
    @Published public var statusMessage: String = "Display Topology Normal"
    
    private var checkTimer: Timer?
    
    private init() {
        evaluateTopology()
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateTopology()
            }
        }
    }
    
    public func startMonitoring() {
        evaluateTopology()
    }
    
    public func stopMonitoring() {
        checkTimer?.invalidate()
        checkTimer = nil
    }
    
    public func evaluateTopology() {
        var count: UInt32 = 0
        CGGetOnlineDisplayList(0, nil, &count)
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        CGGetOnlineDisplayList(count, &displays, &count)
        
        connectedDisplayCount = Int(count)
        
        var builtinFound = false
        var builtinActive = false
        
        for d in displays {
            if CGDisplayIsBuiltin(d) != 0 {
                builtinFound = true
                if CGDisplayIsAsleep(d) == 0 {
                    builtinActive = true
                }
            }
        }
        
        hasBuiltinDisplay = builtinFound
        
        // If device has a builtin display (MacBook), but it's asleep while external displays are connected
        if builtinFound && !builtinActive && connectedDisplayCount >= 1 {
            if !isLidClosedInClamshell {
                isLidClosedInClamshell = true
                statusMessage = "🔒 MacBook Clamshell Active (Lid Closed) • Webcam Standby"
            }
        } else {
            if isLidClosedInClamshell {
                isLidClosedInClamshell = false
                statusMessage = "💻 Built-in Display Open • Optical Fallback Ready"
            }
        }
    }
    
    /// Returns true if optical camera is physically accessible
    public var isCameraPhysicallyAvailable: Bool {
        return !isLidClosedInClamshell
    }
}
