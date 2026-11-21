import SwiftUI
import AppKit

@main
struct AirPodsPostureApp: App {
    @StateObject private var motion = MotionManager.shared
    @Environment(\.openWindow) private var openWindow

    init() {
        // Ensure standard macOS app activation policy
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup(id: "main-dashboard") {
            ContentView()
        }
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1160, height: 780)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    NSApp.activate(ignoringOtherApps: true)
                    openWindow(id: "main-dashboard")
                    AppUpdateManager.shared.checkForUpdates()
                }
            }
        }

        MenuBarExtra {
            MenuBarView(motion: motion) {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "main-dashboard")
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
}
