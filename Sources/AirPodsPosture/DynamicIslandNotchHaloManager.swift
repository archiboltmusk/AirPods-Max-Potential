import SwiftUI
import AppKit

@MainActor
public final class DynamicIslandNotchHaloManager: ObservableObject {
    public static let shared = DynamicIslandNotchHaloManager()
    
    // Disabled by default to prevent screen obstruction
    @Published public var isEnabled: Bool = false
    @Published public var isExpanded: Bool = false
    @Published public var expansionMessage: String = ""
    
    private var haloPanel: NSPanel?
    private var dismissTimer: Timer?
    
    private init() {
        // Do NOT automatically display or construct the floating window on launch
    }
    
    public func toggleEnabled() {
        if isEnabled {
            dismissAndDisablePermanently()
        } else {
            isEnabled = true
            setupWindow()
            haloPanel?.orderFront(nil)
        }
    }
    
    public func dismissAndDisablePermanently() {
        isEnabled = false
        isExpanded = false
        dismissTimer?.invalidate()
        dismissTimer = nil
        haloPanel?.orderOut(nil)
        haloPanel?.close()
        haloPanel = nil
    }
    
    public func setupWindow() {
        guard isEnabled && NSApp != nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              NSClassFromString("XCTest") == nil else { return }
        guard let screen = NSScreen.main else { return }
        let screenFrame = screen.frame
        
        let initialWidth: CGFloat = 200
        let initialHeight: CGFloat = 32
        
        // Position directly at top-center under the display notch or menu bar
        let xPos = (screenFrame.width - initialWidth) / 2.0
        let yPos = screenFrame.height - initialHeight - (screen.safeAreaInsets.top > 0 ? 0 : 4)
        
        let panel = NSPanel(
            contentRect: NSRect(x: xPos, y: yPos, width: initialWidth, height: initialHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.ignoresMouseEvents = false
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary]
        
        let rootView = DynamicIslandPillView(manager: self)
        panel.contentView = NSHostingView(rootView: rootView)
        self.haloPanel = panel
    }
    
    public func triggerExpansion(message: String, autoDismissSeconds: Double = 4.0) {
        guard isEnabled && NSApp != nil,
              ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil,
              NSClassFromString("XCTest") == nil else { return }
        expansionMessage = message
        withAnimation(.interpolatingSpring(stiffness: 240, damping: 20)) {
            isExpanded = true
        }
        
        updatePanelFrame(width: 340, height: 58)
        
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: autoDismissSeconds, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                withAnimation(.interpolatingSpring(stiffness: 240, damping: 20)) {
                    self.isExpanded = false
                }
                self.updatePanelFrame(width: 200, height: 32)
            }
        }
    }
    
    private func updatePanelFrame(width: CGFloat, height: CGFloat) {
        guard let screen = NSScreen.main, let panel = haloPanel else { return }
        let screenFrame = screen.frame
        let xPos = (screenFrame.width - width) / 2.0
        let yPos = screenFrame.height - height - (screen.safeAreaInsets.top > 0 ? 0 : 4)
        panel.setFrame(NSRect(x: xPos, y: yPos, width: width, height: height), display: true, animate: true)
    }
    
    public func updatePosture(postureState: PostureState, deltaPitch: Double) {
        guard isEnabled else { return }
        if postureState == .slouching && !isExpanded {
            triggerExpansion(message: "Slouch Detected: Pitch \(Int(deltaPitch))°", autoDismissSeconds: 4.5)
        }
    }
}

// MARK: - Dynamic Island Pill View

public struct DynamicIslandPillView: View {
    @ObservedObject var manager: DynamicIslandNotchHaloManager
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var respiratory = AcousticRespiratoryEngine.shared
    
    private var stateColor: Color {
        switch motion.postureState {
        case .optimal: return .green
        case .warning: return .orange
        case .slouching: return .red
        case .snoozed: return .blue
        case .disconnected: return .gray
        }
    }
    
    public var body: some View {
        ZStack {
            // Liquid Black Glass Capsule
            Capsule(style: .continuous)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(
                            stateColor.opacity(manager.isExpanded ? 0.7 : 0.25),
                            lineWidth: manager.isExpanded ? 1.2 : 0.6
                        )
                )
                .shadow(color: stateColor.opacity(manager.isExpanded ? 0.35 : 0.12), radius: 10, x: 0, y: 3)
            
            if manager.isExpanded {
                // Expanded Pill
                HStack(spacing: 12) {
                    Image(systemName: motion.postureState == .slouching ? "exclamationmark.triangle.fill" : "sparkles")
                        .foregroundColor(stateColor)
                        .font(.system(size: 18))
                    
                    VStack(alignment: .leading, spacing: 1) {
                        Text(manager.expansionMessage)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Subtle cervical micro-correction will restore optimal alignment")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Spacer()
                    
                    Text("\(motion.postureScore)%")
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(stateColor)
                }
                .padding(.horizontal, 16)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            } else {
                // Compact Ambient Pill
                HStack(spacing: 8) {
                    Circle()
                        .fill(stateColor)
                        .frame(width: 8, height: 8)
                        .shadow(color: stateColor, radius: 4)
                    
                    Text("\(motion.postureScore)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Divider()
                        .frame(height: 12)
                        .background(Color.white.opacity(0.2))
                    
                    HStack(spacing: 3) {
                        Image(systemName: "lungs.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.indigo)
                        Text("\(respiratory.breathsPerMinute)")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.4))
                    
                    Text("\(Int(motion.deltaPitch))°")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .transition(.opacity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onTapGesture {
            manager.triggerExpansion(message: "AirPods Posture Active • Score: \(motion.postureScore)%")
        }
    }
}
