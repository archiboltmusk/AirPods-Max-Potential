import AppKit
import CoreGraphics
import SwiftUI

/// Progressive Screen Blur and Radial Vignette Glow overlay manager.
/// Inspired by tldev/dorso, this creates non-intrusive full-screen overlay panels
/// across all active connected monitors (NSScreen.screens).
@MainActor
public final class ProgressiveScreenBlurManager: ObservableObject {
    public static let shared = ProgressiveScreenBlurManager()
    
    @Published public var isEnabled: Bool = true
    @Published public var blurIntensity: Double = 0.0 // 0.0 to 1.0
    @Published public var selectedColor: NSColor = .systemOrange
    @Published public var reach: Double = 0.65 // 0.3 to 0.95
    @Published public var enableWindowBlur: Bool = true
    
    private var overlayWindows: [NSWindow] = []
    private var glowViews: [GlowVignetteView] = []
    private var blurViews: [NSVisualEffectView] = []
    
    private var displayTimer: Timer? = nil
    private var targetIntensity: Double = 0.0
    
    private init() {
        setupDisplayMonitoring()
    }
    
    private func setupDisplayMonitoring() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rebuildOverlayWindows()
            }
        }
    }
    
    public func update(postureState: PostureState, deltaPitch: Double) {
        guard isEnabled else {
            setTargetIntensity(0.0)
            return
        }
        
        switch postureState {
        case .slouching:
            // Calculate intensity proportional to downward pitch beyond slouch threshold
            let extraSlouch = max(0.0, -deltaPitch - 10.0)
            let calculated = min(1.0, 0.45 + (extraSlouch / 25.0) * 0.55)
            setTargetIntensity(calculated)
        case .warning:
            setTargetIntensity(0.25)
        case .optimal, .snoozed, .disconnected:
            setTargetIntensity(0.0)
        }
    }
    
    public func previewTest(duration: TimeInterval = 3.0) {
        setTargetIntensity(0.85)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.setTargetIntensity(0.0)
        }
    }
    
    private func setTargetIntensity(_ target: Double) {
        targetIntensity = target
        if target > 0 && overlayWindows.isEmpty {
            buildOverlayWindows()
        }
        startAnimationLoop()
    }
    
    private func startAnimationLoop() {
        guard displayTimer == nil else { return }
        displayTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.stepAnimation()
            }
        }
    }
    
    private func stepAnimation() {
        let stepUp = 0.035
        let stepDown = 0.12 // fast recovery when sitting straight
        
        if blurIntensity < targetIntensity {
            blurIntensity = min(targetIntensity, blurIntensity + stepUp)
        } else if blurIntensity > targetIntensity {
            blurIntensity = max(targetIntensity, blurIntensity - stepDown)
        }
        
        applyIntensity(blurIntensity)
        
        if blurIntensity <= 0.001 && targetIntensity <= 0.001 {
            displayTimer?.invalidate()
            displayTimer = nil
            tearDownOverlayWindows()
        }
    }
    
    private func applyIntensity(_ intensity: Double) {
        for glowView in glowViews {
            glowView.intensity = CGFloat(intensity)
            glowView.reach = CGFloat(reach)
            glowView.warningColor = selectedColor
            glowView.needsDisplay = true
        }
        
        for blurView in blurViews {
            blurView.alphaValue = enableWindowBlur ? CGFloat(intensity * 0.65) : 0.0
        }
    }
    
    private func buildOverlayWindows() {
        tearDownOverlayWindows()
        
        for screen in NSScreen.screens {
            let frame = screen.frame
            let window = NSWindow(
                contentRect: frame,
                styleMask: [.borderless],
                backing: .buffered,
                defer: false
            )
            window.isOpaque = false
            window.backgroundColor = .clear
            window.level = .floating
            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            window.ignoresMouseEvents = true
            window.hasShadow = false
            
            let container = NSView(frame: NSRect(origin: .zero, size: frame.size))
            container.wantsLayer = true
            
            // Background soft blur layer
            let blur = NSVisualEffectView(frame: container.bounds)
            blur.autoresizingMask = [.width, .height]
            blur.material = .hudWindow
            blur.blendingMode = .withinWindow
            blur.state = .active
            blur.alphaValue = 0.0
            container.addSubview(blur)
            blurViews.append(blur)
            
            // Radial Glow Vignette Layer
            let glow = GlowVignetteView(frame: container.bounds)
            glow.autoresizingMask = [.width, .height]
            glow.warningColor = selectedColor
            glow.reach = CGFloat(reach)
            glow.intensity = CGFloat(blurIntensity)
            container.addSubview(glow)
            glowViews.append(glow)
            
            window.contentView = container
            window.orderFrontRegardless()
            overlayWindows.append(window)
        }
    }
    
    public func rebuildOverlayWindows() {
        if !overlayWindows.isEmpty {
            buildOverlayWindows()
            applyIntensity(blurIntensity)
        }
    }
    
    private func tearDownOverlayWindows() {
        for window in overlayWindows {
            window.orderOut(nil)
        }
        overlayWindows.removeAll()
        glowViews.removeAll()
        blurViews.removeAll()
    }
}

// MARK: - Radial Glow Vignette Custom View

final class GlowVignetteView: NSView {
    var intensity: CGFloat = 0.0
    var reach: CGFloat = 0.65
    var warningColor: NSColor = .systemOrange
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.isOpaque = false
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
        layer?.isOpaque = false
    }
    
    override func draw(_ dirtyRect: NSRect) {
        guard intensity > 0.005, let ctx = NSGraphicsContext.current?.cgContext else { return }
        
        let bounds = self.bounds
        let centerX = bounds.midX
        let centerY = bounds.midY
        let maxRadius = sqrt(centerX * centerX + centerY * centerY)
        
        let baseInnerRatio = max(0.08, 1.0 - reach)
        let innerRadius = maxRadius * (baseInnerRatio - (intensity * 0.15))
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let alpha = intensity * 0.88
        
        let colors: [CGColor] = [
            NSColor.clear.cgColor,
            warningColor.withAlphaComponent(alpha * 0.18).cgColor,
            warningColor.withAlphaComponent(alpha * 0.55).cgColor,
            warningColor.withAlphaComponent(alpha).cgColor
        ]
        
        let locations: [CGFloat] = [0.0, 0.45, 0.75, 1.0]
        
        guard let gradient = CGGradient(
            colorsSpace: colorSpace,
            colors: colors as CFArray,
            locations: locations
        ) else { return }
        
        ctx.drawRadialGradient(
            gradient,
            startCenter: CGPoint(x: centerX, y: centerY),
            startRadius: innerRadius,
            endCenter: CGPoint(x: centerX, y: centerY),
            endRadius: maxRadius,
            options: [.drawsAfterEndLocation]
        )
    }
}
