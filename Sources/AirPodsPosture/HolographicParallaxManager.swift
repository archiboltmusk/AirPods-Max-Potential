import Foundation
import SwiftUI

@MainActor
public final class HolographicParallaxManager: ObservableObject {
    public static let shared = HolographicParallaxManager()
    
    @Published public var isParallaxEnabled: Bool = true
    @Published public var offsetX: CGFloat = 0.0
    @Published public var offsetY: CGFloat = 0.0
    @Published public var depthIntensity: Double = 1.0
    
    private init() {}
    
    public func update(pitch: Double, yaw: Double) {
        guard isParallaxEnabled else {
            offsetX = 0
            offsetY = 0
            return
        }
        
        // Map degrees to smooth subtle parallax offset (-20px to +20px)
        let targetX = CGFloat(-yaw * 0.75 * depthIntensity)
        let targetY = CGFloat(pitch * 0.75 * depthIntensity)
        
        // Smooth exponential damping
        offsetX = offsetX * 0.8 + targetX * 0.2
        offsetY = offsetY * 0.8 + targetY * 0.2
    }
}
