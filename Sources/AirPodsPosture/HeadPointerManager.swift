import Foundation
import CoreGraphics
import AppKit

@MainActor
public final class HeadPointerManager: ObservableObject {
    public static let shared = HeadPointerManager()
    
    @Published public var isScrollEnabled: Bool = false
    public var isEnabled: Bool {
        get { isScrollEnabled }
        set { isScrollEnabled = newValue }
    }
    @Published public var scrollSensitivity: Double = 1.0
    @Published public var activeScrollSpeed: Double = 0.0
    
    private var lastScrollTime: Date = Date()
    
    private init() {}
    
    public func update(deltaPitch: Double) {
        guard isScrollEnabled else {
            activeScrollSpeed = 0
            return
        }
        
        let now = Date()
        guard now.timeIntervalSince(lastScrollTime) > 0.05 else { return }
        lastScrollTime = now
        
        let deadzone = 12.0 // degrees around center
        let excess = abs(deltaPitch) - deadzone
        
        guard excess > 0 else {
            activeScrollSpeed = 0
            return
        }
        
        // Pitch negative = looking down -> scroll down (positive wheel delta in macOS)
        // Pitch positive = looking up -> scroll up (negative wheel delta)
        let direction: Double = deltaPitch < 0 ? -1.0 : 1.0
        let speed = min(18.0, pow(excess / 4.0, 1.4) * scrollSensitivity) * direction
        activeScrollSpeed = speed
        
        let scrollDelta = Int32(speed)
        guard scrollDelta != 0 else { return }
        
        if let scrollEvent = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 1,
            wheel1: scrollDelta,
            wheel2: 0,
            wheel3: 0
        ) {
            scrollEvent.post(tap: .cghidEventTap)
        }
    }
}
