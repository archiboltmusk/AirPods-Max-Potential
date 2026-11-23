import Foundation

/// Deprecated background audio keeper.
/// CoreMotion maintains Bluetooth telemetry independently. Keeping an audio stream
/// open causes coreaudiod power assertions and triggers macOS "Using Significant Energy".
/// Intentionally disabled to preserve battery.
@MainActor
public final class HeadphoneAudioKeeper: ObservableObject {
    public static let shared = HeadphoneAudioKeeper()
    
    @Published public var isRunning: Bool = false
    
    private init() {}
    
    public func start() {
        // No-op: preserves battery and eliminates coreaudiod power assertions
        isRunning = false
    }
    
    public func stop() {
        isRunning = false
    }
}
