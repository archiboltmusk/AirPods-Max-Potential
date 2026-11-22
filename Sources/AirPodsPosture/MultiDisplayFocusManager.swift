import Foundation
import SwiftUI
import Combine

/// Multi-Display Spatial Focus Manager.
/// Tracks physical head orientation across multi-monitor setups using yaw kinematics.
/// Automatically detects which physical screen the user is directly viewing (Left, Center, Right).
@MainActor
public final class MultiDisplayFocusManager: ObservableObject {
    public static let shared = MultiDisplayFocusManager()
    
    @Published public var isEnabled: Bool = true
    @Published public var activeDisplayId: DisplayZone = .primaryCenter
    @Published public var leftZoneThreshold: Double = -22.0
    @Published public var rightZoneThreshold: Double = 22.0
    @Published public var dwellTimeOnActiveDisplay: Double = 0.0
    @Published public var focusSwitchesToday: Int = 0
    @Published public var focusStatus: String = "Facing Primary Display"
    
    public enum DisplayZone: String, CaseIterable, Identifiable {
        case leftAuxiliary = "Left Auxiliary Screen"
        case primaryCenter = "Center Primary Screen"
        case rightAuxiliary = "Right Auxiliary Screen"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .leftAuxiliary: return "arrow.left.to.line"
            case .primaryCenter: return "macwindow"
            case .rightAuxiliary: return "arrow.right.to.line"
            }
        }
    }
    
    private var lastSwitchTime: Date = Date()
    private var dwellTimer: Timer?
    
    private init() {
        // Dynamic time tracking without continuous 1Hz timer wakeups
    }
    
    public func update(yawDegrees: Double) {
        guard isEnabled else { return }
        
        var detectedZone: DisplayZone = .primaryCenter
        if yawDegrees < leftZoneThreshold {
            detectedZone = .leftAuxiliary
        } else if yawDegrees > rightZoneThreshold {
            detectedZone = .rightAuxiliary
        }
        
        if detectedZone != activeDisplayId {
            activeDisplayId = detectedZone
            dwellTimeOnActiveDisplay = 0.0
            focusSwitchesToday += 1
            lastSwitchTime = Date()
            focusStatus = "Facing \(detectedZone.rawValue)"
        }
    }
}
