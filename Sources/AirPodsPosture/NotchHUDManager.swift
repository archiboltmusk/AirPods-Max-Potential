import SwiftUI
import AppKit

@MainActor
public final class NotchHUDManager: ObservableObject {
    public static let shared = NotchHUDManager()
    
    @Published public var isHUDEnabled: Bool = false {
        didSet {
            if isHUDEnabled { showHUD() } else { hideHUD() }
        }
    }
    
    private var hudWindow: NSPanel? = nil
    
    private init() {}
    
    public func update(postureState: PostureState) {
        guard isHUDEnabled else {
            hideHUD()
            return
        }
        
        if hudWindow == nil {
            showHUD()
        }
        
        if let hosting = hudWindow?.contentView as? NSHostingView<NotchHUDView> {
            hosting.rootView = NotchHUDView(postureState: postureState)
        }
    }
    
    private func showHUD() {
        guard let screen = NSScreen.main else { return }
        
        let width: CGFloat = 140
        let height: CGFloat = 28
        let x = (screen.frame.width - width) / 2.0
        let y = screen.frame.maxY - height - 4
        
        let rect = NSRect(x: x, y: y, width: width, height: height)
        let panel = NSPanel(
            contentRect: rect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.ignoresMouseEvents = true
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.hasShadow = true
        
        panel.contentView = NSHostingView(rootView: NotchHUDView(postureState: MotionManager.shared.postureState))
        panel.orderFrontRegardless()
        hudWindow = panel
    }
    
    public func hideHUD() {
        hudWindow?.orderOut(nil)
        hudWindow = nil
    }
}

struct NotchHUDView: View {
    let postureState: PostureState
    
    private var color: Color {
        switch postureState {
        case .optimal: return .green
        case .warning: return .orange
        case .slouching: return .red
        case .snoozed: return .blue
        case .disconnected: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .shadow(color: color.opacity(0.8), radius: 4)
            
            Text(postureState.rawValue)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            
            Text("\(MotionManager.shared.postureScore)%")
                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.85))
        .clipShape(Capsule())
        .overlay(Capsule().stroke(color.opacity(0.5), lineWidth: 1.5))
    }
}
