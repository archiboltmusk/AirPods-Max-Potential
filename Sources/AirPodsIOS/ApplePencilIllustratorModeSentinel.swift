import Foundation
import Combine

/// Apple Pencil & Drafting Table Mode Sentinel for iPadOS.
/// When the user uses Apple Pencil on iPad (Procreate, GoodNotes, Freeform),
/// forward pitch rules automatically adjust to allow a natural 20°–30° drawing tilt.
@MainActor
public final class ApplePencilIllustratorModeSentinel: ObservableObject {
    public static let shared = ApplePencilIllustratorModeSentinel()
    
    @Published public var isPencilActive: Bool = false
    @Published public var dynamicPitchToleranceOffset: Double = 0.0 // Extra degrees allowed
    @Published public var activeAppMode: String = "Standard Desk Posture"
    
    private init() {}
    
    public func activatePencilDrawingSession() {
        self.isPencilActive = true
        self.dynamicPitchToleranceOffset = 18.0 // Allows an extra 18° of natural drawing tilt
        self.activeAppMode = "🎨 Apple Pencil Drafting Mode (+18° Tilt Window)"
    }
    
    public func deactivatePencilDrawingSession() {
        self.isPencilActive = false
        self.dynamicPitchToleranceOffset = 0.0
        self.activeAppMode = "Standard Desk Posture"
    }
}
