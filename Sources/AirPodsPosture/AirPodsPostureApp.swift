import SwiftUI
import AppKit

@main
struct AirPodsPostureApp: App {
    @StateObject private var motion = MotionManager.shared
    @Environment(\.openWindow) private var openWindow

    init() {
        // Ensure standard macOS app activation policy
        NSApplication.shared.setActivationPolicy(.regular)
        // Strictly disable automatic window tabbing
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        Window("AirPodsIQ", id: "main-dashboard") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1160, height: 780)
        .commands {
            // Disable ⌘N / ⌘T so macOS never spawns extra windows or tabs
            CommandGroup(replacing: .newItem) {}
            
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    activateMainWindow()
                    AppUpdateManager.shared.checkForUpdates()
                }
            }
        }

        MenuBarExtra {
            MenuBarView(motion: motion) {
                activateMainWindow()
            }
        } label: {
            HStack(spacing: 3) {
                let tone: LiveSpineMenuBarGlyph.Tone = !motion.isConnected ? .disconnected : (motion.postureState == .slouching ? .alert : .calm)
                let glyphImage = LiveSpineMenuBarGlyph.image(
                    pitchDegrees: motion.deltaPitch,
                    tone: tone,
                    height: 18,
                    label: motion.isConnected ? "\(Int(motion.deltaPitch))°" : nil
                )
                Image(nsImage: glyphImage)
            }
        }
        .menuBarExtraStyle(.window)
    }
    
    private func activateMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let existing = NSApp.windows.first(where: { !($0 is NSPanel) && $0.canBecomeMain }) {
            existing.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main-dashboard")
        }
    }
}
