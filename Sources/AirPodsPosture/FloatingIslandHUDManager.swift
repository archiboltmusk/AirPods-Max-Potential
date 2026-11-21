import SwiftUI
import AppKit

@MainActor
public final class FloatingIslandHUDManager: ObservableObject {
    public static let shared = FloatingIslandHUDManager()
    
    @Published public var isHUDVisible: Bool = false
    
    private var hudPanel: NSPanel?
    
    private init() {
        setupGlobalShortcut()
    }
    
    public func toggleHUD() {
        if isHUDVisible {
            hudPanel?.orderOut(nil)
            isHUDVisible = false
        } else {
            showHUD()
        }
    }
    
    public func showHUD() {
        if hudPanel == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 380, height: 460),
                styleMask: [.nonactivatingPanel, .fullSizeContentView, .borderless],
                backing: .buffered,
                defer: false
            )
            panel.level = .floating
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.isMovableByWindowBackground = true
            
            let contentView = FloatingHUDContentView()
            panel.contentView = NSHostingView(rootView: contentView)
            self.hudPanel = panel
        }
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 190
            let y = screenRect.midY - 230
            hudPanel?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        hudPanel?.makeKeyAndOrderFront(nil)
        isHUDVisible = true
        MotionManager.shared.playFeedbackSound("Hero")
    }
    
    private func setupGlobalShortcut() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            // Cmd + Shift + Space
            if event.modifierFlags.contains([.command, .shift]) && event.keyCode == 49 {
                self?.toggleHUD()
                return nil
            }
            return event
        }
    }
}

public struct FloatingHUDContentView: View {
    @ObservedObject var motion = MotionManager.shared
    
    public var body: some View {
        ZStack {
            // Background Liquid Glass
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.05), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 25, y: 10)
            
            VStack(spacing: 14) {
                // Header Bar
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(motion.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text("AirPodsIQ MiniHUD")
                            .font(.caption.bold())
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Button(action: {
                        FloatingIslandHUDManager.shared.toggleHUD()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Live 3D Spine Widget
                AnatomicalSpine3DView(
                    pitch: motion.deltaPitch,
                    roll: motion.deltaRoll,
                    yaw: motion.deltaYaw,
                    postureScore: motion.postureScore
                )
                .frame(height: 200)
                
                // Quick Statistics
                HStack(spacing: 16) {
                    VStack {
                        Text("\(motion.postureScore)%")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(motion.postureScore >= 80 ? .green : .orange)
                        Text("Alignment")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider().frame(height: 30)
                    
                    VStack {
                        Text(String(format: "%.1f°", motion.deltaPitch))
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("Pitch Angle")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider().frame(height: 30)
                    
                    VStack {
                        Text("\(HydrationTracker.shared.waterGlassesLogged)")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                        Text("Sips Logged")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                
                // Action Buttons Strip
                HStack(spacing: 10) {
                    Button(action: {
                        motion.calibrateCurrentPosture()
                    }) {
                        Label("Calibrate (⌘⇧C)", systemImage: "scope")
                            .font(.caption.bold())
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        Spatial3DAnchorManager.shared.toggleAnchor()
                    }) {
                        Image(systemName: Spatial3DAnchorManager.shared.isAnchorActive ? "dot.radiowaves.left.and.right" : "waveform")
                    }
                    .buttonStyle(.bordered)
                    .help("Toggle 3D Audio Anchor")
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .frame(width: 380, height: 440)
    }
}
