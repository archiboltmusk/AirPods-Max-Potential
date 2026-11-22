import Foundation
import AppKit
import Combine
import SwiftUI

/// Ghost Dimming Subconscious Visual Biofeedback Manager.
/// When the user slouches for > 20 seconds, subtly dims the Mac display by 15-20%.
/// The exact millisecond their spine straightens, the screen glides back to 100% brightness.
/// Delivers immediate behavioral correction without audio interruptions.
@MainActor
public final class GhostDimmingBiofeedbackManager: ObservableObject {
    public static let shared = GhostDimmingBiofeedbackManager()
    
    @Published public var isGhostDimmingEnabled: Bool = true
    @Published public var maxDimmingOpacity: Double = 0.22 // 22% subtle dimming
    @Published public var currentDimmingOpacity: Double = 0.0
    @Published public var isCurrentlyDimmed: Bool = false
    
    private var dimmingWindows: [NSWindow] = []
    
    private init() {
        setupDimmingOverlays()
    }
    
    public func setupDimmingOverlays() {
        dimmingWindows.forEach { $0.close() }
        dimmingWindows.removeAll()
        
        for screen in NSScreen.screens {
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.ignoresMouseEvents = true
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            
            let hostView = NSHostingView(rootView: DimmingOverlayCanvasView(manager: self))
            window.contentView = hostView
            window.orderFrontRegardless()
            dimmingWindows.append(window)
        }
    }
    
    /// Triggered continuously from MotionManager's posture state evaluation
    public func updatePostureState(isSlouching: Bool, warningProgress: Double) {
        guard isGhostDimmingEnabled else {
            if currentDimmingOpacity > 0.0 {
                restoreBrightness()
            }
            return
        }
        
        if isSlouching {
            // Smoothly ease in dimming as slouch persists
            let target = maxDimmingOpacity
            withAnimation(.easeInOut(duration: 0.8)) {
                self.currentDimmingOpacity = target
                self.isCurrentlyDimmed = true
            }
        } else {
            // Instantly restore full 100% brightness when upright
            restoreBrightness()
        }
    }
    
    public func restoreBrightness() {
        guard currentDimmingOpacity > 0.0 else { return }
        withAnimation(.easeOut(duration: 0.35)) {
            self.currentDimmingOpacity = 0.0
            self.isCurrentlyDimmed = false
        }
    }
}

public struct DimmingOverlayCanvasView: View {
    @ObservedObject var manager: GhostDimmingBiofeedbackManager
    
    public var body: some View {
        Color.black
            .opacity(manager.currentDimmingOpacity)
            .edgesIgnoringSafeArea(.all)
    }
}
