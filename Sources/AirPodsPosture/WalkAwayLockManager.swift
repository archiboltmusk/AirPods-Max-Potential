import Foundation
import AppKit

@MainActor
public final class WalkAwayLockManager: ObservableObject {
    public static let shared = WalkAwayLockManager()
    
    @Published public var isEnabled: Bool = false
    @Published public var gracePeriodSeconds: Double = 12.0
    @Published public var secondsUntilLock: Double = 12.0
    
    private var disconnectDate: Date? = nil
    
    private init() {}
    
    public func update(isConnected: Bool, lastPacketAge: TimeInterval) {
        guard isEnabled else {
            disconnectDate = nil
            return
        }
        
        let isAway = (!isConnected || lastPacketAge > 6.0)
        
        if isAway {
            if disconnectDate == nil {
                disconnectDate = Date()
            }
            
            let elapsed = Date().timeIntervalSince(disconnectDate!)
            secondsUntilLock = max(0, gracePeriodSeconds - elapsed)
            
            if elapsed >= gracePeriodSeconds {
                lockScreenNow()
                disconnectDate = nil
            }
        } else {
            disconnectDate = nil
            secondsUntilLock = gracePeriodSeconds
        }
    }
    
    public func lockScreenNow() {
        // Pause active media
        let pauseScript = "tell application \"Spotify\" to pause\ntell application \"Music\" to pause"
        if let script = NSAppleScript(source: pauseScript) {
            _ = script.executeAndReturnError(nil)
        }
        
        // Execute instant screen lock via login framework SACLockScreenImmediate
        typealias SACLockScreenImmediateFunc = @convention(c) () -> Void
        if let handle = dlopen("/System/Library/PrivateFrameworks/login.framework/Versions/Current/login", RTLD_LAZY) {
            if let sym = dlsym(handle, "SACLockScreenImmediate") {
                let lockFunc = unsafeBitCast(sym, to: SACLockScreenImmediateFunc.self)
                lockFunc()
            }
            dlclose(handle)
        } else {
            // Fallback command
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
            process.arguments = ["displaysleepnow"]
            try? process.run()
        }
    }
}
